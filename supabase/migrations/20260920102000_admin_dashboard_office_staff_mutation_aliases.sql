-- ADM-10 follow-up: qualify table columns that share names with RETURNS TABLE
-- output variables in the two membership mutation RPCs.

create or replace function public.admin_update_office_member_role(
  p_office_id uuid,
  p_user_id uuid,
  p_role_id uuid,
  p_reason text
)
returns table (
  membership_id uuid,
  user_id uuid,
  role_id uuid,
  role_code text,
  role_name text,
  membership_status public.account_status,
  updated_at timestamptz
)
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_member public.office_members;
  v_profile public.profiles;
  v_role public.roles;
  v_old jsonb;
  v_reason text := private.admin_reason_required(p_reason);
begin
  if p_office_id is null or p_user_id is null or p_role_id is null then
    raise exception 'Office, staff user, and role are required' using errcode = '22023';
  end if;
  if not private.can_access_office(p_office_id, 'office_members.manage') then
    raise exception 'Office staff-management access required' using errcode = '42501';
  end if;
  if p_user_id = (select auth.uid()) then
    raise exception 'Self role changes are not allowed' using errcode = '42501';
  end if;

  select om.* into v_member
  from public.office_members om
  where om.office_id = p_office_id and om.user_id = p_user_id
  for update;
  if not found then
    raise exception 'Office staff member not found' using errcode = 'P0002';
  end if;
  select p.* into v_profile from public.profiles p where p.id = p_user_id;
  if v_profile.profile_type <> 'STAFF'::public.profile_type then
    raise exception 'Active staff profile required' using errcode = '42501';
  end if;
  select r.* into v_role from public.roles r where r.id = p_role_id;
  if not found then
    raise exception 'Role not found' using errcode = 'P0002';
  end if;
  if v_role.scope_type not in ('OFFICE', 'CUSTOM') then
    raise exception 'Only office-scoped roles may be assigned' using errcode = '42501';
  end if;

  v_old := jsonb_build_object(
    'role_id', v_member.role_id,
    'role_code', (select r.code from public.roles r where r.id = v_member.role_id),
    'status', v_member.status::text
  );
  update public.office_members om
  set role_id = v_role.id, updated_at = clock_timestamp()
  where om.id = v_member.id
  returning om.* into v_member;

  perform private.record_admin_audit(
    'OFFICE_MEMBER_ROLE_CHANGED', 'OFFICE_MEMBER', v_member.id, v_reason,
    v_old,
    jsonb_build_object('role_id', v_role.id, 'role_code', v_role.code,
      'role_scope_type', v_role.scope_type, 'status', v_member.status::text),
    jsonb_build_object('office_id', p_office_id, 'permission', 'office_members.manage')
  );

  return query select v_member.id, v_member.user_id, v_role.id, v_role.code::text,
    v_role.name::text, v_member.status, v_member.updated_at;
end;
$function$;

create or replace function public.admin_update_office_member_status(
  p_office_id uuid,
  p_user_id uuid,
  p_status public.account_status,
  p_reason text
)
returns table (
  membership_id uuid,
  user_id uuid,
  role_id uuid,
  role_code text,
  membership_status public.account_status,
  updated_at timestamptz
)
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_member public.office_members;
  v_profile public.profiles;
  v_role public.roles;
  v_old_status public.account_status;
  v_reason text := private.admin_reason_required(p_reason);
begin
  if p_office_id is null or p_user_id is null then
    raise exception 'Office and staff user are required' using errcode = '22023';
  end if;
  if not private.can_access_office(p_office_id, 'office_members.manage') then
    raise exception 'Office staff-management access required' using errcode = '42501';
  end if;
  if p_user_id = (select auth.uid()) then
    raise exception 'Self membership changes are not allowed' using errcode = '42501';
  end if;
  if p_status not in ('ACTIVE'::public.account_status, 'SUSPENDED'::public.account_status) then
    raise exception 'Only ACTIVE or SUSPENDED membership is supported' using errcode = '22023';
  end if;

  select om.* into v_member
  from public.office_members om
  where om.office_id = p_office_id and om.user_id = p_user_id
  for update;
  if not found then
    raise exception 'Office staff member not found' using errcode = 'P0002';
  end if;
  select p.* into v_profile from public.profiles p where p.id = p_user_id;
  if v_profile.profile_type <> 'STAFF'::public.profile_type then
    raise exception 'Staff profile required' using errcode = '42501';
  end if;
  if p_status = 'ACTIVE'::public.account_status
     and v_profile.status <> 'ACTIVE'::public.account_status then
    raise exception 'Active profile required before membership activation' using errcode = '42501';
  end if;
  select r.* into v_role from public.roles r where r.id = v_member.role_id;
  v_old_status := v_member.status;

  update public.office_members om
  set status = p_status, updated_at = clock_timestamp()
  where om.id = v_member.id
  returning om.* into v_member;

  perform private.record_admin_audit(
    'OFFICE_MEMBER_STATUS_CHANGED', 'OFFICE_MEMBER', v_member.id, v_reason,
    jsonb_build_object('status', v_old_status::text),
    jsonb_build_object('status', v_member.status::text),
    jsonb_build_object('office_id', p_office_id, 'permission', 'office_members.manage')
  );

  return query select v_member.id, v_member.user_id, v_member.role_id,
    v_role.code::text, v_member.status, v_member.updated_at;
end;
$function$;
