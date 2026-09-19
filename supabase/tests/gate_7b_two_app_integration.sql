-- Gate 7B only: current User + Driver core integration. All fixtures roll back.
begin;
set local statement_timeout = '45s';

do $gate$
declare
  customer_a uuid := '8b7b0000-0000-0000-0000-000000000001';
  customer_b uuid := '8b7b0000-0000-0000-0000-000000000002';
  driver_user_a uuid := '8b7b0000-0000-0000-0000-000000000003';
  driver_user_b uuid := '8b7b0000-0000-0000-0000-000000000004';
  driver_a uuid := '8b7b0000-0000-0000-0000-000000000013';
  driver_b uuid := '8b7b0000-0000-0000-0000-000000000014';
  ride_service uuid;
  delivery_service uuid;
  stable_intent uuid := '8b7b0000-0000-4000-8000-000000000021';
  happy_order uuid;
  recovered_order uuid;
  multi_order uuid;
  withdraw_order uuid;
  book_again_order uuid;
  cross_order_a uuid;
  cross_order_b uuid;
  bidding_cancel_order uuid;
  on_way_cancel_order uuid;
  arrived_cancel_order uuid;
  delivery_order uuid;
  stale_order uuid;
  happy_offer uuid;
  multi_offer_a uuid;
  multi_offer_b uuid;
  withdrawn_offer uuid;
  replacement_offer uuid;
  cross_offer_a uuid;
  cross_offer_b uuid;
  action_offer uuid;
  delivery_offer uuid;
  stale_offer uuid;
  created public.orders;
  hint_text text;
begin
  insert into auth.users (id, email, raw_user_meta_data) values
    (customer_a, 'gate-7b-customer-a@example.invalid', '{}'),
    (customer_b, 'gate-7b-customer-b@example.invalid', '{}'),
    (driver_user_a, 'gate-7b-driver-a@example.invalid', '{}'),
    (driver_user_b, 'gate-7b-driver-b@example.invalid', '{}');

  update public.profiles
  set full_name = case id
        when customer_a then 'Gate 7B Customer Private'
        when customer_b then 'Gate 7B Customer B'
        when driver_user_a then 'Ahmed Driver Private'
        else 'Bassem Driver Private'
      end,
      phone = case
        when id = customer_a then 'private-customer-phone'
        when id in (driver_user_a, driver_user_b) then 'private-driver-phone'
        else null
      end,
      profile_photo_url = case
        when id in (driver_user_a, driver_user_b) then 'https://example.invalid/public-driver.jpg'
        else null
      end,
      profile_type = case
        when id in (driver_user_a, driver_user_b) then 'DRIVER'::public.profile_type
        else 'CUSTOMER'::public.profile_type
      end
  where id in (customer_a, customer_b, driver_user_a, driver_user_b);

  insert into public.drivers (id, user_id, driver_type, status, is_online) values
    (driver_a, driver_user_a, 'INDEPENDENT', 'ACTIVE', true),
    (driver_b, driver_user_b, 'INDEPENDENT', 'ACTIVE', true);

  select id into ride_service from public.service_types where code = 'RIDE';
  select id into delivery_service from public.service_types where code = 'DELIVERY';
  assert ride_service is not null and delivery_service is not null,
    'Gate 7B requires enabled Ride and Delivery services';

  -- Scenario 1: stable User create, Driver candidate/read/offer, Customer select.
  perform set_config('request.jwt.claim.sub', customer_a::text, true);
  set local role authenticated;
  select * into created from public.create_order(
    ride_service, 30, 31, 'Gate 7B Happy Pickup',
    30.1, 31.1, 'Gate 7B Happy Destination', 80,
    p_creation_intent_id => stable_intent
  );
  happy_order := created.id;
  assert created.status = 'BIDDING' and created.bidding_expires_at is not null,
    'Ride must persist as BIDDING with a server deadline';
  assert extract(epoch from (created.bidding_expires_at - clock_timestamp())) between 88 and 91,
    'Ride bidding deadline must be approximately 90 seconds';
  select id into recovered_order from public.create_order(
    ride_service, 30.0, 31.00, 'Gate 7B Happy Pickup',
    30.10, 31.10, 'Gate 7B Happy Destination', 80.0,
    p_creation_intent_id => stable_intent
  );
  assert recovered_order = happy_order, 'Stable creation intent must recover one logical order';
  reset role;
  assert (select count(*) = 1 from public.orders
    where customer_id = customer_a and creation_intent_id = stable_intent),
    'Stable intent must create exactly one row';
  assert (select count(*) = 1 from public.order_events
    where order_id = happy_order and event_type = 'BIDDING'),
    'Stable intent must create one initial event';

  insert into public.order_driver_candidates (order_id, driver_id)
  values (happy_order, driver_a);

  perform set_config('request.jwt.claim.sub', driver_user_a::text, true);
  set local role authenticated;
  assert (select count(*) = 1 from public.get_driver_requests()
    where id = happy_order), 'Eligible Driver must see the Ride request';
  assert not exists (
    select 1 from public.get_driver_requests() request_row
    where request_row.id = happy_order
      and to_jsonb(request_row) ?| array[
        'customer_id', 'customer_name', 'phone', 'full_name',
        'recipient_name', 'recipient_phone', 'parcel_weight_kg', 'declared_value'
      ]
  ), 'Preselection Driver projection must exclude Customer and Delivery privacy fields';
  select id into happy_offer from public.submit_offer(happy_order, 90);

  perform set_config('request.jwt.claim.sub', customer_a::text, true);
  assert (select count(*) = 1 from public.get_customer_order_offers(happy_order)),
    'Customer must see the Driver offer';
  assert (
    select driver_public_id = driver_a and driver_first_name = 'Ahmed'
      and offered_price = 90 and completed_trip_count = 0
    from public.get_customer_order_offers(happy_order)
  ), 'Offer card must contain the correct public Driver identity and price';
  assert (
    select count(distinct key_name) = 8 and bool_and(key_name = any(array[
      'offer_id', 'offered_price', 'driver_public_id', 'driver_first_name',
      'driver_photo_url', 'driver_type', 'office_display_name', 'completed_trip_count'
    ]::text[]))
    from public.get_customer_order_offers(happy_order) offer_row
    cross join lateral jsonb_object_keys(to_jsonb(offer_row)) keys(key_name)
  ), 'Customer offer projection must remain compact and privacy-safe';
  perform public.accept_offer(happy_order, happy_offer);
  reset role;

  assert (select status = 'DRIVER_ASSIGNED' and driver_id = driver_a
      and selected_offer_id = happy_offer and agreed_price = 90
    from public.orders where id = happy_order), 'Selection must atomically assign the chosen Driver';
  assert (select status = 'SELECTED' from public.offers where id = happy_offer),
    'Winning offer must be SELECTED';
  assert (select not is_online from public.drivers where id = driver_a),
    'Assigned Driver must be unavailable for new work';
  assert (select count(*) = 1 from public.order_events
    where order_id = happy_order and event_type = 'DRIVER_ASSIGNED'),
    'Assignment must create exactly one assignment event';

  -- Scenario 5/6/12: ownership, lifecycle, and both authoritative restore reads.
  perform set_config('request.jwt.claim.sub', customer_a::text, true);
  set local role authenticated;
  begin
    perform public.driver_on_way(happy_order);
    raise exception 'Customer mutated Driver lifecycle';
  exception when insufficient_privilege then
    assert sqlerrm = 'Only the assigned driver can perform this action';
  end;
  perform set_config('request.jwt.claim.sub', driver_user_b::text, true);
  begin
    perform public.driver_on_way(happy_order);
    raise exception 'Another Driver mutated the assigned trip';
  exception when insufficient_privilege then
    assert sqlerrm = 'Only the assigned driver can perform this action';
  end;

  perform set_config('request.jwt.claim.sub', driver_user_a::text, true);
  perform public.driver_on_way(happy_order);
  perform set_config('request.jwt.claim.sub', customer_a::text, true);
  assert (select status = 'DRIVER_ON_WAY' and agreed_price = 90
      and selected_offer_id = happy_offer from public.orders where id = happy_order),
    'Customer refresh must observe DRIVER_ON_WAY and preserved assignment';
  perform set_config('request.jwt.claim.sub', driver_user_a::text, true);
  assert (select count(*) = 1 from public.get_driver_requests(happy_order)
    where status = 'DRIVER_ON_WAY'), 'Driver restore read must observe DRIVER_ON_WAY';
  perform public.driver_arrived(happy_order);
  perform set_config('request.jwt.claim.sub', customer_a::text, true);
  assert (select status = 'DRIVER_ARRIVED' from public.orders where id = happy_order),
    'Customer refresh must observe DRIVER_ARRIVED';
  perform set_config('request.jwt.claim.sub', driver_user_a::text, true);
  assert (select count(*) = 1 from public.get_driver_requests(happy_order)
    where status = 'DRIVER_ARRIVED'), 'Driver restore read must observe DRIVER_ARRIVED';
  perform public.start_order(happy_order);
  perform set_config('request.jwt.claim.sub', customer_a::text, true);
  assert (select status = 'IN_PROGRESS' from public.orders where id = happy_order),
    'Customer refresh must observe IN_PROGRESS';
  perform set_config('request.jwt.claim.sub', driver_user_a::text, true);
  assert (select count(*) = 1 from public.get_driver_requests(happy_order)
    where status = 'IN_PROGRESS'), 'Driver restore read must observe IN_PROGRESS';
  perform public.complete_order(happy_order);
  reset role;
  assert (select status = 'COMPLETED' and agreed_price = 90
      and selected_offer_id = happy_offer from public.orders where id = happy_order),
    'Lifecycle must finish COMPLETED without changing assignment';
  assert (select completed_trip_count = 1 from public.drivers where id = driver_a),
    'Completion count must increment exactly once';

  perform set_config('request.jwt.claim.sub', driver_user_a::text, true);
  set local role authenticated;
  perform public.set_driver_online(true);

  -- Scenario 2/8: two offers, public counts, selected/losing closure, Driver cancel propagation.
  perform set_config('request.jwt.claim.sub', customer_a::text, true);
  select id into multi_order from public.create_order(
    ride_service, 30, 31, 'Gate 7B Multi Pickup',
    30.1, 31.1, 'Gate 7B Multi Destination', 82,
    p_creation_intent_id => gen_random_uuid()
  );
  reset role;
  insert into public.order_driver_candidates (order_id, driver_id) values
    (multi_order, driver_a), (multi_order, driver_b);
  perform set_config('request.jwt.claim.sub', driver_user_a::text, true);
  set local role authenticated;
  select id into multi_offer_a from public.submit_offer(multi_order, 92);
  perform set_config('request.jwt.claim.sub', driver_user_b::text, true);
  select id into multi_offer_b from public.submit_offer(multi_order, 88);
  perform set_config('request.jwt.claim.sub', customer_a::text, true);
  assert (select count(*) = 2 and count(distinct driver_public_id) = 2
      and min(offered_price) = 88 and max(offered_price) = 92
    from public.get_customer_order_offers(multi_order)),
    'Customer must see two distinct selectable Driver offers with correct prices';
  assert (select bool_or(driver_public_id = driver_a and completed_trip_count = 1)
      and bool_or(driver_public_id = driver_b and completed_trip_count = 0)
    from public.get_customer_order_offers(multi_order)),
    'Offer cards must publish current completed-trip counts';
  perform public.accept_offer(multi_order, multi_offer_b);
  reset role;
  assert (select status = 'SELECTED' from public.offers where id = multi_offer_b),
    'Chosen multiple-offer winner must be SELECTED';
  assert (select status = 'CLOSED' from public.offers where id = multi_offer_a),
    'Losing same-order offer must be CLOSED';
  assert (select count(*) = 1 from public.order_events
    where order_id = multi_order and event_type = 'DRIVER_ASSIGNED'),
    'Multiple-offer selection must assign exactly once';
  perform set_config('request.jwt.claim.sub', driver_user_a::text, true);
  set local role authenticated;
  assert (select status = 'CLOSED' from public.get_driver_offer(multi_order)
    where id = multi_offer_a), 'Losing Driver refresh must have no actionable offer';
  perform set_config('request.jwt.claim.sub', driver_user_b::text, true);
  perform public.driver_cancel_order(multi_order, 'Gate 7B Driver cancellation');
  reset role;
  assert (select status = 'CANCELLED' and cancellation_type = 'DRIVER_CANCEL'
    from public.orders where id = multi_order), 'Driver cancellation must remain terminal CANCELLED';
  assert (select metadata->>'cancellation_type' = 'DRIVER_CANCEL'
    from public.order_events where order_id = multi_order and event_type = 'CANCELLED'),
    'Driver cancellation event must retain useful classification';
  perform set_config('request.jwt.claim.sub', customer_a::text, true);
  set local role authenticated;
  assert (select status = 'CANCELLED' from public.orders where id = multi_order),
    'Customer refresh must observe Driver cancellation';
  perform set_config('request.jwt.claim.sub', driver_user_b::text, true);
  perform public.set_driver_online(true);

  -- Scenario 3/9/10/12: withdraw, ownership, resubmit, authoritative expiry, Book Again.
  perform set_config('request.jwt.claim.sub', customer_a::text, true);
  select id into withdraw_order from public.create_order(
    ride_service, 30, 31, 'Gate 7B Repeat Pickup',
    30.1, 31.1, 'Gate 7B Repeat Destination', 84,
    p_creation_intent_id => gen_random_uuid()
  );
  reset role;
  insert into public.order_driver_candidates (order_id, driver_id)
  values (withdraw_order, driver_a);
  perform set_config('request.jwt.claim.sub', driver_user_a::text, true);
  set local role authenticated;
  select id into withdrawn_offer from public.submit_offer(withdraw_order, 94);
  perform set_config('request.jwt.claim.sub', driver_user_b::text, true);
  begin
    perform public.withdraw_offer(withdrawn_offer);
    raise exception 'Another Driver withdrew Driver A offer';
  exception when insufficient_privilege then
    assert sqlerrm = 'Only the offer driver can withdraw it';
  end;
  perform set_config('request.jwt.claim.sub', customer_b::text, true);
  assert (select count(*) = 0 from public.orders where id = withdraw_order),
    'Customer B must not read Customer A active order';
  assert (select count(*) = 0 from public.get_customer_order_offers(withdraw_order)),
    'Customer B must not read Customer A offers';
  begin
    perform public.cancel_order(withdraw_order);
    raise exception 'Customer B cancelled Customer A order';
  exception when insufficient_privilege then
    assert sqlerrm = 'Only the order customer can cancel it';
  end;
  begin
    perform public.accept_offer(withdraw_order, withdrawn_offer);
    raise exception 'Customer B accepted Customer A offer';
  exception when insufficient_privilege then
    assert sqlerrm = 'Only the order customer can accept an offer';
  end;
  perform set_config('request.jwt.claim.sub', driver_user_a::text, true);
  perform public.withdraw_offer(withdrawn_offer);
  assert (select status = 'WITHDRAWN' from public.get_driver_offer(withdraw_order)
    where id = withdrawn_offer), 'Withdrawn offer must be non-actionable';
  perform set_config('request.jwt.claim.sub', customer_a::text, true);
  assert (select count(*) = 0 from public.get_customer_order_offers(withdraw_order)),
    'Customer refresh must not present a withdrawn offer';
  perform set_config('request.jwt.claim.sub', driver_user_a::text, true);
  select id into replacement_offer from public.submit_offer(withdraw_order, 96);
  assert replacement_offer <> withdrawn_offer, 'Resubmit must create a new offer ID';
  reset role;
  assert (select count(*) = 1 from public.offers
    where order_id = withdraw_order and driver_id = driver_a and status = 'ACTIVE'),
    'Driver/Order must retain exactly one ACTIVE offer';

  update public.orders
  set bidding_expires_at = clock_timestamp() - interval '1 second'
  where id = withdraw_order;
  perform set_config('request.jwt.claim.sub', customer_a::text, true);
  set local role authenticated;
  perform public.expire_customer_order(withdraw_order);
  reset role;
  assert (select status = 'EXPIRED' from public.orders where id = withdraw_order),
    'Elapsed BIDDING order must become EXPIRED from authoritative server truth';
  assert (select status = 'CLOSED' from public.offers where id = replacement_offer),
    'Expiry must close the active offer';
  perform set_config('request.jwt.claim.sub', driver_user_a::text, true);
  set local role authenticated;
  assert (select count(*) = 0 from public.get_driver_requests()
    where id = withdraw_order), 'Expired request must not remain actionable';
  assert (select order_status = 'EXPIRED' and status = 'CLOSED'
    from public.get_driver_offer(withdraw_order) where id = replacement_offer),
    'Driver waiting truth must reconcile to EXPIRED/CLOSED';
  perform set_config('request.jwt.claim.sub', customer_a::text, true);
  select id into book_again_order from public.create_order(
    ride_service, 30, 31, 'Gate 7B Repeat Pickup',
    30.1, 31.1, 'Gate 7B Repeat Destination', 84,
    p_creation_intent_id => gen_random_uuid()
  );
  assert book_again_order <> withdraw_order, 'Book Again must create a genuinely new order';
  perform public.cancel_order(book_again_order);
  reset role;
  assert (select status = 'EXPIRED' from public.orders where id = withdraw_order),
    'Book Again must not reopen the terminal order';

  -- Scenario 4/7: cross-order offer closure and assigned Customer cancellation.
  perform set_config('request.jwt.claim.sub', customer_a::text, true);
  set local role authenticated;
  select id into cross_order_a from public.create_order(
    ride_service, 30, 31, 'Gate 7B Cross A', 30.1, 31.1, 'Cross A Destination', 86,
    p_creation_intent_id => gen_random_uuid()
  );
  select id into cross_order_b from public.create_order(
    ride_service, 30, 31, 'Gate 7B Cross B', 30.1, 31.1, 'Cross B Destination', 87,
    p_creation_intent_id => gen_random_uuid()
  );
  reset role;
  insert into public.order_driver_candidates (order_id, driver_id) values
    (cross_order_a, driver_a), (cross_order_b, driver_a);
  perform set_config('request.jwt.claim.sub', driver_user_a::text, true);
  set local role authenticated;
  select id into cross_offer_a from public.submit_offer(cross_order_a, 98);
  select id into cross_offer_b from public.submit_offer(cross_order_b, 99);
  assert (select count(*) = 2 from public.get_driver_active_offers()
    where id in (cross_offer_a, cross_offer_b)),
    'Driver may hold ACTIVE offers on two orders before assignment';
  perform set_config('request.jwt.claim.sub', customer_a::text, true);
  perform public.accept_offer(cross_order_a, cross_offer_a);
  reset role;
  assert (select status = 'DRIVER_ASSIGNED' and driver_id = driver_a
    from public.orders where id = cross_order_a), 'Cross-order winner must assign Order A';
  assert (select status = 'SELECTED' from public.offers where id = cross_offer_a),
    'Cross-order winner must be SELECTED';
  assert (select status = 'CLOSED' from public.offers where id = cross_offer_b),
    'Winning Driver cross-order offer must be CLOSED';
  assert (select status = 'BIDDING' and driver_id is null and selected_offer_id is null
    from public.orders where id = cross_order_b), 'Other order must remain BIDDING and unassigned';
  perform set_config('request.jwt.claim.sub', driver_user_a::text, true);
  set local role authenticated;
  assert (select count(*) = 0 from public.get_driver_requests()),
    'Assigned Driver must not remain an eligible new-work candidate';
  begin
    perform public.submit_offer(cross_order_b, 100);
    raise exception 'Assigned Driver submitted another offer';
  exception when sqlstate 'P0001' then
    assert sqlerrm = 'Driver already has an active assignment';
  end;
  begin
    perform public.set_driver_online(true);
    raise exception 'Assigned Driver became available';
  exception when sqlstate 'P0001' then
    get stacked diagnostics hint_text = pg_exception_hint;
    assert hint_text = 'لديك رحلة نشطة بالفعل.';
  end;
  perform set_config('request.jwt.claim.sub', customer_a::text, true);
  begin
    perform public.cancel_order(cross_order_a);
    raise exception 'Assigned Customer cancellation accepted without reason';
  exception when invalid_parameter_value then
    assert sqlerrm = 'Cancellation reason is required after driver assignment';
  end;
  perform public.cancel_order(cross_order_a, 'Gate 7B assigned cancellation');
  reset role;
  assert (select status = 'CANCELLED' and cancellation_type = 'CUSTOMER_CANCEL'
    from public.orders where id = cross_order_a),
    'Assigned Customer cancellation must be terminal and classified';
  assert (select status = 'BIDDING' from public.orders where id = cross_order_b),
    'Assigned cancellation must not rebid either existing order';
  perform set_config('request.jwt.claim.sub', driver_user_a::text, true);
  set local role authenticated;
  assert (select count(*) = 1 from public.get_driver_requests(cross_order_a)
    where status = 'CANCELLED'), 'Driver refresh must observe Customer cancellation';
  perform public.set_driver_online(true);

  -- Scenario 7: BIDDING, ON_WAY, ARRIVED propagation (IN_PROGRESS uses Delivery below).
  perform set_config('request.jwt.claim.sub', customer_a::text, true);
  select id into bidding_cancel_order from public.create_order(
    ride_service, 30, 31, 'Gate 7B Cancel Bidding', 30.1, 31.1, 'Cancel Bidding Dest', 88,
    p_creation_intent_id => gen_random_uuid()
  );
  perform public.cancel_order(bidding_cancel_order);
  reset role;
  assert (select status = 'CANCELLED' and cancellation_reason is null
    from public.orders where id = bidding_cancel_order),
    'BIDDING Customer cancellation must work without a reason';

  perform set_config('request.jwt.claim.sub', customer_a::text, true);
  set local role authenticated;
  select id into on_way_cancel_order from public.create_order(
    ride_service, 30, 31, 'Gate 7B Cancel On Way', 30.1, 31.1, 'Cancel On Way Dest', 89,
    p_creation_intent_id => gen_random_uuid()
  );
  reset role;
  insert into public.order_driver_candidates values (on_way_cancel_order, driver_a, clock_timestamp());
  perform set_config('request.jwt.claim.sub', driver_user_a::text, true);
  set local role authenticated;
  select id into action_offer from public.submit_offer(on_way_cancel_order, 100);
  perform set_config('request.jwt.claim.sub', customer_a::text, true);
  perform public.accept_offer(on_way_cancel_order, action_offer);
  perform set_config('request.jwt.claim.sub', driver_user_a::text, true);
  perform public.driver_on_way(on_way_cancel_order);
  perform set_config('request.jwt.claim.sub', customer_a::text, true);
  perform public.cancel_order(on_way_cancel_order, 'Gate 7B late on-way cancellation');
  reset role;
  assert (select status = 'CANCELLED' and cancellation_type = 'LATE_CANCEL'
    from public.orders where id = on_way_cancel_order),
    'DRIVER_ON_WAY Customer cancellation must be LATE_CANCEL';
  perform set_config('request.jwt.claim.sub', driver_user_a::text, true);
  set local role authenticated;
  assert (select count(*) = 1 from public.get_driver_requests(on_way_cancel_order)
    where status = 'CANCELLED'), 'Driver refresh must observe ON_WAY cancellation';
  perform public.set_driver_online(true);

  perform set_config('request.jwt.claim.sub', customer_a::text, true);
  select id into arrived_cancel_order from public.create_order(
    ride_service, 30, 31, 'Gate 7B Cancel Arrived', 30.1, 31.1, 'Cancel Arrived Dest', 90,
    p_creation_intent_id => gen_random_uuid()
  );
  reset role;
  insert into public.order_driver_candidates values (arrived_cancel_order, driver_a, clock_timestamp());
  perform set_config('request.jwt.claim.sub', driver_user_a::text, true);
  set local role authenticated;
  select id into action_offer from public.submit_offer(arrived_cancel_order, 101);
  perform set_config('request.jwt.claim.sub', customer_a::text, true);
  perform public.accept_offer(arrived_cancel_order, action_offer);
  perform set_config('request.jwt.claim.sub', driver_user_a::text, true);
  perform public.driver_on_way(arrived_cancel_order);
  perform public.driver_arrived(arrived_cancel_order);
  perform set_config('request.jwt.claim.sub', customer_a::text, true);
  perform public.cancel_order(arrived_cancel_order, 'Gate 7B late arrived cancellation');
  reset role;
  assert (select status = 'CANCELLED' and cancellation_type = 'LATE_CANCEL'
    from public.orders where id = arrived_cancel_order),
    'DRIVER_ARRIVED Customer cancellation must be LATE_CANCEL';
  perform set_config('request.jwt.claim.sub', driver_user_a::text, true);
  set local role authenticated;
  assert (select count(*) = 1 from public.get_driver_requests(arrived_cancel_order)
    where status = 'CANCELLED'), 'Driver refresh must observe ARRIVED cancellation';
  perform public.set_driver_online(true);

  -- Scenario 11/12: one Delivery through the same engine, privacy, restore, IN_PROGRESS denial.
  perform set_config('request.jwt.claim.sub', customer_a::text, true);
  select id into delivery_order from public.create_order(
    delivery_service, 30, 31, 'Gate 7B Delivery Pickup',
    30.1, 31.1, 'Gate 7B Delivery Destination', 110,
    'Recipient Gate', '01000000000', 8, 3000, gen_random_uuid()
  );
  reset role;
  assert (select service_types.code = 'DELIVERY'
    from public.orders join public.service_types on service_types.id = orders.service_type_id
    where orders.id = delivery_order), 'Delivery must remain DELIVERY';
  assert (select recipient_name = 'Recipient Gate' and recipient_phone = '01000000000'
      and parcel_weight_kg = 8 and declared_value = 3000
    from public.order_delivery_details where order_id = delivery_order),
    'Delivery details must persist for owned restoration and Book Again';
  insert into public.order_driver_candidates values (delivery_order, driver_a, clock_timestamp());

  perform set_config('request.jwt.claim.sub', customer_b::text, true);
  set local role authenticated;
  assert (select count(*) = 0 from public.order_delivery_details
    where order_id = delivery_order), 'Customer B must not read Customer A Delivery details';
  assert (select count(*) = 0 from public.orders where id = delivery_order),
    'Customer B must not read Customer A Delivery order';
  perform set_config('request.jwt.claim.sub', driver_user_a::text, true);
  assert not exists (
    select 1 from public.get_driver_requests() request_row
    where request_row.id = delivery_order
      and to_jsonb(request_row) ?| array[
        'recipient_name', 'recipient_phone', 'parcel_weight_kg', 'declared_value',
        'customer_id', 'phone', 'full_name'
      ]
  ), 'Delivery candidate projection must not leak private Customer/parcel data';
  assert (select count(*) = 0 from public.order_delivery_details
    where order_id = delivery_order), 'Preselection Driver must not read Delivery details';
  select id into delivery_offer from public.submit_offer(delivery_order, 120);
  perform set_config('request.jwt.claim.sub', customer_a::text, true);
  assert (select count(*) = 1 from public.get_customer_order_offers(delivery_order)),
    'Delivery Customer must see the privacy-safe offer';
  perform public.accept_offer(delivery_order, delivery_offer);
  perform set_config('request.jwt.claim.sub', driver_user_a::text, true);
  perform public.driver_on_way(delivery_order);
  perform public.driver_arrived(delivery_order);
  perform public.start_order(delivery_order);
  perform set_config('request.jwt.claim.sub', customer_a::text, true);
  begin
    perform public.cancel_order(delivery_order, 'Too late');
    raise exception 'IN_PROGRESS Customer cancellation succeeded';
  exception when sqlstate 'P0001' then
    assert sqlerrm = 'Order cannot be cancelled in its current state';
  end;
  assert (select status = 'IN_PROGRESS' from public.orders where id = delivery_order),
    'Rejected Customer cancellation must preserve IN_PROGRESS';
  perform set_config('request.jwt.claim.sub', driver_user_a::text, true);
  perform public.complete_order(delivery_order);
  reset role;
  assert (select status = 'COMPLETED' from public.orders where id = delivery_order),
    'Delivery core lifecycle must complete through the same engine';
  assert (select completed_trip_count = 2 from public.drivers where id = driver_a),
    'Ride and Delivery completion counts must each increment once';
  perform set_config('request.jwt.claim.sub', customer_a::text, true);
  set local role authenticated;
  assert (select count(*) = 1 from public.order_delivery_details
    where order_id = delivery_order and recipient_name = 'Recipient Gate'),
    'Delivery terminal read must retain Book Again prefill data for its owner';
  reset role;

  -- Scenario 15: offer becomes ineligible between refresh and selection.
  perform set_config('request.jwt.claim.sub', customer_a::text, true);
  set local role authenticated;
  select id into stale_order from public.create_order(
    ride_service, 30, 31, 'Gate 7B Stale Pickup', 30.1, 31.1, 'Stale Destination', 91,
    p_creation_intent_id => gen_random_uuid()
  );
  reset role;
  insert into public.order_driver_candidates values (stale_order, driver_b, clock_timestamp());
  perform set_config('request.jwt.claim.sub', driver_user_b::text, true);
  set local role authenticated;
  select id into stale_offer from public.submit_offer(stale_order, 102);
  perform set_config('request.jwt.claim.sub', customer_a::text, true);
  assert (select count(*) = 1 from public.get_customer_order_offers(stale_order)),
    'Customer must initially load the stale-test offer';
  perform set_config('request.jwt.claim.sub', driver_user_b::text, true);
  perform public.set_driver_online(false);
  perform set_config('request.jwt.claim.sub', customer_a::text, true);
  begin
    perform public.accept_offer(stale_order, stale_offer);
    raise exception 'Stale ineligible offer was accepted';
  exception when insufficient_privilege then
    assert sqlerrm = 'Offer driver is no longer eligible';
  end;
  assert (select status = 'BIDDING' and driver_id is null and selected_offer_id is null
    from public.orders where id = stale_order),
    'Stale rejection must not fabricate an assignment';
  assert (select count(*) = 0 from public.get_customer_order_offers(stale_order)),
    'Authoritative refresh must remove the ineligible offer';
  perform public.cancel_order(stale_order);

  -- Scenario 16 and representative security: both histories reflect the same rows.
  assert (select count(*) = 2 from public.orders
    where customer_id = customer_a and status = 'COMPLETED'
      and id in (happy_order, delivery_order)
      and pickup_address is not null and destination_address is not null
      and agreed_price is not null and created_at is not null),
    'Customer history truth must retain service route status price and date';
  assert (select status = 'EXPIRED' and proposed_price = 84
    from public.orders where id = withdraw_order),
    'Customer history must retain the expired Book Again source';
  perform set_config('request.jwt.claim.sub', customer_b::text, true);
  assert (select count(*) = 0 from public.orders
    where id in (happy_order, delivery_order, withdraw_order)),
    'Customer B history must exclude Customer A terminal orders';
  perform set_config('request.jwt.claim.sub', driver_user_a::text, true);
  assert (select count(*) = 2 from public.orders
    where id in (happy_order, delivery_order) and status = 'COMPLETED'
      and driver_id = driver_a and agreed_price is not null and created_at is not null),
    'Driver history truth must match the assigned completed jobs';
  perform set_config('request.jwt.claim.sub', driver_user_b::text, true);
  assert (select count(*) = 1 from public.orders
    where id = multi_order and status = 'CANCELLED' and driver_id = driver_b),
    'Driver history truth must include the assigned cancelled job';
  perform set_config('request.jwt.claim.sub', customer_a::text, true);
  begin
    update public.orders set proposed_price = 1 where id = happy_order;
    raise exception 'Direct client order write was allowed';
  exception when insufficient_privilege then null;
  end;
  reset role;

  assert not has_function_privilege('anon', 'public.accept_offer(uuid,uuid)', 'EXECUTE'),
    'Anon accept_offer execute must remain denied';
  assert not has_function_privilege('anon', 'public.submit_offer(uuid,numeric)', 'EXECUTE'),
    'Anon submit_offer execute must remain denied';
  assert not has_function_privilege('anon', 'public.expire_customer_order(uuid)', 'EXECUTE'),
    'Anon expiry reconciliation execute must remain denied';
  assert not has_table_privilege('authenticated', 'public.order_events', 'INSERT,UPDATE,DELETE'),
    'Normal clients must not mutate order_events';
end;
$gate$;

select 'PASS' as result, array[
  'Ride create/offer/select/lifecycle and authoritative Customer/Driver reads',
  'multiple offers, withdraw/resubmit, cross-order closure, one active job',
  'Customer and Driver cancellation propagation, expiry, Book Again',
  'Delivery core/privacy, ownership negatives, stale selection rejection',
  'consistent terminal histories, event recording, direct-write protection'
] as verified;

rollback;
