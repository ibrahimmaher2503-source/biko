export default function OfficeStaffLoading() {
  return (
    <div className="loading-grid" aria-busy="true" aria-label="جارٍ تحميل موظفي المكتب">
      <div className="skeleton skeleton-wide" />
      <div className="skeleton" />
      <div className="skeleton" />
    </div>
  );
}
