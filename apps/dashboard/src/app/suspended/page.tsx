import Link from "next/link";

export default function SuspendedPage() {
  return (
    <main className="auth-page">
      <section className="auth-card state-card" role="alert">
        <div className="brand-lockup"><span className="brand-mark" aria-hidden="true">B</span><span>بيكو</span></div>
        <p className="eyebrow">الحساب معلّق</p>
        <h1>لا يمكن فتح لوحة بيكو الآن</h1>
        <p className="auth-intro">حسابك أو عضويتك معلّقة. لم يتم تحميل أي بيانات تشغيلية. تواصل مع مسؤول المنصة لاستعادة الوصول.</p>
        <Link className="button button-primary" href="/login">العودة إلى الدخول</Link>
      </section>
    </main>
  );
}
