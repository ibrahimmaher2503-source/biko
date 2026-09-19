-- Keep the compact assigned-driver read usable for terminal orders created
-- before Milestone 10, which may not have a motorcycle snapshot.
drop function public.get_customer_assigned_driver(uuid);
create function public.get_customer_assigned_driver(p_order_id uuid)
returns table (
  driver_public_id uuid,
  driver_first_name text,
  driver_photo_url text,
  driver_type public.driver_type,
  office_display_name text,
  completed_trip_count integer,
  driver_verified boolean,
  motorcycle_brand text,
  motorcycle_model text,
  motorcycle_plate_number text
)
language sql stable security definer set search_path = ''
as $function$
  select
    driver.id,
    split_part(btrim(profile.full_name), ' ', 1),
    profile.profile_photo_url,
    driver.driver_type,
    office.name,
    driver.completed_trip_count,
    motorcycle.id is not null
      and driver.status = 'ACTIVE'::public.driver_status
      and motorcycle.verification_status = 'APPROVED'::public.document_status,
    motorcycle.brand,
    motorcycle.model,
    motorcycle.plate_number
  from public.orders customer_order
  join public.drivers driver on driver.id = customer_order.driver_id
  join public.profiles profile on profile.id = driver.user_id
  left join public.motorcycles motorcycle on motorcycle.id = customer_order.motorcycle_id
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

revoke all on function public.get_customer_assigned_driver(uuid)
from public, anon, authenticated;
grant execute on function public.get_customer_assigned_driver(uuid)
to authenticated;
