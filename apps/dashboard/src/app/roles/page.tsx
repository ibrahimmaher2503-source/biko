import { redirect } from "next/navigation";
import { getAdminStaffData, getDashboardContext } from "@/lib/dashboard";
import { hasPermission } from "@/lib/dashboard-types";
import { DashboardShell, StatePanel } from "@/app/ui/dashboard-shell";
import { RolesStaffClient } from "./roles-staff-client";

export const dynamic = "force-dynamic";

export default async function RolesPage() {
  const contextResult = await getDashboardContext();
  if (contextResult.state === "unauthenticated") redirect("/login?next=/roles");
  if (contextResult.state === "suspended") redirect("/suspended");
  if (contextResult.state === "denied") redirect(`/denied?reason=${contextResult.reason}`);
  if (contextResult.state === "error") {
    return <StatePanel eyebrow="خطأ مؤقت" title="تعذر التحقق من الوصول" description={contextResult.message} tone="error" />;
  }
  if (!hasPermission(contextResult.context, "roles.view")) {
    return <DashboardShell context={contextResult.context} activeSection="roles"><StatePanel eyebrow="403 · ممنوع" title="لا تملك صلاحية إدارة الأدوار" description="لم يتم تحميل كتالوج الأدوار أو الموظفين." tone="warning" /></DashboardShell>;
  }

  const dataResult = await getAdminStaffData();
  if (dataResult.state === "error") {
    return <DashboardShell context={contextResult.context} activeSection="roles"><StatePanel eyebrow="خطأ مؤقت" title="تعذر تحميل كتالوج الأدوار" description={dataResult.message} tone="error" /></DashboardShell>;
  }

  return <DashboardShell context={contextResult.context} activeSection="roles"><RolesStaffClient data={dataResult.data} context={contextResult.context} /></DashboardShell>;
}
