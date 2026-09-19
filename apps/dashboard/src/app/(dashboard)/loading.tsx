export default function Loading() {
  return (
    <section className="loading-grid" aria-label="جارٍ تحميل لوحة بيكو" aria-busy="true">
      <div className="skeleton skeleton-wide" />
      <div className="skeleton" />
      <div className="skeleton" />
    </section>
  );
}
