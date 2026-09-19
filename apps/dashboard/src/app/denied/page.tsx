import Link from "next/link";

export default function DeniedPage() {
  return (
    <main className="auth-page">
      <section className="auth-card state-card" role="alert">
        <div className="brand-lockup"><span className="brand-mark" aria-hidden="true">B</span><span>بيكو</span></div>
        <p className="eyebrow">403 · وصول غير مصرح</p>
        <h1>هذا الحساب ليس موظف لوحة</h1>
        <p className="auth-intro">تم رفض الوصول قبل تحميل أي بيانات محمية. استخدم حساب STAFF نشطًا أو تواصل مع مسؤول المنصة.</p>
        <Link className="button button-primary" href="/login">العودة إلى الدخول</Link>
      </section>
    </main>
  );
}
