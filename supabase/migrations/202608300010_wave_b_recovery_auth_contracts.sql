-- Wave B only: stable creation recovery and privacy-safe owned-offer truth.
alter table public.orders
  add column creation_intent_id uuid,
  add column creation_payload_hash text,
  add constraint orders_customer_creation_intent_key unique (customer_id, creation_intent_id),
  add constraint orders_creation_intent_hash_ck check (
    (creation_intent_id is null and creation_payload_hash is null)
    or (creation_intent_id is not null and creation_payload_hash is not null
      and creation_payload_hash ~ '^[0-9a-f]{64}$')
  );

-- Legacy rows may have no key; all new create_order calls must supply one.
drop function public.create_order(
  uuid,numeric,numeric,text,numeric,numeric,text,numeric,text,text,numeric,numeric
);

create function public.create_order(
  p_service_type_id uuid,
  p_pickup_lat numeric,
  p_pickup_lng numeric,
  p_pickup_address text,
  p_destination_lat numeric,
  p_destination_lng numeric,
  p_destination_address text,
  p_proposed_price numeric,
  p_recipient_name text default null,
  p_recipient_phone text default null,
  p_parcel_weight_kg numeric default null,
  p_declared_value numeric default null,
  p_creation_intent_id uuid default null
)
returns public.orders
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_uid uuid := (select auth.uid());
  v_service_code text;
  v_order public.orders;
  v_payload_hash text;
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  if not exists (
    select 1
    from public.profiles p
    where p.id = v_uid
      and p.profile_type = 'CUSTOMER'::public.profile_type
      and p.status = 'ACTIVE'::public.account_status
  ) then
    raise exception 'Active customer profile required' using errcode = '42501';
  end if;

  select st.code
  into v_service_code
  from public.service_types st
  where st.id = p_service_type_id
    and st.is_enabled
    and st.code in ('RIDE', 'DELIVERY');

  if not found then
    raise exception 'Service type is not enabled' using errcode = '22023';
  end if;

  if p_pickup_lat is null or p_pickup_lng is null
     or p_destination_lat is null or p_destination_lng is null
     or p_pickup_lat = 'NaN'::numeric or p_pickup_lng = 'NaN'::numeric
     or p_destination_lat = 'NaN'::numeric or p_destination_lng = 'NaN'::numeric
     or p_pickup_lat not between -90 and 90
     or p_pickup_lng not between -180 and 180
     or p_destination_lat not between -90 and 90
     or p_destination_lng not between -180 and 180
     or nullif(btrim(p_pickup_address), '') is null
     or nullif(btrim(p_destination_address), '') is null
     or p_proposed_price is null
     or p_proposed_price <= 0
     or p_proposed_price = 'NaN'::numeric then
    raise exception 'Invalid order route or proposed price' using errcode = '22023';
  end if;

  if v_service_code = 'DELIVERY' then
    if nullif(btrim(p_recipient_name), '') is null then
      raise exception 'Delivery recipient name is required' using errcode = '22023';
    end if;
    if nullif(btrim(p_recipient_phone), '') is null then
      raise exception 'Delivery recipient phone is required' using errcode = '22023';
    end if;
    if p_parcel_weight_kg is null
       or p_parcel_weight_kg = 'NaN'::numeric
       or p_parcel_weight_kg <= 0
       or p_parcel_weight_kg > 8 then
      raise exception 'Delivery parcel weight must be greater than 0 and at most 8 kg'
        using errcode = '22023';
    end if;
    if p_declared_value is null
       or p_declared_value = 'NaN'::numeric
       or p_declared_value < 0
       or p_declared_value > 3000 then
      raise exception 'Delivery declared value must be between 0 and 3000 EGP'
        using errcode = '22023';
    end if;
  end if;

  if p_creation_intent_id is null then
    raise exception 'Creation intent ID is required' using errcode = '22023';
  end if;

  -- Retain only a fingerprint, not a second copy of private recipient data.
  -- trim_scale makes numerically equivalent JSON inputs (80 / 80.0) identical.
  v_payload_hash := encode(extensions.digest(
    jsonb_build_array(
      p_service_type_id, trim_scale(p_pickup_lat), trim_scale(p_pickup_lng),
      btrim(p_pickup_address), trim_scale(p_destination_lat), trim_scale(p_destination_lng),
      btrim(p_destination_address), trim_scale(p_proposed_price),
      btrim(p_recipient_name), btrim(p_recipient_phone),
      trim_scale(p_parcel_weight_kg), trim_scale(p_declared_value)
    )::text, 'sha256'), 'hex');

  insert into public.orders (
    creation_intent_id,
    creation_payload_hash,
    customer_id,
    service_type_id,
    pickup_lat,
    pickup_lng,
    pickup_address,
    destination_lat,
    destination_lng,
    destination_address,
    proposed_price,
    bidding_expires_at,
    status
  )
  values (
    p_creation_intent_id,
    v_payload_hash,
    v_uid,
    p_service_type_id,
    p_pickup_lat,
    p_pickup_lng,
    btrim(p_pickup_address),
    p_destination_lat,
    p_destination_lng,
    btrim(p_destination_address),
    p_proposed_price,
    clock_timestamp() + interval '90 seconds',
    'BIDDING'::public.order_status
  )
  on conflict (customer_id, creation_intent_id) do nothing
  returning * into v_order;

  if not found then
    -- The unique index waits for a competing transaction. This next statement
    -- reads its committed order, with no duplicate write or deadline reset.
    select o.* into v_order from public.orders o
    where o.customer_id = v_uid and o.creation_intent_id = p_creation_intent_id;
    if not found or v_order.creation_payload_hash is distinct from v_payload_hash then
      raise exception 'Creation intent conflicts with original payload' using errcode = '22023';
    end if;
    return v_order;
  end if;

  if v_service_code = 'DELIVERY' then
    insert into public.order_delivery_details (
      order_id,
      recipient_name,
      recipient_phone,
      parcel_weight_kg,
      declared_value
    )
    values (
      v_order.id,
      btrim(p_recipient_name),
      btrim(p_recipient_phone),
      p_parcel_weight_kg,
      p_declared_value
    );
  end if;

  return v_order;
end;
$function$;

-- One request, one owned offer plus current order truth; no private identity.
create function public.get_driver_offer(p_order_id uuid)
returns table (
  id uuid, order_id uuid, offered_price numeric, status public.offer_status,
  order_status public.order_status, bidding_expires_at timestamptz,
  assigned_to_me boolean, pickup_address text, destination_address text,
  service_code text, service_name text, server_now timestamptz
)
language sql stable security definer set search_path = ''
as $function$
  select f.id, f.order_id, f.offered_price, f.status,
    o.status, o.bidding_expires_at,
    (o.driver_id = d.id and o.selected_offer_id = f.id) is true,
    o.pickup_address, o.destination_address, s.code, s.name_ar,
    statement_timestamp()
  from public.drivers d
  join public.offers f on f.driver_id = d.id and f.order_id = p_order_id
  join public.orders o on o.id = f.order_id
  join public.service_types s on s.id = o.service_type_id
  where d.user_id = (select auth.uid())
  order by f.created_at desc, f.id desc
  limit 1;
$function$;

revoke all on function public.create_order(
  uuid,numeric,numeric,text,numeric,numeric,text,numeric,text,text,numeric,numeric,uuid
), public.get_driver_offer(uuid) from public, anon, authenticated;
grant execute on function public.create_order(
  uuid,numeric,numeric,text,numeric,numeric,text,numeric,text,text,numeric,numeric,uuid
), public.get_driver_offer(uuid) to authenticated;

