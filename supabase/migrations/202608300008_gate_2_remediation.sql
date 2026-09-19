-- Gate 2 remediation only. Existing 6.1/7A behavior is preserved.
-- Database invariants also protect trusted/manual writes.
create unique index orders_one_active_job_per_driver_idx
  on public.orders (driver_id)
  where status in ('DRIVER_ASSIGNED', 'DRIVER_ON_WAY', 'DRIVER_ARRIVED', 'IN_PROGRESS');

alter table public.offers add constraint offers_order_id_id_key unique (order_id, id);
alter table public.orders
  drop constraint orders_selected_offer_fk,
  add constraint orders_selected_offer_same_order_fk
    foreign key (id, selected_offer_id) references public.offers (order_id, id);

drop policy orders_select_permitted on public.orders;
create policy orders_select_permitted on public.orders for select to authenticated
using (
  customer_id = (select auth.uid())
  or private.is_super_admin()
  or private.can_access_office(office_id, 'orders.view')
);
-- The separate assigned-driver policy remains unchanged.

-- Explicit operational projection; no customer/profile/recipient/private columns.
-- A detail request may also return the caller's assigned (including terminal) order.
create function public.get_driver_requests(p_order_id uuid default null)
returns table (
  id uuid, pickup_address text, destination_address text,
  proposed_price numeric, agreed_price numeric, status public.order_status,
  created_at timestamptz, completed_at timestamptz, bidding_expires_at timestamptz,
  service_code text, service_name text
)
language sql stable security definer set search_path = ''
as $function$
  select o.id, o.pickup_address, o.destination_address, o.proposed_price,
         o.agreed_price, o.status, o.created_at, o.completed_at, o.bidding_expires_at,
         s.code, s.name_ar
  from public.drivers d
  join public.profiles p on p.id = d.user_id
  join public.orders o on (p_order_id is null or o.id = p_order_id)
  join public.service_types s on s.id = o.service_type_id
  where d.user_id = (select auth.uid())
    and (
      (p_order_id is not null and o.driver_id = d.id)
      or (
        o.status = 'BIDDING' and o.bidding_expires_at > now()
        and d.status = 'ACTIVE' and d.is_online
        and p.profile_type = 'DRIVER' and p.status = 'ACTIVE'
        and (d.office_id is null or exists (
          select 1 from public.offices f where f.id = d.office_id and f.status = 'ACTIVE'
        ))
        and not exists (
          select 1 from public.orders a where a.driver_id = d.id
            and a.status in ('DRIVER_ASSIGNED', 'DRIVER_ON_WAY', 'DRIVER_ARRIVED', 'IN_PROGRESS')
        )
        and exists (
          select 1 from public.order_driver_candidates c where c.order_id = o.id and c.driver_id = d.id
        )
      )
    )
  order by o.created_at desc, o.id
  limit 20;
$function$;

-- Paging keeps every valid waiting offer reachable without N+1 order lookups.
create function public.get_driver_active_offers(p_offset integer default 0)
returns table (
  id uuid, order_id uuid, offered_price numeric, status public.offer_status,
  pickup_address text, destination_address text
)
language sql stable security definer set search_path = ''
as $function$
  select f.id, f.order_id, f.offered_price, f.status, o.pickup_address, o.destination_address
  from public.drivers d
  join public.offers f on f.driver_id = d.id
  join public.orders o on o.id = f.order_id
  where d.user_id = (select auth.uid())
    and f.status = 'ACTIVE' and o.status = 'BIDDING' and o.bidding_expires_at > now()
    and not exists (
      select 1 from public.orders a where a.driver_id = d.id
        and a.status in ('DRIVER_ASSIGNED', 'DRIVER_ON_WAY', 'DRIVER_ARRIVED', 'IN_PROGRESS')
    )
  order by f.created_at desc, f.id
  limit 50 offset greatest(coalesce(p_offset, 0), 0);
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

  if exists (
    select 1 from public.orders o where o.driver_id = v_driver.id
      and o.status in ('DRIVER_ASSIGNED', 'DRIVER_ON_WAY', 'DRIVER_ARRIVED', 'IN_PROGRESS')
  ) then
    raise exception 'Driver already has an active assignment' using errcode = 'P0001';
  end if;

  if not found
     or v_driver.status <> 'ACTIVE'::public.driver_status
     or not v_driver.is_online
     or (v_driver.office_id is not null and not exists (
       select 1 from public.offices o where o.id = v_driver.office_id and o.status = 'ACTIVE'
     ))
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
    and order_id = p_order_id;
  -- Do not lock the offer before the Driver: another selection must be able
  -- to close this Driver's cross-order offers while we wait on the Driver.

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

  if exists (
    select 1 from public.orders o where o.driver_id = v_driver.id
      and o.status in ('DRIVER_ASSIGNED', 'DRIVER_ON_WAY', 'DRIVER_ARRIVED', 'IN_PROGRESS')
  ) then
    raise exception 'Driver already has an active assignment' using errcode = 'P0001';
  end if;

  -- Refresh after the Driver lock, including changes committed while waiting.
  select o.* into v_offer from public.offers o
  where o.id = p_offer_id and o.order_id = p_order_id;
  if v_offer.status <> 'ACTIVE' then
    raise exception 'Active offer for this order required' using errcode = 'P0001';
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

  -- Lock the entire affected offer set in a consistent order.
  perform o.id from public.offers o
  where o.status = 'ACTIVE' and (o.order_id = p_order_id or o.driver_id = v_driver.id)
  order by o.id for update;

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
  set status = case when id = v_offer.id then 'SELECTED'::public.offer_status
                    else 'CLOSED'::public.offer_status end,
      updated_at = now()
  where status = 'ACTIVE'
    and (order_id = v_order.id or driver_id = v_driver.id);

  update public.drivers set is_online = false, updated_at = now()
  where id = v_driver.id;

  return v_order;
end;
$function$;

-- Online means available for NEW work, not permission to progress an assigned trip.
create or replace function private.advance_order_state(
  p_order_id uuid,
  p_expected public.order_status,
  p_next public.order_status
)
returns public.orders
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_uid uuid := (select auth.uid());
  v_order public.orders;
  v_driver public.drivers;
  v_profile_status public.account_status;
  v_profile_type public.profile_type;
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  if not (
    (p_expected = 'DRIVER_ASSIGNED'::public.order_status and p_next = 'DRIVER_ON_WAY'::public.order_status)
    or (p_expected = 'DRIVER_ON_WAY'::public.order_status and p_next = 'DRIVER_ARRIVED'::public.order_status)
    or (p_expected = 'DRIVER_ARRIVED'::public.order_status and p_next = 'IN_PROGRESS'::public.order_status)
    or (p_expected = 'IN_PROGRESS'::public.order_status and p_next = 'COMPLETED'::public.order_status)
  ) then
    raise exception 'Invalid order state transition' using errcode = '22023';
  end if;

  select * into v_order
  from public.orders
  where id = p_order_id
  for update;

  if not found then
    raise exception 'Order not found' using errcode = 'P0002';
  end if;
  if v_order.status <> p_expected then
    raise exception 'Order is not in the expected state' using errcode = 'P0001';
  end if;

  select * into v_driver
  from public.drivers
  where id = v_order.driver_id
    and user_id = v_uid
  for update;

  if not found then
    raise exception 'Only the assigned driver can perform this action' using errcode = '42501';
  end if;

  select p.status, p.profile_type
  into v_profile_status, v_profile_type
  from public.profiles p
  where p.id = v_driver.user_id;

  if v_driver.status <> 'ACTIVE'::public.driver_status
     or v_profile_status <> 'ACTIVE'::public.account_status
     or v_profile_type <> 'DRIVER'::public.profile_type
     or (v_driver.office_id is not null and not exists (
       select 1
       from public.offices o
       where o.id = v_driver.office_id
         and o.status = 'ACTIVE'::public.account_status
     )) then
    raise exception 'Assigned driver is not operationally valid' using errcode = '42501';
  end if;

  case p_next
    when 'DRIVER_ON_WAY'::public.order_status then
      update public.orders
      set status = p_next,
          driver_on_way_at = coalesce(driver_on_way_at, now()),
          updated_at = now()
      where id = v_order.id
      returning * into v_order;
    when 'DRIVER_ARRIVED'::public.order_status then
      update public.orders
      set status = p_next,
          driver_arrived_at = coalesce(driver_arrived_at, now()),
          updated_at = now()
      where id = v_order.id
      returning * into v_order;
    when 'IN_PROGRESS'::public.order_status then
      update public.orders
      set status = p_next,
          started_at = coalesce(started_at, now()),
          updated_at = now()
      where id = v_order.id
      returning * into v_order;
    when 'COMPLETED'::public.order_status then
      update public.orders
      set status = p_next,
          completed_at = coalesce(completed_at, now()),
          updated_at = now()
      where id = v_order.id
      returning * into v_order;
  end case;

  return v_order;
end;
$function$;

revoke all on function public.get_driver_requests(uuid) from public, anon, authenticated;
revoke all on function public.get_driver_active_offers(integer) from public, anon, authenticated;
grant execute on function public.get_driver_requests(uuid) to authenticated;
grant execute on function public.get_driver_active_offers(integer) to authenticated;
revoke all on function public.submit_offer(uuid, numeric) from public, anon;
revoke all on function public.accept_offer(uuid, uuid) from public, anon;
revoke all on function private.advance_order_state(uuid, public.order_status, public.order_status) from public, anon, authenticated;

