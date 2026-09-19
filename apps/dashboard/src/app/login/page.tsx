import { Suspense } from "react";
import { LoginForm } from "./login-form";

export default function LoginPage() {
  return (
    <main className="auth-page">
      <section className="auth-card" aria-labelledby="login-title">
        <div className="brand-lockup">
          <span className="brand-mark" aria-hidden="true">B</span>
          <span>بيكو</span>
        </div>
        <p className="eyebrow">لوحة التشغيل والإدارة</p>
        <h1 id="login-title">مرحبًا بك في لوحة بيكو</h1>
        <p className="auth-intro">سجّل الدخول بحساب موظف نشط للوصول إلى نطاقك المصرّح.</p>
        <Suspense fallback={<div className="loading-block" aria-label="جارٍ التحميل" />}>
          <LoginForm />
        </Suspense>
      </section>
    </main>
  );
}
