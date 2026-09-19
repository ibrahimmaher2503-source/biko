-- ADM-08: least-privilege role and staff administration.
-- All mutations are named SECURITY DEFINER RPCs. Auth creation stays in the
-- admin-staff Edge Function; this migration never creates a first admin.

insert into public.permissions (code, description)
values (
  'office_members.manage',
  'Manage staff membership for an authorized office'
)
on conflict (code) do update
  set description = excluded.description;

insert into public.role_permissions (role_id, permission_id)
select r.id, p.id
from public.roles r
cross join public.permissions p
where r.code = 'OFFICE_ADMIN'
  and p.code = 'office_members.manage'
on conflict do nothing;

create or replace function private.admin_reason_required(p_reason text)
returns text
language plpgsql
immutable
set search_path = ''
as $function$
begin
  if nullif(btrim(p_reason), '') is null or length(btrim(p_reason)) > 500 then
    raise exception 'Reason required' using errcode = '22023';
  end if;
  return btrim(p_reason);
end;
$function$;

create or replace function private.admin_valid_super_admin_count()
returns bigint
language sql
stable
security definer
set search_path = ''
as $function$
  select count(*)
  from public.user_roles ur
  join public.roles r
    on r.id = ur.role_id
   and r.code = 'SUPER_ADMIN'
   and r.scope_type = 'PLATFORM'
  join public.profiles p
    on p.id = ur.user_id
   and p.profile_type = 'STAFF'::public.profile_type
   and p.status = 'ACTIVE'::public.account_status;
$function$;

revoke all on function private.admin_reason_required(text) from public, anon, authenticated;
revoke all on function private.admin_valid_super_admin_count() from public, anon, authenticated;

create or replace function public.admin_can_create_staff(
  p_role_id uuid,
  p_office_id uuid default null
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $function$
  select exists (
    select 1
    from public.roles r
    where r.id = p_role_id
      and (
        (
          r.scope_type = 'PLATFORM'
          and p_office_id is null
          and private.is_super_admin()
          and private.has_platform_permission('roles.manage')
        )
        or (
          r.scope_type = 'CUSTOM'
          and p_office_id is null
          and private.is_super_admin()
          and private.has_platform_permission('roles.manage')
        )
        or (
          r.scope_type in ('OFFICE', 'CUSTOM')
          and p_office_id is not null
          and private.can_access_office(p_office_id, 'office_members.manage')
          and exists (
            select 1 from public.offices o
            where o.id = p_office_id
              and o.status = 'ACTIVE'::public.account_status
          )
        )
      )
  );
$function$;

revoke all on function public.admin_can_create_staff(uuid,uuid) from public, anon, authenticated;
grant execute on function public.admin_can_create_staff(uuid,uuid) to authenticated;

create or replace function public.admin_create_role(
  p_code text,
  p_name text,
  p_scope_type text,
  p_permission_codes text[] default '{}'::text[],
  p_reason text default null
)
returns public.roles
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_role public.roles;
  v_reason text := private.admin_reason_required(p_reason);
  v_codes text[] := coalesce(p_permission_codes, '{}'::text[]);
begin
  if not private.is_super_admin()
     or not private.has_platform_permission('roles.manage') then
    raise exception 'Super Admin role management required' using errcode = '42501';
  end if;
  if nullif(btrim(p_code), '') is null
     or btrim(p_code) !~ '^[A-Z][A-Z0-9_]{2,63}$' then
    raise exception 'Invalid role code' using errcode = '22023';
  end if;
  if nullif(btrim(p_name), '') is null or length(btrim(p_name)) > 120 then
    raise exception 'Invalid role name' using errcode = '22023';
  end if;
  if p_scope_type not in ('PLATFORM', 'OFFICE', 'CUSTOM') then
    raise exception 'Unsupported role scope' using errcode = '22023';
  end if;
  if exists (select 1 from public.roles where code = btrim(p_code)) then
    raise exception 'Role code already exists' using errcode = '23505';
  end if;
  if exists (
    select 1 from unnest(v_codes) as c(code)
    where not exists (select 1 from public.permissions p where p.code = c.code)
  ) then
    raise exception 'Unknown permission' using errcode = '22023';
  end if;

  insert into public.roles (code, name, scope_type)
  values (btrim(p_code), btrim(p_name), p_scope_type)
  returning * into v_role;

  insert into public.role_permissions (role_id, permission_id)
  select v_role.id, p.id
  from public.permissions p
  where p.code = any(v_codes)
  on conflict do nothing;

  perform private.record_admin_audit(
    'ROLE_CREATED', 'ROLE', v_role.id, v_reason, null,
    jsonb_build_object('code', v_role.code, 'name', v_role.name,
      'scope_type', v_role.scope_type, 'permission_codes', v_codes),
    '{}'::jsonb
  );
  return v_role;
end;
$function$;

create or replace function public.admin_rename_role(
  p_role_id uuid,
  p_name text,
  p_reason text
)
returns public.roles
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_role public.roles;
  v_old_name text;
  v_reason text := private.admin_reason_required(p_reason);
begin
  if not private.is_super_admin()
     or not private.has_platform_permission('roles.manage') then
    raise exception 'Super Admin role management required' using errcode = '42501';
  end if;
  if nullif(btrim(p_name), '') is null or length(btrim(p_name)) > 120 then
    raise exception 'Invalid role name' using errcode = '22023';
  end if;
  select * into v_role from public.roles where id = p_role_id for update;
  if not found then raise exception 'Role not found' using errcode = 'P0002'; end if;
  v_old_name := v_role.name;
  update public.roles
  set name = btrim(p_name)
  where id = p_role_id
  returning * into v_role;
  perform private.record_admin_audit(
    'ROLE_RENAMED', 'ROLE', v_role.id, v_reason,
    jsonb_build_object('name', v_old_name),
    jsonb_build_object('name', v_role.name, 'code', v_role.code), '{}'::jsonb
  );
  return v_role;
end;
$function$;

create or replace function public.admin_set_role_permissions(
  p_role_id uuid,
  p_permission_codes text[],
  p_reason text
)
returns public.roles
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_role public.roles;
  v_codes text[] := coalesce(p_permission_codes, '{}'::text[]);
  v_old_codes text[];
  v_reason text := private.admin_reason_required(p_reason);
begin
  if not private.is_super_admin()
     or not private.has_platform_permission('roles.manage') then
    raise exception 'Super Admin role management required' using errcode = '42501';
  end if;
  select * into v_role from public.roles where id = p_role_id for update;
  if not found then raise exception 'Role not found' using errcode = 'P0002'; end if;
  if v_role.code = 'SUPER_ADMIN'
     and not ('dashboard.view' = any(v_codes) and 'roles.manage' = any(v_codes)) then
    raise exception 'Super Admin baseline permissions cannot be removed' using errcode = '42501';
  end if;
  if exists (
    select 1 from unnest(v_codes) as c(code)
    where not exists (select 1 from public.permissions p where p.code = c.code)
  ) then
    raise exception 'Unknown permission' using errcode = '22023';
  end if;
  select coalesce(array_agg(p.code order by p.code), '{}'::text[])
    into v_old_codes
  from public.role_permissions rp
  join public.permissions p on p.id = rp.permission_id
  where rp.role_id = p_role_id;
  delete from public.role_permissions where role_id = p_role_id;
  insert into public.role_permissions (role_id, permission_id)
  select p_role_id, p.id from public.permissions p
  where p.code = any(v_codes)
  on conflict do nothing;
  perform private.record_admin_audit(
    'ROLE_PERMISSIONS_CHANGED', 'ROLE', v_role.id, v_reason,
    jsonb_build_object('permission_codes', v_old_codes),
    jsonb_build_object('permission_codes', v_codes), '{}'::jsonb
  );
  return v_role;
end;
$function$;

create or replace function public.admin_assign_staff_role(
  p_target_user_id uuid,
  p_role_id uuid,
  p_office_id uuid default null,
  p_reason text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_uid uuid := (select auth.uid());
  v_role public.roles;
  v_target public.profiles;
  v_old jsonb;
  v_new jsonb;
  v_reason text := private.admin_reason_required(p_reason);
begin
  if v_uid is null or p_target_user_id = v_uid then
    raise exception 'Self role elevation is not allowed' using errcode = '42501';
  end if;
  select * into v_target from public.profiles where id = p_target_user_id for update;
  if not found or v_target.profile_type <> 'STAFF'::public.profile_type
     or v_target.status <> 'ACTIVE'::public.account_status then
    raise exception 'Active staff target required' using errcode = '42501';
  end if;
  select * into v_role from public.roles where id = p_role_id for update;
  if not found then raise exception 'Role not found' using errcode = 'P0002'; end if;
  if v_role.scope_type = 'PLATFORM' then
    if p_office_id is not null or not private.is_super_admin()
       or not private.has_platform_permission('roles.manage') then
      raise exception 'Platform role assignment requires Super Admin' using errcode = '42501';
    end if;
    v_old := coalesce((select to_jsonb(ur) from public.user_roles ur
      where ur.user_id = p_target_user_id and ur.role_id = p_role_id), '{}'::jsonb);
    insert into public.user_roles (user_id, role_id)
    values (p_target_user_id, p_role_id)
    on conflict (user_id, role_id) do nothing;
  elsif v_role.scope_type in ('OFFICE', 'CUSTOM') then
    if p_office_id is null then
      if v_role.scope_type <> 'CUSTOM' or not private.is_super_admin()
         or not private.has_platform_permission('roles.manage') then
        raise exception 'Office role assignment requires an office' using errcode = '42501';
      end if;
    elsif not private.can_access_office(p_office_id, 'office_members.manage') then
      raise exception 'Office role assignment requires office staff-management access' using errcode = '42501';
    end if;
    if p_office_id is not null and not exists (
      select 1 from public.offices where id = p_office_id
        and status = 'ACTIVE'::public.account_status
    ) then raise exception 'Active office required' using errcode = '22023'; end if;
    if p_office_id is null then
      v_old := coalesce((select to_jsonb(ur) from public.user_roles ur
        where ur.user_id = p_target_user_id and ur.role_id = p_role_id), '{}'::jsonb);
      insert into public.user_roles (user_id, role_id)
      values (p_target_user_id, p_role_id)
      on conflict (user_id, role_id) do nothing;
    else
      v_old := coalesce((select to_jsonb(om) from public.office_members om
        where om.user_id = p_target_user_id and om.office_id = p_office_id), '{}'::jsonb);
      insert into public.office_members (user_id, office_id, role_id, status)
      values (p_target_user_id, p_office_id, p_role_id, 'ACTIVE'::public.account_status)
      on conflict (office_id, user_id) do update
        set role_id = excluded.role_id, status = excluded.status, updated_at = clock_timestamp();
    end if;
  else
    raise exception 'Unsupported role scope' using errcode = '22023';
  end if;
  v_new := jsonb_build_object('role_id', p_role_id, 'role_code', v_role.code,
    'scope_type', v_role.scope_type, 'office_id', p_office_id, 'status', 'ACTIVE');
  perform private.record_admin_audit(
    'STAFF_ROLE_ASSIGNED', 'PROFILE', p_target_user_id, v_reason,
    v_old, v_new, jsonb_build_object('role_code', v_role.code, 'office_id', p_office_id)
  );
  return v_new;
end;
$function$;

create or replace function public.admin_revoke_staff_role(
  p_target_user_id uuid,
  p_role_id uuid,
  p_office_id uuid default null,
  p_reason text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_uid uuid := (select auth.uid());
  v_role public.roles;
  v_target public.profiles;
  v_removed boolean := false;
  v_reason text := private.admin_reason_required(p_reason);
begin
  if v_uid is null then raise exception 'Authenticated actor required' using errcode = '42501'; end if;
  select * into v_target from public.profiles where id = p_target_user_id for update;
  if not found then raise exception 'Staff target not found' using errcode = 'P0002'; end if;
  select * into v_role from public.roles where id = p_role_id for update;
  if not found then raise exception 'Role not found' using errcode = 'P0002'; end if;
  if v_role.scope_type = 'PLATFORM' then
    if not private.is_super_admin()
       or not private.has_platform_permission('roles.manage') then
      raise exception 'Platform role revocation requires Super Admin' using errcode = '42501';
    end if;
    if v_role.code = 'SUPER_ADMIN'
       and (select private.admin_valid_super_admin_count()) <= 1 then
      raise exception 'At least one active Super Admin is required' using errcode = '42501';
    end if;
    delete from public.user_roles
    where user_id = p_target_user_id and role_id = p_role_id;
    v_removed := found;
  elsif v_role.scope_type in ('OFFICE', 'CUSTOM') then
    if p_office_id is null then
      if v_role.scope_type <> 'CUSTOM' or not private.is_super_admin()
         or not private.has_platform_permission('roles.manage') then
        raise exception 'Office role revocation requires an office' using errcode = '42501';
      end if;
      delete from public.user_roles where user_id = p_target_user_id and role_id = p_role_id;
      v_removed := found;
    else
      if not private.can_access_office(p_office_id, 'office_members.manage') then
        raise exception 'Office role revocation requires office staff-management access' using errcode = '42501';
      end if;
      delete from public.office_members
      where user_id = p_target_user_id and role_id = p_role_id and office_id = p_office_id;
      v_removed := found;
    end if;
  else
    raise exception 'Unsupported role scope' using errcode = '22023';
  end if;
  if not v_removed then raise exception 'Role assignment not found' using errcode = 'P0002'; end if;
  perform private.record_admin_audit(
    'STAFF_ROLE_REVOKED', 'PROFILE', p_target_user_id, v_reason,
    jsonb_build_object('role_id', p_role_id, 'role_code', v_role.code, 'office_id', p_office_id),
    '{}'::jsonb, '{}'::jsonb
  );
  return jsonb_build_object('user_id', p_target_user_id, 'role_id', p_role_id,
    'role_code', v_role.code, 'office_id', p_office_id, 'revoked', true);
end;
$function$;

create or replace function public.admin_update_staff_status(
  p_target_user_id uuid,
  p_status public.account_status,
  p_reason text
)
returns public.profiles
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_profile public.profiles;
  v_old jsonb;
  v_reason text := private.admin_reason_required(p_reason);
begin
  if not private.is_super_admin()
     or not private.has_platform_permission('roles.manage') then
    raise exception 'Super Admin staff management required' using errcode = '42501';
  end if;
  if p_status not in ('ACTIVE'::public.account_status, 'SUSPENDED'::public.account_status) then
    raise exception 'Unsupported staff status' using errcode = '22023';
  end if;
  select * into v_profile from public.profiles where id = p_target_user_id for update;
  if not found or v_profile.profile_type <> 'STAFF'::public.profile_type then
    raise exception 'Staff target required' using errcode = '22023';
  end if;
  if v_profile.status = 'ACTIVE'::public.account_status
     and p_status = 'SUSPENDED'::public.account_status
     and exists (
       select 1 from public.user_roles ur join public.roles r on r.id = ur.role_id
       where ur.user_id = p_target_user_id and r.code = 'SUPER_ADMIN'
     )
     and (select private.admin_valid_super_admin_count()) <= 1 then
    raise exception 'At least one active Super Admin is required' using errcode = '42501';
  end if;
  v_old := jsonb_build_object('status', v_profile.status::text, 'profile_type', v_profile.profile_type::text);
  update public.profiles set status = p_status, updated_at = clock_timestamp()
  where id = p_target_user_id returning * into v_profile;
  perform private.record_admin_audit(
    'STAFF_STATUS_CHANGED', 'PROFILE', p_target_user_id, v_reason,
    v_old, jsonb_build_object('status', v_profile.status::text), '{}'::jsonb
  );
  return v_profile;
end;
$function$;

create or replace function public.admin_create_staff(
  p_user_id uuid,
  p_full_name text,
  p_role_id uuid,
  p_office_id uuid default null,
  p_reason text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_profile public.profiles;
  v_role public.roles;
  v_uid uuid := (select auth.uid());
  v_reason text := private.admin_reason_required(p_reason);
begin
  if v_uid is null or p_user_id = v_uid then
    raise exception 'Self staff creation or elevation is not allowed' using errcode = '42501';
  end if;
  select * into v_role from public.roles where id = p_role_id for update;
  if not found then raise exception 'Role not found' using errcode = 'P0002'; end if;
  if v_role.scope_type = 'PLATFORM' then
    if p_office_id is not null or not private.is_super_admin()
       or not private.has_platform_permission('roles.manage') then
      raise exception 'Platform staff creation requires Super Admin' using errcode = '42501';
    end if;
  elsif v_role.scope_type in ('OFFICE', 'CUSTOM') then
    if p_office_id is null then
      if v_role.scope_type <> 'CUSTOM' or not private.is_super_admin()
         or not private.has_platform_permission('roles.manage') then
        raise exception 'Office staff creation requires an office' using errcode = '42501';
      end if;
    elsif not private.can_access_office(p_office_id, 'office_members.manage') then
      raise exception 'Office staff creation requires office staff-management access' using errcode = '42501';
    end if;
    if p_office_id is not null and not exists (select 1 from public.offices where id = p_office_id
      and status = 'ACTIVE'::public.account_status) then
      raise exception 'Active office required' using errcode = '22023';
    end if;
  else
    raise exception 'Unsupported role scope' using errcode = '22023';
  end if;
  select * into v_profile from public.profiles where id = p_user_id for update;
  if not found then raise exception 'Auth profile not found' using errcode = 'P0002'; end if;
  if v_profile.profile_type <> 'CUSTOMER'::public.profile_type
     or v_profile.status = 'DELETED'::public.account_status then
    raise exception 'Only a new Customer profile may become staff' using errcode = '42501';
  end if;
  update public.profiles set
    full_name = coalesce(nullif(btrim(p_full_name), ''), full_name),
    profile_type = 'STAFF'::public.profile_type,
    status = 'ACTIVE'::public.account_status,
    updated_at = clock_timestamp()
  where id = p_user_id returning * into v_profile;
  if v_role.scope_type in ('PLATFORM', 'CUSTOM') and p_office_id is null then
    insert into public.user_roles (user_id, role_id) values (p_user_id, p_role_id);
  else
    insert into public.office_members (office_id, user_id, role_id, status)
    values (p_office_id, p_user_id, p_role_id, 'ACTIVE'::public.account_status);
  end if;
  perform private.record_admin_audit(
    'STAFF_CREATED', 'PROFILE', p_user_id, v_reason,
    jsonb_build_object('profile_type', 'CUSTOMER', 'status', 'ACTIVE'),
    jsonb_build_object('profile_type', 'STAFF', 'status', 'ACTIVE',
      'role_code', v_role.code, 'scope_type', v_role.scope_type, 'office_id', p_office_id),
    jsonb_build_object('auth_user_created', true, 'invitation_sent', false)
  );
  return jsonb_build_object('user_id', p_user_id, 'profile_type', v_profile.profile_type::text,
    'status', v_profile.status::text, 'role_code', v_role.code,
    'scope_type', v_role.scope_type, 'office_id', p_office_id,
    'invitation_sent', false);
end;
$function$;

revoke all on function public.admin_create_role(text,text,text,text[],text) from public, anon, authenticated;
revoke all on function public.admin_rename_role(uuid,text,text) from public, anon, authenticated;
revoke all on function public.admin_set_role_permissions(uuid,text[],text) from public, anon, authenticated;
revoke all on function public.admin_assign_staff_role(uuid,uuid,uuid,text) from public, anon, authenticated;
revoke all on function public.admin_revoke_staff_role(uuid,uuid,uuid,text) from public, anon, authenticated;
revoke all on function public.admin_update_staff_status(uuid,public.account_status,text) from public, anon, authenticated;
revoke all on function public.admin_create_staff(uuid,text,uuid,uuid,text) from public, anon, authenticated;
grant execute on function public.admin_create_role(text,text,text,text[],text) to authenticated;
grant execute on function public.admin_rename_role(uuid,text,text) to authenticated;
grant execute on function public.admin_set_role_permissions(uuid,text[],text) to authenticated;
grant execute on function public.admin_assign_staff_role(uuid,uuid,uuid,text) to authenticated;
grant execute on function public.admin_revoke_staff_role(uuid,uuid,uuid,text) to authenticated;
grant execute on function public.admin_update_staff_status(uuid,public.account_status,text) to authenticated;
grant execute on function public.admin_create_staff(uuid,text,uuid,uuid,text) to authenticated;
