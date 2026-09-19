-- A driver's phone is intentionally a narrow, post-assignment customer read.
create function private.get_customer_active_driver_contact(p_order_id uuid)
returns table (driver_phone text)
language sql stable security definer set search_path = ''
as $function$
  select profile.phone
  from public.orders customer_order
  join public.drivers driver on driver.id = customer_order.driver_id
  join public.profiles profile on profile.id = driver.user_id
  where customer_order.id = p_order_id
    and customer_order.customer_id = (select auth.uid())
    and driver.status = 'ACTIVE'::public.driver_status
    and exists (
      select 1
      from public.profiles customer
      where customer.id = (select auth.uid())
        and customer.profile_type = 'CUSTOMER'::public.profile_type
        and customer.status = 'ACTIVE'::public.account_status
    )
    and customer_order.status in (
      'DRIVER_ASSIGNED'::public.order_status,
      'DRIVER_ON_WAY'::public.order_status,
      'DRIVER_ARRIVED'::public.order_status,
      'IN_PROGRESS'::public.order_status
    )
  limit 1;
$function$;

revoke all on function private.get_customer_active_driver_contact(uuid)
from public, anon, authenticated;
grant execute on function private.get_customer_active_driver_contact(uuid)
to authenticated;

create function public.get_customer_active_driver_contact(p_order_id uuid)
returns table (driver_phone text)
language sql stable security invoker set search_path = ''
as $function$
  select * from private.get_customer_active_driver_contact(p_order_id);
$function$;

revoke all on function public.get_customer_active_driver_contact(uuid)
from public, anon, authenticated;
grant execute on function public.get_customer_active_driver_contact(uuid)
to authenticated;
