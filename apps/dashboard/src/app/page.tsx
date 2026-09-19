const projects = [
  ["الطلبات والمزايدات", "مخطط قاعدة البيانات قيد التنفيذ"],
  ["السائقون والمكاتب", "العزل والصلاحيات تأتي في المرحلة الثالثة"],
  ["التشغيل المباشر", "يبدأ بعد اكتمال تدفق الطلب الأساسي"],
];

export default function Home() {
  return (
    <main className="mx-auto flex min-h-screen max-w-5xl flex-col justify-center px-6 py-16">
      <p className="mb-3 text-sm font-semibold text-teal-700">بيكو</p>
      <h1 className="max-w-2xl text-4xl font-bold tracking-tight text-slate-950">
        لوحة الإدارة والمكاتب الموحدة
      </h1>
      <p className="mt-4 max-w-2xl text-lg leading-8 text-slate-600">
        تم تجهيز أساس المشروع. ستُفعّل الشاشات وفق الصلاحيات ونطاق البيانات بعد
        ربط Supabase.
      </p>

      <section className="mt-10 grid gap-4 md:grid-cols-3" aria-label="حالة الوحدات">
        {projects.map(([title, status]) => (
          <article key={title} className="rounded-xl border border-slate-200 bg-white p-5">
            <h2 className="font-semibold text-slate-900">{title}</h2>
            <p className="mt-2 text-sm leading-6 text-slate-600">{status}</p>
          </article>
        ))}
      </section>
    </main>
  );
}

