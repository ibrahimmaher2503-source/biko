import { createClient } from "@/lib/supabase/server";
import type {
  AdminRole,
  AdminPermission,
  AdminStaff,
  AdminOffice,
  AdminRoleAssignment,
  AdminOfficeMembership,
  AdminStaffData,
  AdminOfficesData,
  DashboardContext,
  DashboardLoad,
} from "@/lib/dashboard-types";

type RecordValue = Record<string, unknown>;

function record(value: unknown): RecordValue {
  return value && typeof value === "object" && !Array.isArray(value)
    ? (value as RecordValue)
    : {};
}

function stringValue(value: unknown, fallback = "") {
  return typeof value === "string" ? value : fallback;
}

function permissions(value: unknown) {
  return Array.isArray(value)
    ? value.filter((item): item is string => typeof item === "string")
    : [];
}

function normalizeContext(value: unknown, profile: RecordValue, email: string) {
  const source = record(value);
  const roles = Array.isArray(source.platform_roles) ? source.platform_roles : [];
  const memberships = Array.isArray(source.office_memberships)
    ? source.office_memberships
    : [];

  return {
    authenticated: source.authenticated === true,
    staff: source.staff === true,
    user_id: stringValue(source.user_id),
    profile_type: stringValue(source.profile_type, stringValue(profile.profile_type)),
    status: stringValue(source.status, stringValue(profile.status)),
    full_name: stringValue(profile.full_name, email.split("@")[0] || "مستخدم بيكو"),
    email,
    platform_roles: roles.map((role) => {
      const item = record(role);
      return {
        code: stringValue(item.code),
        name: stringValue(item.name, "دور منصة"),
        scope_type: stringValue(item.scope_type, "PLATFORM"),
        permissions: permissions(item.permissions),
      };
    }),
    office_memberships: memberships.map((membership) => {
      const item = record(membership);
      return {
        office_id: stringValue(item.office_id),
        office_name: stringValue(item.office_name, "مكتب غير مسمى"),
        role_code: stringValue(item.role_code),
        role_name: stringValue(item.role_name, "عضوية مكتب"),
        permissions: permissions(item.permissions),
      };
    }),
  } satisfies DashboardContext;
}

export async function getDashboardContext(): Promise<DashboardLoad> {
  const supabase = await createClient();
  const { data: claimsData, error: claimsError } = await supabase.auth.getClaims();

  if (claimsError) return { state: "error", message: "تعذر التحقق من جلسة الدخول." };
  const userId = typeof claimsData?.claims?.sub === "string" ? claimsData.claims.sub : "";
  const email = typeof claimsData?.claims?.email === "string" ? claimsData.claims.email : "";
  if (!userId) return { state: "unauthenticated" };

  const { data: profile, error: profileError } = await supabase
    .from("profiles")
    .select("full_name, profile_type, status")
    .eq("id", userId)
    .maybeSingle();

  if (profileError) return { state: "error", message: "تعذر تحميل حالة الحساب." };
  if (!profile) return { state: "denied", reason: "no-profile" };
  if (profile.status === "SUSPENDED") return { state: "suspended" };
  if (profile.status === "DELETED") return { state: "denied", reason: "deleted" };

  const { data: contextData, error: contextError } = await supabase.rpc(
    "get_dashboard_context",
  );

  if (contextError) return { state: "error", message: "تعذر تحميل صلاحيات لوحة الإدارة." };

  const context = normalizeContext(contextData, profile, email);
  return context.staff ? { state: "ready", context } : { state: "denied", reason: "not-staff" };
}

export async function getAdminStaffData(): Promise<
  { state: "ready"; data: AdminStaffData } | { state: "error"; message: string }
> {
  const supabase = await createClient();
  const [roles, permissions, rolePermissions, staff, offices, roleAssignments, officeMemberships] =
    await Promise.all([
      supabase.from("roles").select("id, code, name, scope_type").order("name"),
      supabase.from("permissions").select("id, code, description").order("code"),
      supabase.from("role_permissions").select("role_id, permission_id"),
      supabase
        .from("profiles")
        .select("id, full_name, status")
        .eq("profile_type", "STAFF")
        .order("full_name"),
      supabase.from("offices").select("id, name, status").order("name"),
      supabase.from("user_roles").select("user_id, role_id"),
      supabase.from("office_members").select("user_id, role_id, office_id, status"),
    ]);

  const firstError = [
    roles.error,
    permissions.error,
    rolePermissions.error,
    staff.error,
    offices.error,
    roleAssignments.error,
    officeMemberships.error,
  ].find(Boolean);
  if (firstError) {
    return { state: "error", message: "تعذر تحميل كتالوج الأدوار وموظفي المنصة." };
  }

  return {
    state: "ready",
    data: {
      roles: (roles.data ?? []) as AdminRole[],
      permissions: (permissions.data ?? []) as AdminPermission[],
      rolePermissions: (rolePermissions.data ?? []) as Array<{
        role_id: string;
        permission_id: string;
      }>,
      staff: (staff.data ?? []) as AdminStaff[],
      offices: (offices.data ?? []) as AdminOffice[],
      roleAssignments: (roleAssignments.data ?? []) as AdminRoleAssignment[],
      officeMemberships: (officeMemberships.data ?? []) as AdminOfficeMembership[],
    },
  };
}

export async function getAdminOfficesData(): Promise<
  { state: "ready"; data: AdminOfficesData } | { state: "error"; message: string }
> {
  const supabase = await createClient();
  const { data, error } = await supabase.rpc("admin_list_offices", {
    p_search: null,
    p_status: null,
    p_office_id: null,
    p_limit: 100,
    p_offset: 0,
  });
  if (error) return { state: "error", message: "تعذر تحميل بيانات المكاتب." };

  const officesData = (data ?? []) as Array<{
    id: string;
    name: string;
    responsible_person: string | null;
    phone: string | null;
    address: string | null;
    area: string | null;
    status: string;
    created_at: string;
    updated_at: string;
    driver_count: number;
    active_driver_count: number;
    motorcycle_count: number;
    order_count: number;
    active_order_count: number;
    completed_order_count: number;
    cancelled_order_count: number;
    total_count: number;
  }>;

  return {
    state: "ready",
    data: {
      offices: officesData.map((office) => ({
        id: office.id,
        name: office.name,
        responsible_person: office.responsible_person,
        phone: office.phone,
        address: office.address,
        area: office.area,
        status: office.status,
        created_at: office.created_at,
        updated_at: office.updated_at,
        stats: {
          driver_count: Number(office.driver_count),
          active_driver_count: Number(office.active_driver_count),
          motorcycle_count: Number(office.motorcycle_count),
          order_count: Number(office.order_count),
          active_order_count: Number(office.active_order_count),
          completed_order_count: Number(office.completed_order_count),
          cancelled_order_count: Number(office.cancelled_order_count),
        },
      })),
      total_count: Number(officesData[0]?.total_count ?? officesData.length),
    },
  };
}
