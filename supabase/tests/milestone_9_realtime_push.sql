-- Milestone 9 only: token security, durable notification intent, and keyset paging.
-- Every fixture and state change is rolled back.
begin;
set local statement_timeout = '45s';

do $setup$
declare
  customer_a uuid := '9a900000-0000-4000-8000-000000000001';
  customer_b uuid := '9a900000-0000-4000-8000-000000000002';
  driver_user uuid := '9a900000-0000-4000-8000-000000000003';
  driver_id uuid := '9a900000-0000-4000-8000-000000000004';
  ride_id uuid;
  first_token_id uuid;
  refreshed_token_id uuid;
begin
  insert into auth.users (id, email, raw_user_meta_data) values
    (customer_a, 'm9-customer-a@example.invalid', '{}'),
    (customer_b, 'm9-customer-b@example.invalid', '{}'),
    (driver_user, 'm9-driver@example.invalid', '{}');
  update public.profiles
  set profile_type = case when id = driver_user
        then 'DRIVER'::public.profile_type else 'CUSTOMER'::public.profile_type end,
      status = 'ACTIVE'::public.account_status,
      full_name = 'Milestone 9 rollback fixture'
  where id in (customer_a, customer_b, driver_user);
  insert into public.drivers (id, user_id, driver_type, status, is_online)
  values (driver_id, driver_user, 'INDEPENDENT', 'ACTIVE', false);
  insert into public.driver_latest_locations (
    driver_id, latitude, longitude, accuracy_meters, updated_at
  ) values (driver_id, 30, 31, 5, clock_timestamp());
  update public.drivers set is_online = true where id = driver_id;
  select id into ride_id from public.service_types where code = 'RIDE';
  assert ride_id is not null, 'Ride service is required';

  insert into public.orders (
    id, customer_id, service_type_id,
    pickup_lat, pickup_lng, destination_lat, destination_lng,
    pickup_address, destination_address, proposed_price,
    status, created_at, bidding_expires_at
  )
  select md5('m9-order-' || n)::uuid, customer_a, ride_id,
    30, 31, 30.1, 31.1,
    'M9 pickup ' || n, 'M9 destination ' || n, 80,
    'BIDDING'::public.order_status,
    clock_timestamp() - make_interval(secs => n),
    clock_timestamp() + interval '10 minutes'
  from generate_series(1, 60) n;

  insert into public.offers (
    id, order_id, driver_id, offered_price, status, created_at
  )
  select md5('m9-offer-' || n)::uuid, md5('m9-order-' || n)::uuid,
    driver_id, 80 + n, 'ACTIVE'::public.offer_status,
    clock_timestamp() - make_interval(secs => n)
  from generate_series(1, 60) n;

  perform set_config('request.jwt.claim.sub', customer_a::text, true);
  set local role authenticated;
  first_token_id := public.register_push_token(
    'm9-device-token-customer-a-00000001', 'ANDROID', 'USER'
  );
  refreshed_token_id := public.register_push_token(
    'm9-device-token-customer-a-00000001', 'ANDROID', 'USER'
  );
  perform public.register_push_token(
    'm9-device-token-customer-a-00000002', 'IOS', 'USER'
  );
  reset role;
  assert first_token_id = refreshed_token_id,
    'Token refresh/upsert must retain one authoritative row';
  assert (select count(*) = 2 from public.user_push_tokens
    where user_id = customer_a and enabled),
    'One user must support multiple enabled devices';

  perform set_config('request.jwt.claim.sub', customer_b::text, true);
  set local role authenticated;
  assert not public.revoke_push_token(
    'm9-device-token-customer-a-00000001', 'USER'
  ), 'Another user must not revoke an owned token';
  reset role;
  assert (select enabled from public.user_push_tokens
    where token = 'm9-device-token-customer-a-00000001'),
    'Cross-user revoke must leave the token enabled';

  perform set_config('request.jwt.claim.sub', customer_a::text, true);
  set local role authenticated;
  assert public.revoke_push_token(
    'm9-device-token-customer-a-00000001', 'USER'
  ), 'Owner must revoke own token';
  reset role;

  assert not has_function_privilege(
    'anon', 'public.register_push_token(text,text,text)', 'execute'
  ), 'Anon must not register Push tokens';
  assert not has_function_privilege(
    'authenticated', 'private.enqueue_notification(text,text,text,uuid,text,text,uuid,uuid,text,text)', 'execute'
  ), 'Clients must not target arbitrary notification recipients';
  assert not has_table_privilege('authenticated', 'public.user_push_tokens', 'select'),
    'Normal clients must not read token rows';
  assert not has_table_privilege('authenticated', 'public.notification_outbox', 'insert'),
    'Normal clients must not insert notification intents';
  assert not has_table_privilege('authenticated', 'public.order_events', 'insert,update,delete'),
    'order_events must remain append-only for normal clients';
  assert has_function_privilege(
    'service_role', 'public.claim_notification_outbox(integer)', 'execute'
  ), 'Only the service dispatcher needs outbox claim access';

  perform private.enqueue_notification(
    'm9:duplicate', 'NEW_OFFER', 'USER', customer_a, 'USER', 'ORDER',
    md5('m9-order-1')::uuid, md5('m9-offer-1')::uuid,
    'M9 duplicate', 'M9 duplicate intent'
  );
  perform private.enqueue_notification(
    'm9:duplicate', 'NEW_OFFER', 'USER', customer_a, 'USER', 'ORDER',
    md5('m9-order-1')::uuid, md5('m9-offer-1')::uuid,
    'M9 duplicate', 'M9 duplicate intent'
  );
  assert (select count(*) = 1 from public.notification_outbox
    where event_key = 'm9:duplicate'),
    'Stable event key must deduplicate durable notification intent';
  perform set_config('request.jwt.claim.sub', customer_b::text, true);
  set local role authenticated;
  assert (select count(*) = 0 from public.notification_outbox
    where event_key = 'm9:duplicate'),
    'Another user must not read a targeted notification intent';
  reset role;
  perform set_config('request.jwt.claim.sub', customer_a::text, true);
  set local role authenticated;
  assert (select count(*) = 1 from public.notification_outbox
    where event_key = 'm9:duplicate'),
    'Target user must read own operational notification intent';
  assert (select count(*) = 0 from public.driver_work_signals),
    'Customer must not read Driver work signals';
  reset role;
  perform set_config('request.jwt.claim.sub', driver_user::text, true);
  set local role authenticated;
  assert (select count(*) = 60 from public.driver_work_signals),
    'Eligible Driver must read only authoritative work signals';
  reset role;
  assert exists (
    select 1 from public.driver_work_signals s
    join public.notification_outbox n on n.id = s.id and n.order_id = s.order_id
    where s.order_id = md5('m9-order-1')::uuid
  ), 'Realtime and Push new-work signals must share one stable identity';
end;
$setup$;

select set_config(
  'request.jwt.claim.sub',
  '9a900000-0000-4000-8000-000000000003',
  true
);
set local role authenticated;
create temp table m9_page_1 on commit drop as
select * from public.get_driver_active_offers(null, null, 50);
reset role;

update public.offers set status = 'CLOSED'::public.offer_status
where id = md5('m9-offer-1')::uuid;

select set_config(
  'request.jwt.claim.sub',
  '9a900000-0000-4000-8000-000000000003',
  true
);
set local role authenticated;
create temp table m9_page_2 on commit drop as
select * from public.get_driver_active_offers(
  (select created_at from m9_page_1 order by created_at, id limit 1),
  (select id from m9_page_1 order by created_at, id limit 1),
  50
);
reset role;

do $verify$
declare
  claimed_id uuid;
begin
  assert (select count(*) = 50 from m9_page_1),
    'Keyset first page must be bounded to 50';
  assert (select count(*) = 10 from m9_page_2),
    'Earlier disappearance must not skip later active offers';
  assert not exists (
    select id from m9_page_1 intersect select id from m9_page_2
  ), 'Keyset pages must not duplicate offers';

  select id into claimed_id from public.claim_notification_outbox(1) limit 1;
  assert claimed_id is not null, 'Dispatcher must atomically claim one intent';
  assert public.complete_notification_outbox(
    claimed_id, false, 'FCM_TEST_UNAVAILABLE', 30
  ), 'Failed Push must remain an independently recorded attempt';
  assert exists (select 1 from public.orders where id = md5('m9-order-1')::uuid),
    'Push failure must not roll back the business row';

  assert public.disable_push_token(
    'm9-device-token-customer-a-00000002', 'USER'
  ), 'Service dispatcher must safely disable a stale token';
  assert not (select enabled from public.user_push_tokens
    where token = 'm9-device-token-customer-a-00000002'),
    'Invalid token feedback must persist disabled state';
end;
$verify$;

rollback;
