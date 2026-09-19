-- ADM-04 rollback proof. Run after the migration as the Development setup role.
-- No fixture survives the final rollback.
begin;
set local statement_timeout = '30s';

do $test$
declare
  super_admin uuid := 'a4040000-0000-4000-8000-000000000001';
  operations uuid := 'a4040000-0000-4000-8000-000000000002';
  support uuid := 'a4040000-0000-4000-8000-000000000003';
  verifier uuid := 'a4040000-0000-4000-8000-000000000004';
  accountant uuid := 'a4040000-0000-4000-8000-000000000005';
  dispatcher uuid := 'a4040000-0000-4000-8000-000000000006';
  customer uuid := 'a4040000-0000-4000-8000-000000000007';
  other_customer uuid := 'a4040000-0000-4000-8000-000000000008';
  driver_user uuid := 'a4040000-0000-4000-8000-000000000009';
  office_driver_a_user uuid := 'a4040000-0000-4000-8000-00000000000a';
  office_driver_b_user uuid := 'a4040000-0000-4000-8000-00000000000b';
  office_a uuid := 'a4040000-0000-4000-8000-000000000021';
  office_b uuid := 'a4040000-0000-4000-8000-000000000022';
  driver_independent uuid := 'a4040000-0000-4000-8000-000000000031';
  driver_a uuid := 'a4040000-0000-4000-8000-000000000032';
  driver_b uuid := 'a4040000-0000-4000-8000-000000000033';
  motorcycle_independent uuid := 'a4040000-0000-4000-8000-000000000041';
  motorcycle_a uuid := 'a4040000-0000-4000-8000-000000000042';
  motorcycle_b uuid := 'a4040000-0000-4000-8000-000000000043';
  document_independent uuid := 'a4040000-0000-4000-8000-000000000051';
  document_a uuid := 'a4040000-0000-4000-8000-000000000052';
  motorcycle_document_independent uuid := 'a4040000-0000-4000-8000-000000000061';
  motorcycle_document_a uuid := 'a4040000-0000-4000-8000-000000000062';
  independent_order uuid := 'a4040000-0000-4000-8000-000000000071';
  office_order_a uuid := 'a4040000-0000-4000-8000-000000000072';
  office_order_b uuid := 'a4040000-0000-4000-8000-000000000073';
  office_offer_a uuid := 'a4040000-0000-4000-8000-000000000075';
  office_offer_b uuid := 'a4040000-0000-4000-8000-000000000076';
  service_id uuid;
  context jsonb;
  function_name text;
  row_count integer;
begin
  insert into auth.users (id, email, raw_user_meta_data) values
    (super_admin, 'adm04-super@example.invalid', '{}'),
    (operations, 'adm04-operations@example.invalid', '{}'),
    (support, 'adm04-support@example.invalid', '{}'),
    (verifier, 'adm04-verifier@example.invalid', '{}'),
    (accountant, 'adm04-accountant@example.invalid', '{}'),
    (dispatcher, 'adm04-dispatcher@example.invalid', '{}'),
    (customer, 'adm04-customer@example.invalid', '{}'),
    (other_customer, 'adm04-other-customer@example.invalid', '{}'),
    (driver_user, 'adm04-driver@example.invalid', '{}'),
    (office_driver_a_user, 'adm04-driver-a@example.invalid', '{}'),
    (office_driver_b_user, 'adm04-driver-b@example.invalid', '{}');

  update public.profiles
  set profile_type = case
    when id in (driver_user, office_driver_a_user, office_driver_b_user)
      then 'DRIVER'::public.profile_type
    when id in (super_admin, operations, support, verifier, accountant, dispatcher)
      then 'STAFF'::public.profile_type
    else 'CUSTOMER'::public.profile_type
  end
  where id in (
    super_admin, operations, support, verifier, accountant, dispatcher,
    customer, other_customer, driver_user, office_driver_a_user, office_driver_b_user
  );

  insert into public.offices (id, name) values
    (office_a, 'ADM-04 Office A'),
    (office_b, 'ADM-04 Office B');

  insert into public.user_roles (user_id, role_id)
  select super_admin, id from public.roles where code = 'SUPER_ADMIN'
  union all
  select operations, id from public.roles where code = 'PLATFORM_OPERATIONS'
  union all
  select support, id from public.roles where code = 'SUPPORT_AGENT'
  union all
  select verifier, id from public.roles where code = 'VERIFICATION_AGENT';

  insert into public.office_members (office_id, user_id, role_id)
  select office_a, accountant, id from public.roles where code = 'OFFICE_ACCOUNTANT'
  union all
  select office_b, dispatcher, id from public.roles where code = 'OFFICE_DISPATCHER';

  insert into public.drivers (id, user_id, driver_type, office_id, status)
  values
    (driver_independent, driver_user, 'INDEPENDENT', null, 'ACTIVE'),
    (driver_a, office_driver_a_user, 'OFFICE_DRIVER', office_a, 'ACTIVE'),
    (driver_b, office_driver_b_user, 'OFFICE_DRIVER', office_b, 'ACTIVE');

  insert into public.motorcycles (
    id, driver_id, office_id, plate_number, brand, model, color, status,
    verification_status
  ) values
    (motorcycle_independent, driver_independent, null, 'ADM04-IND', 'Honda', 'CB', 'Black', 'ACTIVE', 'PENDING'),
    (motorcycle_a, driver_a, office_a, 'ADM04-A', 'Honda', 'CB', 'Blue', 'ACTIVE', 'PENDING'),
    (motorcycle_b, driver_b, office_b, 'ADM04-B', 'Honda', 'CB', 'Red', 'ACTIVE', 'PENDING');

  insert into public.driver_documents (
    id, driver_id, document_type, file_path, status, is_current
  ) values
    (document_independent, driver_independent, 'NATIONAL_ID', driver_independent || '/driver/NATIONAL_ID/a.pdf', 'PENDING', true),
    (document_a, driver_a, 'NATIONAL_ID', driver_a || '/driver/NATIONAL_ID/a.pdf', 'PENDING', true);
  insert into public.motorcycle_documents (
    id, motorcycle_id, document_type, file_path, status, is_current
  ) values
    (motorcycle_document_independent, motorcycle_independent, 'MOTORCYCLE_PHOTO', driver_independent || '/motorcycle/' || motorcycle_independent || '/MOTORCYCLE_PHOTO/a.jpg', 'PENDING', true),
    (motorcycle_document_a, motorcycle_a, 'MOTORCYCLE_PHOTO', driver_a || '/motorcycle/' || motorcycle_a || '/MOTORCYCLE_PHOTO/a.jpg', 'PENDING', true);

  select id into service_id from public.service_types where code = 'RIDE';
  insert into public.orders (
    id, customer_id, service_type_id, pickup_lat, pickup_lng, pickup_address,
    destination_lat, destination_lng, destination_address, proposed_price,
    office_id, status
  ) values
    (independent_order, other_customer, service_id, 30, 31, 'ADM04 independent', 30.1, 31.1, 'ADM04 destination', 100, null, 'BIDDING'),
    (office_order_a, other_customer, service_id, 30, 31, 'ADM04 A', 30.1, 31.1, 'ADM04 destination', 100, null, 'BIDDING'),
    (office_order_b, other_customer, service_id, 30, 31, 'ADM04 B', 30.1, 31.1, 'ADM04 destination', 100, null, 'BIDDING');
  set local session_replication_role = replica;
  insert into public.offers (id, order_id, driver_id, office_id, offered_price, status)
  values
    (office_offer_a, office_order_a, driver_a, office_a, 100, 'SELECTED'),
    (office_offer_b, office_order_b, driver_b, office_b, 100, 'SELECTED');
  update public.orders
  set driver_id = driver_a, selected_offer_id = office_offer_a,
      agreed_price = 100, assigned_at = clock_timestamp(), office_id = office_a,
      motorcycle_id = motorcycle_a, status = 'DRIVER_ASSIGNED'
  where id = office_order_a;
  update public.orders
  set driver_id = driver_b, selected_offer_id = office_offer_b,
      agreed_price = 100, assigned_at = clock_timestamp(), office_id = office_b,
      motorcycle_id = motorcycle_b, status = 'DRIVER_ASSIGNED'
  where id = office_order_b;
  set local session_replication_role = origin;

  assert exists (select 1 from public.roles where code = 'PLATFORM_OPERATIONS' and scope_type = 'PLATFORM'),
    'Operations role is seeded as platform scope';
  assert exists (select 1 from public.roles where code = 'SUPPORT_AGENT' and scope_type = 'PLATFORM'),
    'Support role is seeded as platform scope';
  assert exists (select 1 from public.roles where code = 'VERIFICATION_AGENT' and scope_type = 'PLATFORM'),
    'Verification role is seeded as platform scope';
  assert exists (
    select 1
    from public.role_permissions rp
    join public.roles r on r.id = rp.role_id and r.code = 'VERIFICATION_AGENT'
    join public.permissions p on p.id = rp.permission_id and p.code = 'motorcycles.verify'
  ), 'Verification motorcycle permission is explicit';
  assert not exists (
    select 1
    from public.role_permissions rp
    join public.roles r on r.id = rp.role_id
    join public.permissions p on p.id = rp.permission_id
    where r.code in ('PLATFORM_OPERATIONS', 'SUPPORT_AGENT', 'VERIFICATION_AGENT')
      and p.code = 'orders.override'
  ), 'Safety override is not granted by baseline platform roles';

  perform set_config('request.jwt.claim.sub', operations::text, true);
  set local role authenticated;
  assert private.has_platform_permission('orders.view'), 'Operations orders permission';
  assert private.has_platform_permission('drivers.view'), 'Operations driver permission';
  assert not private.has_platform_permission('drivers.verify'), 'Operations cannot verify';
  context := public.get_dashboard_context();
  assert context->>'staff' = 'true'
    and context->'platform_roles' @> '[{"code":"PLATFORM_OPERATIONS"}]'::jsonb,
    'Operations context is bounded to the active staff role';
  select count(*) into row_count from public.drivers where id in (driver_independent, driver_a, driver_b);
  assert row_count = 3, 'Operations sees independent and office drivers';
  select count(*) into row_count from public.motorcycles where id in (motorcycle_independent, motorcycle_a, motorcycle_b);
  assert row_count = 3, 'Operations sees independent and office motorcycles';
  select count(*) into row_count from public.driver_documents where id in (document_independent, document_a);
  assert row_count = 2, 'Operations sees bounded driver-document metadata';
  select count(*) into row_count from public.orders where id in (independent_order, office_order_a, office_order_b);
  assert row_count = 3, 'Operations sees independent and office orders';
  select count(distinct order_id) into row_count from public.order_events where order_id in (independent_order, office_order_a, office_order_b);
  assert row_count = 3, 'Operations sees order timelines';
  reset role;

  perform set_config('request.jwt.claim.sub', support::text, true);
  set local role authenticated;
  assert private.has_platform_permission('users.view'), 'Support user permission';
  assert not private.has_platform_permission('motorcycles.view'), 'Support has no motorcycle permission';
  select count(*) into row_count from public.profiles where id in (customer, driver_user, office_driver_a_user);
  assert row_count = 3, 'Support sees platform user profiles';
  select count(*) into row_count from public.offices;
  assert row_count = 0, 'Support does not gain office rows from dashboard.view';
  begin
    perform public.review_driver_document(document_independent, 'REJECTED', 'support must fail');
    raise exception 'Support reviewer unexpectedly accepted';
  exception when insufficient_privilege then null;
  end;
  begin
    perform public.admin_safety_override(independent_order, 'ARRIVE_RIDE', 'support must fail');
    raise exception 'Support safety override unexpectedly accepted';
  exception when insufficient_privilege then null;
  end;
  reset role;

  perform set_config('request.jwt.claim.sub', verifier::text, true);
  set local role authenticated;
  assert private.has_platform_permission('drivers.verify'), 'Verification driver permission';
  assert private.has_platform_permission('motorcycles.verify'), 'Verification motorcycle permission';
  assert not private.has_platform_permission('users.view'), 'Verification cannot view all users';
  select count(*) into row_count from public.drivers where id in (driver_independent, driver_a, driver_b);
  assert row_count = 3, 'Verification sees independent and office drivers';
  select count(*) into row_count from public.profiles where id in (customer, driver_user, office_driver_a_user);
  assert row_count = 2, 'Verification sees driver profiles only';
  select count(*) into row_count from public.motorcycle_documents
    where id in (motorcycle_document_independent, motorcycle_document_a);
  assert row_count = 2, 'Verification sees independent and office motorcycle evidence';
  perform public.review_driver_document(document_independent, 'REJECTED', 'verification fixture');
  reset role;

  perform set_config('request.jwt.claim.sub', accountant::text, true);
  set local role authenticated;
  assert private.can_access_office(office_a, 'orders.view'), 'Accountant can access Office A';
  assert not private.can_access_office(office_b, 'orders.view'), 'Accountant cannot access Office B';
  select count(*) into row_count from public.orders where id in (independent_order, office_order_a, office_order_b);
  assert row_count = 1, 'Accountant sees only the exact membership office';
  select count(*) into row_count from public.drivers where id in (driver_independent, driver_a, driver_b);
  assert row_count = 0, 'Accountant has no drivers.view permission';
  select count(*) into row_count from public.order_events where order_id in (independent_order, office_order_a, office_order_b);
  assert row_count = 1, 'Accountant timeline scope is office-bound';
  reset role;

  perform set_config('request.jwt.claim.sub', dispatcher::text, true);
  set local role authenticated;
  select count(*) into row_count from public.orders where id in (independent_order, office_order_a, office_order_b);
  assert row_count = 1, 'Dispatcher sees only Office B orders';
  reset role;

  perform set_config('request.jwt.claim.sub', customer::text, true);
  set local role authenticated;
  context := public.get_dashboard_context();
  assert context->>'staff' = 'false' and context->'platform_roles' = '[]'::jsonb,
    'Customer has no dashboard context';
  assert not private.has_platform_permission('orders.view'), 'Customer cannot use platform helper';
  select count(*) into row_count from public.drivers where id in (driver_independent, driver_a, driver_b);
  assert row_count = 0, 'Customer cannot read platform drivers';
  reset role;

  perform set_config('request.jwt.claim.sub', driver_user::text, true);
  set local role authenticated;
  assert not private.has_platform_permission('drivers.view'), 'Driver cannot use platform helper';
  select count(*) into row_count from public.drivers where id in (driver_independent, driver_a, driver_b);
  assert row_count = 1, 'Driver sees only own driver row';
  select count(*) into row_count from public.orders where id in (independent_order, office_order_a, office_order_b);
  assert row_count = 0, 'Unassigned Driver cannot read dashboard orders';
  reset role;

  update public.profiles set status = 'SUSPENDED'::public.account_status where id = operations;
  perform set_config('request.jwt.claim.sub', operations::text, true);
  set local role authenticated;
  assert not private.has_platform_permission('orders.view'), 'Suspended platform account denied';
  assert not private.is_super_admin(), 'Suspended role cannot become Super Admin';
  select count(*) into row_count from public.orders where id in (independent_order, office_order_a, office_order_b);
  assert row_count = 0, 'Suspended platform account sees no orders';
  reset role;

  assert not exists (
    select 1 from storage.buckets where id = 'driver-documents' and public
  ), 'Driver evidence bucket remains private';
  assert exists (
    select 1 from pg_policies
    where schemaname = 'storage' and tablename = 'objects'
      and policyname = 'driver_documents_storage_select_own'
      and qual ilike '%drivers.verify%'
      and qual ilike '%motorcycles.verify%'
  ), 'Storage read policy is reviewer-scoped';
  assert not has_table_privilege('authenticated', 'public.order_events', 'INSERT,UPDATE,DELETE'),
    'Timeline remains read-only to clients';
  foreach function_name in array array[
    'private.has_platform_permission(text)',
    'private.is_super_admin()',
    'private.has_permission(text)',
    'private.can_access_office(uuid,text)',
    'public.get_dashboard_context()',
    'public.review_driver_document(uuid,public.document_status,text)',
    'public.review_motorcycle_document(uuid,public.document_status,text)',
    'public.review_motorcycle(uuid,public.document_status,text)',
    'public.review_driver_verification(uuid,public.driver_status,date,text)',
    'public.admin_safety_override(uuid,text,text)'
  ] loop
    assert not has_function_privilege('anon', function_name, 'EXECUTE'), 'Anonymous execute denied: ' || function_name;
    assert has_function_privilege('authenticated', function_name, 'EXECUTE'), 'Authenticated execute retained: ' || function_name;
  end loop;
  assert not exists (
    select 1
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname in ('private', 'public')
      and p.proname in (
        'is_super_admin', 'has_platform_permission', 'has_permission',
        'is_office_member', 'can_access_office', 'get_dashboard_context',
        'review_driver_document', 'review_motorcycle_document',
        'review_motorcycle', 'review_driver_verification', 'admin_safety_override'
      )
      and (not p.prosecdef or not ('search_path=""' = any (p.proconfig)))
  ), 'Changed privileged functions use a fixed empty search_path';
end;
$test$;

rollback;
select 'PASS' as result, array[
  'platform roles and least-privilege permission seeds',
  'active STAFF platform helper and bounded dashboard context',
  'independent and office RLS scope',
  'verification RPC and private Storage read scope',
  'customer, driver, cross-office, suspended-account denials',
  'all fixtures rolled back'
] as checks;
