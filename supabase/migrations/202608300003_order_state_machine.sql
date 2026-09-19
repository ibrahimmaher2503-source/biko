-- Milestone 5: secure lifecycle transitions, cancellation, and bidding expiry.

alter table public.orders
  add column bidding_expires_at timestamptz not null default (now() + interval '30 minutes'),
  add column driver_on_way_at timestamptz,
  add column driver_arrived_at timestamptz,
  add column started_at timestamptz,
  add column completed_at timestamptz,
  add column cancelled_at timestamptz,
  add column expired_at timestamptz;

create index orders_bidding_expiry_idx
  on public.orders (bidding_expires_at)
  where status = 'BIDDING'::public.order_status;

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
     or not v_driver.is_online
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

create or replace function public.driver_on_way(p_order_id uuid)
returns public.orders
language sql
security definer
set search_path = ''
as $function$
  select private.advance_order_state(
    p_order_id,
    'DRIVER_ASSIGNED'::public.order_status,
    'DRIVER_ON_WAY'::public.order_status
  );
$function$;

create or replace function public.driver_arrived(p_order_id uuid)
returns public.orders
language sql
security definer
set search_path = ''
as $function$
  select private.advance_order_state(
    p_order_id,
    'DRIVER_ON_WAY'::public.order_status,
    'DRIVER_ARRIVED'::public.order_status
  );
$function$;

create or replace function public.start_order(p_order_id uuid)
returns public.orders
language sql
security definer
set search_path = ''
as $function$
  select private.advance_order_state(
    p_order_id,
    'DRIVER_ARRIVED'::public.order_status,
    'IN_PROGRESS'::public.order_status
  );
$function$;

create or replace function public.complete_order(p_order_id uuid)
returns public.orders
language sql
security definer
set search_path = ''
as $function$
  select private.advance_order_state(
    p_order_id,
    'IN_PROGRESS'::public.order_status,
    'COMPLETED'::public.order_status
  );
$function$;

create or replace function public.cancel_order(p_order_id uuid)
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

  update public.orders
  set status = 'CANCELLED'::public.order_status,
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

-- Expiry is a trusted maintenance operation; it is not exposed to client roles.
create or replace function public.expire_order(p_order_id uuid)
returns public.orders
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_order public.orders;
begin
  select * into v_order
  from public.orders
  where id = p_order_id
  for update;

  if not found then
    raise exception 'Order not found' using errcode = 'P0002';
  end if;
  if v_order.status <> 'BIDDING'::public.order_status then
    raise exception 'Only BIDDING orders can expire' using errcode = 'P0001';
  end if;
  if v_order.bidding_expires_at is null or v_order.bidding_expires_at > now() then
    raise exception 'Bidding expiry has not elapsed' using errcode = 'P0001';
  end if;

  update public.orders
  set status = 'EXPIRED'::public.order_status,
      expired_at = coalesce(expired_at, now()),
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

revoke all on function private.advance_order_state(uuid, public.order_status, public.order_status) from public, anon, authenticated;
revoke all on function public.driver_on_way(uuid) from public, anon, authenticated;
revoke all on function public.driver_arrived(uuid) from public, anon, authenticated;
revoke all on function public.start_order(uuid) from public, anon, authenticated;
revoke all on function public.complete_order(uuid) from public, anon, authenticated;
revoke all on function public.cancel_order(uuid) from public, anon, authenticated;
revoke all on function public.expire_order(uuid) from public, anon, authenticated;
grant execute on function public.driver_on_way(uuid) to authenticated;
grant execute on function public.driver_arrived(uuid) to authenticated;
grant execute on function public.start_order(uuid) to authenticated;
grant execute on function public.complete_order(uuid) to authenticated;
grant execute on function public.cancel_order(uuid) to authenticated;
grant execute on function public.expire_order(uuid) to service_role;
