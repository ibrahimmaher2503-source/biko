import { redirect } from "next/navigation";
import { getAdminOfficeStaffData, getAdminOfficesData, getDashboardContext } from "@/lib/dashboard";
import { DashboardShell, StatePanel } from "@/app/ui/dashboard-shell";
import { OfficeStaffClient } from "./office-staff-client";

export const dynamic = "force-dynamic";

type SearchParams = { office_id?: string | string[] };

function firstParam(value: string | string[] | undefined) {
  return Array.isArray(value) ? value[0] : value;
}

export default async function OfficeStaffPage({
  searchParams,
}: {
  searchParams?: Promise<SearchParams>;
}) {
  const contextResult = await getDashboardContext();
  if (contextResult.state === "unauthenticated") redirect("/login?next=/office-staff");
  if (contextResult.state === "suspended") redirect("/suspended");
  if (contextResult.state === "denied") redirect(`/denied?reason=${contextResult.reason}`);
  if (contextResult.state === "error") {
    return <StatePanel eyebrow="خطأ مؤقت" title="تعذر التحقق من الوصول" description={contextResult.message} tone="error" />;
  }

  const context = contextResult.context;
  const isSuperAdmin = context.platform_roles.some((role) => role.code === "SUPER_ADMIN");
  const manageableMemberships = context.office_memberships.filter((membership) =>
    membership.permissions.includes("office_members.manage"),
  );

  const options = isSuperAdmin
    ? await getAdminOfficesData()
    : { state: "ready" as const, data: null };
  if (options.state === "error") {
    return <DashboardShell context={context} activeSection="office-staff"><StatePanel eyebrow="خطأ مؤقت" title="تعذر تحميل المكاتب" description={options.message} tone="error" /></DashboardShell>;
  }

  const offices = isSuperAdmin
    ? (options.data?.offices ?? [])
        .filter((office) => office.status === "ACTIVE")
        .map((office) => ({ id: office.id, name: office.name, status: office.status }))
    : manageableMemberships.map((membership) => ({
        id: membership.office_id,
        name: membership.office_name,
        status: "ACTIVE",
      }));
  const uniqueOffices = offices.filter((office, index, all) => all.findIndex((item) => item.id === office.id) === index);
  const requestedOfficeId = firstParam((await searchParams)?.office_id);
  const selectedOfficeId = uniqueOffices.some((office) => office.id === requestedOfficeId)
    ? requestedOfficeId
    : uniqueOffices[0]?.id;

  if (!selectedOfficeId) {
    return (
      <DashboardShell context={context} activeSection="office-staff">
        <StatePanel
          eyebrow="موظفو المكتب"
          title="لا يوجد مكتب متاح للإدارة"
          description="تحتاج إلى عضوية نشطة بصلاحية office_members.manage، أو يجب تجهيز مكتب نشط للمنصة."
          tone="warning"
        />
      </DashboardShell>
    );
  }

  const canManage = isSuperAdmin || manageableMemberships.some((membership) => membership.office_id === selectedOfficeId);
  if (!canManage) {
    return (
      <DashboardShell context={context} activeSection="office-staff">
        <StatePanel eyebrow="403 · ممنوع" title="لا تملك إدارة موظفي هذا المكتب" description="اختيار المكتب لا يغيّر نطاق العضوية المصرّح بها." tone="warning" />
      </DashboardShell>
    );
  }

  const staffResult = await getAdminOfficeStaffData(selectedOfficeId);
  if (staffResult.state === "error") {
    return <DashboardShell context={context} activeSection="office-staff"><StatePanel eyebrow="خطأ مؤقت" title="تعذر تحميل موظفي المكتب" description={staffResult.message} tone="error" /></DashboardShell>;
  }

  const selectedOffice = uniqueOffices.find((office) => office.id === selectedOfficeId);
  return (
    <DashboardShell context={context} activeSection="office-staff">
      <OfficeStaffClient
        context={context}
        data={staffResult.data}
        offices={uniqueOffices}
        selectedOffice={selectedOffice ?? { id: selectedOfficeId, name: "المكتب", status: "ACTIVE" }}
        canManage={canManage}
      />
    </DashboardShell>
  );
}
