-- D05: expose the minimum customer contact data only to the assigned Driver.
create function private.get_driver_active_customer_contact(p_order_id uuid)
returns table (customer_name text, customer_phone text)
language sql stable security definer set search_path = ''
as $function$
  select customer.full_name, customer.phone
  from public.orders customer_order
  join public.drivers assigned_driver
    on assigned_driver.id = customer_order.driver_id
   and assigned_driver.user_id = (select auth.uid())
   and assigned_driver.status = 'ACTIVE'::public.driver_status
  join public.profiles driver_profile
    on driver_profile.id = assigned_driver.user_id
   and driver_profile.profile_type = 'DRIVER'::public.profile_type
   and driver_profile.status = 'ACTIVE'::public.account_status
  join public.profiles customer
    on customer.id = customer_order.customer_id
   and customer.profile_type = 'CUSTOMER'::public.profile_type
   and customer.status = 'ACTIVE'::public.account_status
  where customer_order.id = p_order_id
    and customer_order.status in (
      'DRIVER_ASSIGNED'::public.order_status,
      'DRIVER_ON_WAY'::public.order_status,
      'DRIVER_ARRIVED'::public.order_status,
      'IN_PROGRESS'::public.order_status
    )
  limit 1;
$function$;

revoke all on function private.get_driver_active_customer_contact(uuid)
from public, anon, authenticated;
grant execute on function private.get_driver_active_customer_contact(uuid)
to authenticated;

create function public.get_driver_active_customer_contact(p_order_id uuid)
returns table (customer_name text, customer_phone text)
language sql stable security invoker set search_path = ''
as $function$
  select * from private.get_driver_active_customer_contact(p_order_id);
$function$;

revoke all on function public.get_driver_active_customer_contact(uuid)
from public, anon, authenticated;
grant execute on function public.get_driver_active_customer_contact(uuid)
to authenticated;
