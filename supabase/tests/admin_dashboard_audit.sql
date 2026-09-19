-- ADM-05 focused contract. Fixtures and audit rows roll back with the test transaction.
begin;
set local statement_timeout = '60s';

do $test$
declare
  admin_user uuid := 'a0500000-0000-4000-8000-000000000001';
  verifier_user uuid := 'a0500000-0000-4000-8000-000000000002';
  driver_user uuid := 'a0500000-0000-4000-8000-000000000003';
  driver_pk uuid := 'a0500000-0000-4000-8000-000000000004';
  motorcycle_pk uuid := 'a0500000-0000-4000-8000-000000000005';
  driver_doc_pk uuid := 'a0500000-0000-4000-8000-000000000006';
  motorcycle_doc_pk uuid := 'a0500000-0000-4000-8000-000000000007';
  order_pk uuid := 'a0500000-0000-4000-8000-000000000008';
  offer_pk uuid := 'a0500000-0000-4000-8000-000000000009';
  ride_service uuid;
  audit_count integer;
begin
  assert to_regclass('public.audit_logs') is not null,
    'ADM-05 audit table must exist';
  assert (select c.relrowsecurity from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relname = 'audit_logs'),
    'Audit table must have RLS enabled';
  assert not has_table_privilege(
    'authenticated', 'public.audit_logs', 'select,insert,update,delete'
  ), 'Authenticated clients must not directly access audit rows';
  assert has_table_privilege('service_role', 'public.audit_logs', 'select'),
    'Operations service must be able to read audit rows';
  assert not has_function_privilege(
    'authenticated', 'private.record_admin_audit(text,text,uuid,text,jsonb,jsonb,jsonb)', 'execute'
  ), 'Clients must not execute the generic audit recorder';
  assert not exists (
    select 1 from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'private'
      and p.proname in ('record_admin_audit', 'prevent_audit_log_mutation')
      and coalesce(array_to_string(p.proconfig, ','), '') not like '%search_path=%'
  ), 'Audit security-definer helpers must pin search_path';

  insert into auth.users (id, email, raw_user_meta_data) values
    (admin_user, 'adm05-admin@example.invalid', '{}'),
    (verifier_user, 'adm05-verifier@example.invalid', '{}'),
    (driver_user, 'adm05-driver@example.invalid', '{}');
  update public.profiles
  set profile_type = case when id = driver_user then 'DRIVER'::public.profile_type
                          else 'STAFF'::public.profile_type end,
      status = 'ACTIVE'::public.account_status
  where id in (admin_user, verifier_user, driver_user);
  insert into public.user_roles (user_id, role_id)
  select admin_user, id from public.roles where code = 'SUPER_ADMIN';
  insert into public.user_roles (user_id, role_id)
  select verifier_user, id from public.roles where code = 'VERIFICATION_AGENT';

  insert into public.drivers (
    id, user_id, driver_type, status, date_of_birth, is_online
  ) values (
    driver_pk, driver_user, 'INDEPENDENT', 'PENDING', date '1990-01-01', false
  );
  insert into public.motorcycles (
    id, driver_id, plate_number, brand, model, color, status, verification_status
  ) values (
    motorcycle_pk, driver_pk, 'ADM05-1', 'Test', 'One', 'Black', 'INACTIVE', 'PENDING'
  );
  insert into public.driver_documents (
    id, driver_id, document_type, file_path, status, expiry_date, is_current
  ) values (
    driver_doc_pk, driver_pk, 'NATIONAL_ID', 'private/adm05/document.pdf',
    'PENDING', null, true
  );
  insert into public.motorcycle_documents (
    id, motorcycle_id, document_type, file_path, status, is_current
  ) values (
    motorcycle_doc_pk, motorcycle_pk, 'MOTORCYCLE_PHOTO', 'private/adm05/photo.jpg',
    'PENDING', true
  );
  select id into ride_service from public.service_types where code = 'RIDE';
  insert into public.orders (
    id, customer_id, service_type_id, pickup_lat, pickup_lng,
    destination_lat, destination_lng, pickup_address, destination_address,
    proposed_price, status
  ) values (
    order_pk, driver_user, ride_service, 30.044400, 31.235700,
    30.054400, 31.235700, 'ADM05 pickup', 'ADM05 destination',
    80, 'BIDDING'
  );
  set local session_replication_role = replica;
  insert into public.offers (
    id, order_id, driver_id, offered_price, status
  ) values (
    offer_pk, order_pk, driver_pk, 80, 'SELECTED'
  );
  update public.orders set
    driver_id = driver_pk,
    selected_offer_id = offer_pk,
    agreed_price = 80,
    assigned_at = clock_timestamp(),
    motorcycle_id = motorcycle_pk,
    status = 'DRIVER_ON_WAY'
  where id = order_pk;
  set local session_replication_role = origin;

  perform set_config('request.jwt.claim.sub', verifier_user::text, true);
  set local role authenticated;
  perform public.review_driver_document(driver_doc_pk, 'REJECTED', 'Unreadable identity');
  perform public.review_motorcycle_document(motorcycle_doc_pk, 'REJECTED', 'Photo is unclear');
  reset role;

  assert (select status = 'REJECTED' and rejection_reason = 'Unreadable identity'
    from public.driver_documents where id = driver_doc_pk),
    'Verification agent must review driver documents';
  assert (select status = 'REJECTED' and rejection_reason = 'Photo is unclear'
    from public.motorcycle_documents where id = motorcycle_doc_pk),
    'Verification agent must review motorcycle documents';
  assert (select count(*) = 2 from public.audit_logs
    where actor_user_id = verifier_user and action in (
      'DRIVER_DOCUMENT_REVIEW', 'MOTORCYCLE_DOCUMENT_REVIEW'
    )), 'Each review must write one unified audit row';
  assert not exists (
    select 1 from public.audit_logs
    where actor_user_id = verifier_user
      and (old_value::text ilike '%file_path%' or new_value::text ilike '%file_path%')
  ), 'Audit snapshots must not include document paths';
  assert (select bool_and(reason is not null and length(reason) > 0)
    from public.audit_logs where actor_user_id = verifier_user),
    'Rejected reviews must retain a reason';

  perform set_config('request.jwt.claim.sub', verifier_user::text, true);
  set local role authenticated;
  begin
    perform public.review_driver_verification(
      driver_pk, 'SUSPENDED', date '1990-01-01', null
    );
    raise exception 'Suspension without a reason was accepted';
  exception when sqlstate '22023' then null;
  end;
  reset role;
  assert (select status = 'PENDING' from public.drivers where id = driver_pk),
    'Failed suspension must not change the driver';
  assert (select count(*) = 2 from public.audit_logs
    where actor_user_id = verifier_user),
    'Failed mutation must not leave a success audit row';
  set local role authenticated;
  perform public.review_driver_verification(
    driver_pk, 'SUSPENDED', date '1990-01-01', 'Policy hold'
  );
  reset role;
  assert (select status = 'SUSPENDED' and verification_rejection_reason = 'Policy hold'
    from public.drivers where id = driver_pk),
    'Suspension must persist its reason';
  assert (select count(*) = 3 from public.audit_logs
    where actor_user_id = verifier_user),
    'Suspension must write one audit row';

  perform set_config('request.jwt.claim.sub', admin_user::text, true);
  set local role authenticated;
  perform public.admin_safety_override(order_pk, 'ARRIVE_RIDE', 'Safety correction');
  reset role;
  assert (select status = 'DRIVER_ARRIVED' from public.orders where id = order_pk),
    'Super Admin override must preserve the named lifecycle transition';
  assert (select count(*) = 1 and max(reason) = 'Safety correction'
    from public.audit_logs
    where action = 'SAFETY_OVERRIDE' and entity_id = order_pk),
    'Safety override must write a reasoned unified audit row';
  assert not exists (
    select 1 from public.audit_logs
    where action = 'SAFETY_OVERRIDE'
      and (old_value::text ilike '%code%' or new_value::text ilike '%code%')
  ), 'Safety override snapshots must not include confirmation secrets';

  perform set_config('request.jwt.claim.sub', driver_user::text, true);
  set local role authenticated;
  begin
    perform public.review_driver_document(driver_doc_pk, 'APPROVED', null);
    raise exception 'Driver was allowed to review a document';
  exception when insufficient_privilege then null;
  end;
  reset role;
  assert (select count(*) = 4 from public.audit_logs),
    'Unauthorized review must not create an audit row';
  assert not has_table_privilege(
    'authenticated', 'public.audit_logs', 'insert,update,delete'
  ), 'Audit table must remain client-DML protected';
end;
$test$;

rollback;
