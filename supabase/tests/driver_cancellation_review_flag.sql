-- D06 focused contract. All fixtures and durable writes roll back.
begin;
set local statement_timeout = '20s';

do $test$
declare
  customer_user uuid := 'd0600000-0000-4000-8000-000000000001';
  driver_user uuid := 'd0600000-0000-4000-8000-000000000002';
  driver_pk uuid := 'd0600000-0000-4000-8000-000000000003';
  motorcycle_pk uuid := 'd0600000-0000-4000-8000-000000000004';
  service_id uuid;
  order_one uuid := 'd0600000-0000-4000-8000-000000000011';
  order_two uuid := 'd0600000-0000-4000-8000-000000000012';
  order_three uuid := 'd0600000-0000-4000-8000-000000000013';
  order_four uuid := 'd0600000-0000-4000-8000-000000000014';
  offer_one uuid := 'd0600000-0000-4000-8000-000000000021';
  offer_two uuid := 'd0600000-0000-4000-8000-000000000022';
  offer_three uuid := 'd0600000-0000-4000-8000-000000000023';
  offer_four uuid := 'd0600000-0000-4000-8000-000000000024';
begin
  assert not has_table_privilege(
    'authenticated', 'public.driver_cancellation_review_flags', 'SELECT'
  ), 'Normal clients must not read operations-review audit rows';
  assert has_table_privilege(
    'service_role', 'public.driver_cancellation_review_flags', 'SELECT'
  ), 'Operations service must be able to read review flags';

  insert into auth.users (id, email, raw_user_meta_data) values
    (customer_user, 'd06-customer@example.invalid', '{}'),
    (driver_user, 'd06-driver@example.invalid', '{}');

  update public.profiles
  set profile_type = 'DRIVER'::public.profile_type,
      status = 'ACTIVE'::public.account_status
  where id = driver_user;

  insert into public.drivers (
    id, user_id, driver_type, status, date_of_birth, is_online,
    ride_safety_equipment_confirmed_at
  ) values (
    driver_pk, driver_user, 'INDEPENDENT', 'ACTIVE',
    (current_date - interval '25 years')::date, true, clock_timestamp()
  );

  insert into public.driver_documents (
    driver_id, document_type, file_path, status, expiry_date
  ) values
    (driver_pk, 'NATIONAL_ID', 'd06/national-id', 'APPROVED', current_date + 365),
    (driver_pk, 'DRIVING_LICENSE', 'd06/driving-license', 'APPROVED', current_date + 365),
    (driver_pk, 'DRIVER_SELFIE', 'd06/selfie', 'APPROVED', current_date + 365);

  insert into public.motorcycles (
    id, driver_id, plate_number, brand, model, color, status, verification_status
  ) values (
    motorcycle_pk, driver_pk, 'D06-TEST', 'D06', 'Test', 'Black',
    'ACTIVE'::public.motorcycle_status, 'APPROVED'::public.document_status
  );

  insert into public.driver_latest_locations (
    driver_id, latitude, longitude, accuracy_meters, updated_at
  ) values (driver_pk, 30.044400, 31.235700, 5, clock_timestamp());

  select id into service_id from public.service_types where code = 'RIDE';

  insert into public.orders (
    id, customer_id, service_type_id,
    pickup_lat, pickup_lng, pickup_address,
    destination_lat, destination_lng, destination_address,
    proposed_price, status
  ) values
    (order_one, customer_user, service_id, 30.044400, 31.235700, 'D06 pickup 1', 30.054400, 31.235700, 'D06 destination 1', 80, 'BIDDING'),
    (order_two, customer_user, service_id, 30.044400, 31.235700, 'D06 pickup 2', 30.054400, 31.235700, 'D06 destination 2', 81, 'BIDDING'),
    (order_three, customer_user, service_id, 30.044400, 31.235700, 'D06 pickup 3', 30.054400, 31.235700, 'D06 destination 3', 82, 'BIDDING'),
    (order_four, customer_user, service_id, 30.044400, 31.235700, 'D06 pickup 4', 30.054400, 31.235700, 'D06 destination 4', 83, 'BIDDING');

  insert into public.offers (id, order_id, driver_id, offered_price, status) values
    (offer_one, order_one, driver_pk, 80, 'SELECTED'),
    (offer_two, order_two, driver_pk, 81, 'SELECTED'),
    (offer_three, order_three, driver_pk, 82, 'SELECTED'),
    (offer_four, order_four, driver_pk, 83, 'SELECTED');

  -- Keep the real one-active-job constraint satisfied while building history.
  update public.orders
  set driver_id = driver_pk, selected_offer_id = offer_one,
      agreed_price = proposed_price, assigned_at = clock_timestamp(),
      status = 'DRIVER_ASSIGNED'::public.order_status
  where id = order_one;
  update public.orders
  set status = 'CANCELLED'::public.order_status,
      cancelled_by = driver_user,
      cancellation_type = 'DRIVER_CANCEL',
      cancellation_reason = 'D06 historical cancellation',
      cancelled_at = clock_timestamp() - interval '8 days'
  where id = order_one;

  update public.orders
  set driver_id = driver_pk, selected_offer_id = offer_two,
      agreed_price = proposed_price, assigned_at = clock_timestamp(),
      status = 'DRIVER_ASSIGNED'::public.order_status
  where id = order_two;
  update public.orders
  set status = 'CANCELLED'::public.order_status,
      cancelled_by = driver_user,
      cancellation_type = 'DRIVER_CANCEL',
      cancellation_reason = 'D06 historical cancellation',
      cancelled_at = clock_timestamp() - interval '1 day'
  where id = order_two;

  update public.orders
  set driver_id = driver_pk, selected_offer_id = offer_three,
      agreed_price = proposed_price, assigned_at = clock_timestamp(),
      status = 'DRIVER_ASSIGNED'::public.order_status
  where id = order_three;

  assert (select count(*) = 0 from public.driver_cancellation_review_flags),
    'Two historical cancellations must not create a review flag';

  perform set_config('request.jwt.claim.sub', driver_user::text, true);
  set local role authenticated;
  perform public.driver_cancel_order(order_three, 'D06 third cancellation');
  reset role;

  assert (select status = 'CANCELLED'
      and cancellation_type = 'DRIVER_CANCEL'
    from public.orders where id = order_three),
    'The third Driver cancellation remains terminal';
  assert (select count(*) = 0 from public.driver_cancellation_review_flags),
    'A cancellation older than seven days must not count toward the threshold';
  assert (select count(*) = 0
      from public.notification_outbox
      where event_type = 'DRIVER_CANCELLATION_REVIEW'),
    'The operations-only flag must not invent an unsupported Driver notification';
  assert (select status = 'ACTIVE'::public.driver_status
    from public.drivers where id = driver_pk),
    'The review threshold must not auto-suspend the Driver';
  assert not exists (
    select 1 from public.orders
    where id = order_three and status = 'BIDDING'::public.order_status
  ), 'A post-assignment cancellation must not return the order to bidding';

  update public.orders
  set driver_id = driver_pk, selected_offer_id = offer_four,
      agreed_price = proposed_price, assigned_at = clock_timestamp(),
      status = 'DRIVER_ASSIGNED'::public.order_status
  where id = order_four;
  set local role authenticated;
  perform public.driver_cancel_order(order_four, 'D06 fourth cancellation');
  reset role;
  assert (select count(*) = 1 and max(cancellation_count) = 3
    from public.driver_cancellation_review_flags where driver_id = driver_pk),
    'The third cancellation inside seven days creates one account flag/audit row';
  assert (select trigger_order_id = order_four
      and actor_user_id = driver_user
    from public.driver_cancellation_review_flags
    where driver_id = driver_pk),
    'The flag audit is tied to the threshold order and auth-derived actor';
  assert (select status = 'ACTIVE'::public.driver_status
    from public.drivers where id = driver_pk),
    'The review threshold must not auto-suspend the Driver';
  assert not exists (
    select 1 from public.orders
    where id = order_four and status = 'BIDDING'::public.order_status
  ), 'A post-assignment cancellation must not return the order to bidding';
end;
$test$;

rollback;
