-- ADM-10: exact-office staff management.
-- Office membership is the authorization boundary. These RPCs expose only
-- the selected office and never expose auth metadata beyond the email field.

create or replace function public.admin_list_office_staff(
  p_office_id uuid,
  p_search text default null,
  p_status public.account_status default null,
  p_limit integer default 50,
  p_offset integer default 0
)
returns table (
  membership_id uuid,
  user_id uuid,
  full_name text,
  email text,
  phone text,
  profile_status public.account_status,
  membership_status public.account_status,
  role_id uuid,
  role_code text,
  role_name text,
  role_scope_type text,
  created_at timestamptz,
  updated_at timestamptz,
  total_count bigint
)
language plpgsql
stable
security definer
set search_path = ''
as $function$
begin
  if p_office_id is null then
    raise exception 'Office is required' using errcode = '22023';
  end if;
  if p_limit is null or p_limit < 1 or p_limit > 100
     or p_offset is null or p_offset < 0 then
    raise exception 'Invalid staff pagination' using errcode = '22023';
  end if;
  if p_search is not null and length(btrim(p_search)) > 120 then
    raise exception 'Staff search is too long' using errcode = '22023';
  end if;
  if not private.can_access_office(p_office_id, 'office_members.manage') then
    raise exception 'Office staff-management access required' using errcode = '42501';
  end if;

  return query
  select om.id, p.id, p.full_name, au.email, p.phone, p.status, om.status,
    r.id, r.code, r.name, r.scope_type, om.created_at, om.updated_at,
    count(*) over ()::bigint
  from public.office_members om
  join public.profiles p on p.id = om.user_id
  join public.roles r on r.id = om.role_id
  join auth.users au on au.id = om.user_id
  where om.office_id = p_office_id
    and p.profile_type = 'STAFF'::public.profile_type
    and (p_status is null or om.status = p_status)
    and (
      nullif(btrim(p_search), '') is null
      or p.full_name ilike '%' || btrim(p_search) || '%'
      or coalesce(au.email, '') ilike '%' || btrim(p_search) || '%'
      or coalesce(p.phone, '') ilike '%' || btrim(p_search) || '%'
      or r.code ilike '%' || btrim(p_search) || '%'
    )
  order by p.full_name, p.id
  limit p_limit offset p_offset;
end;
$function$;

create or replace function public.admin_get_office_staff(
  p_office_id uuid,
  p_user_id uuid
)
returns table (
  membership_id uuid,
  user_id uuid,
  full_name text,
  email text,
  phone text,
  profile_status public.account_status,
  membership_status public.account_status,
  role_id uuid,
  role_code text,
  role_name text,
  role_scope_type text,
  created_at timestamptz,
  updated_at timestamptz,
  total_count bigint
)
language plpgsql
stable
security definer
set search_path = ''
as $function$
begin
  if p_office_id is null or p_user_id is null then
    raise exception 'Office and staff user are required' using errcode = '22023';
  end if;
  if not private.can_access_office(p_office_id, 'office_members.manage') then
    raise exception 'Office staff-management access required' using errcode = '42501';
  end if;

  return query
  select om.id, p.id, p.full_name, au.email, p.phone, p.status, om.status,
    r.id, r.code, r.name, r.scope_type, om.created_at, om.updated_at, 1::bigint
  from public.office_members om
  join public.profiles p on p.id = om.user_id
  join public.roles r on r.id = om.role_id
  join auth.users au on au.id = om.user_id
  where om.office_id = p_office_id
    and om.user_id = p_user_id
    and p.profile_type = 'STAFF'::public.profile_type;

  if not found then
    raise exception 'Office staff member not found' using errcode = 'P0002';
  end if;
end;
$function$;

create or replace function public.admin_list_assignable_office_roles(
  p_office_id uuid
)
returns table (
  id uuid,
  code text,
  name text,
  scope_type text
)
language plpgsql
stable
security definer
set search_path = ''
as $function$
begin
  if p_office_id is null then
    raise exception 'Office is required' using errcode = '22023';
  end if;
  if not private.can_access_office(p_office_id, 'office_members.manage') then
    raise exception 'Office staff-management access required' using errcode = '42501';
  end if;

  return query
  select r.id, r.code, r.name, r.scope_type
  from public.roles r
  where r.scope_type in ('OFFICE', 'CUSTOM')
  order by r.name, r.code;
end;
$function$;

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

  select * into v_member
  from public.office_members
  where office_id = p_office_id and user_id = p_user_id
  for update;
  if not found then
    raise exception 'Office staff member not found' using errcode = 'P0002';
  end if;
  select * into v_profile from public.profiles where id = p_user_id;
  if v_profile.profile_type <> 'STAFF'::public.profile_type then
    raise exception 'Active staff profile required' using errcode = '42501';
  end if;
  select * into v_role from public.roles where id = p_role_id;
  if not found then
    raise exception 'Role not found' using errcode = 'P0002';
  end if;
  if v_role.scope_type not in ('OFFICE', 'CUSTOM') then
    raise exception 'Only office-scoped roles may be assigned' using errcode = '42501';
  end if;

  v_old := jsonb_build_object(
    'role_id', v_member.role_id,
    'role_code', (select code from public.roles where id = v_member.role_id),
    'status', v_member.status::text
  );
  update public.office_members
  set role_id = v_role.id, updated_at = clock_timestamp()
  where id = v_member.id
  returning * into v_member;

  perform private.record_admin_audit(
    'OFFICE_MEMBER_ROLE_CHANGED', 'OFFICE_MEMBER', v_member.id, v_reason,
    v_old,
    jsonb_build_object('role_id', v_role.id, 'role_code', v_role.code,
      'role_scope_type', v_role.scope_type, 'status', v_member.status::text),
    jsonb_build_object('office_id', p_office_id, 'permission', 'office_members.manage')
  );

  return query select v_member.id, v_member.user_id, v_role.id, v_role.code,
    v_role.name, v_member.status, v_member.updated_at;
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

  select * into v_member
  from public.office_members
  where office_id = p_office_id and user_id = p_user_id
  for update;
  if not found then
    raise exception 'Office staff member not found' using errcode = 'P0002';
  end if;
  select * into v_profile from public.profiles where id = p_user_id;
  if v_profile.profile_type <> 'STAFF'::public.profile_type then
    raise exception 'Staff profile required' using errcode = '42501';
  end if;
  if p_status = 'ACTIVE'::public.account_status
     and v_profile.status <> 'ACTIVE'::public.account_status then
    raise exception 'Active profile required before membership activation' using errcode = '42501';
  end if;
  select * into v_role from public.roles where id = v_member.role_id;
  v_old_status := v_member.status;

  update public.office_members
  set status = p_status, updated_at = clock_timestamp()
  where id = v_member.id
  returning * into v_member;

  perform private.record_admin_audit(
    'OFFICE_MEMBER_STATUS_CHANGED', 'OFFICE_MEMBER', v_member.id, v_reason,
    jsonb_build_object('status', v_old_status::text),
    jsonb_build_object('status', v_member.status::text),
    jsonb_build_object('office_id', p_office_id, 'permission', 'office_members.manage')
  );

  return query select v_member.id, v_member.user_id, v_member.role_id,
    v_role.code, v_member.status, v_member.updated_at;
end;
$function$;

-- A role key carried by an office membership must not expose the global
-- platform role catalog or platform assignments. Keep self user_roles reads
-- for the caller's bounded identity context; platform catalog reads require
-- a platform-scoped roles.view grant.
drop policy if exists roles_select_authorized on public.roles;
create policy roles_select_authorized
on public.roles
for select
to authenticated
using (
  private.is_super_admin()
  or private.has_platform_permission('roles.view')
);

drop policy if exists permissions_select_authorized on public.permissions;
create policy permissions_select_authorized
on public.permissions
for select
to authenticated
using (
  private.is_super_admin()
  or private.has_platform_permission('roles.view')
);

drop policy if exists role_permissions_select_authorized on public.role_permissions;
create policy role_permissions_select_authorized
on public.role_permissions
for select
to authenticated
using (
  private.is_super_admin()
  or private.has_platform_permission('roles.view')
);

drop policy if exists user_roles_select_permitted on public.user_roles;
create policy user_roles_select_permitted
on public.user_roles
for select
to authenticated
using (
  user_id = (select auth.uid())
  or private.is_super_admin()
  or private.has_platform_permission('roles.view')
);

revoke all on function public.admin_list_office_staff(uuid,text,public.account_status,integer,integer)
  from public, anon, authenticated;
revoke all on function public.admin_get_office_staff(uuid,uuid)
  from public, anon, authenticated;
revoke all on function public.admin_list_assignable_office_roles(uuid)
  from public, anon, authenticated;
revoke all on function public.admin_update_office_member_role(uuid,uuid,uuid,text)
  from public, anon, authenticated;
revoke all on function public.admin_update_office_member_status(uuid,uuid,public.account_status,text)
  from public, anon, authenticated;
grant execute on function public.admin_list_office_staff(uuid,text,public.account_status,integer,integer)
  to authenticated;
grant execute on function public.admin_get_office_staff(uuid,uuid) to authenticated;
grant execute on function public.admin_list_assignable_office_roles(uuid) to authenticated;
grant execute on function public.admin_update_office_member_role(uuid,uuid,uuid,text)
  to authenticated;
grant execute on function public.admin_update_office_member_status(uuid,uuid,public.account_status,text)
  to authenticated;
