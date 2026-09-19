import { PasswordForm } from "./password-form";

export default function ResetPasswordPage() {
  return (
    <main className="auth-page">
      <section className="auth-card" aria-labelledby="reset-title">
        <div className="brand-lockup"><span className="brand-mark" aria-hidden="true">B</span><span>بيكو</span></div>
        <p className="eyebrow">استعادة الوصول</p>
        <h1 id="reset-title">أنشئ كلمة مرور جديدة</h1>
        <p className="auth-intro">اختر كلمة مرور جديدة لحساب لوحة بيكو.</p>
        <PasswordForm />
      </section>
    </main>
  );
}
