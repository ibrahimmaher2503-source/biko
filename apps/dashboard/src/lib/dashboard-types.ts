export type DashboardPermission = string;

export type DashboardRole = {
  code: string;
  name: string;
  scope_type: string;
  permissions: DashboardPermission[];
};

export type OfficeMembership = {
  office_id: string;
  office_name: string;
  role_code: string;
  role_name: string;
  permissions: DashboardPermission[];
};

export type DashboardContext = {
  authenticated: boolean;
  staff: boolean;
  user_id: string;
  profile_type: string;
  status: string;
  full_name: string;
  email: string;
  platform_roles: DashboardRole[];
  office_memberships: OfficeMembership[];
};

export type DashboardLoad =
  | { state: "ready"; context: DashboardContext }
  | { state: "unauthenticated" }
  | { state: "denied"; reason: "not-staff" | "deleted" | "no-profile" }
  | { state: "suspended" }
  | { state: "error"; message: string };

export type AdminRole = {
  id: string;
  code: string;
  name: string;
  scope_type: string;
};

export type AdminPermission = {
  id: string;
  code: string;
  description: string;
};

export type AdminStaff = {
  id: string;
  full_name: string;
  status: string;
};

export type AdminOffice = {
  id: string;
  name: string;
  status: string;
};

export type DashboardOffice = {
  id: string;
  name: string;
  responsible_person: string | null;
  phone: string | null;
  address: string | null;
  area: string | null;
  status: string;
  created_at: string;
  updated_at: string;
};

export type OfficeStats = {
  driver_count: number;
  active_driver_count: number;
  motorcycle_count: number;
  order_count: number;
  active_order_count: number;
  completed_order_count: number;
  cancelled_order_count: number;
};

export type DashboardOfficeRow = DashboardOffice & { stats: OfficeStats };

export type AdminOfficesData = {
  offices: DashboardOfficeRow[];
  total_count: number;
};

export type AdminRoleAssignment = {
  user_id: string;
  role_id: string;
};

export type AdminOfficeMembership = {
  user_id: string;
  role_id: string;
  office_id: string;
  status: string;
};

export type AdminStaffData = {
  roles: AdminRole[];
  permissions: AdminPermission[];
  rolePermissions: Array<{ role_id: string; permission_id: string }>;
  staff: AdminStaff[];
  offices: AdminOffice[];
  roleAssignments: AdminRoleAssignment[];
  officeMemberships: AdminOfficeMembership[];
};

export type AdminOfficeStaffMember = {
  id: string;
  office_id: string;
  user_id: string;
  full_name: string;
  email: string;
  phone: string;
  profile_status: string;
  membership_status: string;
  role_id: string;
  role_code: string;
  role_name: string;
  role_scope_type: string;
  created_at: string;
  updated_at: string;
};

export type AdminOfficeStaffData = {
  members: AdminOfficeStaffMember[];
  roles: AdminRole[];
};

export function hasPermission(context: DashboardContext, permission: string) {
  return (
    context.platform_roles.some((role) => role.code === "SUPER_ADMIN") ||
    context.platform_roles.some((role) => role.permissions.includes(permission)) ||
    context.office_memberships.some((membership) => membership.permissions.includes(permission))
  );
}
