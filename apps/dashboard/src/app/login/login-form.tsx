"use client";

import { FormEvent, useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { createClient } from "@/lib/supabase/client";

type FormMode = "login" | "reset";

export function LoginForm() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const [mode, setMode] = useState<FormMode>("login");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [message, setMessage] = useState("");
  const [error, setError] = useState("");
  const [pending, setPending] = useState(false);

  const initialMessage =
    searchParams.get("message") === "logged-out"
      ? "تم تسجيل الخروج بأمان."
      : searchParams.get("message") === "password-updated"
        ? "تم تحديث كلمة المرور. سجّل الدخول من جديد."
        : "";

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setPending(true);
    setError("");
    setMessage("");

    const supabase = createClient();
    const result =
      mode === "login"
        ? await supabase.auth.signInWithPassword({ email, password })
        : await supabase.auth.resetPasswordForEmail(email, {
            redirectTo: `${window.location.origin}/auth/callback?next=/reset-password`,
          });

    setPending(false);
    if (result.error) {
      setError(
        mode === "login"
          ? "بيانات الدخول غير صحيحة أو الحساب غير متاح."
          : "تعذر إرسال رابط الاستعادة. حاول مرة أخرى.",
      );
      return;
    }

    if (mode === "reset") {
      setMessage("أرسلنا رابط استعادة كلمة المرور إلى بريدك إذا كان مسجلًا.");
      return;
    }

    const next = searchParams.get("next");
    const destination = next?.startsWith("/") && !next.startsWith("//") ? next : "/overview";
    router.replace(destination);
    router.refresh();
  }

  return (
    <form className="auth-form" onSubmit={submit}>
      <div className="field">
        <label htmlFor="email">البريد الإلكتروني</label>
        <input
          id="email"
          name="email"
          type="email"
          dir="ltr"
          autoComplete="email"
          required
          value={email}
          onChange={(event) => setEmail(event.target.value)}
        />
      </div>

      {mode === "login" && (
        <div className="field">
          <label htmlFor="password">كلمة المرور</label>
          <input
            id="password"
            name="password"
            type="password"
            autoComplete="current-password"
            required
            minLength={6}
            value={password}
            onChange={(event) => setPassword(event.target.value)}
          />
        </div>
      )}

      {error && <p className="form-message form-message-error" role="alert">{error}</p>}
      {!message && initialMessage && <p className="form-message form-message-success" role="status">{initialMessage}</p>}
      {message && <p className="form-message form-message-success" role="status">{message}</p>}

      <button className="button button-primary" type="submit" disabled={pending}>
        {pending ? "جارٍ التنفيذ…" : mode === "login" ? "دخول آمن" : "إرسال رابط الاستعادة"}
      </button>

      <button
        className="button button-link"
        type="button"
        onClick={() => {
          setMode(mode === "login" ? "reset" : "login");
          setError("");
          setMessage("");
        }}
      >
        {mode === "login" ? "نسيت كلمة المرور؟" : "العودة إلى تسجيل الدخول"}
      </button>
    </form>
  );
}
