-- Milestone 7A privacy hardening: keep recipient data outside candidate-visible orders.

create table public.order_delivery_details (
  order_id uuid primary key references public.orders(id) on delete cascade,
  recipient_name text not null check (nullif(btrim(recipient_name), '') is not null),
  recipient_phone text not null check (nullif(btrim(recipient_phone), '') is not null),
  parcel_weight_kg numeric(5,2) not null check (
    parcel_weight_kg > 0
    and parcel_weight_kg <= 8
    and parcel_weight_kg <> 'NaN'::numeric
  ),
  declared_value numeric(12,2) not null check (
    declared_value >= 0
    and declared_value <= 3000
    and declared_value <> 'NaN'::numeric
  )
);

insert into public.order_delivery_details (
  order_id,
  recipient_name,
  recipient_phone,
  parcel_weight_kg,
  declared_value
)
select
  o.id,
  o.recipient_name,
  o.recipient_phone,
  o.parcel_weight_kg,
  o.declared_value
from public.orders o
join public.service_types st on st.id = o.service_type_id
where st.code = 'DELIVERY'
  and o.recipient_name is not null
  and o.recipient_phone is not null
  and o.parcel_weight_kg is not null
  and o.declared_value is not null;

alter table public.orders
  drop column recipient_name,
  drop column recipient_phone,
  drop column parcel_weight_kg,
  drop column declared_value;

alter table public.order_delivery_details enable row level security;
revoke all privileges on table public.order_delivery_details from anon, authenticated;
grant select on table public.order_delivery_details to authenticated;

create policy order_delivery_details_select_customer
on public.order_delivery_details
for select
to authenticated
using (
  exists (
    select 1
    from public.orders o
    where o.id = order_delivery_details.order_id
      and o.customer_id = (select auth.uid())
  )
);

create or replace function public.create_order(
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
    now() + interval '90 seconds',
    'BIDDING'::public.order_status
  )
  returning * into v_order;

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

revoke all on function public.create_order(
  uuid, numeric, numeric, text, numeric, numeric, text, numeric,
  text, text, numeric, numeric
) from public, anon, authenticated;
grant execute on function public.create_order(
  uuid, numeric, numeric, text, numeric, numeric, text, numeric,
  text, text, numeric, numeric
) to authenticated;
