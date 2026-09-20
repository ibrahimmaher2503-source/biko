"use client";

import Link from "next/link";
import { type FormEvent, useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { type AdminOfficesData, type DashboardContext, type DashboardOfficeRow } from "@/lib/dashboard-types";

const statusLabels: Record<string, string> = { ACTIVE: "نشط", SUSPENDED: "معلّق", DELETED: "محذوف" };
const emptyForm = { name: "", responsible_person: "", phone: "", address: "", area: "" };
type EditorMode = "create" | "edit" | null;
type OfficeForm = typeof emptyForm;

function statusLabel(status: string) { return statusLabels[status] ?? status; }
function count(value: number) { return value.toLocaleString("ar-EG"); }
function date(value: string) { return new Intl.DateTimeFormat("ar-EG", { dateStyle: "medium" }).format(new Date(value)); }
function value(text: string | null) { return text?.trim() || "غير مسجل"; }
function officeSearchText(office: DashboardOfficeRow) {
  return [office.name, office.responsible_person, office.phone, office.address, office.area].filter(Boolean).join(" ").toLocaleLowerCase("ar");
}
function hasPlatformPermission(context: DashboardContext, permission: string) {
  return context.platform_roles.some((role) => role.code === "SUPER_ADMIN" || role.permissions.includes(permission));
}
function formFromOffice(office: DashboardOfficeRow): OfficeForm {
  return { name: office.name, responsible_person: office.responsible_person ?? "", phone: office.phone ?? "", address: office.address ?? "", area: office.area ?? "" };
}

export function OfficesClient({ data, context }: { data: AdminOfficesData; context: DashboardContext }) {
  const router = useRouter();
  const [search, setSearch] = useState("");
  const [status, setStatus] = useState("ALL");
  const [selectedId, setSelectedId] = useState(data.offices[0]?.id ?? "");
  const [editorMode, setEditorMode] = useState<EditorMode>(null);
  const [form, setForm] = useState<OfficeForm>(emptyForm);
  const [reason, setReason] = useState("");
  const [pending, setPending] = useState(false);
  const [result, setResult] = useState<{ ok: boolean; message: string } | null>(null);

  const filteredOffices = useMemo(() => {
    const query = search.trim().toLocaleLowerCase("ar");
    return data.offices.filter((office) => (!query || officeSearchText(office).includes(query)) && (status === "ALL" || office.status === status));
  }, [data.offices, search, status]);
  const selectedOffice = filteredOffices.find((office) => office.id === selectedId) ?? filteredOffices[0];
  const activeCount = data.offices.filter((office) => office.status === "ACTIVE").length;
  const suspendedCount = data.offices.filter((office) => office.status === "SUSPENDED").length;
  const totalDrivers = data.offices.reduce((total, office) => total + office.stats.driver_count, 0);
  const totalOrders = data.offices.reduce((total, office) => total + office.stats.order_count, 0);
  const canCreate = hasPlatformPermission(context, "offices.create");
  const canEdit = hasPlatformPermission(context, "offices.edit");
  const canSuspend = hasPlatformPermission(context, "offices.suspend");

  function beginCreate() { setResult(null); setForm(emptyForm); setEditorMode("create"); }
  function beginEdit(office: DashboardOfficeRow) { setResult(null); setForm(formFromOffice(office)); setEditorMode("edit"); }
  function setField(field: keyof OfficeForm, text: string) { setForm((current) => ({ ...current, [field]: text })); }

  async function submitEditor(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const name = form.name.trim();
    if (!name) return setResult({ ok: false, message: "اسم المكتب مطلوب." });
    if (!reason.trim()) return setResult({ ok: false, message: "سبب الإجراء مطلوب." });
    const isEdit = editorMode === "edit";
    const officeName = isEdit ? selectedOffice?.name : name;
    if (!window.confirm(isEdit ? `تأكيد تعديل المكتب «${officeName}»؟` : `تأكيد إنشاء المكتب «${name}»؟`)) return;
    setPending(true);
    setResult(null);
    const rpc = isEdit ? "admin_update_office" : "admin_create_office";
    const params = { ...(isEdit ? { p_office_id: selectedOffice?.id } : {}), p_name: name, p_responsible_person: form.responsible_person.trim() || null, p_phone: form.phone.trim() || null, p_address: form.address.trim() || null, p_area: form.area.trim() || null, p_reason: reason.trim() };
    const { error } = await createClient().rpc(rpc, params);
    if (error) setResult({ ok: false, message: error.message });
    else { setResult({ ok: true, message: isEdit ? "تم تعديل المكتب." : "تم إنشاء المكتب." }); setEditorMode(null); setReason(""); router.refresh(); }
    setPending(false);
  }

  async function changeStatus() {
    if (!selectedOffice) return;
    if (!reason.trim()) return setResult({ ok: false, message: "سبب الإجراء مطلوب." });
    const restoring = selectedOffice.status === "SUSPENDED";
    if (!window.confirm(restoring ? `تأكيد استعادة المكتب «${selectedOffice.name}»؟` : `تأكيد تعليق المكتب «${selectedOffice.name}»؟ سيتم منع العمل الجديد.`)) return;
    setPending(true);
    setResult(null);
    const rpc = restoring ? "admin_restore_office" : "admin_suspend_office";
    const { error } = await createClient().rpc(rpc, { p_office_id: selectedOffice.id, p_reason: reason.trim() });
    if (error) setResult({ ok: false, message: error.message });
    else { setResult({ ok: true, message: restoring ? "تمت استعادة المكتب." : "تم تعليق المكتب." }); setReason(""); router.refresh(); }
    setPending(false);
  }

  return (
    <div className="offices-page">
      <div className="section-heading"><div><p className="eyebrow">ADM-09 · إدارة المكاتب</p><h2>المكاتب</h2><p className="section-subtitle">قائمة وإحصاءات المكاتب من العقد الإداري الموحّد، مع احترام صلاحيات المنصة والتدقيق.</p></div><span className="permission-chip">offices.view</span></div>
      {result && <p className={result.ok ? "form-message form-message-success" : "form-message form-message-error"} role={result.ok ? "status" : "alert"}>{result.message}</p>}
      <section className="admin-card reason-card"><div className="field"><label htmlFor="office-reason">سبب الإجراء</label><input id="office-reason" value={reason} onChange={(event) => setReason(event.target.value)} placeholder="اكتب سببًا واضحًا قبل الحفظ أو تغيير الحالة" /></div><p className="inline-note">السبب مطلوب من العقد الموثوق ويُحفظ مع سجل التدقيق.</p></section>
      <section className="office-stats" aria-label="إحصاءات المكاتب"><article className="stat-card"><span>إجمالي المكاتب</span><strong>{count(data.total_count)}</strong></article><article className="stat-card"><span>المكاتب النشطة</span><strong>{count(activeCount)}</strong></article><article className="stat-card"><span>المكاتب المعلّقة</span><strong>{count(suspendedCount)}</strong></article><article className="stat-card"><span>السائقون المرتبطون</span><strong>{count(totalDrivers)}</strong></article><article className="stat-card"><span>الطلبات المرتبطة</span><strong>{count(totalOrders)}</strong></article></section>
      <section className="admin-card office-toolbar" aria-label="بحث وفلاتر المكاتب"><div className="field"><label htmlFor="office-search">بحث</label><input id="office-search" value={search} onChange={(event) => setSearch(event.target.value)} placeholder="اسم المكتب، المسؤول، الهاتف، المنطقة" /></div><div className="field"><label htmlFor="office-status">الحالة</label><select id="office-status" value={status} onChange={(event) => setStatus(event.target.value)}><option value="ALL">كل الحالات</option><option value="ACTIVE">نشط</option><option value="SUSPENDED">معلّق</option><option value="DELETED">محذوف</option></select></div><div className="office-toolbar-action"><button className="button button-primary" type="button" disabled={!canCreate || pending} onClick={beginCreate}>إنشاء مكتب</button><small className="inline-note">متاح لمسؤولي المنصة المصرّح لهم.</small></div></section>
      {editorMode && <section className="admin-card" aria-label={editorMode === "create" ? "إنشاء مكتب" : "تعديل مكتب"}><div className="admin-card-header"><div><h3>{editorMode === "create" ? "إنشاء مكتب" : `تعديل ${selectedOffice?.name ?? "المكتب"}`}</h3><p>الحقول تُرسل إلى العقد الإداري الموثوق فقط.</p></div><button className="button button-link" type="button" onClick={() => setEditorMode(null)}>إلغاء</button></div><form className="admin-form" onSubmit={submitEditor}><div className="form-row"><div className="field"><label htmlFor="office-name">اسم المكتب</label><input id="office-name" value={form.name} onChange={(event) => setField("name", event.target.value)} required maxLength={120} /></div><div className="field"><label htmlFor="office-responsible">المسؤول</label><input id="office-responsible" value={form.responsible_person} onChange={(event) => setField("responsible_person", event.target.value)} maxLength={120} /></div></div><div className="form-row"><div className="field"><label htmlFor="office-phone">الهاتف</label><input id="office-phone" dir="ltr" value={form.phone} onChange={(event) => setField("phone", event.target.value)} maxLength={50} /></div><div className="field"><label htmlFor="office-area">المنطقة</label><input id="office-area" value={form.area} onChange={(event) => setField("area", event.target.value)} maxLength={120} /></div></div><div className="field"><label htmlFor="office-address">العنوان</label><input id="office-address" value={form.address} onChange={(event) => setField("address", event.target.value)} maxLength={255} /></div><button className="button button-primary button-inline" type="submit" disabled={pending}>{pending ? "جارٍ الحفظ…" : "حفظ المكتب"}</button></form></section>}
      <section className="admin-card"><div className="admin-card-header"><div><h3>قائمة المكاتب</h3><p>{count(filteredOffices.length)} من {count(data.total_count)} مكتب</p></div></div>{filteredOffices.length === 0 ? <p className="empty-inline">لا توجد نتائج مطابقة للبحث أو الفلتر الحالي.</p> : <div className="table-wrap"><table className="admin-table offices-table"><thead><tr><th>المكتب</th><th>المسؤول وبيانات الاتصال</th><th>الحالة</th><th>السائقون</th><th>المركبات</th><th>الطلبات</th><th>إجراء</th></tr></thead><tbody>{filteredOffices.map((office) => <tr key={office.id}><td><strong>{office.name}</strong><small dir="ltr">{office.id}</small></td><td>{value(office.responsible_person)}<small dir="ltr">{value(office.phone)}</small></td><td><span className={`status-badge status-${office.status.toLowerCase()}`}>{statusLabel(office.status)}</span></td><td>{count(office.stats.driver_count)}</td><td>{count(office.stats.motorcycle_count)}</td><td>{count(office.stats.order_count)}</td><td><button className="button button-link table-action" type="button" onClick={() => setSelectedId(office.id)}>عرض التفاصيل</button></td></tr>)}</tbody></table></div>}</section>
      {selectedOffice && <section className="office-detail-grid" aria-label={`تفاصيل ${selectedOffice.name}`}><article className="admin-card office-detail-card"><div className="admin-card-header"><div><p className="eyebrow">تفاصيل المكتب</p><h3>{selectedOffice.name}</h3></div><span className={`status-badge status-${selectedOffice.status.toLowerCase()}`}>{statusLabel(selectedOffice.status)}</span></div><dl className="office-details"><div><dt>المسؤول</dt><dd>{value(selectedOffice.responsible_person)}</dd></div><div><dt>الهاتف</dt><dd dir="ltr">{value(selectedOffice.phone)}</dd></div><div><dt>العنوان</dt><dd>{value(selectedOffice.address)}</dd></div><div><dt>المنطقة</dt><dd>{value(selectedOffice.area)}</dd></div><div><dt>تاريخ الإنشاء</dt><dd>{date(selectedOffice.created_at)}</dd></div></dl><div className="office-actions"><button className="button button-secondary" type="button" disabled={!canEdit || pending} onClick={() => beginEdit(selectedOffice)}>تعديل المكتب</button><button className="button button-secondary" type="button" disabled={!canSuspend || pending || selectedOffice.status === "DELETED"} onClick={changeStatus}>{selectedOffice.status === "SUSPENDED" ? "استعادة المكتب" : "تعليق المكتب"}</button></div><p className="inline-note">تعليق المكتب يمنع العمل الجديد، ولا يغيّر تاريخ الطلبات ولا يمنع إنهاء الرحلة القائمة حسب القاعدة.</p></article><article className="admin-card"><div className="admin-card-header"><div><h3>الإحصاءات والروابط المرتبطة</h3><p>الإحصاءات محسوبة داخل العقد الإداري نفسه.</p></div></div><div className="office-detail-stats"><div><span>السائقون</span><strong>{count(selectedOffice.stats.driver_count)}</strong></div><div><span>السائقون النشطون</span><strong>{count(selectedOffice.stats.active_driver_count)}</strong></div><div><span>المركبات</span><strong>{count(selectedOffice.stats.motorcycle_count)}</strong></div><div><span>الطلبات النشطة</span><strong>{count(selectedOffice.stats.active_order_count)}</strong></div><div><span>الطلبات المكتملة</span><strong>{count(selectedOffice.stats.completed_order_count)}</strong></div><div><span>الطلبات الملغاة</span><strong>{count(selectedOffice.stats.cancelled_order_count)}</strong></div></div><nav className="office-links" aria-label="روابط بيانات المكتب"><Link href={`/office-staff?office_id=${selectedOffice.id}`}>موظفو المكتب</Link><Link href={`/drivers?office_id=${selectedOffice.id}`}>سائقو المكتب</Link><Link href={`/motorcycles?office_id=${selectedOffice.id}`}>مركبات المكتب</Link><Link href={`/orders?office_id=${selectedOffice.id}`}>طلبات المكتب</Link><Link href={`/reports?office_id=${selectedOffice.id}`}>تقارير المكتب</Link></nav></article></section>}
    </div>
  );
}
