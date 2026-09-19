-- Wave A only. Run as the Development setup role. All fixtures roll back.
begin;
set local statement_timeout = '20s';

do $test$
declare
  staff uuid := '8a310000-0000-0000-0000-000000000001';
  du uuid := '8a310000-0000-0000-0000-000000000002';
  admin_user uuid := '8a310000-0000-0000-0000-000000000003';
  customer uuid := '8a310000-0000-0000-0000-000000000004';
  other_du uuid := '8a310000-0000-0000-0000-000000000005';
  office_a uuid := '8a310000-0000-0000-0000-000000000011';
  office_b uuid := '8a310000-0000-0000-0000-000000000012';
  driver_a uuid := '8a310000-0000-0000-0000-000000000021';
  driver_b uuid := '8a310000-0000-0000-0000-000000000022';
  doc_a uuid := '8a310000-0000-0000-0000-000000000031';
  doc_b uuid := '8a310000-0000-0000-0000-000000000032';
  service uuid; oa uuid; ob uuid; late_order uuid; completed_order uuid;
  fa uuid; fb uuid; other_offer uuid; late_offer uuid; completed_offer uuid;
  col text; next_status text; rejected_status text; detail text; row_count integer;
begin
  insert into auth.users(id,email,raw_user_meta_data) values
    (staff,'wave-a-staff@example.invalid','{}'),(du,'wave-a-driver@example.invalid','{}'),
    (admin_user,'wave-a-admin@example.invalid','{}'),(customer,'wave-a-customer@example.invalid','{}'),
    (other_du,'wave-a-other-driver@example.invalid','{}');
  update public.profiles set profile_type='STAFF' where id in (staff,admin_user);
  update public.profiles set profile_type='DRIVER' where id in (du,other_du);
  insert into public.offices(id,name) values (office_a,'Wave A'),(office_b,'Wave B');
  insert into public.office_members(office_id,user_id,role_id)
    select office_a,staff,id from public.roles where code='OFFICE_ACCOUNTANT'
    union all select office_b,staff,id from public.roles where code='OFFICE_DISPATCHER';
  insert into public.user_roles(user_id,role_id)
    select admin_user,id from public.roles where code='SUPER_ADMIN';
  insert into public.drivers(id,user_id,driver_type,office_id,status,is_online) values
    (driver_a,du,'OFFICE_DRIVER',office_a,'ACTIVE',true),
    (driver_b,other_du,'OFFICE_DRIVER',office_b,'ACTIVE',true);
  insert into public.driver_documents(id,driver_id,document_type,file_path) values
    (doc_a,driver_a,'wave-a-test','wave-a/private-a'),
    (doc_b,driver_b,'wave-a-test','wave-a/private-b');

  perform set_config('request.jwt.claim.sub',staff::text,true);
  set local role authenticated;
  assert private.is_office_member(office_a) and private.is_office_member(office_b), 'membership positives';
  assert private.can_access_office(office_a,'finance.view'), 'Accountant keeps own finance';
  assert not private.can_access_office(office_b,'finance.view'), 'finance cannot cross offices';
  assert private.has_permission('drivers.view'), 'metadata helper reports available permission';
  assert not private.can_access_office(office_a,'drivers.view'), 'CR-001 no role laundering';
  assert private.can_access_office(office_b,'drivers.view'), 'Dispatcher keeps own Driver access';
  assert (select count(*)=0 from public.driver_documents where id=doc_a), 'CR-001 A document denied';
  assert (select count(*)=1 from public.driver_documents where id=doc_b), 'CR-001 B document allowed';
  reset role;

  foreach rejected_status in array array['SUSPENDED','DELETED'] loop
    update public.profiles set status=rejected_status::public.account_status where id=staff;
    set local role authenticated;
    assert not private.is_office_member(office_b), 'CR-002 inactive staff membership denied';
    assert not private.has_permission('drivers.view'), 'CR-002 inactive staff permission denied';
    assert not private.can_access_office(office_b,'drivers.view'), 'CR-002 inactive staff scope denied';
    assert (select count(*)=0 from public.driver_documents where id in(doc_a,doc_b)), 'CR-002 inactive staff rows denied';
    reset role;
  end loop;
  update public.profiles set status='ACTIVE' where id=staff;
  update public.office_members set status='SUSPENDED' where user_id=staff and office_id=office_b;
  set local role authenticated;
  assert not private.is_office_member(office_b) and not private.has_permission('drivers.view'), 'inactive membership denied';
  reset role;
  update public.office_members set status='ACTIVE' where user_id=staff and office_id=office_b;
  update public.offices set status='SUSPENDED' where id=office_b;
  set local role authenticated;
  assert not private.is_office_member(office_b) and not private.has_permission('drivers.view'), 'CR-002 inactive office helpers denied';
  assert (select count(*)=0 from public.driver_documents where id=doc_b), 'CR-002 inactive office row denied';
  reset role;

  perform set_config('request.jwt.claim.sub',admin_user::text,true);
  set local role authenticated;
  assert private.is_super_admin() and private.can_access_office(office_b,'drivers.view'), 'active platform recovery access retained';
  assert (select count(*)=2 from public.driver_documents where id in(doc_a,doc_b)), 'active admin reads both offices';
  reset role;
  foreach rejected_status in array array['SUSPENDED','DELETED'] loop
    update public.profiles set status=rejected_status::public.account_status where id=admin_user;
    set local role authenticated;
    assert not private.is_super_admin() and not private.has_permission('roles.view'), 'CR-002 inactive admin helpers denied';
    assert (select count(*)=0 from public.driver_documents where id in(doc_a,doc_b)), 'CR-002 inactive admin rows denied';
    reset role;
  end loop;
  update public.offices set status='ACTIVE' where id=office_b;

  select id into service from public.service_types where code='RIDE';
  perform set_config('request.jwt.claim.sub',customer::text,true);
  set local role authenticated;
  select id into oa from public.create_order(service,30,31,'Wave A',30.1,31.1,'Destination',80,p_creation_intent_id => gen_random_uuid());
  select id into ob from public.create_order(service,30,31,'Wave B',30.1,31.1,'Destination',80,p_creation_intent_id => gen_random_uuid());
  select id into late_order from public.create_order(service,30,31,'Wave expiry',30.1,31.1,'Destination',80,p_creation_intent_id => gen_random_uuid());
  select id into completed_order from public.create_order(service,30,31,'Wave history',30.1,31.1,'Destination',80,p_creation_intent_id => gen_random_uuid());
  reset role;
  insert into public.order_driver_candidates(order_id,driver_id) values
    (oa,driver_a),(ob,driver_a),(late_order,driver_a),(late_order,driver_b),
    (oa,driver_b),(completed_order,driver_b);
  perform set_config('request.jwt.claim.sub',du::text,true);
  set local role authenticated;
  select id into fa from public.submit_offer(oa,90);
  select id into fb from public.submit_offer(ob,91);
  select id into late_offer from public.submit_offer(late_order,92);
  perform set_config('request.jwt.claim.sub',other_du::text,true);
  select id into other_offer from public.submit_offer(oa,95);
  reset role;

  -- Expire only this fixture while transaction_timestamp() remains in the past.
  update public.orders set bidding_expires_at=clock_timestamp()+interval '50 milliseconds' where id=late_order;
  perform pg_sleep(0.1);
  assert (select now()<bidding_expires_at and clock_timestamp()>bidding_expires_at
    from public.orders where id=late_order), 'clock test must distinguish transaction and wall time';
  set local role authenticated;
  begin
    perform public.submit_offer(late_order,96);
    raise exception 'CR-003 expired submit accepted';
  exception when sqlstate 'P0001' then
    if sqlerrm <> 'Order is not open for bidding' then raise; end if;
  end;
  perform set_config('request.jwt.claim.sub',du::text,true);
  begin
    perform public.withdraw_offer(late_offer);
    raise exception 'CR-003 expired withdrawal accepted';
  exception when sqlstate 'P0001' then
    if sqlerrm <> 'Order is not open for bidding' then raise; end if;
  end;
  perform set_config('request.jwt.claim.sub',customer::text,true);
  begin
    perform public.accept_offer(late_order,late_offer);
    raise exception 'CR-003 expired selection accepted';
  exception when sqlstate 'P0001' then
    if sqlerrm <> 'Order is no longer open for bidding' then raise; end if;
  end;
  reset role;
  assert (select status='BIDDING' and driver_id is null from public.orders where id=late_order), 'expired denial leaves order untouched';

  update public.profiles set status='SUSPENDED' where id=customer;
  set local role authenticated;
  begin
    perform public.accept_offer(oa,fa);
    raise exception 'CR-009 suspended customer accepted';
  exception when insufficient_privilege then
    assert sqlerrm='Active customer profile required', 'specific inactive customer denial';
  end;
  reset role;
  update public.profiles set status='ACTIVE' where id=customer;
  perform set_config('request.jwt.claim.sub',staff::text,true);
  set local role authenticated;
  begin
    perform public.accept_offer(oa,fa);
    raise exception 'Wrong customer accepted';
  exception when insufficient_privilege then
    assert sqlerrm='Only the order customer can accept an offer', 'auth context ownership';
  end;
  perform set_config('request.jwt.claim.sub',customer::text,true);
  perform public.accept_offer(oa,fa);
  reset role;
  assert (select driver_id=driver_a and selected_offer_id=fa and agreed_price=90
    and assigned_at is not null and status='DRIVER_ASSIGNED' from public.orders where id=oa), 'normal complete assignment';
  assert (select status='CLOSED' from public.offers where id=fb), 'cross-order offer closed atomically';
  assert (select count(*)=1 from public.order_events where order_id=oa and event_type='DRIVER_ASSIGNED'), 'one assignment event';

  foreach col in array array['driver_id','selected_offer_id','agreed_price','assigned_at'] loop
    begin
      execute format('update public.orders set %I=null where id=%L',col,oa);
      raise exception 'CR-020 incomplete assignment accepted: %',col;
    exception when check_violation then
      get stacked diagnostics detail=constraint_name;
      assert detail='orders_assignment_bundle_ck', 'assignment fields all-or-none';
    end;
  end loop;
  foreach next_status in array array['DRIVER_ASSIGNED','DRIVER_ON_WAY','DRIVER_ARRIVED','IN_PROGRESS','COMPLETED'] loop
    begin
      update public.orders set status=next_status::public.order_status where id=ob;
      raise exception 'CR-020 unassigned operational state accepted: %',next_status;
    exception when check_violation then
      get stacked diagnostics detail=constraint_name;
      assert detail='orders_assignment_state_ck', 'operational states require assignment';
    end;
  end loop;
  foreach detail in array array[
    format('update public.orders set agreed_price=123 where id=%L',oa),
    format('update public.orders set driver_id=%L where id=%L',driver_b,oa),
    format('update public.orders set selected_offer_id=%L where id=%L',other_offer,oa),
    format('update public.orders set selected_offer_id=%L where id=%L',fb,oa),
    format('update public.offers set offered_price=123 where id=%L',fa),
    format('update public.offers set driver_id=%L where id=%L',driver_b,fa)
  ] loop
    begin
      execute detail;
      raise exception 'CR-020 inconsistent assignment accepted';
    exception when foreign_key_violation then
      get stacked diagnostics detail=constraint_name;
      assert detail='orders_selected_offer_assignment_fk', 'same order/Driver/price identity';
    end;
  end loop;

  perform set_config('request.jwt.claim.sub',customer::text,true);
  set local role authenticated;
  perform public.cancel_order(oa,'Wave A assigned cancellation');
  perform public.cancel_order(ob);
  reset role;
  assert (select status='CANCELLED' and driver_id=driver_a and selected_offer_id=fa and agreed_price=90
    from public.orders where id=oa), 'cancelled assignment snapshot retained';
  assert (select status='CANCELLED' and driver_id is null from public.orders where id=ob), 'unassigned cancellation allowed';

  perform set_config('request.jwt.claim.sub',other_du::text,true);
  set local role authenticated;
  select id into completed_offer from public.submit_offer(completed_order,95.50);
  perform set_config('request.jwt.claim.sub',customer::text,true);
  perform public.accept_offer(completed_order,completed_offer);
  perform set_config('request.jwt.claim.sub',other_du::text,true);
  perform public.driver_on_way(completed_order);
  perform public.driver_arrived(completed_order);
  perform public.start_order(completed_order);
  perform public.complete_order(completed_order);
  reset role;
  assert (select status='COMPLETED' and agreed_price=95.50 and selected_offer_id=completed_offer
    from public.orders where id=completed_order), 'constraints preserve complete lifecycle/history';

  foreach detail in array array[
    'private.is_super_admin()','private.has_permission(text)','private.is_office_member(uuid)',
    'private.can_access_office(uuid,text)','public.submit_offer(uuid,numeric)',
    'public.withdraw_offer(uuid)','public.accept_offer(uuid,uuid)'
  ] loop
    assert not has_function_privilege('anon',detail,'EXECUTE'), 'anon privileged execute denied';
    assert has_function_privilege('authenticated',detail,'EXECUTE'), 'authenticated API grant retained';
  end loop;
  assert not exists (
    select 1 from pg_proc p join pg_namespace n on n.oid=p.pronamespace
    where n.nspname in('private','public')
      and p.proname in('is_super_admin','has_permission','is_office_member','can_access_office','submit_offer','withdraw_offer','accept_offer')
      and (not p.prosecdef or not ('search_path=""'=any(p.proconfig)))
  ), 'safe search paths on changed functions';
  assert not has_table_privilege('authenticated','public.orders','UPDATE'), 'direct orders write denied';
  assert not has_table_privilege('authenticated','public.offers','UPDATE'), 'direct offers write denied';
  assert not has_table_privilege('authenticated','public.order_events','INSERT,UPDATE,DELETE'), 'events protected';

  -- Test actual rejection, not merely ACL inspection.
  set local role authenticated;
  begin
    update public.orders set proposed_price=1 where id=oa;
    raise exception 'Direct client update allowed';
  exception when insufficient_privilege then null;
  end;
  perform set_config('request.jwt.claim.sub','',true);
  begin
    perform public.accept_offer(oa,fa);
    raise exception 'Unauthenticated mutation allowed';
  exception when insufficient_privilege then
    assert sqlerrm='Authentication required', 'identity is from auth context';
  end;
  reset role;
end;
$test$;

select 'PASS' as result, array[
  'CR-001 office-scoped permission positives/negatives',
  'CR-002 inactive profile/membership/office/admin denials',
  'CR-003 wall-clock submit/withdraw/accept rejection',
  'CR-009 active customer acceptance guard',
  'CR-020 complete assignment and same-order/Driver/price integrity',
  'normal acceptance/cancellation/lifecycle snapshots',
  'changed-object grants/search_path and direct-write denial'
] as verified;
rollback;
