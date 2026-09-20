-- ADM-09 focused rollback proof. Run after the ADM-04/05/08 migrations and
-- admin_dashboard_offices migration. No hosted state is changed.
begin;
set local statement_timeout = '60s';

do $test$
declare
  admin_user uuid := 'a0900000-0000-4000-8000-000000000001';
  office_admin uuid := 'a0900000-0000-4000-8000-000000000002';
  driver_user uuid := 'a0900000-0000-4000-8000-000000000003';
  test_office_id uuid := 'a0900000-0000-4000-8000-000000000010';
  active_order_id uuid := 'a0900000-0000-4000-8000-000000000011';
  bidding_order_id uuid := 'a0900000-0000-4000-8000-000000000012';
  v_driver_id uuid := 'a0900000-0000-4000-8000-000000000013';
  v_selected_offer_id uuid := 'a0900000-0000-4000-8000-000000000014';
  v_motorcycle_id uuid := 'a0900000-0000-4000-8000-000000000015';
  ride_service uuid;
  office_row record;
  office_count integer;
begin
  assert to_regprocedure(
    'public.admin_list_offices(text,public.account_status,uuid,integer,integer)'
  ) is not null, 'ADM-09 list RPC must exist';
  assert to_regprocedure('public.admin_get_office(uuid)') is not null,
    'ADM-09 detail RPC must exist';
  assert to_regprocedure('public.admin_create_office(text,text,text,text,text,text)') is not null,
    'ADM-09 create RPC must exist';
  assert to_regprocedure('public.admin_update_office(uuid,text,text,text,text,text,text)') is not null,
    'ADM-09 update RPC must exist';
  assert to_regprocedure('public.admin_suspend_office(uuid,text)') is not null,
    'ADM-09 suspend RPC must exist';
  assert to_regprocedure('public.admin_restore_office(uuid,text)') is not null,
    'ADM-09 restore RPC must exist';

  insert into auth.users (id, email, raw_user_meta_data) values
    (admin_user, 'adm09-admin@example.invalid', '{}'),
    (office_admin, 'adm09-office@example.invalid', '{}'),
    (driver_user, 'adm09-driver@example.invalid', '{}');
  update public.profiles
  set profile_type = case when id = driver_user then 'DRIVER'::public.profile_type
                          else 'STAFF'::public.profile_type end,
      status = 'ACTIVE'::public.account_status
  where id in (admin_user, office_admin, driver_user);
  insert into public.offices (id, name, area)
  values (test_office_id, 'ADM-09 Office', 'Cairo');
  insert into public.user_roles (user_id, role_id)
  select admin_user, id from public.roles where code = 'SUPER_ADMIN';
  insert into public.office_members (office_id, user_id, role_id)
  select test_office_id, office_admin, id from public.roles where code = 'OFFICE_ADMIN';
  insert into public.drivers (id, user_id, driver_type, office_id, status, is_online)
  values (v_driver_id, driver_user, 'OFFICE_DRIVER', test_office_id, 'ACTIVE', true);
  insert into public.motorcycles (
    id, driver_id, office_id, plate_number, brand, model, color,
    status, verification_status,
    verified_by, verified_at
  ) values (
    v_motorcycle_id, v_driver_id, test_office_id, 'ADM09', 'Biko',
    'Fixture', 'Black', 'ACTIVE',
    'APPROVED', admin_user, clock_timestamp()
  );
  select id into ride_service from public.service_types where code = 'RIDE';

  perform set_config('request.jwt.claim.sub', admin_user::text, true);
  set local role authenticated;
  select * into office_row
  from public.admin_create_office(
    'ADM-09 Created', 'Responsible', '0100', 'Address', 'Giza', 'create office'
  );
  assert office_row.status = 'ACTIVE'::public.account_status,
    'Created office must start active';
  select count(*) into office_count
  from public.admin_list_offices(null, null, null, 100, 0);
  assert office_count >= 2, 'Platform list must include created offices';
  select * into office_row
  from public.admin_update_office(
    test_office_id, 'ADM-09 Renamed', 'Owner', '0111', 'New address', 'Giza',
    'update office'
  );
  assert office_row.name = 'ADM-09 Renamed' and office_row.area = 'Giza',
    'Update must persist office fields';
  perform public.admin_suspend_office(test_office_id, 'Pause operations');
  reset role;
  assert (select status = 'SUSPENDED'::public.account_status
    from public.offices where id = test_office_id),
    'Suspend must change only office status';
  assert (select count(*) = 1 from public.audit_logs
    where entity_id = test_office_id and action = 'OFFICE_SUSPENDED'
      and reason = 'Pause operations'),
    'Suspend must write one reasoned audit row';

  -- Office membership alone must not call the platform-only ADM-09 surface.
  perform set_config('request.jwt.claim.sub', office_admin::text, true);
  set local role authenticated;
  begin
    perform id from public.admin_list_offices(null, null, null, 50, 0);
    raise exception 'Office member accessed platform office list';
  exception when insufficient_privilege then null;
  end;
  reset role;

  -- Suspension blocks new offers, but does not rewrite or stop an assigned trip.
  insert into public.orders (
    id, customer_id, service_type_id, pickup_lat, pickup_lng,
    destination_lat, destination_lng, pickup_address, destination_address,
    proposed_price, status
  ) values
    (bidding_order_id, admin_user, ride_service, 30, 31, 30.1, 31.1,
      'ADM09 bidding pickup', 'ADM09 bidding destination', 80,
      'BIDDING'),
    (active_order_id, admin_user, ride_service, 30, 31, 30.1, 31.1,
      'ADM09 active pickup', 'ADM09 active destination', 80,
      'BIDDING');
  insert into public.order_driver_candidates (order_id, driver_id)
  values (bidding_order_id, v_driver_id);

  perform set_config('request.jwt.claim.sub', driver_user::text, true);
  set local role authenticated;
  begin
    perform public.submit_offer(bidding_order_id, 80);
    raise exception 'Suspended office accepted new offer';
  exception when insufficient_privilege then null;
  end;
  reset role;
  assert not exists (
    select 1 from public.offers where order_id = bidding_order_id
  ), 'Suspended office must block new offer writes';

  -- Fixture-only bypass: production assignment still goes through accept_offer().
  set local session_replication_role = replica;
  insert into public.offers (
    id, order_id, driver_id, office_id, offered_price, status
  ) values (
    v_selected_offer_id, active_order_id, v_driver_id, test_office_id, 80, 'SELECTED'
  );
  update public.orders o
  set status = 'DRIVER_ASSIGNED', driver_id = v_driver_id,
      selected_offer_id = v_selected_offer_id, agreed_price = 80,
      office_id = test_office_id, motorcycle_id = v_motorcycle_id,
      assigned_at = clock_timestamp()
  where id = active_order_id;
  set local session_replication_role = origin;

  perform set_config('request.jwt.claim.sub', driver_user::text, true);
  set local role authenticated;
  select * into office_row
  from public.driver_on_way(active_order_id);
  reset role;
  assert office_row.status = 'DRIVER_ON_WAY'::public.order_status,
    'Assigned trip must continue after office suspension';
  assert (select status = 'DRIVER_ON_WAY'::public.order_status
    from public.orders where id = active_order_id),
    'Suspension must not rewrite the active order';

  perform set_config('request.jwt.claim.sub', admin_user::text, true);
  set local role authenticated;
  perform public.admin_restore_office(test_office_id, 'Resume operations');
  reset role;
  assert (select status = 'ACTIVE'::public.account_status
    from public.offices where id = test_office_id),
    'Restore must reactivate the office';
  assert (select count(*) = 1 from public.audit_logs
    where entity_id = test_office_id and action = 'OFFICE_RESTORED'
      and reason = 'Resume operations'),
    'Restore must write one reasoned audit row';
end;
$test$;

rollback;
