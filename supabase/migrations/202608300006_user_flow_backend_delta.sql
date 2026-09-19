-- Milestone 7A: User App backend contract delta.

alter table public.orders
  alter column bidding_expires_at set default (now() + interval '90 seconds'),
  add column recipient_name text,
  add column recipient_phone text,
  add column parcel_weight_kg numeric(5,2),
  add column declared_value numeric(12,2),
  add column cancellation_type text,
  add constraint orders_recipient_name_ck
    check (recipient_name is null or nullif(btrim(recipient_name), '') is not null),
  add constraint orders_recipient_phone_ck
    check (recipient_phone is null or nullif(btrim(recipient_phone), '') is not null),
  add constraint orders_parcel_weight_ck
    check (
      parcel_weight_kg is null
      or (
        parcel_weight_kg > 0
        and parcel_weight_kg <= 8
        and parcel_weight_kg <> 'NaN'::numeric
      )
    ),
  add constraint orders_declared_value_ck
    check (
      declared_value is null
      or (
        declared_value >= 0
        and declared_value <= 3000
        and declared_value <> 'NaN'::numeric
      )
    ),
  add constraint orders_cancellation_type_ck
    check (
      cancellation_type is null
      or cancellation_type in ('CUSTOMER_CANCEL', 'LATE_CANCEL', 'DRIVER_CANCEL')
    );

drop function public.create_order(uuid, numeric, numeric, text, numeric, numeric, text, numeric);

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
  p_declared_value numeric default null
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

  insert into public.orders (
    customer_id,
    service_type_id,
    pickup_lat,
    pickup_lng,
    pickup_address,
    destination_lat,
    destination_lng,
    destination_address,
    proposed_price,
    recipient_name,
    recipient_phone,
    parcel_weight_kg,
    declared_value,
    bidding_expires_at,
    status
  )
  values (
    v_uid,
    p_service_type_id,
    p_pickup_lat,
    p_pickup_lng,
    btrim(p_pickup_address),
    p_destination_lat,
    p_destination_lng,
    btrim(p_destination_address),
    p_proposed_price,
    case when v_service_code = 'DELIVERY' then btrim(p_recipient_name) end,
    case when v_service_code = 'DELIVERY' then btrim(p_recipient_phone) end,
    case when v_service_code = 'DELIVERY' then p_parcel_weight_kg end,
    case when v_service_code = 'DELIVERY' then p_declared_value end,
    now() + interval '90 seconds',
    'BIDDING'::public.order_status
  )
  returning * into v_order;

  return v_order;
end;
$function$;

create or replace function public.submit_offer(
  p_order_id uuid,
  p_offered_price numeric
)
returns public.offers
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_uid uuid := (select auth.uid());
  v_order public.orders;
  v_driver public.drivers;
  v_offer public.offers;
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  if p_offered_price is null or p_offered_price <= 0 or p_offered_price = 'NaN'::numeric then
    raise exception 'Invalid offer price' using errcode = '22023';
  end if;

  select * into v_order
  from public.orders
  where id = p_order_id
  for update;

  if not found then
    raise exception 'Order not found' using errcode = 'P0002';
  end if;
  if v_order.status <> 'BIDDING'::public.order_status
     or v_order.bidding_expires_at <= now() then
    raise exception 'Order is not open for bidding' using errcode = 'P0001';
  end if;

  select * into v_driver
  from public.drivers
  where user_id = v_uid
  for update;

  if not found
     or v_driver.status <> 'ACTIVE'::public.driver_status
     or not v_driver.is_online
     or not exists (
       select 1
       from public.profiles p
       where p.id = v_uid
         and p.profile_type = 'DRIVER'::public.profile_type
         and p.status = 'ACTIVE'::public.account_status
     ) then
    raise exception 'Eligible active driver required' using errcode = '42501';
  end if;

  if not exists (
    select 1
    from public.order_driver_candidates c
    where c.order_id = p_order_id
      and c.driver_id = v_driver.id
  ) then
    raise exception 'Driver is not eligible for this order' using errcode = '42501';
  end if;

  if exists (
    select 1
    from public.offers o
    where o.order_id = p_order_id
      and o.driver_id = v_driver.id
      and o.status = 'ACTIVE'::public.offer_status
  ) then
    raise exception 'Active offer already exists; withdraw it before submitting a new offer'
      using errcode = 'P0001';
  end if;

  insert into public.offers (order_id, driver_id, office_id, offered_price, status)
  values (
    p_order_id,
    v_driver.id,
    v_driver.office_id,
    p_offered_price,
    'ACTIVE'::public.offer_status
  )
  returning * into v_offer;

  return v_offer;
end;
$function$;

create or replace function public.withdraw_offer(p_offer_id uuid)
returns public.offers
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_uid uuid := (select auth.uid());
  v_order_id uuid;
  v_order public.orders;
  v_offer public.offers;
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  select o.order_id into v_order_id
  from public.offers o
  where o.id = p_offer_id;

  if not found then
    raise exception 'Offer not found' using errcode = 'P0002';
  end if;

  select * into v_order
  from public.orders
  where id = v_order_id
  for update;

  select * into v_offer
  from public.offers o
  where o.id = p_offer_id
    and exists (
      select 1
      from public.drivers d
      where d.id = o.driver_id
        and d.user_id = v_uid
    )
  for update;

  if not found then
    raise exception 'Only the offer driver can withdraw it' using errcode = '42501';
  end if;
  if v_order.status <> 'BIDDING'::public.order_status
     or v_order.bidding_expires_at <= now() then
    raise exception 'Order is not open for bidding' using errcode = 'P0001';
  end if;
  if v_offer.status <> 'ACTIVE'::public.offer_status
     or v_order.selected_offer_id = v_offer.id then
    raise exception 'Only an active unselected offer can be withdrawn' using errcode = 'P0001';
  end if;

  update public.offers
  set status = 'WITHDRAWN'::public.offer_status,
      updated_at = now()
  where id = v_offer.id
  returning * into v_offer;

  return v_offer;
end;
$function$;

create or replace function public.accept_offer(
  p_order_id uuid,
  p_offer_id uuid
)
returns public.orders
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_uid uuid := (select auth.uid());
  v_order public.orders;
  v_offer public.offers;
  v_driver public.drivers;
  v_profile_status public.account_status;
  v_profile_type public.profile_type;
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  select * into v_order
  from public.orders
  where id = p_order_id
  for update;

  if not found then
    raise exception 'Order not found' using errcode = 'P0002';
  end if;
  if v_order.customer_id <> v_uid then
    raise exception 'Only the order customer can accept an offer' using errcode = '42501';
  end if;
  if v_order.status <> 'BIDDING'::public.order_status
     or v_order.bidding_expires_at <= now() then
    raise exception 'Order is no longer open for bidding' using errcode = 'P0001';
  end if;

  select * into v_offer
  from public.offers
  where id = p_offer_id
    and order_id = p_order_id
  for update;

  if not found or v_offer.status <> 'ACTIVE'::public.offer_status then
    raise exception 'Active offer for this order required' using errcode = 'P0001';
  end if;

  select * into v_driver
  from public.drivers
  where id = v_offer.driver_id
  for update;

  if not found then
    raise exception 'Offer driver not found' using errcode = 'P0002';
  end if;

  select p.status, p.profile_type
  into v_profile_status, v_profile_type
  from public.profiles p
  where p.id = v_driver.user_id;

  if v_driver.status <> 'ACTIVE'::public.driver_status
     or not v_driver.is_online
     or v_profile_status <> 'ACTIVE'::public.account_status
     or v_profile_type <> 'DRIVER'::public.profile_type
     or not exists (
       select 1
       from public.order_driver_candidates c
       where c.order_id = p_order_id
         and c.driver_id = v_driver.id
     )
     or (
       v_driver.office_id is not null
       and not exists (
         select 1
         from public.offices o
         where o.id = v_driver.office_id
           and o.status = 'ACTIVE'::public.account_status
       )
     ) then
    raise exception 'Offer driver is no longer eligible' using errcode = '42501';
  end if;

  update public.orders
  set selected_offer_id = v_offer.id,
      driver_id = v_driver.id,
      office_id = v_driver.office_id,
      agreed_price = v_offer.offered_price,
      status = 'DRIVER_ASSIGNED'::public.order_status,
      assigned_at = now(),
      updated_at = now()
  where id = v_order.id
  returning * into v_order;

  update public.offers
  set status = 'SELECTED'::public.offer_status,
      updated_at = now()
  where id = v_offer.id;

  update public.offers
  set status = 'CLOSED'::public.offer_status,
      updated_at = now()
  where order_id = v_order.id
    and id <> v_offer.id
    and status = 'ACTIVE'::public.offer_status;

  return v_order;
end;
$function$;

drop policy offers_select_permitted on public.offers;

create policy offers_select_permitted
on public.offers
for select
to authenticated
using (
  private.is_super_admin()
  or private.can_access_office(office_id, 'orders.view')
  or exists (
    select 1
    from public.drivers d
    where d.id = offers.driver_id
      and d.user_id = (select auth.uid())
  )
);

create function public.get_customer_order_offers(p_order_id uuid)
returns table (
  offer_id uuid,
  offered_price numeric,
  driver_public_id uuid,
  driver_first_name text,
  driver_photo_url text,
  driver_type public.driver_type,
  office_display_name text,
  completed_trip_count integer
)
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
  v_uid uuid := (select auth.uid());
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  return query
  select
    ofr.id,
    ofr.offered_price,
    dr.id,
    split_part(btrim(pr.full_name), ' ', 1),
    pr.profile_photo_url,
    dr.driver_type,
    offc.name,
    dr.completed_trip_count
  from public.orders ord
  join public.offers ofr on ofr.order_id = ord.id
  join public.drivers dr on dr.id = ofr.driver_id
  join public.profiles pr on pr.id = dr.user_id
  left join public.offices offc on offc.id = dr.office_id
  where ord.id = p_order_id
    and ord.customer_id = v_uid
    and ord.status = 'BIDDING'::public.order_status
    and ord.bidding_expires_at > now()
    and ofr.status = 'ACTIVE'::public.offer_status
    and dr.status = 'ACTIVE'::public.driver_status
    and pr.profile_type = 'DRIVER'::public.profile_type
    and pr.status = 'ACTIVE'::public.account_status
    and (dr.office_id is null or offc.status = 'ACTIVE'::public.account_status)
  order by ofr.created_at desc;
end;
$function$;

drop function public.cancel_order(uuid);

create function public.cancel_order(
  p_order_id uuid,
  p_reason text default null
)
returns public.orders
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_uid uuid := (select auth.uid());
  v_reason text := nullif(btrim(p_reason), '');
  v_order public.orders;
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  if v_reason is not null and length(v_reason) > 500 then
    raise exception 'Cancellation reason must not exceed 500 characters'
      using errcode = '22023';
  end if;

  select * into v_order
  from public.orders
  where id = p_order_id
  for update;

  if not found then
    raise exception 'Order not found' using errcode = 'P0002';
  end if;
  if v_order.customer_id <> v_uid then
    raise exception 'Only the order customer can cancel it' using errcode = '42501';
  end if;
  if v_order.status not in (
    'BIDDING'::public.order_status,
    'DRIVER_ASSIGNED'::public.order_status,
    'DRIVER_ON_WAY'::public.order_status,
    'DRIVER_ARRIVED'::public.order_status
  ) then
    raise exception 'Order cannot be cancelled in its current state' using errcode = 'P0001';
  end if;
  if v_order.status in (
    'DRIVER_ASSIGNED'::public.order_status,
    'DRIVER_ON_WAY'::public.order_status,
    'DRIVER_ARRIVED'::public.order_status
  ) and v_reason is null then
    raise exception 'Cancellation reason is required after driver assignment'
      using errcode = '22023';
  end if;

  update public.orders
  set status = 'CANCELLED'::public.order_status,
      cancelled_by = v_uid,
      cancellation_reason = v_reason,
      cancellation_type = case
        when v_order.status in (
          'DRIVER_ON_WAY'::public.order_status,
          'DRIVER_ARRIVED'::public.order_status
        ) then 'LATE_CANCEL'
        else 'CUSTOMER_CANCEL'
      end,
      cancelled_at = coalesce(cancelled_at, now()),
      updated_at = now()
  where id = v_order.id
  returning * into v_order;

  update public.offers
  set status = 'CLOSED'::public.offer_status,
      updated_at = now()
  where order_id = v_order.id
    and status = 'ACTIVE'::public.offer_status;

  return v_order;
end;
$function$;

create or replace function public.driver_cancel_order(
  p_order_id uuid,
  p_reason text
)
returns public.orders
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_uid uuid := (select auth.uid());
  v_order public.orders;
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  if nullif(btrim(p_reason), '') is null or length(btrim(p_reason)) > 500 then
    raise exception 'Cancellation reason is required and must not exceed 500 characters'
      using errcode = '22023';
  end if;

  select * into v_order
  from public.orders
  where id = p_order_id
  for update;

  if not found then
    raise exception 'Order not found' using errcode = 'P0002';
  end if;
  if not exists (
    select 1
    from public.drivers d
    where d.id = v_order.driver_id
      and d.user_id = v_uid
  ) then
    raise exception 'Only the assigned driver can cancel this order' using errcode = '42501';
  end if;
  if v_order.status not in (
    'DRIVER_ASSIGNED'::public.order_status,
    'DRIVER_ON_WAY'::public.order_status,
    'DRIVER_ARRIVED'::public.order_status
  ) then
    raise exception 'Driver cannot cancel this order in its current state' using errcode = 'P0001';
  end if;

  update public.orders
  set status = 'CANCELLED'::public.order_status,
      cancelled_by = v_uid,
      cancellation_reason = btrim(p_reason),
      cancellation_type = 'DRIVER_CANCEL',
      cancelled_at = coalesce(cancelled_at, now()),
      updated_at = now()
  where id = v_order.id
  returning * into v_order;

  update public.offers
  set status = 'CLOSED'::public.offer_status,
      updated_at = now()
  where order_id = v_order.id
    and status = 'ACTIVE'::public.offer_status;

  return v_order;
end;
$function$;

create or replace function private.record_order_event()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
begin
  if tg_op = 'INSERT' or old.status is distinct from new.status then
    insert into public.order_events (
      order_id,
      event_type,
      actor_user_id,
      from_status,
      to_status,
      metadata
    )
    values (
      new.id,
      new.status::text,
      coalesce((select auth.uid()), new.cancelled_by),
      case when tg_op = 'UPDATE' then old.status end,
      new.status,
      case
        when new.status = 'CANCELLED'::public.order_status then
          jsonb_strip_nulls(
            jsonb_build_object(
              'reason', new.cancellation_reason,
              'cancellation_type', new.cancellation_type
            )
          )
        else '{}'::jsonb
      end
    );
  end if;

  return new;
end;
$function$;

revoke all on function public.create_order(
  uuid, numeric, numeric, text, numeric, numeric, text, numeric,
  text, text, numeric, numeric
) from public, anon, authenticated;
revoke all on function public.submit_offer(uuid, numeric) from public, anon, authenticated;
revoke all on function public.withdraw_offer(uuid) from public, anon, authenticated;
revoke all on function public.accept_offer(uuid, uuid) from public, anon, authenticated;
revoke all on function public.get_customer_order_offers(uuid) from public, anon, authenticated;
revoke all on function public.cancel_order(uuid, text) from public, anon, authenticated;
revoke all on function public.driver_cancel_order(uuid, text) from public, anon, authenticated;
revoke all on function private.record_order_event() from public, anon, authenticated;

grant execute on function public.create_order(
  uuid, numeric, numeric, text, numeric, numeric, text, numeric,
  text, text, numeric, numeric
) to authenticated;
grant execute on function public.submit_offer(uuid, numeric) to authenticated;
grant execute on function public.withdraw_offer(uuid) to authenticated;
grant execute on function public.accept_offer(uuid, uuid) to authenticated;
grant execute on function public.get_customer_order_offers(uuid) to authenticated;
grant execute on function public.cancel_order(uuid, text) to authenticated;
grant execute on function public.driver_cancel_order(uuid, text) to authenticated;
