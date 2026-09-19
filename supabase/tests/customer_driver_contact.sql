-- Contact read security contract. Fixtures roll back.
begin;

do $test$
declare
  customer_a uuid := '8b500000-0000-0000-0000-000000000001';
  customer_b uuid := '8b500000-0000-0000-0000-000000000002';
  driver_user uuid := '8b500000-0000-0000-0000-000000000003';
  driver_id uuid := '8b500000-0000-0000-0000-000000000004';
  order_id uuid;
  service_id uuid;
begin
  insert into auth.users(id, email, raw_user_meta_data) values
    (customer_a, 'contact-a@example.invalid', '{}'),
    (customer_b, 'contact-b@example.invalid', '{}'),
    (driver_user, 'contact-driver@example.invalid', '{}');
  select id into service_id from public.service_types where code = 'RIDE';
  update public.profiles set
    full_name = case when id = driver_user then 'Driver One' else 'Customer' end,
    phone = case when id = driver_user then '+201001234567' end,
    profile_type = case when id = driver_user
      then 'DRIVER'::public.profile_type else 'CUSTOMER'::public.profile_type end,
    status = 'ACTIVE'::public.account_status
  where id in (customer_a, customer_b, driver_user);
  insert into public.drivers(id, user_id, driver_type, status, is_online)
  values (driver_id, driver_user, 'INDEPENDENT', 'ACTIVE', false);
  insert into public.orders(
    customer_id, service_type_id, pickup_lat, pickup_lng, pickup_address,
    destination_lat, destination_lng, destination_address, proposed_price,
    driver_id, status
  ) values (
    customer_a, service_id, 30, 31, 'Pickup', 30.1, 31.1, 'Destination', 80,
    driver_id, 'DRIVER_ASSIGNED'
  ) returning id into order_id;

  perform set_config('request.jwt.claim.sub', customer_a::text, true);
  set local role authenticated;
  assert (select driver_phone = '+201001234567'
    from public.get_customer_active_driver_contact(order_id)),
    'Owner receives only the active assigned driver contact';
  reset role;

  perform set_config('request.jwt.claim.sub', customer_b::text, true);
  set local role authenticated;
  assert not exists (
    select 1 from public.get_customer_active_driver_contact(order_id)
  ), 'Non-owner cannot read driver contact';
  reset role;

  update public.orders set status = 'COMPLETED' where id = order_id;
  perform set_config('request.jwt.claim.sub', customer_a::text, true);
  set local role authenticated;
  assert not exists (
    select 1 from public.get_customer_active_driver_contact(order_id)
  ), 'Terminal orders cannot read driver contact';
  reset role;

  update public.orders set status = 'BIDDING', driver_id = null where id = order_id;
  perform set_config('request.jwt.claim.sub', customer_a::text, true);
  set local role authenticated;
  assert not exists (
    select 1 from public.get_customer_active_driver_contact(order_id)
  ), 'Pre-assignment orders cannot read driver contact';
  reset role;

  assert has_function_privilege(
    'authenticated',
    'public.get_customer_active_driver_contact(uuid)',
    'execute'
  ), 'Authenticated customers can call the narrow contact RPC';
  assert not has_function_privilege(
    'anon',
    'public.get_customer_active_driver_contact(uuid)',
    'execute'
  ), 'Anonymous callers cannot call the contact RPC';
end;
$test$;

rollback;
