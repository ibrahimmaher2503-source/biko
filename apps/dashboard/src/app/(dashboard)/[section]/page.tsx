import { notFound, redirect } from "next/navigation";
import { getDashboardContext } from "@/lib/dashboard";
import { hasPermission } from "@/lib/dashboard-types";
import { DashboardShell, StatePanel, dashboardSections } from "@/app/ui/dashboard-shell";

export const dynamic = "force-dynamic";

const sectionCopy: Record<string, { title: string; description: string }> = {
  overview: {
    title: "جاهز للتشغيل ضمن نطاقك",
    description: "ستظهر المؤشرات والعمليات المصرّح بها هنا بعد تفعيل عقود القراءة الخاصة بكل قسم.",
  },
  orders: { title: "لا توجد طلبات معروضة", description: "لم تُحمّل طلبات ضمن نطاقك بعد." },
  offers: { title: "لا توجد عروض معروضة", description: "لم تصل عروض ضمن نطاقك بعد." },
  drivers: { title: "لا توجد سجلات سائقين", description: "لا توجد سجلات متاحة لهذا النطاق." },
  verification: { title: "قائمة التحقق فارغة", description: "لا توجد طلبات تحقق معلّقة حاليًا." },
  motorcycles: { title: "لا توجد مركبات", description: "لم تُسجّل مركبات ضمن نطاقك بعد." },
  users: { title: "لا توجد سجلات مستخدمين", description: "لا توجد سجلات مستخدمين متاحة لهذا الدور." },
  offices: { title: "لا توجد مكاتب", description: "لا توجد مكاتب متاحة لهذا الدور." },
  reports: { title: "لا توجد تقارير", description: "ستظهر التقارير عند توفر بياناتها المصرّح بها." },
  finance: { title: "لا توجد بيانات مالية", description: "لا توجد ملخصات مالية متاحة لهذا النطاق." },
  roles: { title: "لا توجد إدارة أدوار", description: "إدارة الأدوار متاحة فقط للصلاحيات المخصصة لها." },
  settings: { title: "لا توجد إعدادات قابلة للتعديل", description: "لا توجد إعدادات تشغيلية متاحة لهذا الدور." },
  audit: { title: "لا توجد أحداث تدقيق", description: "ستظهر الأحداث بعد تنفيذ عمليات حساسة." },
};

export default async function DashboardSectionPage({
  params,
}: {
  params: Promise<{ section: string }>;
}) {
  const { section } = await params;
  const sectionDefinition = dashboardSections.find((item) => item.slug === section);
  if (!sectionDefinition) notFound();

  const result = await getDashboardContext();
  if (result.state === "unauthenticated") redirect(`/login?next=/${section}`);
  if (result.state === "suspended") redirect("/suspended");
  if (result.state === "denied") redirect(`/denied?reason=${result.reason}`);
  if (result.state === "error") {
    return (
      <DashboardShell
        context={{
          authenticated: true,
          staff: false,
          user_id: "",
          profile_type: "",
          status: "",
          full_name: "",
          email: "",
          platform_roles: [],
          office_memberships: [],
        }}
        activeSection={section}
      >
        <StatePanel eyebrow="خطأ مؤقت" title="تعذر تحميل لوحة بيكو" description={result.message} tone="error" />
      </DashboardShell>
    );
  }

  if (!hasPermission(result.context, sectionDefinition.permission)) {
    return (
      <DashboardShell context={result.context} activeSection={section}>
        <StatePanel
          eyebrow="403 · ممنوع"
          title="لا تملك صلاحية هذا القسم"
          description="اطلب من مسؤول المنصة مراجعة دورك أو نطاق مكتبك. لم يتم تحميل أي بيانات محمية."
          tone="warning"
        />
      </DashboardShell>
    );
  }

  const copy = sectionCopy[section] ?? sectionCopy.overview;
  return (
    <DashboardShell context={result.context} activeSection={section}>
      <section className="content-grid" aria-label={sectionDefinition.label}>
        <div className="section-heading">
          <div>
            <p className="eyebrow">{sectionDefinition.label}</p>
            <h2>{copy.title}</h2>
          </div>
          <span className="permission-chip">{sectionDefinition.permission}</span>
        </div>
        <StatePanel title={copy.title} description={copy.description} />
      </section>
    </DashboardShell>
  );
}
