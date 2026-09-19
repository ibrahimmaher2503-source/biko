-- D05 rollback proof. All fixtures are removed by rollback.
begin;

do $test$
<<contact_test>>
declare
  customer_user uuid := 'd0500000-0000-0000-0000-000000000001';
  driver_user uuid := 'd0500000-0000-0000-0000-000000000002';
  driver_id uuid := 'd0500000-0000-0000-0000-000000000003';
  motorcycle_id uuid := 'd0500000-0000-0000-0000-000000000004';
  order_id uuid := 'd0500000-0000-4000-8000-000000000001';
  offer_id uuid := 'd0500000-0000-4000-8000-000000000002';
  service_id uuid;
  contact jsonb;
begin
  insert into auth.users (id, email, raw_user_meta_data)
  values
    (customer_user, 'd05-customer@example.invalid', '{}'),
    (driver_user, 'd05-driver@example.invalid', '{}');

  update public.profiles
  set full_name = case when id = customer_user then 'D05 Customer' else 'D05 Driver' end,
      phone = case when id = customer_user then '+201011111111' end,
      profile_type = case when id = customer_user
        then 'CUSTOMER'::public.profile_type else 'DRIVER'::public.profile_type end,
      status = 'ACTIVE'::public.account_status
  where id in (customer_user, driver_user);

  insert into public.drivers (
    id, user_id, driver_type, status, date_of_birth, is_online,
    ride_safety_equipment_confirmed_at
  ) values (
    driver_id, driver_user, 'INDEPENDENT', 'ACTIVE',
    (current_date - interval '25 years')::date, true, clock_timestamp()
  );
  insert into public.driver_documents (
    driver_id, document_type, file_path, status, expiry_date
  ) values
    (driver_id, 'NATIONAL_ID', 'd05/national-id', 'APPROVED', current_date + 365),
    (driver_id, 'DRIVING_LICENSE', 'd05/driving-license', 'APPROVED', current_date + 365),
    (driver_id, 'DRIVER_SELFIE', 'd05/selfie', 'APPROVED', current_date + 365);
  insert into public.motorcycles (
    id, driver_id, plate_number, brand, model, color, status, verification_status
  ) values (
    motorcycle_id, driver_id, 'D05-TEST', 'D05', 'Test', 'Black',
    'ACTIVE'::public.motorcycle_status, 'APPROVED'::public.document_status
  );
  insert into public.driver_latest_locations (
    driver_id, latitude, longitude, accuracy_meters, updated_at
  ) values (driver_id, 30.044400, 31.235700, 5, clock_timestamp());

  select id into service_id from public.service_types where code = 'RIDE';
  insert into public.orders (
    id, customer_id, service_type_id, pickup_lat, pickup_lng,
    destination_lat, destination_lng, pickup_address, destination_address,
    proposed_price, status
  ) values (
    order_id, customer_user, service_id, 30.044400, 31.235700,
    30.044400, 31.235700, 'D05 pickup', 'D05 destination', 80, 'BIDDING'
  );

  -- Pre-assignment must remain private even for the eventual Driver.
  perform set_config('request.jwt.claim.sub', driver_user::text, true);
  set local role authenticated;
  assert not exists (
    select 1 from public.get_driver_active_customer_contact(order_id)
  ), 'Pre-assignment orders cannot expose customer contact';
  reset role;

  insert into public.offers (id, order_id, driver_id, offered_price, status)
  values (offer_id, order_id, driver_id, 80, 'SELECTED');
  update public.orders
  set driver_id = contact_test.driver_id,
      selected_offer_id = contact_test.offer_id,
      agreed_price = 80,
      assigned_at = clock_timestamp(),
      status = 'DRIVER_ASSIGNED'::public.order_status
  where id = contact_test.order_id;

  perform set_config('request.jwt.claim.sub', driver_user::text, true);
  set local role authenticated;
  select to_jsonb(row_value) into contact
  from public.get_driver_active_customer_contact(order_id) row_value;
  assert contact = jsonb_build_object(
    'customer_name', 'D05 Customer',
    'customer_phone', '+201011111111'
  ), 'DRIVER_ASSIGNED exposes only the minimum customer contact fields';

  perform public.driver_on_way(order_id);
  select to_jsonb(row_value) into contact
  from public.get_driver_active_customer_contact(order_id) row_value;
  assert contact = jsonb_build_object(
    'customer_name', 'D05 Customer',
    'customer_phone', '+201011111111'
  ), 'DRIVER_ON_WAY exposes the minimum customer contact fields';

  perform public.driver_arrived(order_id);
  select to_jsonb(row_value) into contact
  from public.get_driver_active_customer_contact(order_id) row_value;
  assert contact = jsonb_build_object(
    'customer_name', 'D05 Customer',
    'customer_phone', '+201011111111'
  ), 'DRIVER_ARRIVED exposes the minimum customer contact fields';

  perform public.start_order(order_id);
  select to_jsonb(row_value) into contact
  from public.get_driver_active_customer_contact(order_id) row_value;
  assert contact = jsonb_build_object(
    'customer_name', 'D05 Customer',
    'customer_phone', '+201011111111'
  ), 'IN_PROGRESS exposes the minimum customer contact fields';

  assert (select count(*) = 2
      and bool_and(key_name = any(array['customer_name', 'customer_phone']::text[]))
    from public.get_driver_active_customer_contact(order_id) contact_row
    cross join lateral jsonb_object_keys(to_jsonb(contact_row)) keys(key_name)),
    'Contact projection must remain exactly two explicit fields';

  reset role;
  perform set_config('request.jwt.claim.sub', customer_user::text, true);
  set local role authenticated;
  assert not exists (
    select 1 from public.get_driver_active_customer_contact(order_id)
  ), 'Non-Driver callers cannot read customer contact';
  reset role;

  perform set_config('request.jwt.claim.sub', driver_user::text, true);
  set local role authenticated;
  perform public.complete_order(order_id);
  assert (select completed_at is not null from public.orders where id = order_id),
    'Terminal completion must use the trusted lifecycle metadata';
  assert not exists (
    select 1 from public.get_driver_active_customer_contact(order_id)
  ), 'Completed orders cannot expose customer contact';
  reset role;

  assert not has_function_privilege(
    'anon', 'public.get_driver_active_customer_contact(uuid)', 'EXECUTE'
  ), 'Anonymous callers cannot execute the contact RPC';
  assert has_function_privilege(
    'authenticated', 'public.get_driver_active_customer_contact(uuid)', 'EXECUTE'
  ), 'Authenticated Drivers can execute the contact RPC';
end;
$test$;

rollback;
