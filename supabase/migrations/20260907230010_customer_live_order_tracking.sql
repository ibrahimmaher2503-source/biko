-- Customer-visible tracking is a deliberately narrow projection, never a read
-- grant on the Driver's private latest-location source.
create table public.order_driver_tracking (
  order_id uuid primary key references public.orders(id) on delete cascade,
  customer_id uuid not null references public.profiles(id) on delete cascade,
  driver_id uuid not null references public.drivers(id) on delete cascade,
  latitude numeric(9,6) not null,
  longitude numeric(9,6) not null,
  heading_degrees numeric(6,2),
  driver_location_updated_at timestamptz not null,
  eta_seconds integer check (eta_seconds is null or eta_seconds >= 0),
  eta_updated_at timestamptz,
  eta_refresh_started_at timestamptz,
  eta_reservation_id uuid,
  updated_at timestamptz not null default clock_timestamp(),
  check ((eta_seconds is null) = (eta_updated_at is null))
);

alter table public.order_driver_tracking enable row level security;
revoke all on table public.order_driver_tracking from public, anon, authenticated;
grant select on table public.order_driver_tracking to authenticated;

create policy order_driver_tracking_select_owned_active
on public.order_driver_tracking for select to authenticated
using (
  customer_id = (select auth.uid())
  and exists (
    select 1 from public.profiles p
    where p.id = (select auth.uid())
      and p.profile_type = 'CUSTOMER'::public.profile_type
      and p.status = 'ACTIVE'::public.account_status
  )
  and exists (
    select 1 from public.orders o
    where o.id = order_driver_tracking.order_id
      and o.customer_id = (select auth.uid())
      and o.driver_id = order_driver_tracking.driver_id
      and o.status in (
        'DRIVER_ASSIGNED'::public.order_status,
        'DRIVER_ON_WAY'::public.order_status,
        'DRIVER_ARRIVED'::public.order_status,
        'IN_PROGRESS'::public.order_status
      )
  )
);

create function private.project_driver_location_to_active_order()
returns trigger
language plpgsql security definer set search_path = ''
as $function$
begin
  insert into public.order_driver_tracking (
    order_id, customer_id, driver_id, latitude, longitude, heading_degrees,
    driver_location_updated_at, eta_seconds, eta_updated_at,
    eta_refresh_started_at, eta_reservation_id, updated_at
  )
  select o.id, o.customer_id, new.driver_id, new.latitude, new.longitude,
    new.heading_degrees, new.updated_at, null, null, null, null, clock_timestamp()
  from public.orders o
  where o.driver_id = new.driver_id
    and o.status in (
      'DRIVER_ASSIGNED'::public.order_status,
      'DRIVER_ON_WAY'::public.order_status,
      'DRIVER_ARRIVED'::public.order_status,
      'IN_PROGRESS'::public.order_status
    )
  on conflict (order_id) do update set
    customer_id = excluded.customer_id,
    driver_id = excluded.driver_id,
    latitude = excluded.latitude,
    longitude = excluded.longitude,
    heading_degrees = excluded.heading_degrees,
    driver_location_updated_at = excluded.driver_location_updated_at,
    updated_at = excluded.updated_at;
  return new;
end;
$function$;

create trigger driver_latest_locations_project_active_order
after insert or update on public.driver_latest_locations
for each row execute function private.project_driver_location_to_active_order();

create function private.sync_active_order_tracking()
returns trigger
language plpgsql security definer set search_path = ''
as $function$
begin
  if new.status not in (
    'DRIVER_ASSIGNED'::public.order_status,
    'DRIVER_ON_WAY'::public.order_status,
    'DRIVER_ARRIVED'::public.order_status,
    'IN_PROGRESS'::public.order_status
  ) then
    delete from public.order_driver_tracking where order_id = new.id;
  elsif old.driver_id is distinct from new.driver_id then
    delete from public.order_driver_tracking where order_id = new.id;
    insert into public.order_driver_tracking (
      order_id, customer_id, driver_id, latitude, longitude, heading_degrees,
      driver_location_updated_at
    )
    select new.id, new.customer_id, new.driver_id, l.latitude, l.longitude,
      l.heading_degrees, l.updated_at
    from public.driver_latest_locations l where l.driver_id = new.driver_id
    on conflict (order_id) do nothing;
  elsif old.status is distinct from new.status and new.status = 'IN_PROGRESS'::public.order_status then
    update public.order_driver_tracking set eta_seconds = null, eta_updated_at = null,
      eta_refresh_started_at = null, eta_reservation_id = null, updated_at = clock_timestamp()
    where order_id = new.id;
  elsif old.status = 'BIDDING'::public.order_status then
    insert into public.order_driver_tracking (
      order_id, customer_id, driver_id, latitude, longitude, heading_degrees,
      driver_location_updated_at
    )
    select new.id, new.customer_id, new.driver_id, l.latitude, l.longitude,
      l.heading_degrees, l.updated_at
    from public.driver_latest_locations l where l.driver_id = new.driver_id
    on conflict (order_id) do nothing;
  end if;
  return new;
end;
$function$;

create trigger orders_sync_active_tracking
after update of status, driver_id on public.orders
for each row execute function private.sync_active_order_tracking();

create function private.get_customer_order_tracking(p_order_id uuid)
returns table (
  latitude numeric,
  longitude numeric,
  heading_degrees numeric,
  driver_location_updated_at timestamptz,
  eta_seconds integer,
  eta_updated_at timestamptz,
  is_stale boolean
)
language sql stable security definer set search_path = ''
as $function$
  select t.latitude, t.longitude, t.heading_degrees,
    t.driver_location_updated_at, t.eta_seconds, t.eta_updated_at,
    t.driver_location_updated_at < clock_timestamp() - make_interval(
      secs => private.setting_positive_int('driver_location_freshness_seconds', 120)
    )
  from public.order_driver_tracking t
  join public.orders o on o.id = t.order_id
  where t.order_id = p_order_id
    and t.customer_id = (select auth.uid())
    and exists (select 1 from public.profiles p where p.id = (select auth.uid())
      and p.profile_type = 'CUSTOMER'::public.profile_type and p.status = 'ACTIVE'::public.account_status)
    and o.customer_id = (select auth.uid())
    and o.driver_id = t.driver_id
    and o.status in (
      'DRIVER_ASSIGNED'::public.order_status,
      'DRIVER_ON_WAY'::public.order_status,
      'DRIVER_ARRIVED'::public.order_status,
      'IN_PROGRESS'::public.order_status
    );
$function$;

-- The Edge Function calls this with the caller JWT before spending a Routes API
-- request. The per-order lease is the shared 60-second cache/single-flight.
create function private.reserve_customer_order_eta(p_order_id uuid)
returns table (
  refresh_required boolean,
  latitude numeric,
  longitude numeric,
  target_latitude numeric,
  target_longitude numeric,
  eta_seconds integer,
  eta_updated_at timestamptz,
  eta_reservation_id uuid
)
language plpgsql security definer set search_path = ''
as $function$
declare
  v_tracking public.order_driver_tracking;
  v_order public.orders;
begin
  select t.* into v_tracking from public.order_driver_tracking t
  join public.orders o on o.id = t.order_id
  where t.order_id = p_order_id
    and t.customer_id = (select auth.uid())
    and exists (select 1 from public.profiles p where p.id = (select auth.uid())
      and p.profile_type = 'CUSTOMER'::public.profile_type and p.status = 'ACTIVE'::public.account_status)
    and o.customer_id = (select auth.uid())
    and o.driver_id = t.driver_id
    and o.status in (
      'DRIVER_ASSIGNED'::public.order_status,
      'DRIVER_ON_WAY'::public.order_status,
      'DRIVER_ARRIVED'::public.order_status,
      'IN_PROGRESS'::public.order_status
    )
  for update of t;
  if not found then return; end if;
  select * into v_order from public.orders where id = p_order_id;
  if v_tracking.driver_location_updated_at < clock_timestamp() - make_interval(
    secs => private.setting_positive_int('driver_location_freshness_seconds', 120)
  ) then return; end if;

  if v_order.status = 'DRIVER_ARRIVED'::public.order_status then
    update public.order_driver_tracking
    set eta_seconds = 0, eta_updated_at = clock_timestamp(),
      eta_refresh_started_at = null, eta_reservation_id = null, updated_at = clock_timestamp()
    where order_id = p_order_id;
    return query select false, v_tracking.latitude, v_tracking.longitude,
      v_order.pickup_lat, v_order.pickup_lng, 0, clock_timestamp(), null::uuid;
    return;
  end if;
  if v_tracking.eta_seconds is not null
     and v_tracking.eta_updated_at >= clock_timestamp() - interval '60 seconds' then
    return query select false, v_tracking.latitude, v_tracking.longitude,
      case when v_order.status = 'IN_PROGRESS'::public.order_status then v_order.destination_lat else v_order.pickup_lat end,
      case when v_order.status = 'IN_PROGRESS'::public.order_status then v_order.destination_lng else v_order.pickup_lng end,
      v_tracking.eta_seconds, v_tracking.eta_updated_at, null::uuid;
    return;
  end if;
  if v_tracking.eta_refresh_started_at >= clock_timestamp() - interval '60 seconds' then
    return query select false, v_tracking.latitude, v_tracking.longitude,
      case when v_order.status = 'IN_PROGRESS'::public.order_status then v_order.destination_lat else v_order.pickup_lat end,
      case when v_order.status = 'IN_PROGRESS'::public.order_status then v_order.destination_lng else v_order.pickup_lng end,
      null::integer, null::timestamptz, null::uuid;
    return;
  end if;
  update public.order_driver_tracking set eta_seconds = null, eta_updated_at = null,
    eta_refresh_started_at = clock_timestamp(), eta_reservation_id = gen_random_uuid(), updated_at = clock_timestamp()
  where order_id = p_order_id;
  select * into v_tracking from public.order_driver_tracking where order_id = p_order_id;
  return query select true, v_tracking.latitude, v_tracking.longitude,
    case when v_order.status = 'IN_PROGRESS'::public.order_status then v_order.destination_lat else v_order.pickup_lat end,
    case when v_order.status = 'IN_PROGRESS'::public.order_status then v_order.destination_lng else v_order.pickup_lng end,
    null::integer, null::timestamptz, v_tracking.eta_reservation_id;
end;
$function$;

create function public.get_customer_order_tracking(p_order_id uuid)
returns table (
  latitude numeric, longitude numeric, heading_degrees numeric,
  driver_location_updated_at timestamptz, eta_seconds integer,
  eta_updated_at timestamptz, is_stale boolean
)
language sql stable security invoker set search_path = ''
as $function$
  select * from private.get_customer_order_tracking(p_order_id);
$function$;

create function public.reserve_customer_order_eta(p_order_id uuid)
returns table (
  refresh_required boolean, latitude numeric, longitude numeric,
  target_latitude numeric, target_longitude numeric, eta_seconds integer,
  eta_updated_at timestamptz, eta_reservation_id uuid
)
language sql volatile security invoker set search_path = ''
as $function$
  select * from private.reserve_customer_order_eta(p_order_id);
$function$;

revoke all on function public.get_customer_order_tracking(uuid), public.reserve_customer_order_eta(uuid),
  private.get_customer_order_tracking(uuid), private.reserve_customer_order_eta(uuid)
from public, anon, authenticated;
grant execute on function public.get_customer_order_tracking(uuid), public.reserve_customer_order_eta(uuid),
  private.get_customer_order_tracking(uuid), private.reserve_customer_order_eta(uuid)
to authenticated;
revoke all on function private.project_driver_location_to_active_order(), private.sync_active_order_tracking()
from public, anon, authenticated;

do $publication$
begin
  alter publication supabase_realtime add table public.order_driver_tracking;
exception when duplicate_object then null;
end;
$publication$;
