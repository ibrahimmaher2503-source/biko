-- ADM-10 focused rollback proof. Run after ADM-08/09 migrations.
begin;
set local statement_timeout = '60s';

do $test$
declare
  office_admin uuid := 'a1000000-0000-4000-8000-000000000001';
  office_staff uuid := 'a1000000-0000-4000-8000-000000000002';
  office_b_staff uuid := 'a1000000-0000-4000-8000-000000000003';
  platform_staff uuid := 'a1000000-0000-4000-8000-000000000004';
  office_a uuid := 'a1000000-0000-4000-8000-000000000010';
  office_b uuid := 'a1000000-0000-4000-8000-000000000011';
  admin_role uuid;
  custom_role uuid;
  dispatcher_role uuid;
  accountant_role uuid;
  platform_role uuid;
  listed_count integer;
  listed_users uuid[];
  detail_user uuid;
  audit_before integer;
begin
  insert into auth.users (id, email, raw_user_meta_data) values
    (office_admin, 'adm10-office-admin@example.invalid', '{}'),
    (office_staff, 'adm10-office-staff@example.invalid', '{}'),
    (office_b_staff, 'adm10-office-b@example.invalid', '{}'),
    (platform_staff, 'adm10-platform@example.invalid', '{}');
  update public.profiles
  set profile_type = 'STAFF'::public.profile_type,
      status = 'ACTIVE'::public.account_status
  where id in (office_admin, office_staff, office_b_staff, platform_staff);
  insert into public.offices (id, name) values
    (office_a, 'ADM-10 Office A'), (office_b, 'ADM-10 Office B');
  select id into admin_role from public.roles where code = 'OFFICE_ADMIN';
  select id into dispatcher_role from public.roles where code = 'OFFICE_DISPATCHER';
  select id into accountant_role from public.roles where code = 'OFFICE_ACCOUNTANT';
  select id into platform_role from public.roles where code = 'SUPER_ADMIN';
  insert into public.roles (code, name, scope_type)
  values ('ADM10_OFFICE_CUSTOM', 'ADM-10 Office Custom', 'CUSTOM')
  returning id into custom_role;
  insert into public.role_permissions (role_id, permission_id)
  select custom_role, id
  from public.permissions
  where code in ('office_members.manage', 'roles.view');
  insert into public.office_members (office_id, user_id, role_id)
  values
    (office_a, office_admin, custom_role),
    (office_a, office_staff, dispatcher_role),
    (office_b, office_b_staff, dispatcher_role);
  insert into public.user_roles (user_id, role_id)
  values (platform_staff, platform_role), (office_admin, custom_role);

  -- Exact-office list returns A only, with no B/platform rows.
  perform set_config('request.jwt.claim.sub', office_admin::text, true);
  set local role authenticated;
  select count(*), array_agg(user_id order by user_id)
    into listed_count, listed_users
  from public.admin_list_office_staff(office_a, null, null, 50, 0);
  assert listed_count = 2, 'Office A list must contain only its two memberships';
  assert office_b_staff <> all(listed_users), 'Office B staff must not leak';
  assert platform_staff <> all(listed_users), 'Platform staff must not leak';
  select user_id into detail_user
  from public.admin_get_office_staff(office_a, office_staff);
  assert detail_user = office_staff, 'Exact-office detail must return the selected member';
  perform 1 from public.admin_list_assignable_office_roles(office_a)
    where code = 'OFFICE_ACCOUNTANT';
  assert found, 'Office roles must be available for role assignment';
  assert not exists (
    select 1 from public.admin_list_assignable_office_roles(office_a)
    where scope_type = 'PLATFORM'
  ), 'Platform roles must never be assignable from the office surface';

  -- Office-scoped roles may carry a same-office roles.view key without
  -- exposing the global role catalog or another user's platform assignment.
  assert (select count(*) = 0 from public.roles),
    'Office roles.view must not expose the global role catalog';
  assert (select count(*) = 0 from public.permissions),
    'Office roles.view must not expose the global permission catalog';
  assert (select count(*) = 0 from public.role_permissions),
    'Office roles.view must not expose global role permissions';
  assert (select count(*) = 0 from public.user_roles where user_id = platform_staff),
    'Office roles.view must not expose platform user assignments';
  assert (select count(*) = 1 from public.user_roles where user_id = office_admin),
    'Self user_roles visibility must remain available';

  -- Cross-office read and write are denied by the exact membership boundary.
  begin
    perform 1 from public.admin_list_office_staff(office_b, null, null, 50, 0);
    raise exception 'Cross-office list was accepted';
  exception when insufficient_privilege then null;
  end;
  begin
    perform public.admin_update_office_member_status(
      office_b, office_b_staff, 'SUSPENDED', 'cross-office status attempt'
    );
    raise exception 'Cross-office status change was accepted';
  exception when insufficient_privilege then null;
  end;

  reset role;
  select count(*) into audit_before
  from public.audit_logs
  where entity_type = 'OFFICE_MEMBER'
    and entity_id = (
      select id from public.office_members
      where office_id = office_a and user_id = office_staff
    );
  set local role authenticated;
  perform public.admin_update_office_member_role(
    office_a, office_staff, accountant_role, 'ADM-10 role acceptance'
  );
  assert (select role_id = accountant_role from public.office_members
    where office_id = office_a and user_id = office_staff),
    'Role change must stay on the exact office membership';
  perform public.admin_update_office_member_status(
    office_a, office_staff, 'SUSPENDED', 'ADM-10 suspend acceptance'
  );
  assert (select status = 'SUSPENDED'::public.account_status from public.office_members
    where office_id = office_a and user_id = office_staff),
    'Membership suspension must not change profile status';
  perform public.admin_update_office_member_status(
    office_a, office_staff, 'ACTIVE', 'ADM-10 restore acceptance'
  );
  assert (select status = 'ACTIVE'::public.account_status from public.office_members
    where office_id = office_a and user_id = office_staff),
    'Membership restoration must reactivate the membership';
  reset role;
  assert (select count(*) > audit_before from public.audit_logs
    where entity_type = 'OFFICE_MEMBER' and entity_id = (
      select id from public.office_members
      where office_id = office_a and user_id = office_staff
    )), 'Role and status changes must be audited';

  set local role authenticated;
  perform public.admin_update_office_member_role(
    office_a, office_staff, custom_role, 'ADM-10 custom office role acceptance'
  );
  assert (select role_id = custom_role from public.office_members
    where office_id = office_a and user_id = office_staff),
    'CUSTOM role assignment must remain available for same-office roles';

  begin
    perform public.admin_update_office_member_role(
      office_a, office_staff, platform_role, 'platform role attempt'
    );
    raise exception 'Platform role assignment was accepted';
  exception when insufficient_privilege then null;
  end;
  begin
    perform public.admin_update_office_member_role(
      office_a, office_admin, dispatcher_role, 'self role attempt'
    );
    raise exception 'Self role change was accepted';
  exception when insufficient_privilege then null;
  end;
  reset role;
end;
$test$;

rollback;
