-- Run after all migrations. Fixtures roll back, including auth users.
begin;

do $test$
<<tracking_test>>
declare
  customer_a uuid := '99000000-0000-0000-0000-000000000001';
  customer_b uuid := '99000000-0000-0000-0000-000000000002';
  driver_user uuid := '99000000-0000-0000-0000-000000000011';
  driver_id uuid := '99000000-0000-0000-0000-000000000021';
  order_id uuid := '99000000-0000-4000-8000-000000000001';
  offer_id uuid := '99000000-0000-4000-8000-000000000002';
  ride_id uuid;
begin
  insert into auth.users(id, email, raw_user_meta_data) values
    (customer_a, 'tracking-customer-a@example.invalid', '{}'),
    (customer_b, 'tracking-customer-b@example.invalid', '{}'),
    (driver_user, 'tracking-driver@example.invalid', '{}');
  update public.profiles set profile_type = 'DRIVER'::public.profile_type where id = driver_user;
  insert into public.drivers(id, user_id, driver_type, status, is_online)
  values (driver_id, driver_user, 'INDEPENDENT', 'ACTIVE', true);
  select id into ride_id from public.service_types where code = 'RIDE';
  insert into public.orders(
    id, customer_id, service_type_id, pickup_lat, pickup_lng, pickup_address,
    destination_lat, destination_lng, destination_address, proposed_price, status
  ) values (
    order_id, customer_a, ride_id, 30.050000, 31.240000, 'Pickup',
    30.060000, 31.250000, 'Destination', 100, 'BIDDING'
  );
  insert into public.offers(id, order_id, driver_id, offered_price, status)
  values (offer_id, order_id, driver_id, 100, 'SELECTED');
  insert into public.driver_latest_locations(driver_id, latitude, longitude, accuracy_meters)
  values (driver_id, 30.051000, 31.241000, 8);
  update public.orders set driver_id = tracking_test.driver_id, selected_offer_id = tracking_test.offer_id,
    agreed_price = 100, assigned_at = clock_timestamp(), status = 'DRIVER_ASSIGNED'
  where id = order_id;
  assert (select count(*) = 1 from public.order_driver_tracking where order_id = tracking_test.order_id),
    'Assignment must seed the projection from the latest Driver row immediately';

  perform set_config('request.jwt.claim.sub', customer_a::text, true);
  set local role authenticated;
  assert (select count(*) = 1 from public.get_customer_order_tracking(order_id)),
    'Owner must receive only their active assigned Driver snapshot';
  assert (select refresh_required from public.reserve_customer_order_eta(order_id)),
    'First owner ETA request must receive the shared reservation';
  assert not (select refresh_required from public.reserve_customer_order_eta(order_id)),
    'Concurrent owner ETA request must reuse the 60-second lease';
  reset role;

  update public.driver_latest_locations set latitude = 30.052000, updated_at = clock_timestamp()
  where driver_id = tracking_test.driver_id;
  assert (select eta_refresh_started_at is not null from public.order_driver_tracking where order_id = tracking_test.order_id),
    'A GPS update must preserve the shared ETA lease rather than reset the paid-call cadence';
  update public.orders set status = 'IN_PROGRESS' where id = tracking_test.order_id;
  assert (select eta_seconds is null and eta_refresh_started_at is null from public.order_driver_tracking where order_id = tracking_test.order_id),
    'Changing from pickup to destination must invalidate the cached ETA';
  update public.orders set status = 'DRIVER_ARRIVED' where id = tracking_test.order_id;
  perform set_config('request.jwt.claim.sub', customer_a::text, true);
  set local role authenticated;
  assert (select count(*) = 1 from public.reserve_customer_order_eta(order_id)),
    'Arrived ETA must return exactly one cache response';
  assert not (select refresh_required from public.reserve_customer_order_eta(order_id))
    and (select eta_seconds = 0 from public.reserve_customer_order_eta(order_id)),
    'Arrived ETA must be zero without opening a paid-route lease';
  reset role;

  perform set_config('request.jwt.claim.sub', customer_b::text, true);
  set local role authenticated;
  assert (select count(*) = 0 from public.get_customer_order_tracking(order_id)),
    'Another Customer must not read the Driver location or ETA reservation';
  assert (select count(*) = 0 from public.reserve_customer_order_eta(order_id)),
    'Spoofed order ID must not reserve a paid route request';
  reset role;

  update public.orders set status = 'COMPLETED' where id = order_id;
  assert (select count(*) = 0 from public.order_driver_tracking where order_id = tracking_test.order_id),
    'Terminal transition must delete the realtime tracking projection';
  assert not has_table_privilege('authenticated', 'public.driver_latest_locations', 'SELECT'),
    'Customer tracking must not grant reads on the private location source';
  assert not has_table_privilege('authenticated', 'public.order_driver_tracking', 'INSERT,UPDATE,DELETE'),
    'Customer tracking projection is server-written only';
  assert not has_function_privilege('authenticated', 'private.project_driver_location_to_active_order()', 'EXECUTE'),
    'Private tracking triggers must not expose SECURITY DEFINER execution';
end;
$test$;

rollback;
