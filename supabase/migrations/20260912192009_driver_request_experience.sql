-- Waiting-offer UX needs the customer's original price without another read.
drop function public.get_driver_offer(uuid);

create function public.get_driver_offer(p_order_id uuid)
returns table (
  id uuid, order_id uuid, offered_price numeric, proposed_price numeric,
  status public.offer_status, order_status public.order_status,
  bidding_expires_at timestamptz, assigned_to_me boolean,
  pickup_address text, destination_address text,
  service_code text, service_name text, server_now timestamptz
)
language sql stable security definer set search_path = ''
as $function$
  select f.id, f.order_id, f.offered_price, o.proposed_price,
    f.status, o.status, o.bidding_expires_at,
    (o.driver_id = d.id and o.selected_offer_id = f.id) is true,
    o.pickup_address, o.destination_address, s.code, s.name_ar,
    statement_timestamp()
  from public.drivers d
  join public.offers f on f.driver_id = d.id and f.order_id = p_order_id
  join public.orders o on o.id = f.order_id
  join public.service_types s on s.id = o.service_type_id
  where d.user_id = (select auth.uid())
  order by f.created_at desc, f.id desc
  limit 1;
$function$;

revoke all on function public.get_driver_offer(uuid)
from public, anon, authenticated;
grant execute on function public.get_driver_offer(uuid) to authenticated;

-- Preserve the existing geographic/candidate implementation and add the
-- database clock to the same response, avoiding a second client read.
alter function public.get_driver_requests(uuid)
rename to get_driver_requests_without_server_now;

revoke all on function public.get_driver_requests_without_server_now(uuid)
from public, anon, authenticated;

create function public.get_driver_requests(p_order_id uuid default null)
returns table (
  id uuid, pickup_address text, destination_address text,
  pickup_lat numeric, pickup_lng numeric,
  destination_lat numeric, destination_lng numeric,
  proposed_price numeric, agreed_price numeric, status public.order_status,
  created_at timestamptz, completed_at timestamptz,
  bidding_expires_at timestamptz, service_code text, service_name text,
  route_distance_meters integer, route_duration_seconds integer,
  route_polyline text, driver_distance_meters integer,
  dispatch_radius_meters integer, server_now timestamptz
)
language sql volatile security definer set search_path = ''
as $function$
  select request.*, statement_timestamp()
  from public.get_driver_requests_without_server_now(p_order_id) request;
$function$;

revoke all on function public.get_driver_requests(uuid)
from public, anon, authenticated;
grant execute on function public.get_driver_requests(uuid) to authenticated;
