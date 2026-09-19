-- Milestone 4: orders, offers, eligibility boundaries, and atomic offer acceptance.

create type public.order_status as enum (
  'DRAFT',
  'BIDDING',
  'DRIVER_ASSIGNED',
  'DRIVER_ON_WAY',
  'DRIVER_ARRIVED',
  'IN_PROGRESS',
  'COMPLETED',
  'CANCELLED',
  'EXPIRED'
);

create type public.offer_status as enum (
  'ACTIVE',
  'SELECTED',
  'REJECTED',
  'WITHDRAWN',
  'EXPIRED',
  'CLOSED'
);

create table public.orders (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.profiles(id),
  service_type_id uuid not null references public.service_types(id),
  pickup_lat numeric(9,6) not null check (pickup_lat between -90 and 90 and pickup_lat <> 'NaN'::numeric),
  pickup_lng numeric(9,6) not null check (pickup_lng between -180 and 180 and pickup_lng <> 'NaN'::numeric),
  destination_lat numeric(9,6) not null check (destination_lat between -90 and 90 and destination_lat <> 'NaN'::numeric),
  destination_lng numeric(9,6) not null check (destination_lng between -180 and 180 and destination_lng <> 'NaN'::numeric),
  pickup_address text not null check (nullif(btrim(pickup_address), '') is not null),
  destination_address text not null check (nullif(btrim(destination_address), '') is not null),
  proposed_price numeric(12,2) not null check (proposed_price > 0 and proposed_price <> 'NaN'::numeric),
  agreed_price numeric(12,2) check (agreed_price is null or (agreed_price > 0 and agreed_price <> 'NaN'::numeric)),
  driver_id uuid references public.drivers(id),
  selected_offer_id uuid,
  office_id uuid references public.offices(id),
  status public.order_status not null default 'DRAFT',
  created_at timestamptz not null default now(),
  assigned_at timestamptz,
  updated_at timestamptz not null default now()
);

create table public.offers (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  driver_id uuid not null references public.drivers(id),
  office_id uuid references public.offices(id),
  offered_price numeric(12,2) not null check (offered_price > 0 and offered_price <> 'NaN'::numeric),
  status public.offer_status not null default 'ACTIVE',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.orders
  add constraint orders_selected_offer_fk
  foreign key (selected_offer_id) references public.offers(id);

-- Trusted dispatch writes candidates; clients can only see candidates for themselves.
create table public.order_driver_candidates (
  order_id uuid not null references public.orders(id) on delete cascade,
  driver_id uuid not null references public.drivers(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (order_id, driver_id)
);

create index orders_customer_status_created_idx
  on public.orders (customer_id, status, created_at desc);
create index orders_driver_status_created_idx
  on public.orders (driver_id, status, created_at desc);
create index orders_office_status_created_idx
  on public.orders (office_id, status, created_at desc);
create index orders_bidding_created_idx
  on public.orders (created_at desc)
  where status = 'BIDDING'::public.order_status;
create index offers_order_status_created_idx
  on public.offers (order_id, status, created_at desc);
create index offers_driver_status_created_idx
  on public.offers (driver_id, status, created_at desc);
create index order_driver_candidates_driver_order_idx
  on public.order_driver_candidates (driver_id, order_id);
create unique index offers_one_active_per_driver_order_idx
  on public.offers (order_id, driver_id)
  where status = 'ACTIVE'::public.offer_status;

create trigger orders_set_updated_at before update on public.orders
for each row execute function public.set_updated_at();
create trigger offers_set_updated_at before update on public.offers
for each row execute function public.set_updated_at();

alter table public.orders enable row level security;
alter table public.offers enable row level security;
alter table public.order_driver_candidates enable row level security;

revoke all privileges on table public.orders, public.offers, public.order_driver_candidates from anon, authenticated;
grant select on table public.orders, public.offers, public.order_driver_candidates to authenticated;

create policy orders_select_permitted
on public.orders
for select
to authenticated
using (
  customer_id = (select auth.uid())
  or private.is_super_admin()
  or private.can_access_office(office_id, 'orders.view')
  or (
    status = 'BIDDING'::public.order_status
    and exists (
      select 1
      from public.order_driver_candidates c
      join public.drivers d on d.id = c.driver_id
      where c.order_id = orders.id
        and d.user_id = (select auth.uid())
        and d.status = 'ACTIVE'::public.driver_status
        and d.is_online
    )
  )
);

create policy offers_select_permitted
on public.offers
for select
to authenticated
using (
  private.is_super_admin()
  or private.can_access_office(office_id, 'orders.view')
  or exists (
    select 1
    from public.orders o
    where o.id = offers.order_id
      and o.customer_id = (select auth.uid())
      and o.status = 'BIDDING'::public.order_status
  )
  or exists (
    select 1
    from public.drivers d
    where d.id = offers.driver_id
      and d.user_id = (select auth.uid())
  )
);

create policy order_driver_candidates_select_permitted
on public.order_driver_candidates
for select
to authenticated
using (
  private.is_super_admin()
  or exists (
    select 1
    from public.drivers d
    where d.id = order_driver_candidates.driver_id
      and d.user_id = (select auth.uid())
  )
  or exists (
    select 1
    from public.drivers d
    where d.id = order_driver_candidates.driver_id
      and private.can_access_office(d.office_id, 'orders.view')
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
  p_proposed_price numeric
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

  if not exists (
    select 1
    from public.profiles p
    where p.id = v_uid
      and p.profile_type = 'CUSTOMER'::public.profile_type
      and p.status = 'ACTIVE'::public.account_status
  ) then
    raise exception 'Active customer profile required' using errcode = '42501';
  end if;

  if not exists (
    select 1
    from public.service_types st
    where st.id = p_service_type_id
      and st.is_enabled
      and st.code in ('RIDE', 'DELIVERY')
  ) then
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
  if v_order.status <> 'BIDDING'::public.order_status then
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
       select 1 from public.profiles p
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

  update public.offers
  set offered_price = p_offered_price,
      office_id = v_driver.office_id,
      updated_at = now()
  where order_id = p_order_id
    and driver_id = v_driver.id
    and status = 'ACTIVE'::public.offer_status
  returning * into v_offer;

  if found then
    return v_offer;
  end if;

  insert into public.offers (order_id, driver_id, office_id, offered_price, status)
  values (p_order_id, v_driver.id, v_driver.office_id, p_offered_price, 'ACTIVE'::public.offer_status)
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
  if v_order.status <> 'BIDDING'::public.order_status then
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
     or (v_driver.office_id is not null and not exists (
       select 1 from public.offices o
       where o.id = v_driver.office_id
         and o.status = 'ACTIVE'::public.account_status
     )) then
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

revoke all on function public.create_order(uuid, numeric, numeric, text, numeric, numeric, text, numeric) from public, anon, authenticated;
revoke all on function public.submit_offer(uuid, numeric) from public, anon, authenticated;
revoke all on function public.accept_offer(uuid, uuid) from public, anon, authenticated;
grant execute on function public.create_order(uuid, numeric, numeric, text, numeric, numeric, text, numeric) to authenticated;
grant execute on function public.submit_offer(uuid, numeric) to authenticated;
grant execute on function public.accept_offer(uuid, uuid) to authenticated;
