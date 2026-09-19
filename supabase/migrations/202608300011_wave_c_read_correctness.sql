-- Deep Code Review Wave C: completion statistics and offer read eligibility.

-- Reconcile the stored public statistic once before maintaining it incrementally.
with actual_counts as (
  select
    d.id,
    count(o.id) filter (
      where o.status = 'COMPLETED'::public.order_status
    )::integer as completed_count
  from public.drivers d
  left join public.orders o on o.driver_id = d.id
  group by d.id
)
update public.drivers d
set completed_trip_count = counts.completed_count,
    updated_at = now()
from actual_counts counts
where d.id = counts.id
  and d.completed_trip_count is distinct from counts.completed_count;

-- Online availability is unrelated to an assigned Driver's lifecycle authority.
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

      update public.drivers
      set completed_trip_count = completed_trip_count + 1,
          updated_at = now()
      where id = v_driver.id;
  end case;

  return v_order;
end;
$function$;

create or replace function public.get_customer_order_offers(p_order_id uuid)
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
    and ord.bidding_expires_at > clock_timestamp()
    and ofr.status = 'ACTIVE'::public.offer_status
    and dr.status = 'ACTIVE'::public.driver_status
    and dr.is_online
    and pr.profile_type = 'DRIVER'::public.profile_type
    and pr.status = 'ACTIVE'::public.account_status
    and (dr.office_id is null or offc.status = 'ACTIVE'::public.account_status)
    and exists (
      select 1
      from public.order_driver_candidates candidate
      where candidate.order_id = ord.id
        and candidate.driver_id = dr.id
    )
    and not exists (
      select 1
      from public.orders active_order
      where active_order.driver_id = dr.id
        and active_order.status in (
          'DRIVER_ASSIGNED'::public.order_status,
          'DRIVER_ON_WAY'::public.order_status,
          'DRIVER_ARRIVED'::public.order_status,
          'IN_PROGRESS'::public.order_status
        )
    )
  order by ofr.created_at desc;
end;
$function$;

revoke all on function private.advance_order_state(
  uuid, public.order_status, public.order_status
) from public, anon, authenticated;
revoke all on function public.get_customer_order_offers(uuid)
from public, anon, authenticated;
grant execute on function public.get_customer_order_offers(uuid) to authenticated;
