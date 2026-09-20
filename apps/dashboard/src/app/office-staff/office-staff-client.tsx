"use client";

import { FormEvent, useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import type { AdminOfficeStaffData, AdminOfficeStaffMember, DashboardContext } from "@/lib/dashboard-types";

type OfficeOption = { id: string; name: string; status: string };
type FilterStatus = "ALL" | "ACTIVE" | "SUSPENDED" | "DELETED";
type ProvisionMode = "invite_staff" | "create_staff";
type ActionResult = { ok: boolean; message: string };

async function invokeAdminStaff(body: Record<string, unknown>) {
  const { data, error } = await createClient().functions.invoke("admin-staff", { body });
  if (error) throw new Error(error.message);
  if (data && typeof data === "object" && "error" in data && data.error) {
    throw new Error(String(data.error));
  }
}

async function invokeOfficeStaffRpc(name: string, body: Record<string, unknown>) {
  const { error } = await createClient().rpc(name, body);
  if (error) throw new Error(error.message);
}

function statusLabel(status: string) {
  if (status === "ACTIVE") return "نشطة";
  if (status === "SUSPENDED") return "معلّقة";
  if (status === "DELETED") return "محذوفة";
  return status;
}

function memberStatus(member: AdminOfficeStaffMember) {
  if (member.profile_status !== "ACTIVE") return member.profile_status;
  return member.membership_status;
}

export function OfficeStaffClient({
  context,
  data,
  offices,
  selectedOffice,
  canManage,
}: {
  context: DashboardContext;
  data: AdminOfficeStaffData;
  offices: OfficeOption[];
  selectedOffice: OfficeOption;
  canManage: boolean;
}) {
  const router = useRouter();
  const [search, setSearch] = useState("");
  const [status, setStatus] = useState<FilterStatus>("ALL");
  const [provisionMode, setProvisionMode] = useState<ProvisionMode>("invite_staff");
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [roleId, setRoleId] = useState(data.roles[0]?.id ?? "");
  const [roleByUser, setRoleByUser] = useState<Record<string, string>>({});
  const [reason, setReason] = useState("");
  const [pendingKey, setPendingKey] = useState("");
  const [result, setResult] = useState<ActionResult | null>(null);

  const officeRoles = data.roles.filter((role) => role.scope_type !== "PLATFORM");
  const filteredMembers = useMemo(() => {
    const needle = search.trim().toLocaleLowerCase();
    return data.members.filter((member) => {
      const valueMatches = !needle || [member.full_name, member.user_id, member.role_name, member.role_code]
        .join(" ")
        .toLocaleLowerCase()
        .includes(needle);
      const currentStatus = memberStatus(member);
      return valueMatches && (status === "ALL" || currentStatus === status);
    });
  }, [data.members, search, status]);

  async function runAction(
    action: string,
    body: Record<string, unknown>,
    confirmation: string,
    key = action,
  ) {
    setResult(null);
    if (!reason.trim()) {
      setResult({ ok: false, message: "سبب الإجراء مطلوب." });
      return;
    }
    if (!window.confirm(confirmation)) return;
    setPendingKey(key);
    try {
      await invokeAdminStaff({ action, reason: reason.trim(), ...body });
      setReason("");
      setResult({ ok: true, message: "تم تنفيذ الإجراء وستتم إعادة تحميل البيانات." });
      router.refresh();
    } catch (error) {
      setResult({ ok: false, message: error instanceof Error ? error.message : "تعذر تنفيذ الإجراء." });
    } finally {
      setPendingKey("");
    }
  }

  async function runOfficeRpc(
    name: string,
    body: Record<string, unknown>,
    confirmation: string,
    key: string,
  ) {
    setResult(null);
    if (!reason.trim()) {
      setResult({ ok: false, message: "سبب الإجراء مطلوب." });
      return;
    }
    if (!window.confirm(confirmation)) return;
    setPendingKey(key);
    try {
      await invokeOfficeStaffRpc(name, { ...body, p_reason: reason.trim() });
      setReason("");
      setResult({ ok: true, message: "تم تنفيذ الإجراء وستتم إعادة تحميل البيانات." });
      router.refresh();
    } catch (error) {
      setResult({ ok: false, message: error instanceof Error ? error.message : "تعذر تنفيذ الإجراء." });
    } finally {
      setPendingKey("");
    }
  }

  async function submitProvision(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!name.trim() || !email.trim() || !roleId || !canManage) {
      setResult({ ok: false, message: "أكمل بيانات الموظف واختر دورًا مكتبيًا." });
      return;
    }
    if (provisionMode === "create_staff" && password.length < 8) {
      setResult({ ok: false, message: "كلمة المرور الأولية يجب أن تكون 8 أحرف على الأقل." });
      return;
    }
    await runAction(
      provisionMode,
      {
        full_name: name.trim(),
        email: email.trim(),
        role_id: roleId,
        office_id: selectedOffice.id,
        ...(provisionMode === "create_staff" ? { password } : {}),
      },
      provisionMode === "invite_staff" ? `إرسال دعوة موظف إلى ${email.trim()}؟` : `إنشاء حساب موظف لـ${email.trim()}؟`,
      "provision",
    );
    setName("");
    setEmail("");
    setPassword("");
  }

  function assignRole(member: AdminOfficeStaffMember) {
    const nextRoleId = roleByUser[member.user_id] || member.role_id;
    const role = officeRoles.find((item) => item.id === nextRoleId);
    if (!role || member.user_id === context.user_id) return;
    void runOfficeRpc(
      "admin_update_office_member_role",
      { p_user_id: member.user_id, p_role_id: role.id, p_office_id: selectedOffice.id },
      `تأكيد إسناد دور «${role.name}» للموظف؟`,
      `role-${member.user_id}`,
    );
  }

  function toggleMembership(member: AdminOfficeStaffMember) {
    if (member.user_id === context.user_id || member.profile_status === "DELETED") return;
    const nextStatus = member.membership_status === "ACTIVE" ? "SUSPENDED" : "ACTIVE";
    void runOfficeRpc(
      "admin_update_office_member_status",
      { p_user_id: member.user_id, p_office_id: selectedOffice.id, p_status: nextStatus },
      `${nextStatus === "ACTIVE" ? "استعادة" : "تعليق"} عضوية الموظف؟`,
      `status-${member.user_id}`,
    );
  }

  const activeCount = data.members.filter((member) => memberStatus(member) === "ACTIVE").length;
  const suspendedCount = data.members.filter((member) => memberStatus(member) === "SUSPENDED").length;

  return (
    <div className="office-staff-page">
      <div className="section-heading">
        <div>
          <p className="eyebrow">ADM-10 · إدارة النطاق</p>
          <h2>موظفو المكتب</h2>
          <p className="section-subtitle">إدارة عضويات المكتب المحدد فقط؛ اختيار المكتب لا يمنح نطاقًا جديدًا.</p>
        </div>
        <span className="permission-chip">office_members.manage</span>
      </div>

      {result && <p className={result.ok ? "form-message form-message-success" : "form-message form-message-error"} role={result.ok ? "status" : "alert"}>{result.message}</p>}

      <section className="admin-card office-staff-toolbar">
        <div className="field"><label htmlFor="staff-office">المكتب</label><select id="staff-office" value={selectedOffice.id} onChange={(event) => router.push(`/office-staff?office_id=${event.target.value}`)}><option value={selectedOffice.id}>{selectedOffice.name}</option>{offices.filter((office) => office.id !== selectedOffice.id).map((office) => <option key={office.id} value={office.id}>{office.name}</option>)}</select></div>
        <div className="field"><label htmlFor="staff-search">بحث</label><input id="staff-search" value={search} onChange={(event) => setSearch(event.target.value)} placeholder="اسم الموظف أو الدور أو المعرف" /></div>
        <div className="field"><label htmlFor="staff-status">الحالة</label><select id="staff-status" value={status} onChange={(event) => setStatus(event.target.value as FilterStatus)}><option value="ALL">كل الحالات</option><option value="ACTIVE">نشطة</option><option value="SUSPENDED">معلّقة</option><option value="DELETED">محذوفة</option></select></div>
        <div className="staff-summary"><strong>{activeCount}</strong><span>نشطة</span><strong>{suspendedCount}</strong><span>معلّقة</span></div>
      </section>

      <section className="admin-card">
        <div className="admin-card-header"><div><h3>قائمة الموظفين</h3><p>{filteredMembers.length} من {data.members.length} عضوية في {selectedOffice.name}</p></div></div>
        {filteredMembers.length === 0 ? <p className="empty-inline">لا توجد عضويات مطابقة للبحث أو الفلتر الحالي.</p> : <div className="table-wrap"><table className="admin-table office-staff-table"><thead><tr><th>الموظف</th><th>الدور</th><th>حالة الحساب</th><th>حالة العضوية</th><th>الإجراءات</th></tr></thead><tbody>{filteredMembers.map((member) => { const isSelf = member.user_id === context.user_id; const busy = pendingKey === `status-${member.user_id}` || pendingKey === `role-${member.user_id}`; return <tr key={member.id}><td><strong>{member.full_name || "بدون اسم"}</strong><small dir="ltr">{member.email || member.phone || member.user_id}</small></td><td><div className="staff-role-cell"><span>{member.role_name}</span><small dir="ltr">{member.role_code}</small><select aria-label={`دور ${member.full_name}`} value={roleByUser[member.user_id] || member.role_id} onChange={(event) => setRoleByUser((current) => ({ ...current, [member.user_id]: event.target.value }))} disabled={!canManage || isSelf || busy}><option value={member.role_id}>{member.role_name}</option>{officeRoles.filter((role) => role.id !== member.role_id).map((role) => <option key={role.id} value={role.id}>{role.name}</option>)}</select><button className="button button-link table-action" type="button" onClick={() => assignRole(member)} disabled={!canManage || isSelf || busy || !officeRoles.length}>تعيين</button></div></td><td><span className={`status-badge status-${member.profile_status.toLowerCase()}`}>{statusLabel(member.profile_status)}</span></td><td><span className={`status-badge status-${member.membership_status.toLowerCase()}`}>{statusLabel(member.membership_status)}</span>{isSelf && <small>حسابك الحالي</small>}</td><td><button className="button button-secondary table-action" type="button" onClick={() => toggleMembership(member)} disabled={!canManage || isSelf || member.profile_status === "DELETED" || busy}>{member.membership_status === "ACTIVE" ? "تعليق العضوية" : "تفعيل العضوية"}</button>{isSelf && <small className="inline-note">لا يمكن تعديل عضويتك الحالية من هنا.</small>}</td></tr>; })}</tbody></table></div>}
      </section>

      <section className="admin-card">
        <div className="admin-card-header"><div><h3>{provisionMode === "invite_staff" ? "دعوة موظف" : "إنشاء موظف"}</h3><p>الدور المقترح هنا مكتبي فقط. لا يوجد مسار لمنح دور منصة من شاشة المكتب.</p></div></div>
        <form className="admin-form" onSubmit={submitProvision}>
          <div className="mode-switch" role="tablist" aria-label="طريقة إضافة الموظف"><button className={provisionMode === "invite_staff" ? "mode-option active" : "mode-option"} type="button" role="tab" aria-selected={provisionMode === "invite_staff"} onClick={() => setProvisionMode("invite_staff")}>دعوة بالبريد</button><button className={provisionMode === "create_staff" ? "mode-option active" : "mode-option"} type="button" role="tab" aria-selected={provisionMode === "create_staff"} onClick={() => setProvisionMode("create_staff")}>إنشاء مباشر</button></div>
          <div className="form-row"><div className="field"><label htmlFor="office-staff-name">اسم الموظف</label><input id="office-staff-name" value={name} onChange={(event) => setName(event.target.value)} required /></div><div className="field"><label htmlFor="office-staff-email">البريد الإلكتروني</label><input id="office-staff-email" type="email" dir="ltr" value={email} onChange={(event) => setEmail(event.target.value)} required /></div></div>
          {provisionMode === "create_staff" && <div className="field"><label htmlFor="office-staff-password">كلمة المرور الأولية</label><input id="office-staff-password" type="password" dir="ltr" minLength={8} autoComplete="new-password" value={password} onChange={(event) => setPassword(event.target.value)} required /><small className="inline-note">8 أحرف على الأقل. أرسلها للموظف عبر قناة آمنة منفصلة.</small></div>}
          <div className="field"><label htmlFor="office-staff-role">الدور المكتبي</label><select id="office-staff-role" value={roleId} onChange={(event) => setRoleId(event.target.value)} required disabled={!officeRoles.length}><option value="">{officeRoles.length ? "اختر دورًا مكتبيًا" : "لا يوجد دور مكتبي متاح"}</option>{officeRoles.map((role) => <option key={role.id} value={role.id}>{role.name} · {role.code}</option>)}</select></div>
          <button className="button button-primary button-inline" type="submit" disabled={!canManage || pendingKey === "provision" || !officeRoles.length}>{pendingKey === "provision" ? "جارٍ التنفيذ…" : provisionMode === "invite_staff" ? "إرسال الدعوة" : "إنشاء الموظف"}</button>
        </form>
      </section>

      <section className="admin-card reason-card"><div className="field"><label htmlFor="office-staff-reason">سبب الإجراء</label><input id="office-staff-reason" value={reason} onChange={(event) => setReason(event.target.value)} placeholder="مطلوب لكل دعوة أو تغيير دور أو حالة عضوية" required /></div><p className="inline-note">التفويض النهائي والتحقق من المكتب والحالة يتمان في المسار الخادمي، وليس في المتصفح.</p></section>
    </div>
  );
}
