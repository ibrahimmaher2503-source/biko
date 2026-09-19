-- Wave B contracts only. No committed fixtures.
begin;
do $test$
declare
  ca uuid := '8b320000-0000-0000-0000-000000000001';
  cb uuid := '8b320000-0000-0000-0000-000000000002';
  du uuid := '8b320000-0000-0000-0000-000000000003';
  other_du uuid := '8b320000-0000-0000-0000-000000000004';
  driver uuid := '8b320000-0000-0000-0000-000000000013';
  other_driver uuid := '8b320000-0000-0000-0000-000000000014';
  intent uuid := '8b320000-0000-0000-0000-000000000021';
  intent2 uuid := '8b320000-0000-0000-0000-000000000022';
  delivery_intent uuid := '8b320000-0000-0000-0000-000000000023';
  ride uuid; delivery uuid; first_order public.orders; repeated public.orders;
  second_order public.orders; delivery_order public.orders; fid uuid; data jsonb;
  saved_expiry timestamptz; constraint_id text;
begin
  insert into auth.users(id,email,raw_user_meta_data) values
    (ca,'wave-b-a@example.invalid','{}'),(cb,'wave-b-b@example.invalid','{}'),
    (du,'wave-b-d@example.invalid','{}'),(other_du,'wave-b-other@example.invalid','{}');
  update public.profiles set profile_type='DRIVER' where id in(du,other_du);
  insert into public.drivers(id,user_id,driver_type,status,is_online) values
    (driver,du,'INDEPENDENT','ACTIVE',true),(other_driver,other_du,'INDEPENDENT','ACTIVE',true);
  select id into ride from public.service_types where code='RIDE';
  select id into delivery from public.service_types where code='DELIVERY';

  perform set_config('request.jwt.claim.sub',ca::text,true);
  set local role authenticated;
  select * into first_order from public.create_order(ride,30,31,'Pickup',30.1,31.1,'Destination',80,
    p_creation_intent_id=>intent);
  saved_expiry := first_order.bidding_expires_at;
  select * into repeated from public.create_order(ride,30.0,31.00,'Pickup',30.10,31.10,'Destination',80.0,
    p_creation_intent_id=>intent);
  assert first_order.id=repeated.id and repeated.bidding_expires_at=saved_expiry, 'same normalized intent recovers unchanged order';
  begin
    perform public.create_order(ride,30,31,'Pickup',30.1,31.1,'Destination',81,p_creation_intent_id=>intent);
    raise exception 'Changed intent payload accepted';
  exception when invalid_parameter_value then
    assert sqlerrm='Creation intent conflicts with original payload', 'intent conflict';
  end;
  select * into second_order from public.create_order(ride,30,31,'Pickup',30.1,31.1,'Destination',80,
    p_creation_intent_id=>intent2);
  assert second_order.id<>first_order.id, 'deliberately identical booking remains allowed';
  begin
    perform public.create_order(ride,30,31,'Pickup',30.1,31.1,'Destination',80);
    raise exception 'Missing creation intent accepted';
  exception when invalid_parameter_value then
    assert sqlerrm='Creation intent ID is required', 'caller must retain an intent';
  end;
  select * into delivery_order from public.create_order(delivery,30,31,'Pickup',30.1,31.1,'Destination',80,
    'Recipient','010-test',8,3000,delivery_intent);
  select * into repeated from public.create_order(delivery,30,31,'Pickup',30.1,31.1,'Destination',80,
    'Recipient','010-test',8.0,3000.0,delivery_intent);
  assert delivery_order.id=repeated.id, 'delivery recovery';
  begin
    perform public.create_order(delivery,30,31,'Pickup',30.1,31.1,'Destination',80,
      'Different recipient','010-test',8,3000,delivery_intent);
    raise exception 'Changed recipient accepted';
  exception when invalid_parameter_value then
    assert sqlerrm='Creation intent conflicts with original payload', 'private payload is part of intent';
  end;
  perform set_config('request.jwt.claim.sub',cb::text,true);
  select * into repeated from public.create_order(ride,30,31,'Pickup',30.1,31.1,'Destination',80,
    p_creation_intent_id=>intent);
  assert repeated.id<>first_order.id and repeated.customer_id=cb, 'intent unique per customer, no cross-owner recovery';
  reset role;
  assert (select count(*)=1 from public.orders where customer_id=ca and creation_intent_id=intent), 'one logical order';
  assert (select count(*)=1 from public.order_delivery_details where order_id=delivery_order.id), 'one delivery record';
  assert (select count(*)=1 from public.order_events where order_id=first_order.id and event_type='BIDDING'), 'no duplicate create event';
  begin
    insert into public.orders(customer_id,service_type_id,pickup_lat,pickup_lng,pickup_address,
      destination_lat,destination_lng,destination_address,proposed_price,status,creation_intent_id,creation_payload_hash)
    values(ca,ride,30,31,'Pickup',30.1,31.1,'Destination',80,'BIDDING',intent,first_order.creation_payload_hash);
    raise exception 'Database accepted duplicate intent';
  exception when unique_violation then
    get stacked diagnostics constraint_id=constraint_name;
    assert constraint_id='orders_customer_creation_intent_key', 'native concurrency backstop';
  end;

  insert into public.order_driver_candidates(order_id,driver_id) values(first_order.id,driver);
  perform set_config('request.jwt.claim.sub',du::text,true);
  set local role authenticated;
  select id into fid from public.submit_offer(first_order.id,90);
  select to_jsonb(r) into data from public.get_driver_offer(first_order.id) r;
  assert data->>'id'=fid::text and data->>'order_status'='BIDDING', 'owned offer + order truth';
  assert (data->>'bidding_expires_at')::timestamptz>(data->>'server_now')::timestamptz, 'live expiry truth';
  assert not (data ?| array['customer_id','phone','full_name','recipient_name','recipient_phone','driver_id','office_id','creation_payload_hash']),
    'private fields absent from compact projection';
  perform set_config('request.jwt.claim.sub',other_du::text,true);
  assert (select count(*)=0 from public.get_driver_offer(first_order.id)), 'other driver cannot read owned offer';
  reset role;
  update public.orders set bidding_expires_at=clock_timestamp()-interval '1 second' where id=first_order.id;
  perform set_config('request.jwt.claim.sub',du::text,true);
  set local role authenticated;
  select to_jsonb(r) into data from public.get_driver_offer(first_order.id) r;
  assert data->>'status'='ACTIVE' and (data->>'bidding_expires_at')::timestamptz<(data->>'server_now')::timestamptz,
    'expired order exposed even when offer still ACTIVE';
  perform set_config('request.jwt.claim.sub',ca::text,true);
  perform public.cancel_order(first_order.id);
  select * into repeated from public.create_order(ride,30,31,'Pickup',30.1,31.1,'Destination',80,p_creation_intent_id=>intent);
  assert repeated.id=first_order.id and repeated.status='CANCELLED', 'recovery never reopens terminal order';
  perform set_config('request.jwt.claim.sub',du::text,true);
  select to_jsonb(r) into data from public.get_driver_offer(first_order.id) r;
  assert data->>'order_status'='CANCELLED' and not (data->>'assigned_to_me')::boolean, 'terminal waiting truth';
  reset role;

  assert not has_function_privilege('anon','public.get_driver_offer(uuid)','EXECUTE'), 'anon read RPC denied';
  assert not has_function_privilege('anon',
    'public.create_order(uuid,numeric,numeric,text,numeric,numeric,text,numeric,text,text,numeric,numeric,uuid)','EXECUTE'),
    'anon creation denied';
  assert not has_table_privilege('authenticated','public.orders','INSERT,UPDATE'), 'direct intent/order writes denied';
  assert not exists (
    select 1 from pg_proc p join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='public' and p.proname in('create_order','get_driver_offer')
    and (not p.prosecdef or not ('search_path=""'=any(p.proconfig)))
  ), 'changed functions safe search path';
end;
$test$;
select 'PASS' as result, array[
  'same intent/same payload recovery','different payload conflict','different intent identical bookings',
  'required caller intent','per-customer isolation','Delivery payload recovery/conflict',
  'native unique constraint','one creation event/detail','terminal order stays terminal',
  'owned-offer order/expiry truth','other Driver denial','private fields absent','grants/search paths'
] as verified;
rollback;

