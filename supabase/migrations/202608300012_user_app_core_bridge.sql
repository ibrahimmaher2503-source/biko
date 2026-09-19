-- Milestone 7: the two small server bridges required by User App restoration.

create function public.expire_customer_order(p_order_id uuid)
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
    and customer_id = v_uid
  for update;

  if not found then
    raise exception 'Order not found' using errcode = 'P0002';
  end if;

  if v_order.status = 'BIDDING'::public.order_status
     and v_order.bidding_expires_at <= clock_timestamp() then
    update public.orders
    set status = 'EXPIRED'::public.order_status,
        expired_at = coalesce(expired_at, clock_timestamp()),
        updated_at = clock_timestamp()
    where id = v_order.id
    returning * into v_order;

    update public.offers
    set status = 'CLOSED'::public.offer_status,
        updated_at = clock_timestamp()
    where order_id = v_order.id
      and status = 'ACTIVE'::public.offer_status;
  end if;

  return v_order;
end;
$function$;

create function public.get_customer_assigned_driver(p_order_id uuid)
returns table (
  driver_public_id uuid,
  driver_first_name text,
  driver_photo_url text,
  driver_type public.driver_type,
  office_display_name text,
  completed_trip_count integer
)
language sql
stable
security definer
set search_path = ''
as $function$
  select
    driver.id,
    split_part(btrim(profile.full_name), ' ', 1),
    profile.profile_photo_url,
    driver.driver_type,
    office.name,
    driver.completed_trip_count
  from public.orders customer_order
  join public.drivers driver on driver.id = customer_order.driver_id
  join public.profiles profile on profile.id = driver.user_id
  left join public.offices office on office.id = customer_order.office_id
  where customer_order.id = p_order_id
    and customer_order.customer_id = (select auth.uid())
    and customer_order.status in (
      'DRIVER_ASSIGNED'::public.order_status,
      'DRIVER_ON_WAY'::public.order_status,
      'DRIVER_ARRIVED'::public.order_status,
      'IN_PROGRESS'::public.order_status,
      'COMPLETED'::public.order_status,
      'CANCELLED'::public.order_status
    )
  limit 1;
$function$;

revoke all on function public.expire_customer_order(uuid),
  public.get_customer_assigned_driver(uuid)
from public, anon, authenticated;

grant execute on function public.expire_customer_order(uuid),
  public.get_customer_assigned_driver(uuid)
to authenticated;
