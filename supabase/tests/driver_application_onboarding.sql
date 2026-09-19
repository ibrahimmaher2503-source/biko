-- Packet A onboarding contract; all fixtures are rolled back.
begin;
do $test$
declare
  customer_user uuid := '9a200000-0000-0000-0000-000000000001';
  staff_user uuid := '9a200000-0000-0000-0000-000000000002';
  active_user uuid := '9a200000-0000-0000-0000-000000000003';
  office_user uuid := '9a200000-0000-0000-0000-000000000004';
  office_id uuid := '9a200000-0000-0000-0000-000000000010';
  first_driver uuid;
  first_motorcycle uuid;
  retry_driver uuid;
  retry_motorcycle uuid;
begin
  insert into auth.users(id, email, raw_user_meta_data)
  values
    (customer_user, 'packet-a-customer@example.invalid', '{}'),
    (staff_user, 'packet-a-staff@example.invalid', '{}'),
    (active_user, 'packet-a-active@example.invalid', '{}'),
    (office_user, 'packet-a-office@example.invalid', '{}');

  update public.profiles
  set profile_type = 'STAFF'::public.profile_type
  where id = staff_user;

  insert into public.offices(id, name, status)
  values (office_id, 'Packet A Office', 'ACTIVE'::public.account_status);
  insert into public.drivers(
    user_id, driver_type, office_id, status, date_of_birth, is_online
  ) values (
    active_user, 'INDEPENDENT'::public.driver_type, null,
    'ACTIVE'::public.driver_status, (current_date - interval '30 years')::date, false
  ), (
    office_user, 'OFFICE_DRIVER'::public.driver_type, office_id,
    'PENDING'::public.driver_status, (current_date - interval '30 years')::date, false
  );

  assert not has_function_privilege(
    'anon',
    'public.submit_independent_driver_application(text,text,date,text,text,text,text,integer)',
    'EXECUTE'
  ), 'anon must not execute onboarding RPC';
  assert (select p.prosecdef and 'search_path=""' = any(p.proconfig)
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname = 'submit_independent_driver_application'),
    'onboarding RPC must use a definer with an empty search_path';
  assert (select
      length(lower(p.prosrc)) - length(replace(lower(p.prosrc), 'for update', ''))
        >= length('for update') * 2
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = 'submit_motorcycle_document'),
    'motorcycle document registration must lock Driver then Motorcycle';

  set local role anon;
  begin
    perform public.submit_independent_driver_application(
      'Anon', '01012345678', (current_date - interval '30 years')::date,
      'A 1', 'Honda', 'CG', 'Red', 2022
    );
    raise exception 'anon onboarding call unexpectedly succeeded';
  exception when insufficient_privilege then
    null;
  end;
  reset role;

  perform set_config('request.jwt.claim.sub', customer_user::text, true);
  set local role authenticated;
  select driver_id, motorcycle_id
  into first_driver, first_motorcycle
  from public.submit_independent_driver_application(
    'مستخدم بيكو', '01012345678', (current_date - interval '30 years')::date,
    'أ ب ج 123', 'Honda', 'CG', 'أحمر', 2022
  );
  reset role;

  assert (select profile_type = 'DRIVER'::public.profile_type
    from public.profiles where id = customer_user),
    'active CUSTOMER application must become DRIVER';
  assert (select count(*) = 1 from public.drivers
    where id = first_driver and user_id = customer_user
      and driver_type = 'INDEPENDENT'::public.driver_type
      and status = 'PENDING'::public.driver_status
      and date_of_birth = (current_date - interval '30 years')::date),
    'application must create one pending independent Driver with DOB';
  assert (select count(*) = 1 from public.motorcycles
    where id = first_motorcycle and driver_id = first_driver
      and status = 'INACTIVE'::public.motorcycle_status
      and verification_status = 'PENDING'::public.document_status),
    'application must create one pending Motorcycle';
  assert (select count(*) = 1 from public.drivers where user_id = customer_user),
    'application must keep one Driver identity';
  assert (select count(*) = 1 from public.motorcycles where driver_id = first_driver),
    'application must keep one Motorcycle row';

  perform set_config('request.jwt.claim.sub', customer_user::text, true);
  set local role authenticated;
  select driver_id, motorcycle_id
  into retry_driver, retry_motorcycle
  from public.submit_independent_driver_application(
    'مستخدم بيكو محدث', '01098765432', (current_date - interval '31 years')::date,
    'د هـ و 456', 'Yamaha', 'FZ', 'أسود', 2023
  );
  reset role;

  assert retry_driver = first_driver and retry_motorcycle = first_motorcycle,
    'retry must reuse the same Driver and Motorcycle IDs';
  assert (select count(*) = 1 from public.drivers where user_id = customer_user
    and date_of_birth = (current_date - interval '31 years')::date),
    'retry must update the pending Driver DOB';
  assert (select count(*) = 1 from public.motorcycles where driver_id = first_driver
    and plate_number = 'د هـ و 456' and brand = 'Yamaha'
    and verification_status = 'PENDING'::public.document_status),
    'retry must update the existing pending Motorcycle';

  insert into public.motorcycle_documents(
    motorcycle_id, document_type, file_path
  ) values (
    first_motorcycle, 'MOTORCYCLE_PHOTO', 'test/packet-a/motorcycle.jpg'
  );
  perform set_config('request.jwt.claim.sub', customer_user::text, true);
  set local role authenticated;
  begin
    perform public.submit_independent_driver_application(
      'مستخدم بيكو محدث', '01098765432', (current_date - interval '31 years')::date,
      'ز ح ط 789', 'Yamaha', 'FZ', 'أسود', 2023
    );
    raise exception 'document-backed Motorcycle identity was changed';
  exception when sqlstate 'P0001' then
    assert sqlerrm = 'Motorcycle details cannot change after documents are uploaded',
      'document-backed Motorcycle must return a deterministic error';
  end;
  reset role;
  assert (select plate_number = 'د هـ و 456'
    from public.motorcycles where id = first_motorcycle),
    'document-backed Motorcycle identity must remain unchanged';

  perform set_config('request.jwt.claim.sub', staff_user::text, true);
  set local role authenticated;
  begin
    perform public.submit_independent_driver_application(
      'Staff', '01012345678', (current_date - interval '30 years')::date,
      'S 1', 'Honda', 'CG', 'Red', 2022
    );
    raise exception 'STAFF onboarding unexpectedly succeeded';
  exception when sqlstate 'P0002' then
    null;
  end;
  reset role;
  assert (select count(*) = 0 from public.drivers where user_id = staff_user),
    'STAFF must not receive a Driver identity';

  perform set_config('request.jwt.claim.sub', active_user::text, true);
  set local role authenticated;
  begin
    perform public.submit_independent_driver_application(
      'Active', '01012345678', (current_date - interval '30 years')::date,
      'A 2', 'Honda', 'CB', 'Blue', 2022
    );
    raise exception 'ACTIVE Driver was changed';
  exception when sqlstate 'P0001' then
    assert sqlerrm = 'Driver application cannot be changed in its current status',
      'ACTIVE Driver must return a deterministic status error';
  end;
  reset role;
  assert (select status = 'ACTIVE'::public.driver_status
    and date_of_birth = (current_date - interval '30 years')::date
    from public.drivers d where d.user_id = active_user),
    'ACTIVE Driver must remain unchanged';

  perform set_config('request.jwt.claim.sub', office_user::text, true);
  set local role authenticated;
  begin
    perform public.submit_independent_driver_application(
      'Office', '01012345678', (current_date - interval '30 years')::date,
      'O 1', 'Honda', 'CG', 'White', 2022
    );
    raise exception 'Office Driver was changed';
  exception when sqlstate 'P0001' then
    assert sqlerrm = 'Independent Driver application is not available for this account',
      'Office Driver must return a deterministic type error';
  end;
  reset role;
  assert (select driver_type = 'OFFICE_DRIVER'::public.driver_type
    and d.office_id = '9a200000-0000-0000-0000-000000000010'::uuid
    from public.drivers d where d.user_id = office_user),
    'Office Driver ownership must remain unchanged';
end;
$test$;
select 'PASS' as result, array[
  'anon denial',
  'CUSTOMER to DRIVER pending application with DOB',
  'idempotent Driver and Motorcycle retry',
  'document-backed Motorcycle identity protection',
  'STAFF denial',
  'ACTIVE and Office Driver protection'
] as verified;
rollback;
