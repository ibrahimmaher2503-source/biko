"use client";

import { FormEvent, useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";

export function PasswordForm() {
  const router = useRouter();
  const [password, setPassword] = useState("");
  const [confirmation, setConfirmation] = useState("");
  const [error, setError] = useState("");
  const [pending, setPending] = useState(false);

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setError("");
    if (password.length < 6 || password !== confirmation) {
      setError("استخدم كلمة مرور من 6 أحرف على الأقل وتأكد من تطابقها.");
      return;
    }
    setPending(true);
    const { error: updateError } = await createClient().auth.updateUser({ password });
    setPending(false);
    if (updateError) {
      setError("تعذر تحديث كلمة المرور. اطلب رابط استعادة جديدًا.");
      return;
    }
    await createClient().auth.signOut();
    router.replace("/login?message=password-updated");
  }

  return (
    <form className="auth-form" onSubmit={submit}>
      <div className="field">
        <label htmlFor="password">كلمة المرور الجديدة</label>
        <input id="password" type="password" minLength={6} required value={password} onChange={(e) => setPassword(e.target.value)} />
      </div>
      <div className="field">
        <label htmlFor="confirmation">تأكيد كلمة المرور</label>
        <input id="confirmation" type="password" minLength={6} required value={confirmation} onChange={(e) => setConfirmation(e.target.value)} />
      </div>
      {error && <p className="form-message form-message-error" role="alert">{error}</p>}
      <button className="button button-primary" type="submit" disabled={pending}>
        {pending ? "جارٍ الحفظ…" : "حفظ كلمة المرور"}
      </button>
    </form>
  );
}
