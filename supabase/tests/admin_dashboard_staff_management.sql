-- ADM-08 focused rollback proof. Run after ADM-04/05 and this migration.
begin;
set local statement_timeout = '60s';

do $test$
declare
  admin_user uuid := 'a0800000-0000-4000-8000-000000000001';
  office_admin uuid := 'a0800000-0000-4000-8000-000000000002';
  staff_user uuid := 'a0800000-0000-4000-8000-000000000003';
  invited_user uuid := 'a0800000-0000-4000-8000-000000000004';
  test_office_id uuid := 'a0800000-0000-4000-8000-000000000010';
  custom_role uuid;
  platform_role uuid;
  office_role uuid;
  result jsonb;
  audit_before integer;
begin
  insert into auth.users (id, email, raw_user_meta_data) values
    (admin_user, 'adm08-admin@example.invalid', '{}'),
    (office_admin, 'adm08-office@example.invalid', '{}'),
    (staff_user, 'adm08-staff@example.invalid', '{}'),
    (invited_user, 'adm08-invited@example.invalid', '{}');
  update public.profiles set profile_type = 'STAFF'::public.profile_type,
    status = 'ACTIVE'::public.account_status
  where id in (admin_user, office_admin, staff_user);
  insert into public.offices (id, name) values (test_office_id, 'ADM-08 Office');
  insert into public.user_roles (user_id, role_id)
  select admin_user, id from public.roles where code = 'SUPER_ADMIN';
  insert into public.office_members (office_id, user_id, role_id)
  select test_office_id, office_admin, id from public.roles where code = 'OFFICE_ADMIN';

  perform set_config('request.jwt.claim.sub', admin_user::text, true);
  set local role authenticated;
  select id into platform_role from public.roles where code = 'PLATFORM_OPERATIONS';
  select id into office_role from public.roles where code = 'OFFICE_ADMIN';
  perform public.admin_create_role(
    'ADM08_CUSTOM', 'ADM-08 Custom', 'CUSTOM', array['dashboard.view'], 'Create test role'
  );
  select id into custom_role from public.roles where code = 'ADM08_CUSTOM';
  perform public.admin_rename_role(custom_role, 'ADM-08 Renamed', 'Rename test role');
  perform public.admin_set_role_permissions(
    custom_role, array['dashboard.view', 'users.view'], 'Set test permissions'
  );
  begin
    perform public.admin_set_role_permissions(
      (select id from public.roles where code = 'SUPER_ADMIN'),
      array['dashboard.view', 'roles.manage'],
      'self role permission change'
    );
    raise exception 'Self role permission change was accepted';
  exception when insufficient_privilege then null;
  end;
  perform public.admin_create_staff(
    invited_user, 'Invited Staff', custom_role, null, 'Create test staff'
  );
  reset role;

  assert (select profile_type = 'STAFF' and status = 'ACTIVE'
    from public.profiles where id = invited_user), 'Creation must promote a new Auth profile to STAFF';
  assert (select count(*) = 1 from public.user_roles
    where user_id = invited_user and role_id = custom_role), 'Creation must assign platform custom role';

  -- A staff actor may not grant itself a role, even when it otherwise has a role.
  perform set_config('request.jwt.claim.sub', staff_user::text, true);
  set local role authenticated;
  begin
    perform public.admin_assign_staff_role(staff_user, custom_role, null, 'self elevation');
    raise exception 'Self elevation was accepted';
  exception when insufficient_privilege then null;
  end;
  reset role;

  -- Office Admin can manage its office membership, never a platform assignment.
  perform set_config('request.jwt.claim.sub', office_admin::text, true);
  set local role authenticated;
  begin
    perform public.admin_assign_staff_role(staff_user, platform_role, null, 'cross scope');
    raise exception 'Office actor assigned a platform role';
  exception when insufficient_privilege then null;
  end;
  assert not public.admin_can_create_staff(platform_role, null),
    'Office actor preflight must deny platform staff creation';
  assert not public.admin_can_create_staff(custom_role, null),
    'Office actor preflight must deny platform-like custom creation';
  begin
    perform public.admin_assign_staff_role(staff_user, custom_role, null, 'custom cross scope');
    raise exception 'Office actor assigned a platform-like custom role';
  exception when insufficient_privilege then null;
  end;
  perform public.admin_assign_staff_role(staff_user, office_role, test_office_id, 'office assignment');
  reset role;
  assert (select count(*) = 1 from public.office_members
    where user_id = staff_user and office_id = test_office_id and role_id = office_role),
    'Office assignment must be scoped to the exact office';

  -- Permission revocation is visible to the next request; no role cache is used.
  perform set_config('request.jwt.claim.sub', admin_user::text, true);
  select count(*) into audit_before from public.audit_logs;
  set local role authenticated;
  perform public.admin_revoke_staff_role(staff_user, office_role, test_office_id, 'revoke office role');
  reset role;
  perform set_config('request.jwt.claim.sub', staff_user::text, true);
  set local role authenticated;
  assert not private.can_access_office(test_office_id, 'office_members.manage'),
    'Revoked office access must fail on the next request';
  reset role;
  assert (select count(*) > audit_before from public.audit_logs), 'Staff mutation must be audited';

  -- The last active Super Admin cannot be revoked or suspended.
  perform set_config('request.jwt.claim.sub', admin_user::text, true);
  set local role authenticated;
  begin
    perform public.admin_revoke_staff_role(admin_user,
      (select id from public.roles where code = 'SUPER_ADMIN'), null, 'remove last admin');
    raise exception 'Last Super Admin role was revoked';
  exception when insufficient_privilege then null;
  end;
  begin
    perform public.admin_update_staff_status(admin_user, 'SUSPENDED', 'suspend last admin');
    raise exception 'Last Super Admin was suspended';
  exception when insufficient_privilege then null;
  end;
  reset role;
end;
$test$;

rollback;
