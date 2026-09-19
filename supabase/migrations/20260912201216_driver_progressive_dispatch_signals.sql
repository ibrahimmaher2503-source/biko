-- D03: trusted scheduled expansion for the existing 2/4/6/8 km dispatch.
-- The order-insert trigger already covers the initial generic NEW_WORK signal
-- for the 2 km stage. This tick only targets drivers newly discovered after
-- that stage, through the existing private notification outbox.

create function private.driver_is_initial_dispatch_eligible(
  p_driver_id uuid,
  p_order_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $function$
  select private.driver_is_geographically_eligible(p_driver_id, p_order_id)
    and exists (
      select 1
      from public.driver_latest_locations l
      join public.orders o on o.id = p_order_id
      where l.driver_id = p_driver_id
        and extensions.st_dwithin(
          l.position,
          extensions.st_setsrid(
            extensions.st_makepoint(o.pickup_lng::double precision, o.pickup_lat::double precision),
            4326
          )::extensions.geography,
          2000
        )
    );
$function$;

revoke all on function private.driver_is_initial_dispatch_eligible(uuid, uuid)
from public, anon, authenticated;

create function public.run_driver_progressive_dispatch_tick(
  p_order_id uuid default null,
  p_order_limit integer default 50,
  p_driver_limit integer default 200
)
returns integer
language plpgsql
volatile
security definer
set search_path = ''
as $function$
declare
  v_now timestamptz := clock_timestamp();
  v_order_limit integer := least(greatest(coalesce(p_order_limit, 50), 1), 50);
  v_driver_limit integer := least(greatest(coalesce(p_driver_limit, 200), 1), 200);
  v_signalled integer := 0;
begin
  with active_orders as (
    select
      o.id,
      o.service_type_id,
      private.dispatch_radius_meters(o.created_at) as dispatch_radius_meters,
      extensions.st_setsrid(
        extensions.st_makepoint(o.pickup_lng::double precision, o.pickup_lat::double precision),
        4326
      )::extensions.geography as pickup_position
    from public.orders o
    where (p_order_id is null or o.id = p_order_id)
      and o.status = 'BIDDING'::public.order_status
      and o.bidding_expires_at > v_now
      and o.created_at >= v_now - interval '90 seconds'
    order by o.created_at, o.id
    for update skip locked
    limit v_order_limit
  ), eligible_drivers as (
    -- ponytail: scheduler eligibility is a snapshot; request/offer RPCs recheck.
    -- Add driver-row serialization only if rare stale Push noise becomes material.
    select
      o.id as order_id,
      d.id as driver_id,
      d.user_id as driver_user_id,
      o.dispatch_radius_meters,
      round(extensions.st_distance(l.position, o.pickup_position))::integer
        as driver_distance_meters,
      extensions.st_dwithin(l.position, o.pickup_position, 2000)
        as initial_dispatch_eligible
    from active_orders o
    join public.drivers d on true
    join public.profiles p on p.id = d.user_id
    join public.driver_latest_locations l on l.driver_id = d.id
    join public.service_types service on service.id = o.service_type_id
    where d.status = 'ACTIVE'::public.driver_status
      and d.is_online
      and p.profile_type = 'DRIVER'::public.profile_type
      and p.status = 'ACTIVE'::public.account_status
      and private.driver_safety_ineligibility(d.id) is null
      and (service.code <> 'RIDE' or d.ride_safety_equipment_confirmed_at is not null)
      and (d.office_id is null or exists (
        select 1
        from public.offices office
        where office.id = d.office_id
          and office.status = 'ACTIVE'::public.account_status
      ))
      and not exists (
        select 1
        from public.orders active_order
        where active_order.driver_id = d.id
          and active_order.status in (
            'DRIVER_ASSIGNED'::public.order_status,
            'DRIVER_ON_WAY'::public.order_status,
            'DRIVER_ARRIVED'::public.order_status,
            'IN_PROGRESS'::public.order_status
          )
      )
      and l.updated_at >= v_now - make_interval(
        secs => private.setting_positive_int('driver_location_freshness_seconds', 120)
      )
      and private.operating_zone_allows(l.position)
      and private.operating_zone_allows(o.pickup_position)
      and extensions.st_dwithin(
        l.position, o.pickup_position, o.dispatch_radius_meters
      )
  ), new_candidates as (
    select e.*
    from eligible_drivers e
    where not exists (
      select 1
      from public.order_driver_candidates existing
      where existing.order_id = e.order_id
        and existing.driver_id = e.driver_id
    )
  ), bounded_candidates as (
    select n.*
    from (
      select
        n.*,
        row_number() over (
          partition by n.order_id
          order by
            (not n.initial_dispatch_eligible) desc,
            n.driver_distance_meters,
            n.driver_id
        ) as row_number
      from new_candidates n
    ) n
    where n.row_number <= v_driver_limit
  ), inserted_candidates as (
    insert into public.order_driver_candidates (order_id, driver_id)
    select order_id, driver_id
    from bounded_candidates
    on conflict (order_id, driver_id) do nothing
    returning order_id, driver_id
  )
  insert into public.notification_outbox (
    event_key,
    event_type,
    audience,
    target_user_id,
    target_app_kind,
    target_type,
    order_id,
    offer_id,
    title,
    body
  )
  select
    'dispatch:' || b.order_id || ':driver:' || b.driver_id
      || ':radius:' || b.dispatch_radius_meters,
    'NEW_WORK',
    'USER',
    b.driver_user_id,
    'DRIVER',
    'REQUESTS',
    b.order_id,
    null,
    'طلب جديد قريب',
    'قد يوجد طلب مناسب بالقرب منك.'
  from inserted_candidates i
  join bounded_candidates b
    on b.order_id = i.order_id and b.driver_id = i.driver_id
  -- The order-insert signal covers the initial 2 km stage. Never duplicate it.
  where not b.initial_dispatch_eligible
  on conflict (event_key) do nothing;

  get diagnostics v_signalled = row_count;
  return v_signalled;
end;
$function$;

-- Keep the order-create audience at its original 2 km boundary. Without
-- this guard, a delayed Push claim could fan that one generic row out to a
-- later radius and duplicate the targeted expansion signal.
create or replace function public.claim_notification_outbox(p_limit integer default 20)
returns table (
  id uuid,
  event_type text,
  target_app_kind text,
  target_type text,
  order_id uuid,
  offer_id uuid,
  title text,
  body text,
  attempt_count integer,
  tokens text[]
)
language sql
volatile
security definer
set search_path = ''
as $function$
  with candidates as (
    select n.id
    from public.notification_outbox n
    where n.attempt_count < 5
      and (
        (n.status in ('PENDING', 'FAILED') and n.next_attempt_at <= clock_timestamp())
        or (n.status = 'SENDING' and n.last_attempt_at < clock_timestamp() - interval '10 minutes')
      )
    order by n.created_at, n.id
    for update skip locked
    limit least(greatest(coalesce(p_limit, 20), 1), 50)
  ), claimed as (
    update public.notification_outbox n
    set status = 'SENDING',
        attempt_count = n.attempt_count + 1,
        last_attempt_at = clock_timestamp(),
        last_error_code = null
    from candidates c
    where n.id = c.id
    returning n.*
  )
  select c.id, c.event_type, c.target_app_kind, c.target_type, c.order_id, c.offer_id,
    c.title, c.body, c.attempt_count, coalesce(targets.tokens, '{}'::text[])
  from claimed c
  left join lateral (
    select array_agg(token_rows.token) as tokens
    from (
      select distinct t.token
      from public.user_push_tokens t
      where t.enabled
        and t.app_kind = c.target_app_kind
        and (
          (c.audience = 'USER' and t.user_id = c.target_user_id)
          or (
            c.audience = 'ELIGIBLE_DRIVERS'
            and private.driver_is_initial_dispatch_eligible(
              (select d.id from public.drivers d where d.user_id = t.user_id),
              c.order_id
            )
          )
        )
      -- ponytail: bounded MVP fanout; shard outbox audiences if one order can exceed 200 devices.
      limit 200
    ) token_rows
  ) targets on true;
$function$;

revoke all on function public.run_driver_progressive_dispatch_tick(uuid, integer, integer)
from public, anon, authenticated;

grant execute on function public.run_driver_progressive_dispatch_tick(uuid, integer, integer)
to service_role;

comment on function public.run_driver_progressive_dispatch_tick(uuid, integer, integer)
is 'Trusted scheduler entrypoint: invoke every 20 seconds; no scheduler job is created here.';
