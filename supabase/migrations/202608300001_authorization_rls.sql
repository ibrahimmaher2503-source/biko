-- Milestone 3: role, permission, office-scope, and least-privilege RLS enforcement.

create schema if not exists private;

create or replace function private.is_super_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select (select auth.uid()) is not null
    and exists (
      select 1
      from public.user_roles ur
      join public.roles r on r.id = ur.role_id
      where ur.user_id = (select auth.uid())
        and r.code = 'SUPER_ADMIN'
    );
$$;

create or replace function private.has_permission(permission_code text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select (select auth.uid()) is not null
    and exists (
      select 1
      from public.user_roles ur
      join public.role_permissions rp on rp.role_id = ur.role_id
      join public.permissions p on p.id = rp.permission_id
      where ur.user_id = (select auth.uid())
        and p.code = permission_code
    )
    or exists (
      select 1
      from public.office_members om
      join public.role_permissions rp on rp.role_id = om.role_id
      join public.permissions p on p.id = rp.permission_id
      where om.user_id = (select auth.uid())
        and om.status = 'ACTIVE'::public.account_status
        and p.code = permission_code
    );
$$;

create or replace function private.is_office_member(target_office_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select (select auth.uid()) is not null
    and exists (
      select 1
      from public.office_members om
      where om.office_id = target_office_id
        and om.user_id = (select auth.uid())
        and om.status = 'ACTIVE'::public.account_status
    );
$$;

create or replace function private.can_access_office(
  target_office_id uuid,
  permission_code text
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select private.is_super_admin()
    or (
      private.is_office_member(target_office_id)
      and private.has_permission(permission_code)
    );
$$;

revoke all on schema private from public;
grant usage on schema private to authenticated;

revoke all on function private.is_super_admin() from public, anon, authenticated;
revoke all on function private.has_permission(text) from public, anon, authenticated;
revoke all on function private.is_office_member(uuid) from public, anon, authenticated;
revoke all on function private.can_access_office(uuid, text) from public, anon, authenticated;
grant execute on function private.is_super_admin() to authenticated;
grant execute on function private.has_permission(text) to authenticated;
grant execute on function private.is_office_member(uuid) to authenticated;
grant execute on function private.can_access_office(uuid, text) to authenticated;

-- Service types are non-sensitive reference data: keep public read access explicit under RLS.
alter table public.service_types enable row level security;
revoke all privileges on table public.service_types from anon, authenticated;
grant select on table public.service_types to anon, authenticated;
create policy service_types_public_read
on public.service_types
for select
to anon, authenticated
using (true);

revoke all privileges on table
  public.profiles,
  public.offices,
  public.office_members,
  public.drivers,
  public.motorcycles,
  public.driver_documents,
  public.roles,
  public.permissions,
  public.role_permissions,
  public.user_roles
from anon, authenticated;

grant select on table
  public.profiles,
  public.offices,
  public.office_members,
  public.drivers,
  public.motorcycles,
  public.driver_documents,
  public.roles,
  public.permissions,
  public.role_permissions,
  public.user_roles
to authenticated;

create policy profiles_select_permitted
on public.profiles
for select
to authenticated
using (
  id = (select auth.uid())
  or private.is_super_admin()
  or exists (
    select 1
    from public.office_members om
    where om.user_id = profiles.id
      and private.can_access_office(om.office_id, 'dashboard.view')
  )
  or exists (
    select 1
    from public.drivers d
    where d.user_id = profiles.id
      and d.office_id is not null
      and private.can_access_office(d.office_id, 'drivers.view')
  )
);

create policy offices_select_permitted
on public.offices
for select
to authenticated
using (private.can_access_office(id, 'dashboard.view'));

create policy office_members_select_permitted
on public.office_members
for select
to authenticated
using (
  user_id = (select auth.uid())
  or private.can_access_office(office_id, 'dashboard.view')
);

create policy drivers_select_permitted
on public.drivers
for select
to authenticated
using (
  user_id = (select auth.uid())
  or private.can_access_office(office_id, 'drivers.view')
);

create policy motorcycles_select_permitted
on public.motorcycles
for select
to authenticated
using (
  exists (
    select 1
    from public.drivers d
    where d.id = motorcycles.driver_id
      and d.user_id = (select auth.uid())
  )
  or private.can_access_office(office_id, 'motorcycles.view')
  or private.is_super_admin()
);

create policy driver_documents_select_permitted
on public.driver_documents
for select
to authenticated
using (
  exists (
    select 1
    from public.drivers d
    where d.id = driver_documents.driver_id
      and d.user_id = (select auth.uid())
  )
  or exists (
    select 1
    from public.drivers d
    where d.id = driver_documents.driver_id
      and private.can_access_office(d.office_id, 'drivers.view')
  )
  or private.is_super_admin()
);

create policy roles_select_authorized
on public.roles
for select
to authenticated
using (private.is_super_admin() or private.has_permission('roles.view'));

create policy permissions_select_authorized
on public.permissions
for select
to authenticated
using (private.is_super_admin() or private.has_permission('roles.view'));

create policy role_permissions_select_authorized
on public.role_permissions
for select
to authenticated
using (private.is_super_admin() or private.has_permission('roles.view'));

create policy user_roles_select_permitted
on public.user_roles
for select
to authenticated
using (
  user_id = (select auth.uid())
  or private.is_super_admin()
  or private.has_permission('roles.view')
);

-- The profile trigger is invoked by auth.users only; it is not an RPC surface.
revoke all on function public.handle_new_auth_user() from public, anon, authenticated;
