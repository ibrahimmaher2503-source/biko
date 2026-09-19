-- Milestone 8 targeted hosted verification. Every fixture and config edit rolls back.
begin;
set local statement_timeout = '45s';

do $test$
declare
  customer_a uuid := '88000000-0000-0000-0000-000000000001';
  customer_b uuid := '88000000-0000-0000-0000-000000000002';
  driver_user_1 uuid := '88000000-0000-0000-0000-000000000011';
  driver_user_2 uuid := '88000000-0000-0000-0000-000000000012';
  driver_user_3 uuid := '88000000-0000-0000-0000-000000000013';
  driver_user_4 uuid := '88000000-0000-0000-0000-000000000014';
  driver_user_5 uuid := '88000000-0000-0000-0000-000000000015';
  driver_1 uuid := '88000000-0000-0000-0000-000000000021';
  driver_2 uuid := '88000000-0000-0000-0000-000000000022';
  driver_3 uuid := '88000000-0000-0000-0000-000000000023';
  driver_4 uuid := '88000000-0000-0000-0000-000000000024';
  driver_5 uuid := '88000000-0000-0000-0000-000000000025';
  ride uuid;
  delivery uuid;
  q_ride public.route_quotes;
  q_delivery public.route_quotes;
  q_below public.route_quotes;
  q_above public.route_quotes;
  q_other public.route_quotes;
  q_changed public.route_quotes;
  q_expired public.route_quotes;
  q_active public.route_quotes;
  created public.orders;
  recovered public.orders;
  dispatch_order uuid;
  active_offer uuid;
begin
  insert into auth.users (id, email, raw_user_meta_data) values
    (customer_a, 'm8-customer-a@example.invalid', '{}'),
    (customer_b, 'm8-customer-b@example.invalid', '{}'),
    (driver_user_1, 'm8-driver-1@example.invalid', '{}'),
    (driver_user_2, 'm8-driver-2@example.invalid', '{}'),
    (driver_user_3, 'm8-driver-3@example.invalid', '{}'),
    (driver_user_4, 'm8-driver-4@example.invalid', '{}'),
    (driver_user_5, 'm8-driver-5@example.invalid', '{}');
  update public.profiles set profile_type = 'DRIVER'::public.profile_type
  where id in (driver_user_1, driver_user_2, driver_user_3, driver_user_4, driver_user_5);
  insert into public.drivers (id, user_id, driver_type, status, is_online) values
    (driver_1, driver_user_1, 'INDEPENDENT', 'ACTIVE', false),
    (driver_2, driver_user_2, 'INDEPENDENT', 'ACTIVE', false),
    (driver_3, driver_user_3, 'INDEPENDENT', 'ACTIVE', false),
    (driver_4, driver_user_4, 'INDEPENDENT', 'ACTIVE', false),
    (driver_5, driver_user_5, 'INDEPENDENT', 'ACTIVE', false);

  select id into ride from public.service_types where code = 'RIDE';
  select id into delivery from public.service_types where code = 'DELIVERY';
  update public.service_types set config = jsonb_build_object(
    'suggested_price_enabled', true,
    'suggested_price_base', case when code = 'RIDE' then 50 else 30 end,
    'suggested_price_distance_component', case when code = 'RIDE' then 10 else 20 end,
    'minimum_proposal_percent', 70
  ) where id in (ride, delivery);

  q_ride := public.create_trusted_route_quote(
    customer_a, ride, 30.044400, 31.235700, 30.134400, 31.235700,
    10000, 1200, 'ride-polyline'
  );
  q_delivery := public.create_trusted_route_quote(
    customer_a, delivery, 30.044400, 31.235700, 30.134400, 31.235700,
    10000, 1200, 'delivery-polyline'
  );
  assert q_ride.suggested_price = 150 and q_ride.minimum_customer_price = 105,
    'RIDE pricing must use its own Base plus distance configuration';
  assert q_delivery.suggested_price = 230 and q_delivery.minimum_customer_price = 161,
    'DELIVERY pricing must remain isolated from RIDE';

  perform set_config('request.jwt.claim.sub', customer_a::text, true);
  set local role authenticated;
  select * into created from public.create_order(
    ride, q_ride.pickup_lat, q_ride.pickup_lng, 'M8 Pickup',
    q_ride.destination_lat, q_ride.destination_lng, 'M8 Destination', 105,
    p_creation_intent_id => '88000000-0000-4000-8000-000000000101',
    p_route_quote_id => q_ride.id
  );
  assert created.route_quote_id = q_ride.id and created.route_distance_meters = 10000
    and created.route_duration_seconds = 1200 and created.route_polyline = 'ride-polyline',
    'Order must snapshot the trusted route quote';
  assert created.proposed_price = 105 and created.suggested_price = 150
    and created.minimum_customer_price = 105,
    'Exact 70 percent proposal must be accepted';
  reset role;

  update public.route_quotes set expires_at = clock_timestamp() - interval '1 second'
  where id = q_ride.id;
  perform set_config('request.jwt.claim.sub', customer_a::text, true);
  set local role authenticated;
  select * into recovered from public.create_order(
    ride, q_ride.pickup_lat, q_ride.pickup_lng, 'M8 Pickup',
    q_ride.destination_lat, q_ride.destination_lng, 'M8 Destination', 105,
    p_creation_intent_id => '88000000-0000-4000-8000-000000000101',
    p_route_quote_id => q_ride.id
  );
  assert recovered.id = created.id, 'Stable intent recovery must precede quote expiry checks';
  reset role;

  q_below := public.create_trusted_route_quote(customer_a, ride, 30, 31, 30.02, 31, 1000, 300, 'below');
  perform set_config('request.jwt.claim.sub', customer_a::text, true);
  set local role authenticated;
  begin
    perform public.create_order(
      ride, q_below.pickup_lat, q_below.pickup_lng, 'Below',
      q_below.destination_lat, q_below.destination_lng, 'Destination',
      q_below.minimum_customer_price - 0.01,
      p_creation_intent_id => gen_random_uuid(), p_route_quote_id => q_below.id
    );
    raise exception 'Proposal below 70 percent was accepted';
  exception when sqlstate '22023' then
    assert sqlerrm = 'Customer proposed price is below the trusted minimum';
  end;
  reset role;

  q_above := public.create_trusted_route_quote(customer_a, ride, 30, 31, 30.02, 31, 1000, 300, 'above');
  perform set_config('request.jwt.claim.sub', customer_a::text, true);
  set local role authenticated;
  perform public.create_order(
    ride, q_above.pickup_lat, q_above.pickup_lng, 'Above',
    q_above.destination_lat, q_above.destination_lng, 'Destination',
    q_above.suggested_price + 100,
    p_creation_intent_id => gen_random_uuid(), p_route_quote_id => q_above.id
  );
  reset role;

  q_other := public.create_trusted_route_quote(customer_b, ride, 30, 31, 30.02, 31, 1000, 300, 'other');
  perform set_config('request.jwt.claim.sub', customer_a::text, true);
  set local role authenticated;
  begin
    perform public.create_order(
      ride, q_other.pickup_lat, q_other.pickup_lng, 'Other',
      q_other.destination_lat, q_other.destination_lng, 'Destination', q_other.minimum_customer_price,
      p_creation_intent_id => gen_random_uuid(), p_route_quote_id => q_other.id
    );
    raise exception 'Another Customer quote was accepted';
  exception when insufficient_privilege then null;
  end;
  reset role;

  q_changed := public.create_trusted_route_quote(customer_a, ride, 30, 31, 30.02, 31, 1000, 300, 'changed');
  perform set_config('request.jwt.claim.sub', customer_a::text, true);
  set local role authenticated;
  begin
    perform public.create_order(
      ride, q_changed.pickup_lat + 0.001, q_changed.pickup_lng, 'Changed',
      q_changed.destination_lat, q_changed.destination_lng, 'Destination', q_changed.minimum_customer_price,
      p_creation_intent_id => gen_random_uuid(), p_route_quote_id => q_changed.id
    );
    raise exception 'Changed coordinates were accepted with a stale quote';
  exception when sqlstate '22023' then
    assert sqlerrm = 'Order coordinates do not match route quote';
  end;
  reset role;

  q_expired := public.create_trusted_route_quote(customer_a, ride, 30, 31, 30.02, 31, 1000, 300, 'expired');
  update public.route_quotes set expires_at = clock_timestamp() - interval '1 second' where id = q_expired.id;
  perform set_config('request.jwt.claim.sub', customer_a::text, true);
  set local role authenticated;
  begin
    perform public.create_order(
      ride, q_expired.pickup_lat, q_expired.pickup_lng, 'Expired',
      q_expired.destination_lat, q_expired.destination_lng, 'Destination', q_expired.minimum_customer_price,
      p_creation_intent_id => gen_random_uuid(), p_route_quote_id => q_expired.id
    );
    raise exception 'Expired quote authorized a new order';
  exception when sqlstate 'P0001' then
    assert sqlerrm = 'Route quote has expired';
  end;
  reset role;

  -- Five foreground uploads prove one-row UPSERT and staged discovery distances.
  perform set_config('request.jwt.claim.sub', driver_user_1::text, true);
  set local role authenticated;
  perform public.update_driver_location(30.053400, 31.235700, 8);
  perform public.update_driver_location(30.053410, 31.235700, 7);
  perform public.set_driver_online(true);
  perform set_config('request.jwt.claim.sub', driver_user_2::text, true);
  perform public.update_driver_location(30.071400, 31.235700, 8);
  perform public.set_driver_online(true);
  perform set_config('request.jwt.claim.sub', driver_user_3::text, true);
  perform public.update_driver_location(30.089400, 31.235700, 8);
  perform public.set_driver_online(true);
  perform set_config('request.jwt.claim.sub', driver_user_4::text, true);
  perform public.update_driver_location(30.107400, 31.235700, 8);
  perform public.set_driver_online(true);
  perform set_config('request.jwt.claim.sub', driver_user_5::text, true);
  perform public.update_driver_location(30.125400, 31.235700, 8);
  perform public.set_driver_online(true);
  reset role;
  assert (select count(*) = 5 from public.driver_latest_locations),
    'Latest location storage must keep one UPSERT row per Driver';
  assert (select accuracy_meters = 7 from public.driver_latest_locations where driver_id = driver_1),
    'Second Driver upload must replace the same row';

  q_active := public.create_trusted_route_quote(customer_a, ride, 30.0444, 31.2357, 30.06, 31.2357, 1800, 360, 'dispatch');
  perform set_config('request.jwt.claim.sub', customer_a::text, true);
  set local role authenticated;
  select id into dispatch_order from public.create_order(
    ride, q_active.pickup_lat, q_active.pickup_lng, 'Dispatch Pickup',
    q_active.destination_lat, q_active.destination_lng, 'Dispatch Destination', q_active.minimum_customer_price,
    p_creation_intent_id => gen_random_uuid(), p_route_quote_id => q_active.id
  );
  reset role;

  perform set_config('request.jwt.claim.sub', driver_user_1::text, true);
  set local role authenticated;
  assert (select count(*) = 1 from public.get_driver_requests() where id = dispatch_order and dispatch_radius_meters = 2000),
    'Fresh Driver within 2 km must be initially eligible';
  perform set_config('request.jwt.claim.sub', driver_user_2::text, true);
  assert (select count(*) = 0 from public.get_driver_requests() where id = dispatch_order),
    'Driver at 3 km must be excluded initially';
  reset role;

  update public.orders set created_at = clock_timestamp() - interval '21 seconds' where id = dispatch_order;
  perform set_config('request.jwt.claim.sub', driver_user_2::text, true);
  set local role authenticated;
  assert (select count(*) = 1 from public.get_driver_requests() where id = dispatch_order and dispatch_radius_meters = 4000),
    'Same 3 km Driver must become eligible at the 4 km stage';
  reset role;
  update public.orders set created_at = clock_timestamp() - interval '41 seconds' where id = dispatch_order;
  perform set_config('request.jwt.claim.sub', driver_user_3::text, true);
  set local role authenticated;
  assert (select count(*) = 1 from public.get_driver_requests() where id = dispatch_order and dispatch_radius_meters = 6000),
    '5 km Driver must become eligible at the 6 km stage';
  reset role;
  update public.orders set created_at = clock_timestamp() - interval '61 seconds' where id = dispatch_order;
  perform set_config('request.jwt.claim.sub', driver_user_4::text, true);
  set local role authenticated;
  assert (select count(*) = 1 from public.get_driver_requests() where id = dispatch_order and dispatch_radius_meters = 8000),
    '7 km Driver must become eligible at the 8 km stage';
  perform set_config('request.jwt.claim.sub', driver_user_5::text, true);
  assert (select count(*) = 0 from public.get_driver_requests() where id = dispatch_order),
    'Driver outside 8 km must remain excluded';
  reset role;

  update public.driver_latest_locations set updated_at = clock_timestamp() - interval '121 seconds'
  where driver_id = driver_2;
  assert not private.driver_is_geographically_eligible(driver_2, dispatch_order),
    'Stale Driver location must be excluded centrally';
  perform set_config('request.jwt.claim.sub', driver_user_2::text, true);
  set local role authenticated;
  begin
    perform public.get_driver_requests();
    raise exception 'Stale Driver discovery did not return a useful denial';
  exception when sqlstate 'P0001' then
    assert sqlerrm = 'Driver location is stale';
  end;
  reset role;

  update public.drivers set is_online = false where id = driver_3;
  assert not private.driver_is_geographically_eligible(driver_3, dispatch_order), 'Offline Driver must be excluded';
  update public.drivers set is_online = true where id = driver_3;
  update public.profiles set status = 'SUSPENDED'::public.account_status where id = driver_user_3;
  assert not private.driver_is_geographically_eligible(driver_3, dispatch_order), 'Suspended profile must be excluded';
  update public.profiles set status = 'ACTIVE'::public.account_status where id = driver_user_3;

  perform set_config('request.jwt.claim.sub', driver_user_1::text, true);
  set local role authenticated;
  select id into active_offer from public.submit_offer(dispatch_order, 200);
  perform set_config('request.jwt.claim.sub', customer_a::text, true);
  perform public.accept_offer(dispatch_order, active_offer);
  perform set_config('request.jwt.claim.sub', driver_user_1::text, true);
  assert (select count(*) = 0 from public.get_driver_requests()),
    'Assigned Driver must receive no new geographic work';
  reset role;

  perform set_config('request.jwt.claim.sub', customer_a::text, true);
  set local role authenticated;
  begin
    perform public.update_driver_location(30, 31, 5);
    raise exception 'Customer updated a Driver location';
  exception when insufficient_privilege then null;
  end;
  assert (select count(*) = 0 from public.order_driver_candidates),
    'Customer cannot read candidate membership';
  reset role;

  assert not has_function_privilege('anon', 'public.update_driver_location(numeric,numeric,numeric,numeric,numeric)', 'EXECUTE'),
    'anon must not execute Driver location updates';
  assert not has_function_privilege('authenticated', 'public.create_trusted_route_quote(uuid,uuid,numeric,numeric,numeric,numeric,integer,integer,text)', 'EXECUTE'),
    'authenticated clients must not mint trusted quotes';
  assert not has_table_privilege('authenticated', 'public.driver_latest_locations', 'INSERT,UPDATE,DELETE'),
    'Clients must not directly write Driver locations';
  assert not has_table_privilege('authenticated', 'public.route_quotes', 'INSERT,UPDATE,DELETE'),
    'Clients must not directly write trusted route quotes';
end;
$test$;

rollback;
