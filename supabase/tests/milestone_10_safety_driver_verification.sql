-- Milestone 10 targeted hosted verification. Everything rolls back.
begin;
set local statement_timeout = '60s';

do $test$
declare
  customer_a uuid := 'a1000000-0000-4000-8000-000000000001';
  customer_b uuid := 'a1000000-0000-4000-8000-000000000002';
  driver_user_a uuid := 'a1000000-0000-4000-8000-000000000011';
  driver_user_b uuid := 'a1000000-0000-4000-8000-000000000012';
  driver_user_c uuid := 'a1000000-0000-4000-8000-000000000013';
  admin_user uuid := 'a1000000-0000-4000-8000-000000000099';
  driver_a uuid := 'a1000000-0000-4000-8000-000000000021';
  driver_b uuid := 'a1000000-0000-4000-8000-000000000022';
  driver_c uuid := 'a1000000-0000-4000-8000-000000000023';
  motorcycle_a uuid := 'a1000000-0000-4000-8000-000000000031';
  motorcycle_b uuid := 'a1000000-0000-4000-8000-000000000032';
  motorcycle_c uuid := 'a1000000-0000-4000-8000-000000000033';
  ride_service uuid;
  delivery_service uuid;
  ride_order uuid := 'a1000000-0000-4000-8000-000000000101';
  delivery_order uuid := 'a1000000-0000-4000-8000-000000000102';
  delivery_order_b uuid := 'a1000000-0000-4000-8000-000000000103';
  cancelled_delivery uuid := 'a1000000-0000-4000-8000-000000000104';
  privacy_order uuid := 'a1000000-0000-4000-8000-000000000105';
  offer_id uuid;
  delivery_code text;
  delivery_code_b text;
  result record;
  new_document uuid;
begin
  insert into auth.users (id, email, raw_user_meta_data) values
    (customer_a, 'm10-customer-a@example.invalid', '{}'),
    (customer_b, 'm10-customer-b@example.invalid', '{}'),
    (driver_user_a, 'm10-driver-a@example.invalid', '{}'),
    (driver_user_b, 'm10-driver-b@example.invalid', '{}'),
    (driver_user_c, 'm10-driver-c@example.invalid', '{}'),
    (admin_user, 'm10-admin@example.invalid', '{}');
  update public.profiles set
    profile_type = case when id in (driver_user_a, driver_user_b, driver_user_c)
      then 'DRIVER'::public.profile_type
      when id = admin_user then 'STAFF'::public.profile_type
      else 'CUSTOMER'::public.profile_type end,
    status = 'ACTIVE'::public.account_status,
    full_name = case
      when id = driver_user_a then 'Ahmed Verified'
      when id = driver_user_b then 'Bassem Verified'
      else 'Milestone 10 Fixture' end,
    profile_photo_url = case when id = driver_user_a then 'https://example.invalid/approved-driver.jpg' end
  where id in (customer_a, customer_b, driver_user_a, driver_user_b, driver_user_c, admin_user);
  insert into public.user_roles (user_id, role_id)
  select admin_user, id from public.roles where code = 'SUPER_ADMIN';

  insert into public.drivers (
    id, user_id, driver_type, status, is_online, date_of_birth,
    ride_safety_equipment_confirmed_at
  ) values
    (driver_a, driver_user_a, 'INDEPENDENT', 'ACTIVE', false, date '1990-01-01', clock_timestamp()),
    (driver_b, driver_user_b, 'INDEPENDENT', 'ACTIVE', false, date '1991-01-01', clock_timestamp()),
    (driver_c, driver_user_c, 'INDEPENDENT', 'ACTIVE', false, date '1992-01-01', null);
  insert into public.motorcycles (
    id, driver_id, plate_number, brand, model, color, status, verification_status
  ) values
    (motorcycle_a, driver_a, 'ا ب ج 123', 'Honda', 'CB', 'Black', 'ACTIVE', 'APPROVED'),
    (motorcycle_b, driver_b, 'د هـ و 456', 'Bajaj', 'Boxer', 'Blue', 'ACTIVE', 'APPROVED'),
    (motorcycle_c, driver_c, 'ز ح ط 789', 'TVS', 'HLX', 'Red', 'ACTIVE', 'APPROVED');
  insert into public.driver_documents (
    driver_id, document_type, file_path, status, expiry_date, is_current
  ) values
    (driver_a, 'NATIONAL_ID', driver_a || '/driver/NATIONAL_ID/a.pdf', 'APPROVED', null, true),
    (driver_a, 'DRIVING_LICENSE', driver_a || '/driver/DRIVING_LICENSE/a.pdf', 'APPROVED', current_date + 365, true),
    (driver_a, 'DRIVER_SELFIE', driver_a || '/driver/DRIVER_SELFIE/a.jpg', 'APPROVED', null, true),
    (driver_b, 'NATIONAL_ID', driver_b || '/driver/NATIONAL_ID/b.pdf', 'APPROVED', null, true),
    (driver_b, 'DRIVING_LICENSE', driver_b || '/driver/DRIVING_LICENSE/b.pdf', 'APPROVED', current_date + 365, true),
    (driver_b, 'DRIVER_SELFIE', driver_b || '/driver/DRIVER_SELFIE/b.jpg', 'APPROVED', null, true),
    (driver_c, 'NATIONAL_ID', driver_c || '/driver/NATIONAL_ID/c.pdf', 'APPROVED', null, true),
    (driver_c, 'DRIVING_LICENSE', driver_c || '/driver/DRIVING_LICENSE/c.pdf', 'APPROVED', current_date, true),
    (driver_c, 'DRIVER_SELFIE', driver_c || '/driver/DRIVER_SELFIE/c.jpg', 'APPROVED', null, true);
  insert into public.driver_latest_locations (
    driver_id, latitude, longitude, accuracy_meters, updated_at
  ) values
    (driver_a, 30, 31, 5, clock_timestamp()),
    (driver_b, 30, 31, 5, clock_timestamp()),
    (driver_c, 30, 31, 5, clock_timestamp());
  select id into ride_service from public.service_types where code = 'RIDE';
  select id into delivery_service from public.service_types where code = 'DELIVERY';

  perform set_config('request.jwt.claim.sub', driver_user_c::text, true);
  set local role authenticated;
  begin
    perform public.set_driver_online(true);
    raise exception 'Expired required document allowed Online';
  exception when sqlstate 'P0001' then
    assert sqlerrm = 'Online eligibility denied';
  end;
  reset role;

  perform set_config('request.jwt.claim.sub', driver_user_a::text, true);
  set local role authenticated;
  perform public.set_driver_online(true);
  reset role;
  perform set_config('request.jwt.claim.sub', driver_user_b::text, true);
  set local role authenticated;
  perform public.set_driver_online(true);
  reset role;
  assert (select is_online from public.drivers where id = driver_a),
    'Verified Driver with valid documents must go Online';

  perform set_config('request.jwt.claim.sub', driver_user_c::text, true);
  set local role authenticated;
  begin
    perform public.review_driver_document(
      (select id from public.driver_documents where driver_id = driver_c and document_type = 'DRIVING_LICENSE'),
      'APPROVED', null
    );
    raise exception 'Driver self-approved a document';
  exception when insufficient_privilege then null;
  end;
  reset role;

  perform set_config('request.jwt.claim.sub', customer_a::text, true);
  set local role authenticated;
  assert (select count(*) = 0 from public.driver_documents),
    'Customer must not read Driver documents';
  reset role;
  perform set_config('request.jwt.claim.sub', driver_user_b::text, true);
  set local role authenticated;
  assert (select count(*) = 0 from public.driver_documents where driver_id = driver_a),
    'Another Driver must not read Driver documents';
  reset role;

  insert into public.orders (
    id, customer_id, service_type_id, pickup_lat, pickup_lng,
    destination_lat, destination_lng, pickup_address, destination_address,
    proposed_price, status, bidding_expires_at
  ) values (
    ride_order, customer_a, ride_service, 30, 31, 30.010000, 31,
    'Ride pickup', 'Ride destination', 80, 'BIDDING', clock_timestamp() + interval '10 minutes'
  );
  insert into public.order_driver_candidates (order_id, driver_id) values (ride_order, driver_a);
  insert into public.offers (order_id, driver_id, offered_price, status)
  values (ride_order, driver_a, 80, 'ACTIVE') returning id into offer_id;
  perform set_config('request.jwt.claim.sub', customer_a::text, true);
  set local role authenticated;
  perform public.accept_offer(ride_order, offer_id);
  reset role;
  assert (select motorcycle_id = motorcycle_a from public.orders where id = ride_order),
    'Assignment must snapshot a verified active motorcycle';

  perform set_config('request.jwt.claim.sub', driver_user_a::text, true);
  set local role authenticated;
  perform public.driver_on_way(ride_order);
  begin
    perform public.start_order(ride_order);
    raise exception 'Ride started before ARRIVED';
  exception when sqlstate 'P0001' then null;
  end;
  perform public.update_driver_location(30.002500, 31, 5);
  begin
    perform public.driver_arrived(ride_order);
    raise exception 'Ride ARRIVED outside 200m';
  exception when sqlstate 'P0001' then
    assert sqlerrm = 'Driver is outside the required geofence';
  end;
  reset role;
  update public.driver_latest_locations
  set latitude = 30, longitude = 31, updated_at = clock_timestamp() - interval '121 seconds'
  where driver_id = driver_a;
  perform set_config('request.jwt.claim.sub', driver_user_a::text, true);
  set local role authenticated;
  begin
    perform public.driver_arrived(ride_order);
    raise exception 'Stale location authorized ARRIVED';
  exception when sqlstate 'P0001' then
    assert sqlerrm = 'Driver location is stale';
  end;
  perform public.update_driver_location(30, 31, 5);
  perform public.driver_arrived(ride_order);
  reset role;
  assert (select status = 'DRIVER_ARRIVED' from public.orders where id = ride_order),
    'Ride ARRIVED within 200m must succeed';

  perform set_config('request.jwt.claim.sub', customer_a::text, true);
  set local role authenticated;
  begin
    perform public.start_order(ride_order);
    raise exception 'Customer started Ride';
  exception when insufficient_privilege then null;
  end;
  reset role;
  perform set_config('request.jwt.claim.sub', driver_user_b::text, true);
  set local role authenticated;
  begin
    perform public.start_order(ride_order);
    raise exception 'Another Driver started Ride';
  exception when insufficient_privilege then null;
  end;
  reset role;
  perform set_config('request.jwt.claim.sub', driver_user_a::text, true);
  set local role authenticated;
  perform public.start_order(ride_order);
  reset role;
  assert (select status = 'IN_PROGRESS' from public.orders where id = ride_order),
    'Selected Driver must start Ride after ARRIVED with no code parameter';

  -- Simulate an availability flag left true by a delayed worker; active work must win.
  update public.drivers set is_online = true where id = driver_a;
  update public.driver_documents set expiry_date = current_date
  where driver_id = driver_a and document_type = 'DRIVING_LICENSE' and is_current;
  perform public.enqueue_driver_document_expiry_notifications();
  assert (select status = 'IN_PROGRESS' from public.orders where id = ride_order),
    'Document expiry during active trip must not cancel the trip';
  assert (select is_online from public.drivers where id = driver_a),
    'Expiry reconciliation must not force active-trip Driver Offline';
  update public.driver_documents set status = 'APPROVED', expiry_date = current_date + 365
  where driver_id = driver_a and document_type = 'DRIVING_LICENSE' and is_current;

  perform set_config('request.jwt.claim.sub', driver_user_a::text, true);
  set local role authenticated;
  perform public.update_driver_location(30.013000, 31, 5);
  begin
    perform public.complete_order(ride_order);
    raise exception 'Ride completed outside 300m';
  exception when sqlstate 'P0001' then null;
  end;
  perform public.update_driver_location(30.010000, 31, 5);
  perform public.complete_order(ride_order);
  reset role;
  assert (select status = 'COMPLETED' from public.orders where id = ride_order),
    'Ride completion within 300m must succeed with no code';

  insert into public.orders (
    id, customer_id, service_type_id, pickup_lat, pickup_lng,
    destination_lat, destination_lng, pickup_address, destination_address,
    proposed_price, status, bidding_expires_at
  ) values (
    delivery_order, customer_a, delivery_service, 30, 31, 30.010000, 31,
    'Delivery pickup', 'Delivery destination', 90, 'BIDDING', clock_timestamp() + interval '10 minutes'
  );
  insert into public.order_delivery_details (
    order_id, recipient_name, recipient_phone, parcel_weight_kg, declared_value
  ) values (delivery_order, 'Recipient', '01000000000', 2, 500);
  insert into public.order_driver_candidates (order_id, driver_id) values (delivery_order, driver_a);
  insert into public.offers (order_id, driver_id, offered_price, status)
  values (delivery_order, driver_a, 90, 'ACTIVE') returning id into offer_id;
  perform set_config('request.jwt.claim.sub', customer_a::text, true);
  set local role authenticated;
  perform public.accept_offer(delivery_order, offer_id);
  delivery_code := public.get_delivery_confirmation_code(delivery_order);
  assert delivery_code ~ '^[0-9]{4}$', 'Customer must receive one four-digit Delivery code';
  reset role;
  perform set_config('request.jwt.claim.sub', customer_b::text, true);
  set local role authenticated;
  begin
    perform public.get_delivery_confirmation_code(delivery_order);
    raise exception 'Unrelated Customer retrieved Delivery code';
  exception when insufficient_privilege then null;
  end;
  reset role;
  perform set_config('request.jwt.claim.sub', driver_user_a::text, true);
  set local role authenticated;
  begin
    perform public.get_delivery_confirmation_code(delivery_order);
    raise exception 'Driver retrieved valid Delivery code';
  exception when insufficient_privilege then null;
  end;
  perform public.driver_on_way(delivery_order);
  perform public.update_driver_location(30.002500, 31, 5);
  begin
    perform public.confirm_delivery_pickup(delivery_order);
    raise exception 'Delivery pickup outside 200m';
  exception when sqlstate 'P0001' then null;
  end;
  perform public.update_driver_location(30, 31, 5);
  perform public.confirm_delivery_pickup(delivery_order);
  reset role;
  assert (select status = 'IN_PROGRESS' from public.orders where id = delivery_order),
    'Delivery pickup within 200m must proceed with no pickup code';

  perform set_config('request.jwt.claim.sub', driver_user_a::text, true);
  set local role authenticated;
  perform public.update_driver_location(30.013000, 31, 5);
  begin
    perform public.complete_delivery_with_code(delivery_order, delivery_code);
    raise exception 'Delivery completed outside 300m';
  exception when sqlstate 'P0001' then null;
  end;
  perform public.update_driver_location(30.010000, 31, 5);
  select * into result from public.complete_delivery_with_code(delivery_order, '9999');
  assert result.outcome = 'INVALID_CODE' and result.attempts_remaining = 4,
    'Wrong code must be a safe persisted business rejection';
  select * into result from public.complete_delivery_with_code(delivery_order, delivery_code);
  assert result.outcome = 'COMPLETED', 'Correct code within 300m must complete Delivery';
  begin
    perform public.complete_delivery_with_code(delivery_order, delivery_code);
    raise exception 'Completed Delivery code was reused';
  exception when sqlstate 'P0001' or insufficient_privilege then null;
  end;
  reset role;
  assert not exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'orders'
      and column_name ilike '%code%'
  ), 'Raw Delivery code must not exist in ordinary order rows';
  assert not exists (
    select 1 from public.notification_outbox n
    where n.order_id = delivery_order
      and (n.title like '%' || delivery_code || '%' or n.body like '%' || delivery_code || '%')
  ), 'Push payloads must never contain the Delivery code';

  insert into public.orders (
    id, customer_id, service_type_id, pickup_lat, pickup_lng,
    destination_lat, destination_lng, pickup_address, destination_address,
    proposed_price, status, bidding_expires_at
  ) values (
    delivery_order_b, customer_a, delivery_service, 30, 31, 30.010000, 31,
    'Delivery B pickup', 'Delivery B destination', 95, 'BIDDING', clock_timestamp() + interval '10 minutes'
  );
  insert into public.order_delivery_details (
    order_id, recipient_name, recipient_phone, parcel_weight_kg, declared_value
  ) values (delivery_order_b, 'Recipient B', '01000000001', 2, 500);
  insert into public.order_driver_candidates (order_id, driver_id) values (delivery_order_b, driver_b);
  insert into public.offers (order_id, driver_id, offered_price, status)
  values (delivery_order_b, driver_b, 95, 'ACTIVE') returning id into offer_id;
  perform set_config('request.jwt.claim.sub', customer_a::text, true);
  set local role authenticated;
  perform public.accept_offer(delivery_order_b, offer_id);
  delivery_code_b := public.get_delivery_confirmation_code(delivery_order_b);
  reset role;
  perform set_config('request.jwt.claim.sub', driver_user_b::text, true);
  set local role authenticated;
  perform public.driver_on_way(delivery_order_b);
  perform public.update_driver_location(30, 31, 5);
  perform public.confirm_delivery_pickup(delivery_order_b);
  perform public.update_driver_location(30.010000, 31, 5);
  select * into result from public.complete_delivery_with_code(delivery_order_b, delivery_code);
  assert result.outcome = 'INVALID_CODE', 'Code from another order must be rejected';
  perform public.complete_delivery_with_code(delivery_order_b, '1111');
  perform public.complete_delivery_with_code(delivery_order_b, '2222');
  perform public.complete_delivery_with_code(delivery_order_b, '3333');
  select * into result from public.complete_delivery_with_code(delivery_order_b, '4444');
  assert result.outcome = 'LOCKED' and result.locked_until is not null,
    'Five failed attempts must create a temporary lock';
  reset role;
  perform set_config('request.jwt.claim.sub', driver_user_a::text, true);
  set local role authenticated;
  begin
    perform public.complete_delivery_with_code(delivery_order_b, delivery_code_b);
    raise exception 'Wrong Driver used Delivery code';
  exception when insufficient_privilege then null;
  end;
  reset role;

  perform set_config('request.jwt.claim.sub', driver_user_a::text, true);
  set local role authenticated;
  perform public.set_driver_online(true);
  reset role;
  insert into public.orders (
    id, customer_id, service_type_id, pickup_lat, pickup_lng,
    destination_lat, destination_lng, pickup_address, destination_address,
    proposed_price, status, bidding_expires_at
  ) values (
    cancelled_delivery, customer_a, delivery_service, 30, 31, 30.01, 31,
    'Cancelled pickup', 'Cancelled destination', 100, 'BIDDING', clock_timestamp() + interval '10 minutes'
  );
  insert into public.order_delivery_details (
    order_id, recipient_name, recipient_phone, parcel_weight_kg, declared_value
  ) values (cancelled_delivery, 'Cancelled Recipient', '01000000002', 2, 500);
  insert into public.order_driver_candidates (order_id, driver_id) values (cancelled_delivery, driver_a);
  insert into public.offers (order_id, driver_id, offered_price, status)
  values (cancelled_delivery, driver_a, 100, 'ACTIVE') returning id into offer_id;
  perform set_config('request.jwt.claim.sub', customer_a::text, true);
  set local role authenticated;
  perform public.accept_offer(cancelled_delivery, offer_id);
  delivery_code := public.get_delivery_confirmation_code(cancelled_delivery);
  perform public.cancel_order(cancelled_delivery, 'Cancelled before pickup');
  reset role;
  perform set_config('request.jwt.claim.sub', driver_user_a::text, true);
  set local role authenticated;
  begin
    perform public.complete_delivery_with_code(cancelled_delivery, delivery_code);
    raise exception 'Cancelled Delivery code was accepted';
  exception when sqlstate 'P0001' or insufficient_privilege then null;
  end;
  reset role;

  perform set_config('request.jwt.claim.sub', driver_user_a::text, true);
  set local role authenticated;
  perform public.set_driver_online(true);
  reset role;
  insert into public.orders (
    id, customer_id, service_type_id, pickup_lat, pickup_lng,
    destination_lat, destination_lng, pickup_address, destination_address,
    proposed_price, status, bidding_expires_at
  ) values (
    privacy_order, customer_a, delivery_service, 30, 31, 30.01, 31,
    'Privacy pickup', 'Privacy destination', 80, 'BIDDING', clock_timestamp() + interval '10 minutes'
  );
  insert into public.order_driver_candidates (order_id, driver_id) values (privacy_order, driver_a);
  insert into public.offers (order_id, driver_id, offered_price, status)
  values (privacy_order, driver_a, 80, 'ACTIVE');
  perform set_config('request.jwt.claim.sub', customer_b::text, true);
  set local role authenticated;
  assert (select count(*) = 0 from public.get_customer_order_offers(privacy_order)),
    'Customer offer privacy must remain unchanged';
  reset role;
  perform set_config('request.jwt.claim.sub', driver_user_b::text, true);
  set local role authenticated;
  begin
    perform public.submit_offer(privacy_order, 80);
    raise exception 'Driver with active job submitted a new offer';
  exception when sqlstate 'P0001' then null;
  end;
  reset role;

  perform set_config('request.jwt.claim.sub', driver_user_a::text, true);
  set local role authenticated;
  begin
    perform public.admin_safety_override(ride_order, 'COMPLETE_RIDE', 'Unauthorized');
    raise exception 'Driver invoked safety override';
  exception when insufficient_privilege then null;
  end;
  reset role;
  perform set_config('request.jwt.claim.sub', customer_a::text, true);
  set local role authenticated;
  begin
    perform public.admin_safety_override(ride_order, 'COMPLETE_RIDE', 'Unauthorized');
    raise exception 'Customer invoked safety override';
  exception when insufficient_privilege then null;
  end;
  reset role;

  update public.driver_documents set expiry_date = current_date + 1
  where driver_id = driver_c and document_type = 'DRIVING_LICENSE' and is_current;
  perform public.enqueue_driver_document_expiry_notifications();
  perform public.enqueue_driver_document_expiry_notifications();
  assert (
    select count(*) = 1 from public.notification_outbox
    where event_key like 'driver-document:%:expiry:1' and target_user_id = driver_user_c
  ), 'Expiry notification intent must dedupe';

  perform set_config('request.jwt.claim.sub', driver_user_a::text, true);
  set local role authenticated;
  insert into storage.objects (bucket_id, name, owner_id)
  values (
    'driver-documents',
    driver_a || '/driver/NATIONAL_ID/a1000000-0000-4000-8000-000000000501.pdf',
    driver_user_a::text
  );
  new_document := public.submit_driver_document(
    'NATIONAL_ID',
    driver_a || '/driver/NATIONAL_ID/a1000000-0000-4000-8000-000000000501.pdf'
  );
  assert new_document is not null, 'Driver-scoped upload must register a pending replacement';
  assert (
    select status = 'PENDING'::public.document_status
    from public.driver_documents where id = new_document
  ), 'Replacement document must remain pending review';
  reset role;
  perform set_config('request.jwt.claim.sub', driver_user_b::text, true);
  set local role authenticated;
  assert (
    select count(*) = 0 from storage.objects
    where name like driver_a::text || '/%'
  ), 'Another Driver must not read private Storage objects';
  reset role;

  assert not has_function_privilege('anon', 'public.driver_arrived(uuid)', 'execute'),
    'Anon must not execute safety lifecycle RPCs';
  assert not has_function_privilege('anon', 'public.get_delivery_confirmation_code(uuid)', 'execute'),
    'Anon must not retrieve Delivery codes';
  assert not has_table_privilege('authenticated', 'public.driver_documents', 'insert,update,delete'),
    'Normal clients must not directly change Driver document review rows';
  assert not has_table_privilege('authenticated', 'public.motorcycle_documents', 'insert,update,delete'),
    'Normal clients must not directly change motorcycle document review rows';
  assert not has_table_privilege('authenticated', 'public.order_events', 'insert,update,delete'),
    'order_events must remain append-only for normal clients';
  assert not has_table_privilege('authenticated', 'public.safety_overrides', 'select,insert,update,delete'),
    'Safety override audit rows must remain private';
  assert (
    select count(*) >= 1 from public.order_events
    where order_id = ride_order and event_type = 'DRIVER_ARRIVED'
  ) and (
    select count(*) = 1 from public.order_events
    where order_id = ride_order and event_type = 'IN_PROGRESS'
  ) and (
    select count(*) = 1 from public.order_events
    where order_id = ride_order and event_type = 'COMPLETED'
  ), 'Representative lifecycle events must be append-only and singular';
  assert not exists (
    select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname in ('public', 'private')
      and p.proname in (
        'driver_arrived', 'start_order', 'complete_order',
        'confirm_delivery_pickup', 'complete_delivery_with_code',
        'get_delivery_confirmation_code', 'admin_safety_override'
      ) and coalesce(array_to_string(p.proconfig, ','), '') not like '%search_path=%'
  ), 'Milestone 10 privileged functions must pin search_path';
end;
$test$;

rollback;
