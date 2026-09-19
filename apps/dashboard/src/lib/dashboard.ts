import { createClient } from "@/lib/supabase/server";
import type {
  AdminRole,
  AdminPermission,
  AdminStaff,
  AdminOffice,
  AdminRoleAssignment,
  AdminOfficeMembership,
  AdminStaffData,
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
