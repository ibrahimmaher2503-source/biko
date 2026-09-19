"use client";

import { FormEvent, useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { hasPermission, type AdminStaffData, type DashboardContext } from "@/lib/dashboard-types";

type ActionResult = { ok: boolean; message: string };
type StaffProvisionMode = "invite_staff" | "create_staff";

async function invokeAdminStaff(body: Record<string, unknown>) {
  const { data, error } = await createClient().functions.invoke("admin-staff", { body });
  if (error) throw new Error(error.message);
  if (data && typeof data === "object" && "error" in data && data.error) {
    throw new Error(String(data.error));
  }
}

function permissionCodes(data: AdminStaffData, roleId: string) {
  const permissionIds = new Set(
    data.rolePermissions.filter((item) => item.role_id === roleId).map((item) => item.permission_id),
  );
  return data.permissions.filter((item) => permissionIds.has(item.id)).map((item) => item.code);
}

export function RolesStaffClient({ data, context }: { data: AdminStaffData; context: DashboardContext }) {
  const router = useRouter();
  const isSuperAdmin = context.platform_roles.some((role) => role.code === "SUPER_ADMIN");
  const canManageRoles = isSuperAdmin && hasPermission(context, "roles.manage");
  const canManageOfficeStaff = canManageRoles || hasPermission(context, "office_members.manage");
  const [selectedRoleId, setSelectedRoleId] = useState(data.roles[0]?.id ?? "");
  const [roleName, setRoleName] = useState(data.roles[0]?.name ?? "");
  const [rolePermissions, setRolePermissions] = useState(() => permissionCodes(data, data.roles[0]?.id ?? ""));
  const [createName, setCreateName] = useState("");
  const [createCode, setCreateCode] = useState("");
  const [createPermissions, setCreatePermissions] = useState<string[]>([]);
  const [selectedUserId, setSelectedUserId] = useState("");
  const [assignmentRoleId, setAssignmentRoleId] = useState(data.roles[0]?.id ?? "");
  const [assignmentScope, setAssignmentScope] = useState<"PLATFORM" | "OFFICE">("OFFICE");
  const [assignmentOfficeId, setAssignmentOfficeId] = useState(data.offices[0]?.id ?? "");
  const [inviteEmail, setInviteEmail] = useState("");
  const [inviteName, setInviteName] = useState("");
  const [inviteRoleId, setInviteRoleId] = useState(data.roles[0]?.id ?? "");
  const [inviteScope, setInviteScope] = useState<"PLATFORM" | "OFFICE">("OFFICE");
  const [inviteOfficeId, setInviteOfficeId] = useState(data.offices[0]?.id ?? "");
  const [provisionMode, setProvisionMode] = useState<StaffProvisionMode>("invite_staff");
  const [initialPassword, setInitialPassword] = useState("");
  const [reason, setReason] = useState("");
  const [pending, setPending] = useState(false);
  const [result, setResult] = useState<ActionResult | null>(null);

  const selectedRole = data.roles.find((role) => role.id === selectedRoleId);
  const assignmentRole = data.roles.find((role) => role.id === assignmentRoleId);
  const inviteRole = data.roles.find((role) => role.id === inviteRoleId);
  const roleOwnedByActor = data.roleAssignments.some(
    (assignment) => assignment.user_id === context.user_id && assignment.role_id === selectedRoleId,
  );
  const activeOffices = data.offices.filter((office) => office.status === "ACTIVE");
  const availableAssignmentScopes = useMemo(() => {
    if (!assignmentRole || !canManageOfficeStaff) return [] as Array<"PLATFORM" | "OFFICE">;
    const scopes: Array<"PLATFORM" | "OFFICE"> = [];
    if (assignmentRole.scope_type === "PLATFORM" && isSuperAdmin) scopes.push("PLATFORM");
    if (assignmentRole.scope_type !== "PLATFORM") scopes.push("OFFICE");
    return scopes;
  }, [assignmentRole, canManageOfficeStaff, isSuperAdmin]);
  const availableInviteScopes = useMemo(() => {
    if (!inviteRole || !canManageOfficeStaff) return [] as Array<"PLATFORM" | "OFFICE">;
    const scopes: Array<"PLATFORM" | "OFFICE"> = [];
    if (inviteRole.scope_type === "PLATFORM" && isSuperAdmin) scopes.push("PLATFORM");
    if (inviteRole.scope_type !== "PLATFORM") scopes.push("OFFICE");
    return scopes;
  }, [inviteRole, canManageOfficeStaff, isSuperAdmin]);

  function selectRole(roleId: string) {
    const role = data.roles.find((item) => item.id === roleId);
    setSelectedRoleId(roleId);
    setRoleName(role?.name ?? "");
    setRolePermissions(permissionCodes(data, roleId));
  }

  function togglePermission(code: string, setter: (next: string[]) => void, current: string[]) {
    setter(current.includes(code) ? current.filter((item) => item !== code) : [...current, code]);
  }

  async function runActions(
    actions: Array<{ action: string; body: Record<string, unknown> }>,
    confirmation: string,
  ) {
    setResult(null);
    if (!reason.trim()) {
      setResult({ ok: false, message: "سبب الإجراء مطلوب." });
      return;
    }
    if (!window.confirm(confirmation)) return;
    setPending(true);
    try {
      for (const item of actions) {
        await invokeAdminStaff({ action: item.action, reason: reason.trim(), ...item.body });
      }
      setResult({ ok: true, message: "تم تنفيذ الإجراء. ستتم إعادة تحميل البيانات." });
      setReason("");
      router.refresh();
    } catch (error) {
      setResult({ ok: false, message: error instanceof Error ? error.message : "تعذر تنفيذ الإجراء." });
    } finally {
      setPending(false);
    }
  }

  async function runAction(action: string, body: Record<string, unknown>, confirmation: string) {
    return runActions([{ action, body }], confirmation);
  }

  async function saveRole(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!canManageRoles || !selectedRole || selectedRole.code === "SUPER_ADMIN" || roleOwnedByActor) return;
    await runActions(
      [
        { action: "rename_role", body: { p_role_id: selectedRole.id, p_name: roleName.trim() } },
        { action: "set_role_permissions", body: { p_role_id: selectedRole.id, p_permission_codes: rolePermissions } },
      ],
      `تأكيد تعديل الدور «${selectedRole.name}»؟`,
    );
  }

  async function createRole(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const code = createCode.trim().toUpperCase().replace(/[^A-Z0-9_]+/g, "_");
    if (!createName.trim() || !code) {
      setResult({ ok: false, message: "اسم الدور ورمزه مطلوبان." });
      return;
    }
    await runAction(
      "create_role",
      { p_code: code, p_name: createName.trim(), p_scope_type: "CUSTOM", p_permission_codes: createPermissions },
      `تأكيد إنشاء الدور المخصص «${createName.trim()}»؟`,
    );
    setCreateName("");
    setCreateCode("");
    setCreatePermissions([]);
  }

  async function assignRole(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!selectedUserId || selectedUserId === context.user_id || !assignmentRole) {
      setResult({ ok: false, message: "لا يمكن إسناد دور لحسابك الحالي من هذه الشاشة." });
      return;
    }
    if (!availableAssignmentScopes.includes(assignmentScope)) {
      setResult({ ok: false, message: "هذا الدور لا يمكن إسناده بهذا النطاق." });
      return;
    }
    await runAction(
      "assign_role",
      {
        p_target_user_id: selectedUserId,
        p_role_id: assignmentRole.id,
        p_office_id: assignmentScope === "OFFICE" ? assignmentOfficeId : null,
      },
      "تأكيد إسناد هذا الدور؟",
    );
  }

  async function inviteStaff(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!inviteEmail.trim() || !inviteName.trim() || !inviteRole || !availableInviteScopes.includes(inviteScope)) {
      setResult({ ok: false, message: "أكمل بيانات الدعوة واختر نطاقًا صالحًا للدور." });
      return;
    }
    if (provisionMode === "create_staff" && initialPassword.length < 8) {
      setResult({ ok: false, message: "كلمة المرور الأولية يجب أن تكون 8 أحرف على الأقل." });
      return;
    }
    await runAction(
      provisionMode,
      {
        email: inviteEmail.trim(),
        full_name: inviteName.trim(),
        role_id: inviteRole.id,
        scope_type: inviteScope,
        office_id: inviteScope === "OFFICE" ? inviteOfficeId : null,
        ...(provisionMode === "create_staff" ? { password: initialPassword } : {}),
      },
      provisionMode === "invite_staff"
        ? `إرسال دعوة موظف إلى ${inviteEmail.trim()}؟`
        : `إنشاء حساب موظف لـ${inviteEmail.trim()}؟`,
    );
    setInviteEmail("");
    setInviteName("");
    setInitialPassword("");
  }

  return (
    <div className="roles-staff-page">
      <div className="section-heading">
        <div>
          <p className="eyebrow">ADM-08 · إدارة الوصول</p>
          <h2>الأدوار والموظفون</h2>
        </div>
        <span className="permission-chip">roles.manage</span>
      </div>

      {result && <p className={result.ok ? "form-message form-message-success" : "form-message form-message-error"} role={result.ok ? "status" : "alert"}>{result.message}</p>}

      <div className="admin-card reason-card">
        <div className="field"><label htmlFor="action-reason">سبب الإجراء</label><input id="action-reason" value={reason} onChange={(event) => setReason(event.target.value)} placeholder="اكتب سببًا واضحًا قبل الحفظ أو الإسناد أو الدعوة" required /></div>
        <p className="inline-note">يُسجّل السبب مع الإجراء في المسار الموثوق. تغيير النطاق في الواجهة لا يمنح صلاحية بحد ذاته.</p>
      </div>

      <section className="admin-card">
        <div className="admin-card-header"><div><h3>الأدوار والصلاحيات</h3><p>تعديل الدور المخصص يحتاج سببًا وتأكيدًا. لا يمكن تعديل دورك الحالي من هذه الواجهة.</p></div></div>
        <div className="admin-split">
          <div className="admin-list" aria-label="قائمة الأدوار">
            {data.roles.map((role) => (
              <button className={role.id === selectedRoleId ? "admin-list-item active" : "admin-list-item"} key={role.id} type="button" onClick={() => selectRole(role.id)}>
                <strong>{role.name}</strong><span>{role.code} · {role.scope_type}</span>
              </button>
            ))}
          </div>
          <form className="admin-form" onSubmit={saveRole}>
            <div className="form-row"><div className="field"><label htmlFor="role-name">اسم الدور</label><input id="role-name" value={roleName} onChange={(event) => setRoleName(event.target.value)} disabled={!canManageRoles || !selectedRole || selectedRole.code === "SUPER_ADMIN" || roleOwnedByActor} /></div><div className="field"><label>النطاق</label><div className="read-only-field">{selectedRole?.scope_type ?? "—"}</div></div></div>
            <fieldset className="permission-grid" disabled={!canManageRoles || !selectedRole || selectedRole.code === "SUPER_ADMIN" || roleOwnedByActor}>
              <legend>الصلاحيات</legend>
              {data.permissions.map((permission) => (
                <label className="permission-option" key={permission.id}><input type="checkbox" checked={rolePermissions.includes(permission.code)} onChange={() => togglePermission(permission.code, setRolePermissions, rolePermissions)} /><span><strong>{permission.code}</strong><small>{permission.description || "صلاحية تشغيلية"}</small></span></label>
              ))}
            </fieldset>
            <button className="button button-primary button-inline" type="submit" disabled={pending || !canManageRoles || !selectedRole || selectedRole.code === "SUPER_ADMIN" || roleOwnedByActor}>حفظ صلاحيات الدور</button>
            {roleOwnedByActor && <p className="inline-note">لا يمكن تعديل دور مرتبط بحسابك الحالي لمنع تصعيد الصلاحيات الذاتي.</p>}
          </form>
        </div>
      </section>

      <section className="admin-card">
        <div className="admin-card-header"><div><h3>إنشاء دور CUSTOM</h3><p>الأدوار المخصصة تبدأ دون أي صلاحيات ويمكن مراجعتها قبل الإسناد.</p></div></div>
        <form className="admin-form" onSubmit={createRole}>
          <div className="form-row"><div className="field"><label htmlFor="custom-role-name">اسم الدور</label><input id="custom-role-name" value={createName} onChange={(event) => setCreateName(event.target.value)} required /></div><div className="field"><label htmlFor="custom-role-code">الرمز</label><input id="custom-role-code" dir="ltr" value={createCode} onChange={(event) => setCreateCode(event.target.value)} placeholder="CUSTOM_REVIEWER" required /></div></div>
          <fieldset className="permission-grid"><legend>الصلاحيات الأولية</legend>{data.permissions.map((permission) => <label className="permission-option" key={`create-${permission.id}`}><input type="checkbox" checked={createPermissions.includes(permission.code)} onChange={() => togglePermission(permission.code, setCreatePermissions, createPermissions)} /><span><strong>{permission.code}</strong><small>{permission.description || "صلاحية تشغيلية"}</small></span></label>)}</fieldset>
          <button className="button button-primary button-inline" type="submit" disabled={pending || !canManageRoles}>إنشاء الدور</button>
        </form>
      </section>

      <section className="admin-card">
        <div className="admin-card-header"><div><h3>الموظفون وإسناد الأدوار</h3><p>النطاق المختار للعرض فقط؛ الخادم يعيد فحص الدور والمكتب في كل إجراء.</p></div></div>
        <div className="table-wrap"><table className="admin-table"><thead><tr><th>الموظف</th><th>الحالة</th><th>أدوار المنصة</th><th>عضويات المكاتب</th></tr></thead><tbody>{data.staff.map((member) => <tr key={member.id}><td><strong>{member.full_name || "بدون اسم"}</strong><small dir="ltr">{member.id}</small></td><td><span className={`status-badge status-${member.status.toLowerCase()}`}>{member.status}</span></td><td>{data.roleAssignments.filter((assignment) => assignment.user_id === member.id).map((assignment) => data.roles.find((role) => role.id === assignment.role_id)?.name).filter(Boolean).join("، ") || "—"}</td><td>{data.officeMemberships.filter((membership) => membership.user_id === member.id).map((membership) => { const office = data.offices.find((item) => item.id === membership.office_id); const role = data.roles.find((item) => item.id === membership.role_id); return `${office?.name ?? "مكتب"} · ${role?.name ?? "دور"}`; }).join("، ") || "—"}</td></tr>)}</tbody></table></div>
        <form className="admin-form" onSubmit={assignRole}>
          <div className="form-row form-row-3"><div className="field"><label htmlFor="assignment-user">الموظف</label><select id="assignment-user" value={selectedUserId} onChange={(event) => setSelectedUserId(event.target.value)} required><option value="">اختر موظفًا</option>{data.staff.filter((member) => member.id !== context.user_id).map((member) => <option key={member.id} value={member.id}>{member.full_name || member.id}</option>)}</select></div><div className="field"><label htmlFor="assignment-role">الدور</label><select id="assignment-role" value={assignmentRoleId} onChange={(event) => { setAssignmentRoleId(event.target.value); const role = data.roles.find((item) => item.id === event.target.value); setAssignmentScope(role?.scope_type === "PLATFORM" && isSuperAdmin ? "PLATFORM" : "OFFICE"); }} required>{data.roles.map((role) => <option key={role.id} value={role.id}>{role.name} · {role.scope_type}</option>)}</select></div><div className="field"><label htmlFor="assignment-scope">النطاق</label><select id="assignment-scope" value={assignmentScope} onChange={(event) => setAssignmentScope(event.target.value as "PLATFORM" | "OFFICE")} disabled={availableAssignmentScopes.length < 2}>{availableAssignmentScopes.map((scope) => <option key={scope} value={scope}>{scope === "PLATFORM" ? "المنصة" : "مكتب"}</option>)}</select></div></div>
          {assignmentScope === "OFFICE" && <div className="field"><label htmlFor="assignment-office">المكتب</label><select id="assignment-office" value={assignmentOfficeId} onChange={(event) => setAssignmentOfficeId(event.target.value)} required><option value="">اختر مكتبًا نشطًا</option>{activeOffices.map((office) => <option key={office.id} value={office.id}>{office.name}</option>)}</select></div>}
          <button className="button button-primary button-inline" type="submit" disabled={pending || !canManageOfficeStaff || !selectedUserId}>إسناد الدور</button>
        </form>
      </section>

      <section className="admin-card">
        <div className="admin-card-header"><div><h3>{provisionMode === "invite_staff" ? "دعوة موظف بالبريد" : "إنشاء موظف مباشرة"}</h3><p>{provisionMode === "invite_staff" ? "سيُرسل بريد دعوة عبر المسار الموثوق admin-staff، ولا يمنح التسجيل العام صلاحيات STAFF." : "ينشئ المسار الموثوق حساب STAFF باستخدام كلمة مرور أولية؛ لا تستخدم هذا الخيار لإسناد صلاحيات لنفسك."}</p></div></div>
        <form className="admin-form" onSubmit={inviteStaff}>
          <div className="mode-switch" role="tablist" aria-label="طريقة إضافة الموظف">
            <button className={provisionMode === "invite_staff" ? "mode-option active" : "mode-option"} type="button" role="tab" aria-selected={provisionMode === "invite_staff"} onClick={() => setProvisionMode("invite_staff")}>دعوة بالبريد</button>
            <button className={provisionMode === "create_staff" ? "mode-option active" : "mode-option"} type="button" role="tab" aria-selected={provisionMode === "create_staff"} onClick={() => setProvisionMode("create_staff")}>إنشاء مباشر</button>
          </div>
          <div className="form-row"><div className="field"><label htmlFor="invite-name">اسم الموظف</label><input id="invite-name" value={inviteName} onChange={(event) => setInviteName(event.target.value)} required /></div><div className="field"><label htmlFor="invite-email">البريد الإلكتروني</label><input id="invite-email" dir="ltr" type="email" value={inviteEmail} onChange={(event) => setInviteEmail(event.target.value)} required /></div></div>
          {provisionMode === "create_staff" && <div className="field"><label htmlFor="initial-password">كلمة المرور الأولية</label><input id="initial-password" dir="ltr" type="password" minLength={8} autoComplete="new-password" value={initialPassword} onChange={(event) => setInitialPassword(event.target.value)} required /><small className="inline-note">8 أحرف على الأقل. ستُرسل بيانات الحساب عبر قناة آمنة منفصلة.</small></div>}
          <div className="form-row form-row-3"><div className="field"><label htmlFor="invite-role">الدور</label><select id="invite-role" value={inviteRoleId} onChange={(event) => { setInviteRoleId(event.target.value); const role = data.roles.find((item) => item.id === event.target.value); setInviteScope(role?.scope_type === "PLATFORM" && isSuperAdmin ? "PLATFORM" : "OFFICE"); }} required>{data.roles.map((role) => <option key={role.id} value={role.id}>{role.name} · {role.scope_type}</option>)}</select></div><div className="field"><label htmlFor="invite-scope">النطاق</label><select id="invite-scope" value={inviteScope} onChange={(event) => setInviteScope(event.target.value as "PLATFORM" | "OFFICE")} disabled={availableInviteScopes.length < 2}>{availableInviteScopes.map((scope) => <option key={scope} value={scope}>{scope === "PLATFORM" ? "المنصة" : "مكتب"}</option>)}</select></div>{inviteScope === "OFFICE" && <div className="field"><label htmlFor="invite-office">المكتب</label><select id="invite-office" value={inviteOfficeId} onChange={(event) => setInviteOfficeId(event.target.value)} required><option value="">اختر مكتبًا نشطًا</option>{activeOffices.map((office) => <option key={office.id} value={office.id}>{office.name}</option>)}</select></div>}</div>
          <button className="button button-primary button-inline" type="submit" disabled={pending || !canManageOfficeStaff}>{provisionMode === "invite_staff" ? "إرسال الدعوة" : "إنشاء الموظف"}</button>
        </form>
      </section>
    </div>
  );
}
