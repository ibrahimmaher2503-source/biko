-- D03 rollback proof: staged discovery, targeted privacy-safe signals, and
-- repeat-tick idempotency. The transaction removes every fixture on rollback.
begin;
set local statement_timeout = '45s';

do $test$
declare
  customer_user uuid := gen_random_uuid();
  near_user uuid := gen_random_uuid();
  far_user uuid := gen_random_uuid();
  farther_user uuid := gen_random_uuid();
  outer_user uuid := gen_random_uuid();
  near_driver uuid := gen_random_uuid();
  far_driver uuid := gen_random_uuid();
  farther_driver uuid := gen_random_uuid();
  outer_driver uuid := gen_random_uuid();
  delivery_id uuid;
  v_order_id uuid := gen_random_uuid();
  signal_count integer;
  claimed_id uuid;
  claimed_tokens text[];
begin
  insert into auth.users (id, email, raw_user_meta_data)
  values
    (customer_user, customer_user::text || '@d03.invalid', '{}'),
    (near_user, near_user::text || '@d03.invalid', '{}'),
    (far_user, far_user::text || '@d03.invalid', '{}'),
    (farther_user, farther_user::text || '@d03.invalid', '{}'),
    (outer_user, outer_user::text || '@d03.invalid', '{}');

  update public.profiles
  set profile_type = case when id = customer_user
        then 'CUSTOMER'::public.profile_type else 'DRIVER'::public.profile_type end,
      status = 'ACTIVE'::public.account_status
  where id in (customer_user, near_user, far_user, farther_user, outer_user);

  insert into public.drivers (
    id, user_id, driver_type, status, date_of_birth, is_online
  )
  values
    (near_driver, near_user, 'INDEPENDENT', 'ACTIVE', (current_date - interval '25 years')::date, true),
    (far_driver, far_user, 'INDEPENDENT', 'ACTIVE', (current_date - interval '25 years')::date, true),
    (farther_driver, farther_user, 'INDEPENDENT', 'ACTIVE', (current_date - interval '25 years')::date, true),
    (outer_driver, outer_user, 'INDEPENDENT', 'ACTIVE', (current_date - interval '25 years')::date, true);

  insert into public.driver_documents (
    driver_id, document_type, file_path, status, expiry_date
  )
  select d.id, required.document_type, 'd03/' || d.id || '/' || required.document_type,
    'APPROVED'::public.document_status, current_date + 365
  from public.drivers d
  cross join (values
    ('NATIONAL_ID'), ('DRIVING_LICENSE'), ('DRIVER_SELFIE')
  ) required(document_type)
  where d.id in (near_driver, far_driver, farther_driver, outer_driver);

  insert into public.motorcycles (
    driver_id, plate_number, brand, model, color, status, verification_status
  )
  select d.id, 'D03-' || left(d.id::text, 6), 'D03', 'Test', 'Black',
    'ACTIVE'::public.motorcycle_status, 'APPROVED'::public.document_status
  from public.drivers d
  where d.id in (near_driver, far_driver, farther_driver, outer_driver);

  insert into public.driver_latest_locations (
    driver_id, latitude, longitude, accuracy_meters, updated_at
  )
  values
    (near_driver, 30.053400, 31.235700, 5, clock_timestamp()),
    (far_driver, 30.071400, 31.235700, 5, clock_timestamp()),
    (farther_driver, 30.089400, 31.235700, 5, clock_timestamp()),
    (outer_driver, 30.107400, 31.235700, 5, clock_timestamp());

  insert into public.user_push_tokens (user_id, token, platform, app_kind)
  values
    (near_user, 'd03-near-token-0000000001', 'ANDROID', 'DRIVER'),
    (far_user, 'd03-far-token-00000000001', 'ANDROID', 'DRIVER');

  select id into delivery_id
  from public.service_types
  where code = 'DELIVERY';
  assert delivery_id is not null, 'DELIVERY service is required';

  insert into public.orders (
    id, customer_id, service_type_id,
    pickup_lat, pickup_lng, destination_lat, destination_lng,
    pickup_address, destination_address, proposed_price,
    status, created_at, bidding_expires_at
  ) values (
    v_order_id, customer_user, delivery_id,
    30.044400, 31.235700, 30.134400, 31.235700,
    'D03 pickup', 'D03 destination', 80,
    'BIDDING'::public.order_status,
    clock_timestamp() - interval '21 seconds',
    clock_timestamp() + interval '60 seconds'
  );

  assert (select count(*) = 1 from public.notification_outbox
    where event_key = 'order:' || v_order_id || ':new-work'
      and audience = 'ELIGIBLE_DRIVERS'
      and target_type = 'REQUESTS'),
    'The existing order signal must cover the initial 2 km stage';

  signal_count := public.run_driver_progressive_dispatch_tick(v_order_id, 10, 10);
  assert signal_count = 1,
    'The first expansion must signal only the newly eligible 3 km Driver';
  assert (select count(*) = 2 from public.order_driver_candidates candidates
    where candidates.order_id = v_order_id),
    'The first expansion must record both eligible candidates';
  assert (select count(*) = 1 from public.notification_outbox
    where event_key = 'dispatch:' || v_order_id || ':driver:' || far_driver || ':radius:4000'
      and target_user_id = far_user
      and audience = 'USER'
      and target_app_kind = 'DRIVER'
      and target_type = 'REQUESTS'),
    'The 4 km signal must target the newly eligible Driver only';
  assert (select count(*) = 0 from public.notification_outbox
    where event_key = 'dispatch:' || v_order_id || ':driver:' || near_driver || ':radius:4000'),
    'The initial 2 km Driver must not receive a duplicate stage signal';

  select id, tokens into claimed_id, claimed_tokens
  from public.claim_notification_outbox(1)
  limit 1;
  assert claimed_id is not null and 'd03-near-token-0000000001' = any(claimed_tokens)
    and not ('d03-far-token-00000000001' = any(claimed_tokens)),
    'A delayed generic Push claim must remain bounded to the initial 2 km';
  assert public.complete_notification_outbox(claimed_id, true),
    'The generic Push claim must remain completable';

  signal_count := public.run_driver_progressive_dispatch_tick(v_order_id, 10, 10);
  assert signal_count = 0, 'Repeating one stage must be idempotent';
  assert (select count(*) = 1 from public.notification_outbox
    where event_key like 'dispatch:' || v_order_id || ':driver:%'),
    'Repeating one stage must not duplicate signals';

  update public.orders
  set created_at = clock_timestamp() - interval '41 seconds'
  where id = v_order_id;
  signal_count := public.run_driver_progressive_dispatch_tick();
  assert signal_count = 1,
    'The 6 km expansion must signal the newly eligible 5 km Driver';
  assert (select count(*) = 1 from public.notification_outbox
    where event_key = 'dispatch:' || v_order_id || ':driver:' || farther_driver || ':radius:6000'
      and target_user_id = farther_user),
    'The 6 km signal must remain targeted and stable';
  assert (select count(*) = 2 from public.notification_outbox
    where event_key like 'dispatch:' || v_order_id || ':driver:%'),
    'Only one signal per newly eligible Driver is retained';
  assert (select count(*) = 0 from public.notification_outbox
    where notification_outbox.order_id = v_order_id
      and (title || ' ' || body) ~* '(phone|هاتف|customer|عميل)'),
    'Progressive signals must not disclose pre-assignment identity or phone';

  update public.orders
  set created_at = clock_timestamp() - interval '61 seconds'
  where id = v_order_id;
  signal_count := public.run_driver_progressive_dispatch_tick();
  assert signal_count = 1,
    'The 8 km expansion must signal the newly eligible 7 km Driver';
  assert (select count(*) = 1 from public.notification_outbox
    where event_key = 'dispatch:' || v_order_id || ':driver:' || outer_driver || ':radius:8000'
      and target_user_id = outer_user),
    'The 8 km signal must remain targeted and stable';
  assert (select count(*) = 3 from public.notification_outbox
    where event_key like 'dispatch:' || v_order_id || ':driver:%'),
    'The 2/4/6/8 km stages must retain one signal per new Driver';

  assert has_function_privilege(
    'service_role',
    'public.run_driver_progressive_dispatch_tick(uuid,integer,integer)',
    'execute'
  ), 'Only the trusted dispatcher may execute the tick';
  assert not has_function_privilege(
    'authenticated',
    'public.run_driver_progressive_dispatch_tick(uuid,integer,integer)',
    'execute'
  ), 'Authenticated clients must not execute the tick';
end;
$test$;

rollback;
