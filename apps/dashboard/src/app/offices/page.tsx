import { redirect } from "next/navigation";
import { getAdminOfficesData, getDashboardContext } from "@/lib/dashboard";
import { hasPermission } from "@/lib/dashboard-types";
import { DashboardShell, StatePanel } from "@/app/ui/dashboard-shell";
import { OfficesClient } from "./offices-client";

export const dynamic = "force-dynamic";

export default async function OfficesPage() {
  const contextResult = await getDashboardContext();
  if (contextResult.state === "unauthenticated") redirect("/login?next=/offices");
  if (contextResult.state === "suspended") redirect("/suspended");
  if (contextResult.state === "denied") redirect(`/denied?reason=${contextResult.reason}`);
  if (contextResult.state === "error") {
    return <StatePanel eyebrow="خطأ مؤقت" title="تعذر التحقق من الوصول" description={contextResult.message} tone="error" />;
  }

  if (!hasPermission(contextResult.context, "offices.view")) {
    return (
      <DashboardShell context={contextResult.context} activeSection="offices">
        <StatePanel eyebrow="403 · ممنوع" title="لا تملك صلاحية عرض المكاتب" description="لم يتم تحميل أي بيانات محمية." tone="warning" />
      </DashboardShell>
    );
  }

  const dataResult = await getAdminOfficesData();
  if (dataResult.state === "error") {
    return (
      <DashboardShell context={contextResult.context} activeSection="offices">
        <StatePanel eyebrow="خطأ مؤقت" title="تعذر تحميل المكاتب" description={dataResult.message} tone="error" />
      </DashboardShell>
    );
  }

  return (
    <DashboardShell context={contextResult.context} activeSection="offices">
      <OfficesClient data={dataResult.data} context={contextResult.context} />
    </DashboardShell>
  );
}
