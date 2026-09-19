import type { ReactNode } from "react";
import Link from "next/link";
import { logout } from "@/app/actions";
import { hasPermission, type DashboardContext } from "@/lib/dashboard-types";

export const dashboardSections = [
  { slug: "overview", label: "نظرة عامة", permission: "dashboard.view" },
  { slug: "orders", label: "الطلبات", permission: "orders.view" },
  { slug: "offers", label: "العروض", permission: "bids.view" },
  { slug: "drivers", label: "السائقون", permission: "drivers.view" },
  { slug: "verification", label: "التحقق", permission: "drivers.verify" },
  { slug: "motorcycles", label: "المركبات", permission: "motorcycles.view" },
  { slug: "users", label: "المستخدمون", permission: "users.view" },
  { slug: "offices", label: "المكاتب", permission: "offices.view" },
  { slug: "reports", label: "التقارير", permission: "reports.view" },
  { slug: "finance", label: "المالية", permission: "finance.view" },
  { slug: "roles", label: "الأدوار والصلاحيات", permission: "roles.view" },
  { slug: "settings", label: "الإعدادات", permission: "settings.view" },
  { slug: "audit", label: "سجل التدقيق", permission: "audit.view" },
] as const;

export function StatePanel({
  eyebrow,
  title,
  description,
  tone = "neutral",
}: {
  eyebrow?: string;
  title: string;
  description: string;
  tone?: "neutral" | "error" | "warning";
}) {
  return (
    <section className={`state-panel state-${tone}`} role={tone === "error" ? "alert" : undefined}>
      {eyebrow && <p className="eyebrow">{eyebrow}</p>}
      <h2>{title}</h2>
      <p>{description}</p>
    </section>
  );
}

function scopeLabel(context: DashboardContext) {
  const offices = context.office_memberships.map((membership) => membership.office_name);
  if (offices.length) return offices.join("، ");
  return context.platform_roles.length ? "نطاق المنصة" : "لا يوجد نطاق نشط";
}

export function DashboardShell({
  context,
  activeSection,
  children,
}: {
  context: DashboardContext;
  activeSection: string;
  children: ReactNode;
}) {
  const availableSections = dashboardSections.filter((section) =>
    hasPermission(context, section.permission),
  );
  const current = dashboardSections.find((section) => section.slug === activeSection);

  return (
    <div className="dashboard-frame">
      <aside className="sidebar" aria-label="التنقل الرئيسي">
        <Link className="sidebar-brand" href="/overview">
          <span className="brand-mark" aria-hidden="true">B</span>
          <span>بيكو</span>
        </Link>
        <div className="sidebar-context">
          <span>النطاق الحالي</span>
          <strong>{scopeLabel(context)}</strong>
        </div>
        <nav className="sidebar-nav">
          {availableSections.map((section) => (
            <Link
              key={section.slug}
              href={`/${section.slug}`}
              className={section.slug === activeSection ? "nav-link nav-link-active" : "nav-link"}
              aria-current={section.slug === activeSection ? "page" : undefined}
            >
              {section.label}
            </Link>
          ))}
        </nav>
        <form className="sidebar-footer" action={logout}>
          <div className="user-summary">
            <strong>{context.full_name}</strong>
            <span dir="ltr">{context.email}</span>
          </div>
          <button className="logout-button" type="submit">تسجيل الخروج</button>
        </form>
      </aside>

      <main className="dashboard-main">
        <header className="dashboard-header">
          <div>
            <p className="eyebrow">لوحة بيكو</p>
            <h1>{current?.label ?? "لوحة الإدارة"}</h1>
          </div>
          <div className="scope-pill" aria-label={`النطاق: ${scopeLabel(context)}`}>
            <span className="status-dot" aria-hidden="true" />
            <span>{scopeLabel(context)}</span>
          </div>
        </header>
        <div className="breadcrumb" aria-label="مسار التنقل">
          <Link href="/overview">الرئيسية</Link>
          <span aria-hidden="true">/</span>
          <span>{current?.label ?? "قسم"}</span>
        </div>
        {children}
      </main>
    </div>
  );
}
