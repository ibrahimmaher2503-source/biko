"use client";

export default function DashboardError({ reset }: { reset: () => void }) {
  return (
    <section className="state-panel state-error" role="alert">
      <p className="eyebrow">خطأ غير متوقع</p>
      <h2>تعذر عرض القسم</h2>
      <p>حاول إعادة تحميل هذا القسم. لم يتم تغيير أي بيانات.</p>
      <button className="button button-primary button-inline" onClick={reset}>إعادة المحاولة</button>
    </section>
  );
}
