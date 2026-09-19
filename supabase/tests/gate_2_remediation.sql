-- SVG2 remediation A/B/D/E/L only; all fixtures roll back.
begin;
do $test$
declare
  ca uuid := '8a200000-0000-0000-0000-000000000001';
  cb uuid := '8a200000-0000-0000-0000-000000000002';
  ua uuid := '8a200000-0000-0000-0000-000000000003';
  ub uuid := '8a200000-0000-0000-0000-000000000004';
  uc uuid := '8a200000-0000-0000-0000-000000000005';
  da uuid := '8a200000-0000-0000-0000-000000000013';
  db uuid := '8a200000-0000-0000-0000-000000000014';
  dc uuid := '8a200000-0000-0000-0000-000000000015';
  oa uuid; ob uuid; oc uuid; fa uuid; fb uuid; fc uuid; loser uuid;
  svc uuid; detail text;
begin
  insert into auth.users(id, email, raw_user_meta_data) values
    (ca, 'svg2-rem-a@example.invalid', '{}'), (cb, 'svg2-rem-b@example.invalid', '{}'),
    (ua, 'svg2-rem-da@example.invalid', '{}'), (ub, 'svg2-rem-db@example.invalid', '{}'),
    (uc, 'svg2-rem-dc@example.invalid', '{}');
  update public.profiles set profile_type='DRIVER' where id in (ua,ub,uc);
  update public.profiles set full_name='Private Customer Name', phone='private-phone' where id=ca;
  insert into public.drivers(id,user_id,driver_type,status,is_online) values
    (da,ua,'INDEPENDENT','ACTIVE',true),(db,ub,'INDEPENDENT','ACTIVE',true),
    (dc,uc,'INDEPENDENT','ACTIVE',true);
  select id into svc from public.service_types where code='RIDE';
  perform set_config('request.jwt.claim.sub',ca::text,true);
  select id into oa from public.create_order(svc,30,31,'SVG2 A',30.1,31.1,'Dest A',80,p_creation_intent_id => gen_random_uuid());
  select id into ob from public.create_order(svc,30,31,'SVG2 B',30.1,31.1,'Dest B',80,p_creation_intent_id => gen_random_uuid());
  select id into oc from public.create_order(svc,30,31,'SVG2 C',30.1,31.1,'Dest C',80,p_creation_intent_id => gen_random_uuid());
  insert into public.order_driver_candidates(order_id,driver_id) values (oa,da),(ob,da),(oc,da),(oa,db);

  perform set_config('request.jwt.claim.sub',ua::text,true);
  set local role authenticated;
  assert (select count(*)=3 from public.get_driver_requests()), 'L: safe candidates';
  assert not exists (select 1 from public.get_driver_requests() r
    where to_jsonb(r) ?| array['customer_id','phone','full_name','recipient_phone','office_id']),
    'L: private keys absent';
  assert (select count(*)=0 from public.orders), 'L: raw candidate rows denied';
  assert (select count(*)=0 from public.profiles where id=ca), 'L: private customer profile denied';
  select id into fa from public.submit_offer(oa,90);
  select id into fb from public.submit_offer(ob,95);
  select id into fc from public.submit_offer(oc,100);
  assert (select count(*)=3 from public.get_driver_active_offers()), 'A: three cross-order offers';
  begin
    perform public.submit_offer(oa,91);
    raise exception 'A failed: duplicate same-order offer accepted';
  exception when sqlstate 'P0001' then
    if sqlerrm not like 'Active offer already exists%' then raise; end if;
  end;

  perform set_config('request.jwt.claim.sub',uc::text,true);
  assert (select count(*)=0 from public.get_driver_requests()), 'L: noncandidate denied';
  perform set_config('request.jwt.claim.sub',ub::text,true);
  select id into loser from public.submit_offer(oa,85);
  perform set_config('request.jwt.claim.sub',ca::text,true);
  perform public.accept_offer(oa,fa);
  reset role;

  assert (select status='DRIVER_ASSIGNED' and driver_id=da and selected_offer_id=fa and agreed_price=90
    from public.orders where id=oa), 'B: assignment';
  assert (select status='SELECTED' from public.offers where id=fa), 'B: winner';
  assert (select count(*)=3 from public.offers where id in(fb,fc,loser) and status='CLOSED'), 'B: all affected offers closed';
  assert (select not is_online from public.drivers where id=da), 'B: unavailable';
  assert (select count(*)=1 from public.orders where driver_id=da and
    status in ('DRIVER_ASSIGNED','DRIVER_ON_WAY','DRIVER_ARRIVED','IN_PROGRESS')), 'B: one job';

  perform set_config('request.jwt.claim.sub',ua::text,true);
  set local role authenticated;
  assert (select count(*)=0 from public.get_driver_requests()), 'B: active Driver no candidates';
  assert (select count(*)=0 from public.get_driver_active_offers()), 'B: no waiting offers';
  assert (select count(*)=1 from public.get_driver_requests(oa)), 'L: assigned safe details';
  assert (select count(*)=1 from public.orders where id=oa), 'L: assigned raw read preserved';
  begin
    perform public.submit_offer(ob,95);
    raise exception 'B failed: active Driver submitted offer';
  exception when sqlstate 'P0001' then
    if sqlerrm <> 'Driver already has an active assignment' then raise; end if;
  end;
  begin
    perform public.set_driver_online(true);
    raise exception 'B failed: active Driver went available';
  exception when sqlstate 'P0001' then
    get stacked diagnostics detail = pg_exception_hint;
    assert detail='لديك رحلة نشطة بالفعل.', 'B: useful availability conflict';
  end;
  perform public.driver_on_way(oa);
  reset role;
  assert (select status='DRIVER_ON_WAY' from public.orders where id=oa), 'B: offline availability does not break lifecycle';
  assert (select count(*)=1 from public.order_events where order_id=oa and event_type='DRIVER_ASSIGNED'), 'B: assignment event preserved';

  begin
    update public.orders set driver_id=da,selected_offer_id=fb,agreed_price=95,
      assigned_at=clock_timestamp(),status='DRIVER_ASSIGNED' where id=ob;
    raise exception 'D failed: manual double assignment accepted';
  exception when unique_violation then
    get stacked diagnostics detail = constraint_name;
    assert detail='orders_one_active_job_per_driver_idx', 'D: correct database invariant';
  end;
  begin
    update public.orders set selected_offer_id=fb where id=oa;
    raise exception 'E failed: cross-order selected offer accepted';
  exception when foreign_key_violation then
    get stacked diagnostics detail = constraint_name;
    assert detail='orders_selected_offer_assignment_fk', 'E: correct relational invariant';
  end;

  assert not has_function_privilege('anon','public.get_driver_requests(uuid)','EXECUTE'), 'security anon request RPC';
  assert not has_function_privilege('anon','public.get_driver_active_offers(integer)','EXECUTE'), 'security anon offers RPC';
  assert not has_function_privilege('anon','public.accept_offer(uuid,uuid)','EXECUTE'), 'security anon accept';
  assert not has_function_privilege('anon','public.submit_offer(uuid,numeric)','EXECUTE'), 'security anon submit';
  assert not exists (
    select 1 from pg_proc p join pg_namespace n on n.oid=p.pronamespace
    where n.nspname in ('public','private')
      and p.proname in ('get_driver_requests','get_driver_active_offers','accept_offer','submit_offer','advance_order_state')
      and (not p.prosecdef or not ('search_path=""'=any(p.proconfig)))
  ), 'security safe search paths';
  assert not has_table_privilege('authenticated','public.orders','UPDATE'), 'security no client order writes';
  assert not has_table_privilege('authenticated','public.offers','UPDATE'), 'security no client offer writes';
  assert not has_table_privilege('authenticated','public.order_events','INSERT'), 'security protected events';
end;
$test$;
select 'PASS' as result, array['A multiple offers + duplicate denial','B atomic closing + active-job eligibility + lifecycle/event preservation',
 'D manual one-active-job invariant','E selected-offer composite FK','L safe candidate/assigned reads + noncandidate denial',
 'changed-object security grants/search_path'] as verified;
rollback;
