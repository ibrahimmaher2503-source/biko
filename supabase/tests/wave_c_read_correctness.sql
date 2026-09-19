-- Deep Code Review Wave C only. Development fixtures are transactionally rolled back.
begin;
set local statement_timeout = '20s';

do $test$
declare
  customer_a uuid := '8a330000-0000-0000-0000-000000000001';
  customer_b uuid := '8a330000-0000-0000-0000-000000000002';
  driver_user uuid := '8a330000-0000-0000-0000-000000000003';
  office_id uuid := '8a330000-0000-0000-0000-000000000011';
  driver_pk uuid := '8a330000-0000-0000-0000-000000000021';
  service_id uuid;
  complete_one uuid;
  complete_two uuid;
  cancelled_order uuid;
  expired_order uuid;
  visible_order uuid;
  active_job uuid;
  offer_id uuid;
  visible_offer uuid;
  active_job_offer uuid;
begin
  insert into auth.users (id, email, raw_user_meta_data) values
    (customer_a, 'wave-c-customer-a@example.invalid', '{}'),
    (customer_b, 'wave-c-customer-b@example.invalid', '{}'),
    (driver_user, 'wave-c-driver@example.invalid', '{}');

  update public.profiles
  set profile_type = 'DRIVER'::public.profile_type,
      full_name = 'Wave C Driver Private Name',
      phone = 'private-wave-c-phone'
  where id = driver_user;

  insert into public.offices (id, name)
  values (office_id, 'Wave C Office');

  insert into public.drivers (
    id, user_id, driver_type, office_id, status, is_online
  ) values (
    driver_pk, driver_user, 'OFFICE_DRIVER', office_id, 'ACTIVE', true
  );

  select id into service_id
  from public.service_types
  where code = 'RIDE';

  perform set_config('request.jwt.claim.sub', customer_a::text, true);
  set local role authenticated;
  select id into complete_one from public.create_order(
    service_id, 30, 31, 'Wave C complete 1', 30.1, 31.1, 'Destination', 80,
    p_creation_intent_id => gen_random_uuid()
  );
  select id into complete_two from public.create_order(
    service_id, 30, 31, 'Wave C complete 2', 30.1, 31.1, 'Destination', 81,
    p_creation_intent_id => gen_random_uuid()
  );
  select id into cancelled_order from public.create_order(
    service_id, 30, 31, 'Wave C cancelled', 30.1, 31.1, 'Destination', 82,
    p_creation_intent_id => gen_random_uuid()
  );
  select id into expired_order from public.create_order(
    service_id, 30, 31, 'Wave C expired', 30.1, 31.1, 'Destination', 83,
    p_creation_intent_id => gen_random_uuid()
  );
  select id into visible_order from public.create_order(
    service_id, 30, 31, 'Wave C visible', 30.1, 31.1, 'Destination', 84,
    p_creation_intent_id => gen_random_uuid()
  );
  select id into active_job from public.create_order(
    service_id, 30, 31, 'Wave C active job', 30.1, 31.1, 'Destination', 85,
    p_creation_intent_id => gen_random_uuid()
  );
  reset role;

  insert into public.order_driver_candidates (order_id, driver_id) values
    (complete_one, driver_pk),
    (complete_two, driver_pk),
    (cancelled_order, driver_pk),
    (visible_order, driver_pk),
    (active_job, driver_pk);

  -- First successful completion increments once; a stale repeat cannot increment.
  perform set_config('request.jwt.claim.sub', driver_user::text, true);
  set local role authenticated;
  select id into offer_id from public.submit_offer(complete_one, 90.50);
  perform set_config('request.jwt.claim.sub', customer_a::text, true);
  perform public.accept_offer(complete_one, offer_id);
  perform set_config('request.jwt.claim.sub', driver_user::text, true);
  perform public.driver_on_way(complete_one);
  perform public.driver_arrived(complete_one);
  perform public.start_order(complete_one);
  perform public.complete_order(complete_one);
  reset role;
  assert (select completed_trip_count = 1 from public.drivers where id = driver_pk),
    'CR-010 first completion must increment once';

  set local role authenticated;
  begin
    perform public.complete_order(complete_one);
    raise exception 'CR-010 stale completion was accepted';
  exception when sqlstate 'P0001' then
    if sqlerrm <> 'Order is not in the expected state' then raise; end if;
  end;
  reset role;
  assert (select completed_trip_count = 1 from public.drivers where id = driver_pk),
    'CR-010 rejected repeat must not increment';

  -- A second independent completion produces an exact count of two.
  set local role authenticated;
  perform public.set_driver_online(true);
  select id into offer_id from public.submit_offer(complete_two, 91.50);
  perform set_config('request.jwt.claim.sub', customer_a::text, true);
  perform public.accept_offer(complete_two, offer_id);
  perform set_config('request.jwt.claim.sub', driver_user::text, true);
  perform public.driver_on_way(complete_two);
  perform public.driver_arrived(complete_two);
  perform public.start_order(complete_two);
  perform public.complete_order(complete_two);
  reset role;
  assert (
    select d.completed_trip_count = 2
      and count(o.id) filter (where o.status = 'COMPLETED'::public.order_status) = 2
    from public.drivers d
    left join public.orders o on o.driver_id = d.id
    where d.id = driver_pk
    group by d.completed_trip_count
  ), 'CR-010 stored and actual completion counts must both equal two';

  -- Driver cancellation and order expiry are terminal but never completed.
  perform set_config('request.jwt.claim.sub', driver_user::text, true);
  set local role authenticated;
  perform public.set_driver_online(true);
  select id into offer_id from public.submit_offer(cancelled_order, 92.50);
  perform set_config('request.jwt.claim.sub', customer_a::text, true);
  perform public.accept_offer(cancelled_order, offer_id);
  perform set_config('request.jwt.claim.sub', driver_user::text, true);
  perform public.driver_cancel_order(cancelled_order, 'Wave C cancellation');
  reset role;

  update public.orders
  set bidding_expires_at = now() - interval '1 second'
  where id = expired_order;
  set local role service_role;
  perform public.expire_order(expired_order);
  reset role;
  assert (select completed_trip_count = 2 from public.drivers where id = driver_pk),
    'CR-010 cancelled and expired orders must not increment';
  assert (select status = 'CANCELLED' from public.orders where id = cancelled_order),
    'cancel fixture must remain CANCELLED';
  assert (select status = 'EXPIRED' from public.orders where id = expired_order),
    'expiry fixture must remain EXPIRED';

  -- One eligible offer is visible through the unchanged compact projection.
  perform set_config('request.jwt.claim.sub', driver_user::text, true);
  set local role authenticated;
  perform public.set_driver_online(true);
  select id into visible_offer from public.submit_offer(visible_order, 105.50);
  perform set_config('request.jwt.claim.sub', customer_a::text, true);
  assert (select count(*) = 1 from public.get_customer_order_offers(visible_order)),
    'CR-026 eligible offer must be visible';
  assert (
    select count(distinct key_name) = 8
      and bool_and(key_name = any(array[
        'offer_id', 'offered_price', 'driver_public_id', 'driver_first_name',
        'driver_photo_url', 'driver_type', 'office_display_name',
        'completed_trip_count'
      ]::text[]))
    from public.get_customer_order_offers(visible_order) offer_row
    cross join lateral jsonb_object_keys(to_jsonb(offer_row)) keys(key_name)
  ), 'CR-026 privacy-safe offer projection must remain exact';
  assert (
    select completed_trip_count = 2
    from public.get_customer_order_offers(visible_order)
  ), 'CR-010 reconciled count must be published';

  perform set_config('request.jwt.claim.sub', customer_b::text, true);
  assert (select count(*) = 0 from public.get_customer_order_offers(visible_order)),
    'CR-026 another customer must not see offers';
  reset role;

  -- Offline offers stay ACTIVE, are filtered, fail write-time acceptance, then reappear.
  perform set_config('request.jwt.claim.sub', driver_user::text, true);
  set local role authenticated;
  perform public.set_driver_online(false);
  perform set_config('request.jwt.claim.sub', customer_a::text, true);
  assert (select count(*) = 0 from public.get_customer_order_offers(visible_order)),
    'CR-026 offline Driver offer must be filtered';
  begin
    perform public.accept_offer(visible_order, visible_offer);
    raise exception 'CR-026 offline Driver offer was accepted';
  exception when insufficient_privilege then
    if sqlerrm <> 'Offer driver is no longer eligible' then raise; end if;
  end;
  reset role;
  assert (select status = 'ACTIVE' from public.offers where id = visible_offer),
    'CR-026 offline filtering must not mutate the offer';

  perform set_config('request.jwt.claim.sub', driver_user::text, true);
  set local role authenticated;
  perform public.set_driver_online(true);
  perform set_config('request.jwt.claim.sub', customer_a::text, true);
  assert (select count(*) = 1 from public.get_customer_order_offers(visible_order)),
    'CR-026 offer must reappear when Driver returns online';
  reset role;

  -- Candidate, Driver, profile, and office eligibility are independently enforced.
  delete from public.order_driver_candidates
  where order_id = visible_order and driver_id = driver_pk;
  set local role authenticated;
  assert (select count(*) = 0 from public.get_customer_order_offers(visible_order)),
    'CR-026 noncandidate offer must be filtered';
  reset role;
  insert into public.order_driver_candidates (order_id, driver_id)
  values (visible_order, driver_pk);

  update public.drivers
  set status = 'SUSPENDED', is_online = false
  where id = driver_pk;
  set local role authenticated;
  assert (select count(*) = 0 from public.get_customer_order_offers(visible_order)),
    'CR-026 suspended Driver must be filtered';
  reset role;
  update public.drivers
  set status = 'ACTIVE', is_online = true
  where id = driver_pk;

  update public.profiles set status = 'SUSPENDED' where id = driver_user;
  set local role authenticated;
  assert (select count(*) = 0 from public.get_customer_order_offers(visible_order)),
    'CR-026 suspended Driver profile must be filtered';
  reset role;
  update public.profiles set status = 'ACTIVE' where id = driver_user;

  update public.offices set status = 'SUSPENDED' where id = office_id;
  set local role authenticated;
  assert (select count(*) = 0 from public.get_customer_order_offers(visible_order)),
    'CR-026 suspended office must be filtered';
  reset role;
  update public.offices set status = 'ACTIVE' where id = office_id;

  -- Preserve an ACTIVE stale offer to isolate the active-job read predicate.
  perform set_config('request.jwt.claim.sub', driver_user::text, true);
  set local role authenticated;
  select id into active_job_offer from public.submit_offer(active_job, 106.50);
  perform set_config('request.jwt.claim.sub', customer_a::text, true);
  perform public.accept_offer(active_job, active_job_offer);
  reset role;
  update public.offers set status = 'ACTIVE' where id = visible_offer;
  update public.drivers set is_online = true where id = driver_pk;
  set local role authenticated;
  assert (select count(*) = 0 from public.get_customer_order_offers(visible_order)),
    'CR-026 active-job Driver offer must be filtered';
  reset role;
  assert (select status = 'ACTIVE' from public.offers where id = visible_offer),
    'CR-026 active-job filtering must not mutate the offer';
  assert (select completed_trip_count = 2 from public.drivers where id = driver_pk),
    'non-completion transitions must preserve the completed count';

  assert not has_function_privilege(
    'anon', 'public.get_customer_order_offers(uuid)', 'EXECUTE'
  ), 'CR-026 anon execute must remain denied';
  assert has_function_privilege(
    'authenticated', 'public.get_customer_order_offers(uuid)', 'EXECUTE'
  ), 'CR-026 authenticated execute must remain explicit';
  assert not has_function_privilege(
    'authenticated',
    'private.advance_order_state(uuid,public.order_status,public.order_status)',
    'EXECUTE'
  ), 'CR-010 private lifecycle boundary must not be client executable';
  assert not exists (
    select 1
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where (n.nspname, p.proname) in (
      ('private', 'advance_order_state'),
      ('public', 'get_customer_order_offers')
    )
      and (not p.prosecdef or not ('search_path=""' = any(p.proconfig)))
  ), 'Wave C SECURITY DEFINER functions require an empty search_path';
end;
$test$;

select 'PASS' as result, array[
  'CR-010 exact 1/2 completion counts, stale repeat denial, cancellation/expiry exclusion',
  'CR-026 eligible/offline/candidate/account/office/active-job filtering and write-time recheck',
  'customer ownership, compact privacy projection, changed-function grants/search_path'
] as verified;

rollback;
