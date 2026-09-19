-- Milestone 8: trusted route quotes, spatial dispatch, and one-row Driver locations.
create extension if not exists postgis with schema extensions;

create table public.platform_settings (
  key text primary key,
  value jsonb not null,
  updated_at timestamptz not null default now()
);

insert into public.platform_settings (key, value) values
  ('driver_location_freshness_seconds', '120'::jsonb),
  ('dispatch_radius_step_seconds', '20'::jsonb),
  ('route_quote_ttl_seconds', '600'::jsonb);

alter table public.platform_settings enable row level security;
revoke all on table public.platform_settings from public, anon, authenticated;

create table public.operating_zones (
  id uuid primary key default gen_random_uuid(),
  name text not null check (nullif(btrim(name), '') is not null),
  area extensions.geography(MultiPolygon, 4326) not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index operating_zones_area_gist_idx
  on public.operating_zones using gist (area)
  where is_active;
alter table public.operating_zones enable row level security;
revoke all on table public.operating_zones from public, anon, authenticated;

create table public.driver_latest_locations (
  driver_id uuid primary key references public.drivers(id) on delete cascade,
  latitude numeric(9,6) not null check (latitude between -90 and 90 and latitude <> 'NaN'::numeric),
  longitude numeric(9,6) not null check (longitude between -180 and 180 and longitude <> 'NaN'::numeric),
  accuracy_meters numeric(8,2) not null check (accuracy_meters >= 0 and accuracy_meters <= 1000),
  heading_degrees numeric(6,2) check (heading_degrees is null or heading_degrees between 0 and 360),
  speed_mps numeric(8,2) check (speed_mps is null or speed_mps >= 0),
  position extensions.geography(Point, 4326) generated always as (
    extensions.st_setsrid(
      extensions.st_makepoint(longitude::double precision, latitude::double precision),
      4326
    )::extensions.geography
  ) stored,
  updated_at timestamptz not null default clock_timestamp()
);

create index driver_latest_locations_position_gist_idx
  on public.driver_latest_locations using gist (position);
create index driver_latest_locations_updated_idx
  on public.driver_latest_locations (updated_at desc);
alter table public.driver_latest_locations enable row level security;
revoke all on table public.driver_latest_locations from public, anon, authenticated;

create table public.route_quotes (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.profiles(id) on delete cascade,
  service_type_id uuid not null references public.service_types(id),
  pickup_lat numeric(9,6) not null check (pickup_lat between -90 and 90),
  pickup_lng numeric(9,6) not null check (pickup_lng between -180 and 180),
  destination_lat numeric(9,6) not null check (destination_lat between -90 and 90),
  destination_lng numeric(9,6) not null check (destination_lng between -180 and 180),
  distance_meters integer not null check (distance_meters > 0 and distance_meters <= 2000000),
  duration_seconds integer not null check (duration_seconds > 0 and duration_seconds <= 172800),
  encoded_polyline text not null check (length(encoded_polyline) between 1 and 100000),
  suggested_price numeric(12,2) not null check (suggested_price > 0),
  minimum_customer_price numeric(12,2) not null check (
    minimum_customer_price > 0 and minimum_customer_price = round(suggested_price * 0.70, 2)
  ),
  pricing_version text not null,
  expires_at timestamptz not null,
  used_order_id uuid unique references public.orders(id),
  created_at timestamptz not null default clock_timestamp()
);

create index route_quotes_customer_expiry_idx
  on public.route_quotes (customer_id, expires_at desc);
alter table public.route_quotes enable row level security;
revoke all on table public.route_quotes from public, anon, authenticated;
grant select on table public.route_quotes to authenticated;
create policy route_quotes_select_owned on public.route_quotes for select to authenticated
using (customer_id = (select auth.uid()));

alter table public.orders
  add column route_quote_id uuid unique references public.route_quotes(id),
  add column route_distance_meters integer check (route_distance_meters is null or route_distance_meters > 0),
  add column route_duration_seconds integer check (route_duration_seconds is null or route_duration_seconds > 0),
  add column route_polyline text,
  add column suggested_price numeric(12,2) check (suggested_price is null or suggested_price > 0),
  add column minimum_customer_price numeric(12,2) check (minimum_customer_price is null or minimum_customer_price > 0);

create index orders_bidding_pickup_position_gist_idx
  on public.orders using gist ((
    extensions.st_setsrid(
      extensions.st_makepoint(pickup_lng::double precision, pickup_lat::double precision),
      4326
    )::extensions.geography
  )) where status = 'BIDDING'::public.order_status;

create or replace function private.setting_positive_int(p_key text, p_fallback integer)
returns integer
language sql stable security definer set search_path = ''
as $function$
  select case
    when coalesce((s.value #>> '{}')::integer, 0) > 0 then (s.value #>> '{}')::integer
    else p_fallback
  end
  from (select p_fallback) fallback
  left join public.platform_settings s on s.key = p_key;
$function$;

create or replace function private.dispatch_radius_meters(p_created_at timestamptz)
returns integer
language sql stable security definer set search_path = ''
as $function$
  select least(
    8000,
    2000 + 2000 * floor(
      greatest(0, extract(epoch from (clock_timestamp() - p_created_at))) /
      private.setting_positive_int('dispatch_radius_step_seconds', 20)
    )::integer
  );
$function$;

create or replace function private.operating_zone_allows(p_point extensions.geography)
returns boolean
language sql stable security definer set search_path = ''
as $function$
  select not exists (select 1 from public.operating_zones z where z.is_active)
    or exists (
      select 1 from public.operating_zones z
      where z.is_active and extensions.st_covers(z.area::extensions.geometry, p_point::extensions.geometry)
    );
$function$;

create or replace function private.driver_is_geographically_eligible(
  p_driver_id uuid,
  p_order_id uuid
)
returns boolean
language sql stable security definer set search_path = ''
as $function$
  select exists (
    select 1
    from public.drivers d
    join public.profiles p on p.id = d.user_id
    join public.driver_latest_locations l on l.driver_id = d.id
    join public.orders o on o.id = p_order_id
    where d.id = p_driver_id
      and d.status = 'ACTIVE'::public.driver_status
      and d.is_online
      and p.profile_type = 'DRIVER'::public.profile_type
      and p.status = 'ACTIVE'::public.account_status
      and (d.office_id is null or exists (
        select 1 from public.offices office
        where office.id = d.office_id and office.status = 'ACTIVE'::public.account_status
      ))
      and not exists (
        select 1 from public.orders active_order
        where active_order.driver_id = d.id
          and active_order.status in (
            'DRIVER_ASSIGNED'::public.order_status,
            'DRIVER_ON_WAY'::public.order_status,
            'DRIVER_ARRIVED'::public.order_status,
            'IN_PROGRESS'::public.order_status
          )
      )
      and l.updated_at >= clock_timestamp() - make_interval(
        secs => private.setting_positive_int('driver_location_freshness_seconds', 120)
      )
      and o.status = 'BIDDING'::public.order_status
      and o.bidding_expires_at > clock_timestamp()
      and private.operating_zone_allows(l.position)
      and private.operating_zone_allows(
        extensions.st_setsrid(
          extensions.st_makepoint(o.pickup_lng::double precision, o.pickup_lat::double precision),
          4326
        )::extensions.geography
      )
      and extensions.st_dwithin(
        l.position,
        extensions.st_setsrid(
          extensions.st_makepoint(o.pickup_lng::double precision, o.pickup_lat::double precision),
          4326
        )::extensions.geography,
        private.dispatch_radius_meters(o.created_at)
      )
  );
$function$;

create or replace function public.update_driver_location(
  p_latitude numeric,
  p_longitude numeric,
  p_accuracy_meters numeric,
  p_heading_degrees numeric default null,
  p_speed_mps numeric default null
)
returns public.driver_latest_locations
language plpgsql security definer set search_path = ''
as $function$
declare
  v_uid uuid := (select auth.uid());
  v_driver public.drivers;
  v_location public.driver_latest_locations;
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  if p_latitude is null or p_longitude is null or p_accuracy_meters is null
     or p_latitude = 'NaN'::numeric or p_longitude = 'NaN'::numeric
     or p_latitude not between -90 and 90 or p_longitude not between -180 and 180
     or p_accuracy_meters = 'NaN'::numeric or p_accuracy_meters not between 0 and 1000
     or (p_heading_degrees is not null and (
       p_heading_degrees = 'NaN'::numeric or p_heading_degrees not between 0 and 360
     ))
     or (p_speed_mps is not null and (p_speed_mps = 'NaN'::numeric or p_speed_mps < 0)) then
    raise exception 'Invalid Driver location' using errcode = '22023';
  end if;

  select d.* into v_driver
  from public.drivers d
  join public.profiles p on p.id = d.user_id
  where d.user_id = v_uid
    and d.status = 'ACTIVE'::public.driver_status
    and p.profile_type = 'DRIVER'::public.profile_type
    and p.status = 'ACTIVE'::public.account_status
    and (d.office_id is null or exists (
      select 1 from public.offices o where o.id = d.office_id and o.status = 'ACTIVE'::public.account_status
    ));
  if not found then
    raise exception 'Eligible active Driver required' using errcode = '42501';
  end if;

  insert into public.driver_latest_locations (
    driver_id, latitude, longitude, accuracy_meters, heading_degrees, speed_mps, updated_at
  ) values (
    v_driver.id, p_latitude, p_longitude, p_accuracy_meters,
    p_heading_degrees, p_speed_mps, clock_timestamp()
  )
  on conflict (driver_id) do update set
    latitude = excluded.latitude,
    longitude = excluded.longitude,
    accuracy_meters = excluded.accuracy_meters,
    heading_degrees = excluded.heading_degrees,
    speed_mps = excluded.speed_mps,
    updated_at = excluded.updated_at
  returning * into v_location;
  return v_location;
end;
$function$;

create or replace function private.ensure_fresh_location_before_online()
returns trigger
language plpgsql security definer set search_path = ''
as $function$
begin
  if new.is_online and not old.is_online and not exists (
    select 1 from public.driver_latest_locations l
    where l.driver_id = new.id
      and l.updated_at >= clock_timestamp() - make_interval(
        secs => private.setting_positive_int('driver_location_freshness_seconds', 120)
      )
  ) then
    raise exception 'Online eligibility denied'
      using errcode = 'P0001', hint = 'حدّث موقعك الحالي ثم حاول الاتصال.';
  end if;
  return new;
end;
$function$;

create trigger drivers_require_fresh_location_before_online
before update of is_online on public.drivers
for each row execute function private.ensure_fresh_location_before_online();

create or replace function private.enforce_offer_geography()
returns trigger
language plpgsql security definer set search_path = ''
as $function$
begin
  if not private.driver_is_geographically_eligible(new.driver_id, new.order_id) then
    raise exception 'Driver is not geographically eligible for this order'
      using errcode = '42501', hint = 'حدّث موقعك ثم أعد تحميل الطلبات المتاحة.';
  end if;
  return new;
end;
$function$;

create trigger offers_enforce_current_geography
before insert on public.offers
for each row execute function private.enforce_offer_geography();

create or replace function private.enforce_assignment_geography()
returns trigger
language plpgsql security definer set search_path = ''
as $function$
begin
  if new.status = 'DRIVER_ASSIGNED'::public.order_status
     and old.status = 'BIDDING'::public.order_status
     and not private.driver_is_geographically_eligible(new.driver_id, new.id) then
    raise exception 'Offer driver is no longer geographically eligible'
      using errcode = '42501';
  end if;
  return new;
end;
$function$;

create trigger orders_enforce_assignment_geography
before update of status, driver_id on public.orders
for each row execute function private.enforce_assignment_geography();

create or replace function public.create_trusted_route_quote(
  p_customer_id uuid,
  p_service_type_id uuid,
  p_pickup_lat numeric,
  p_pickup_lng numeric,
  p_destination_lat numeric,
  p_destination_lng numeric,
  p_distance_meters integer,
  p_duration_seconds integer,
  p_encoded_polyline text
)
returns public.route_quotes
language plpgsql security definer set search_path = ''
as $function$
declare
  v_service public.service_types;
  v_base numeric;
  v_per_km numeric;
  v_suggested numeric(12,2);
  v_quote public.route_quotes;
begin
  if p_customer_id is null or not exists (
    select 1 from public.profiles p
    where p.id = p_customer_id and p.profile_type = 'CUSTOMER'::public.profile_type
      and p.status = 'ACTIVE'::public.account_status
  ) then
    raise exception 'Active Customer required' using errcode = '42501';
  end if;
  if p_pickup_lat is null or p_pickup_lng is null
     or p_destination_lat is null or p_destination_lng is null
     or p_pickup_lat not between -90 and 90 or p_pickup_lng not between -180 and 180
     or p_destination_lat not between -90 and 90 or p_destination_lng not between -180 and 180
     or p_distance_meters is null or p_distance_meters <= 0 or p_distance_meters > 2000000
     or p_duration_seconds is null or p_duration_seconds <= 0 or p_duration_seconds > 172800
     or nullif(p_encoded_polyline, '') is null or length(p_encoded_polyline) > 100000 then
    raise exception 'Invalid trusted route result' using errcode = '22023';
  end if;

  select * into v_service from public.service_types
  where id = p_service_type_id and is_enabled and code in ('RIDE', 'DELIVERY');
  if not found then
    raise exception 'Service type is not enabled' using errcode = '22023';
  end if;

  begin
    if coalesce((v_service.config ->> 'suggested_price_enabled')::boolean, false) then
      v_base := (v_service.config ->> 'suggested_price_base')::numeric;
      v_per_km := (v_service.config ->> 'suggested_price_distance_component')::numeric;
    end if;
  exception when invalid_text_representation then
    v_base := null;
    v_per_km := null;
  end;
  if v_base is null or v_per_km is null or v_base < 0 or v_per_km < 0 then
    raise exception 'Pricing configuration unavailable for service' using errcode = 'P0001';
  end if;

  v_suggested := round(v_base + v_per_km * (p_distance_meters::numeric / 1000), 2);
  if v_suggested <= 0 then
    raise exception 'Pricing configuration produced an invalid price' using errcode = 'P0001';
  end if;

  insert into public.route_quotes (
    customer_id, service_type_id,
    pickup_lat, pickup_lng, destination_lat, destination_lng,
    distance_meters, duration_seconds, encoded_polyline,
    suggested_price, minimum_customer_price, pricing_version, expires_at
  ) values (
    p_customer_id, p_service_type_id,
    round(p_pickup_lat, 6), round(p_pickup_lng, 6),
    round(p_destination_lat, 6), round(p_destination_lng, 6),
    p_distance_meters, p_duration_seconds, p_encoded_polyline,
    v_suggested, round(v_suggested * 0.70, 2),
    v_service.code || '@' || extract(epoch from v_service.updated_at)::bigint,
    clock_timestamp() + make_interval(
      secs => private.setting_positive_int('route_quote_ttl_seconds', 600)
    )
  ) returning * into v_quote;
  return v_quote;
end;
$function$;

drop function public.create_order(
  uuid,numeric,numeric,text,numeric,numeric,text,numeric,text,text,numeric,numeric,uuid
);

create function public.create_order(
  p_service_type_id uuid,
  p_pickup_lat numeric,
  p_pickup_lng numeric,
  p_pickup_address text,
  p_destination_lat numeric,
  p_destination_lng numeric,
  p_destination_address text,
  p_proposed_price numeric,
  p_recipient_name text default null,
  p_recipient_phone text default null,
  p_parcel_weight_kg numeric default null,
  p_declared_value numeric default null,
  p_creation_intent_id uuid default null,
  p_route_quote_id uuid default null
)
returns public.orders
language plpgsql security definer set search_path = ''
as $function$
declare
  v_uid uuid := (select auth.uid());
  v_service_code text;
  v_order public.orders;
  v_quote public.route_quotes;
  v_payload_hash text;
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  if not exists (
    select 1 from public.profiles p
    where p.id = v_uid and p.profile_type = 'CUSTOMER'::public.profile_type
      and p.status = 'ACTIVE'::public.account_status
  ) then
    raise exception 'Active customer profile required' using errcode = '42501';
  end if;
  select st.code into v_service_code from public.service_types st
  where st.id = p_service_type_id and st.is_enabled and st.code in ('RIDE', 'DELIVERY');
  if not found then
    raise exception 'Service type is not enabled' using errcode = '22023';
  end if;
  if p_pickup_lat is null or p_pickup_lng is null
     or p_destination_lat is null or p_destination_lng is null
     or p_pickup_lat = 'NaN'::numeric or p_pickup_lng = 'NaN'::numeric
     or p_destination_lat = 'NaN'::numeric or p_destination_lng = 'NaN'::numeric
     or p_pickup_lat not between -90 and 90 or p_pickup_lng not between -180 and 180
     or p_destination_lat not between -90 and 90 or p_destination_lng not between -180 and 180
     or nullif(btrim(p_pickup_address), '') is null
     or nullif(btrim(p_destination_address), '') is null
     or p_proposed_price is null or p_proposed_price <= 0
     or p_proposed_price = 'NaN'::numeric then
    raise exception 'Invalid order route or proposed price' using errcode = '22023';
  end if;
  if v_service_code = 'DELIVERY' then
    if nullif(btrim(p_recipient_name), '') is null then
      raise exception 'Delivery recipient name is required' using errcode = '22023';
    end if;
    if nullif(btrim(p_recipient_phone), '') is null then
      raise exception 'Delivery recipient phone is required' using errcode = '22023';
    end if;
    if p_parcel_weight_kg is null or p_parcel_weight_kg = 'NaN'::numeric
       or p_parcel_weight_kg <= 0 or p_parcel_weight_kg > 8 then
      raise exception 'Delivery parcel weight must be greater than 0 and at most 8 kg' using errcode = '22023';
    end if;
    if p_declared_value is null or p_declared_value = 'NaN'::numeric
       or p_declared_value < 0 or p_declared_value > 3000 then
      raise exception 'Delivery declared value must be between 0 and 3000 EGP' using errcode = '22023';
    end if;
  end if;
  if p_creation_intent_id is null then
    raise exception 'Creation intent ID is required' using errcode = '22023';
  end if;

  v_payload_hash := encode(extensions.digest(
    jsonb_build_array(
      p_service_type_id, trim_scale(p_pickup_lat), trim_scale(p_pickup_lng),
      btrim(p_pickup_address), trim_scale(p_destination_lat), trim_scale(p_destination_lng),
      btrim(p_destination_address), trim_scale(p_proposed_price),
      btrim(p_recipient_name), btrim(p_recipient_phone),
      trim_scale(p_parcel_weight_kg), trim_scale(p_declared_value)
    )::text, 'sha256'), 'hex');

  select o.* into v_order from public.orders o
  where o.customer_id = v_uid and o.creation_intent_id = p_creation_intent_id;
  if found then
    if v_order.creation_payload_hash is distinct from v_payload_hash then
      raise exception 'Creation intent conflicts with original payload' using errcode = '22023';
    end if;
    return v_order;
  end if;

  if p_route_quote_id is null then
    raise exception 'Trusted route quote is required' using errcode = '22023';
  end if;
  select q.* into v_quote from public.route_quotes q
  where q.id = p_route_quote_id for update;
  if not found or v_quote.customer_id <> v_uid
     or v_quote.service_type_id <> p_service_type_id then
    raise exception 'Route quote is not owned by this customer and service' using errcode = '42501';
  end if;
  if v_quote.used_order_id is not null then
    select o.* into v_order from public.orders o
    where o.customer_id = v_uid and o.creation_intent_id = p_creation_intent_id;
    if found and v_order.id = v_quote.used_order_id
       and v_order.creation_payload_hash = v_payload_hash then
      return v_order;
    end if;
    raise exception 'Route quote has already been used' using errcode = 'P0001';
  end if;
  if v_quote.expires_at <= clock_timestamp() then
    raise exception 'Route quote has expired' using errcode = 'P0001';
  end if;
  if v_quote.pickup_lat <> round(p_pickup_lat, 6)
     or v_quote.pickup_lng <> round(p_pickup_lng, 6)
     or v_quote.destination_lat <> round(p_destination_lat, 6)
     or v_quote.destination_lng <> round(p_destination_lng, 6) then
    raise exception 'Order coordinates do not match route quote' using errcode = '22023';
  end if;
  if p_proposed_price < v_quote.minimum_customer_price then
    raise exception 'Customer proposed price is below the trusted minimum'
      using errcode = '22023', hint = 'أقل سعر مسموح هو 70% من السعر المقترح.';
  end if;

  insert into public.orders (
    creation_intent_id, creation_payload_hash, customer_id, service_type_id,
    pickup_lat, pickup_lng, pickup_address,
    destination_lat, destination_lng, destination_address,
    proposed_price, bidding_expires_at, status,
    route_quote_id, route_distance_meters, route_duration_seconds,
    route_polyline, suggested_price, minimum_customer_price
  ) values (
    p_creation_intent_id, v_payload_hash, v_uid, p_service_type_id,
    v_quote.pickup_lat, v_quote.pickup_lng, btrim(p_pickup_address),
    v_quote.destination_lat, v_quote.destination_lng, btrim(p_destination_address),
    p_proposed_price, clock_timestamp() + interval '90 seconds', 'BIDDING'::public.order_status,
    v_quote.id, v_quote.distance_meters, v_quote.duration_seconds,
    v_quote.encoded_polyline, v_quote.suggested_price, v_quote.minimum_customer_price
  )
  on conflict (customer_id, creation_intent_id) do nothing
  returning * into v_order;

  if not found then
    select o.* into v_order from public.orders o
    where o.customer_id = v_uid and o.creation_intent_id = p_creation_intent_id;
    if not found or v_order.creation_payload_hash is distinct from v_payload_hash then
      raise exception 'Creation intent conflicts with original payload' using errcode = '22023';
    end if;
    return v_order;
  end if;

  update public.route_quotes set used_order_id = v_order.id where id = v_quote.id;
  if v_service_code = 'DELIVERY' then
    insert into public.order_delivery_details (
      order_id, recipient_name, recipient_phone, parcel_weight_kg, declared_value
    ) values (
      v_order.id, btrim(p_recipient_name), btrim(p_recipient_phone),
      p_parcel_weight_kg, p_declared_value
    );
  end if;
  return v_order;
end;
$function$;

drop function public.get_driver_requests(uuid);
create function public.get_driver_requests(p_order_id uuid default null)
returns table (
  id uuid, pickup_address text, destination_address text,
  pickup_lat numeric, pickup_lng numeric, destination_lat numeric, destination_lng numeric,
  proposed_price numeric, agreed_price numeric, status public.order_status,
  created_at timestamptz, completed_at timestamptz, bidding_expires_at timestamptz,
  service_code text, service_name text,
  route_distance_meters integer, route_duration_seconds integer, route_polyline text,
  driver_distance_meters integer, dispatch_radius_meters integer
)
language plpgsql security definer set search_path = ''
as $function$
declare
  v_uid uuid := (select auth.uid());
  v_driver public.drivers;
  v_location public.driver_latest_locations;
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  select d.* into v_driver from public.drivers d
  join public.profiles p on p.id = d.user_id
  where d.user_id = v_uid and d.status = 'ACTIVE'::public.driver_status
    and p.profile_type = 'DRIVER'::public.profile_type and p.status = 'ACTIVE'::public.account_status
    and (d.office_id is null or exists (
      select 1 from public.offices f where f.id = d.office_id and f.status = 'ACTIVE'::public.account_status
    ));
  if not found then
    raise exception 'Eligible active Driver required' using errcode = '42501';
  end if;

  if p_order_id is not null and exists (
    select 1 from public.orders assigned where assigned.id = p_order_id and assigned.driver_id = v_driver.id
  ) then
    return query
    select o.id, o.pickup_address, o.destination_address,
      o.pickup_lat, o.pickup_lng, o.destination_lat, o.destination_lng,
      o.proposed_price, o.agreed_price, o.status, o.created_at, o.completed_at,
      o.bidding_expires_at, s.code, s.name_ar,
      o.route_distance_meters, o.route_duration_seconds, o.route_polyline,
      null::integer, null::integer
    from public.orders o join public.service_types s on s.id = o.service_type_id
    where o.id = p_order_id;
    return;
  end if;

  if not v_driver.is_online then return; end if;
  select l.* into v_location from public.driver_latest_locations l
  where l.driver_id = v_driver.id
    and l.updated_at >= clock_timestamp() - make_interval(
      secs => private.setting_positive_int('driver_location_freshness_seconds', 120)
    );
  if not found then
    raise exception 'Driver location is stale'
      using errcode = 'P0001', hint = 'حدّث موقعك الحالي لعرض الطلبات القريبة.';
  end if;

  delete from public.order_driver_candidates c
  using public.orders o
  where c.driver_id = v_driver.id and c.order_id = o.id
    and o.status = 'BIDDING'::public.order_status
    and not private.driver_is_geographically_eligible(v_driver.id, o.id);

  insert into public.order_driver_candidates (order_id, driver_id)
  select o.id, v_driver.id from public.orders o
  where (p_order_id is null or o.id = p_order_id)
    and private.driver_is_geographically_eligible(v_driver.id, o.id)
  on conflict (order_id, driver_id) do nothing;

  return query
  select o.id, o.pickup_address, o.destination_address,
    o.pickup_lat, o.pickup_lng, o.destination_lat, o.destination_lng,
    o.proposed_price, o.agreed_price, o.status, o.created_at, o.completed_at,
    o.bidding_expires_at, s.code, s.name_ar,
    o.route_distance_meters, o.route_duration_seconds, o.route_polyline,
    round(extensions.st_distance(
      v_location.position,
      extensions.st_setsrid(
        extensions.st_makepoint(o.pickup_lng::double precision, o.pickup_lat::double precision), 4326
      )::extensions.geography
    ))::integer,
    private.dispatch_radius_meters(o.created_at)
  from public.orders o
  join public.service_types s on s.id = o.service_type_id
  where (p_order_id is null or o.id = p_order_id)
    and private.driver_is_geographically_eligible(v_driver.id, o.id)
  order by o.created_at desc, o.id
  limit 20;
end;
$function$;

create or replace function public.get_customer_order_offers(p_order_id uuid)
returns table (
  offer_id uuid, offered_price numeric, driver_public_id uuid,
  driver_first_name text, driver_photo_url text, driver_type public.driver_type,
  office_display_name text, completed_trip_count integer
)
language plpgsql stable security definer set search_path = ''
as $function$
declare
  v_uid uuid := (select auth.uid());
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  return query
  select ofr.id, ofr.offered_price, dr.id,
    split_part(btrim(pr.full_name), ' ', 1), pr.profile_photo_url,
    dr.driver_type, offc.name, dr.completed_trip_count
  from public.orders ord
  join public.offers ofr on ofr.order_id = ord.id
  join public.drivers dr on dr.id = ofr.driver_id
  join public.profiles pr on pr.id = dr.user_id
  left join public.offices offc on offc.id = dr.office_id
  where ord.id = p_order_id and ord.customer_id = v_uid
    and ord.status = 'BIDDING'::public.order_status
    and ord.bidding_expires_at > clock_timestamp()
    and ofr.status = 'ACTIVE'::public.offer_status
    and exists (
      select 1 from public.order_driver_candidates c
      where c.order_id = ord.id and c.driver_id = dr.id
    )
    and private.driver_is_geographically_eligible(dr.id, ord.id)
  order by ofr.created_at desc;
end;
$function$;

revoke all on function private.setting_positive_int(text,integer),
  private.dispatch_radius_meters(timestamptz),
  private.operating_zone_allows(extensions.geography),
  private.driver_is_geographically_eligible(uuid,uuid),
  private.ensure_fresh_location_before_online(),
  private.enforce_offer_geography(), private.enforce_assignment_geography(),
  public.update_driver_location(numeric,numeric,numeric,numeric,numeric),
  public.create_trusted_route_quote(uuid,uuid,numeric,numeric,numeric,numeric,integer,integer,text),
  public.create_order(uuid,numeric,numeric,text,numeric,numeric,text,numeric,text,text,numeric,numeric,uuid,uuid),
  public.get_driver_requests(uuid), public.get_customer_order_offers(uuid)
from public, anon, authenticated;

grant execute on function public.update_driver_location(numeric,numeric,numeric,numeric,numeric),
  public.create_order(uuid,numeric,numeric,text,numeric,numeric,text,numeric,text,text,numeric,numeric,uuid,uuid),
  public.get_driver_requests(uuid), public.get_customer_order_offers(uuid)
to authenticated;
grant execute on function public.create_trusted_route_quote(
  uuid,uuid,numeric,numeric,numeric,numeric,integer,integer,text
) to service_role;
