-- ADM-09: bounded office management contracts.
-- Office status blocks new dispatch/online eligibility; assigned trips keep
-- their historical office snapshot and may finish after a suspension.

create or replace function public.admin_list_offices(
  p_search text default null,
  p_status public.account_status default null,
  p_office_id uuid default null,
  p_limit integer default 50,
  p_offset integer default 0
)
returns table (
  id uuid,
  name text,
  responsible_person text,
  phone text,
  address text,
  area text,
  status public.account_status,
  commission_config jsonb,
  created_at timestamptz,
  updated_at timestamptz,
  driver_count bigint,
  active_driver_count bigint,
  motorcycle_count bigint,
  order_count bigint,
  active_order_count bigint,
  completed_order_count bigint,
  cancelled_order_count bigint,
  total_count bigint
)
language plpgsql
stable
security definer
set search_path = ''
as $function$
begin
  if p_limit is null or p_limit < 1 or p_limit > 100
     or p_offset is null or p_offset < 0 then
    raise exception 'Invalid office pagination' using errcode = '22023';
  end if;
  if p_search is not null and length(btrim(p_search)) > 120 then
    raise exception 'Office search is too long' using errcode = '22023';
  end if;
  -- ADM-09 is a platform office-management surface. Office membership or a
  -- selected office never substitutes for the platform offices.view grant.
  if not private.has_platform_permission('offices.view') then
    raise exception 'Platform office access required' using errcode = '42501';
  end if;

  return query
  with driver_counts as (
    select d.office_id,
      count(*)::bigint as driver_count,
      count(*) filter (where d.status = 'ACTIVE'::public.driver_status)::bigint
        as active_driver_count
    from public.drivers d
    where d.office_id is not null
    group by d.office_id
  ), motorcycle_counts as (
    select m.office_id, count(*)::bigint as motorcycle_count
    from public.motorcycles m
    where m.office_id is not null
    group by m.office_id
  ), order_counts as (
    select o.office_id,
      count(*)::bigint as order_count,
      count(*) filter (where o.status not in (
        'COMPLETED'::public.order_status,
        'CANCELLED'::public.order_status,
        'EXPIRED'::public.order_status
      ))::bigint as active_order_count,
      count(*) filter (where o.status = 'COMPLETED'::public.order_status)::bigint
        as completed_order_count,
      count(*) filter (where o.status = 'CANCELLED'::public.order_status)::bigint
        as cancelled_order_count
    from public.orders o
    where o.office_id is not null
    group by o.office_id
  )
  select o.id, o.name, o.responsible_person, o.phone, o.address, o.area,
    o.status, o.commission_config, o.created_at, o.updated_at,
    coalesce(dc.driver_count, 0), coalesce(dc.active_driver_count, 0),
    coalesce(mc.motorcycle_count, 0), coalesce(oc.order_count, 0),
    coalesce(oc.active_order_count, 0), coalesce(oc.completed_order_count, 0),
    coalesce(oc.cancelled_order_count, 0),
    count(*) over ()::bigint
  from public.offices o
  left join driver_counts dc on dc.office_id = o.id
  left join motorcycle_counts mc on mc.office_id = o.id
  left join order_counts oc on oc.office_id = o.id
  where (p_office_id is null or o.id = p_office_id)
    and (p_status is null or o.status = p_status)
    and (
      nullif(btrim(p_search), '') is null
      or o.name ilike '%' || btrim(p_search) || '%'
      or coalesce(o.responsible_person, '') ilike '%' || btrim(p_search) || '%'
      or coalesce(o.phone, '') ilike '%' || btrim(p_search) || '%'
      or coalesce(o.area, '') ilike '%' || btrim(p_search) || '%'
    )
  order by o.name, o.id
  limit p_limit offset p_offset;
end;
$function$;

create or replace function public.admin_get_office(p_office_id uuid)
returns table (
  id uuid,
  name text,
  responsible_person text,
  phone text,
  address text,
  area text,
  status public.account_status,
  commission_config jsonb,
  created_at timestamptz,
  updated_at timestamptz,
  driver_count bigint,
  active_driver_count bigint,
  motorcycle_count bigint,
  order_count bigint,
  active_order_count bigint,
  completed_order_count bigint,
  cancelled_order_count bigint,
  total_count bigint
)
language plpgsql
stable
security definer
set search_path = ''
as $function$
begin
  return query
  select * from public.admin_list_offices(null, null, p_office_id, 1, 0);
  if not found then
    raise exception 'Office not found' using errcode = 'P0002';
  end if;
end;
$function$;

create or replace function public.admin_create_office(
  p_name text,
  p_responsible_person text default null,
  p_phone text default null,
  p_address text default null,
  p_area text default null,
  p_reason text default null
)
returns public.offices
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_office public.offices;
  v_reason text := private.admin_reason_required(p_reason);
begin
  if not private.has_platform_permission('offices.create') then
    raise exception 'Office creation permission required' using errcode = '42501';
  end if;
  if nullif(btrim(p_name), '') is null or length(btrim(p_name)) > 120 then
    raise exception 'Invalid office name' using errcode = '22023';
  end if;
  if p_responsible_person is not null and length(btrim(p_responsible_person)) > 120
     or p_phone is not null and length(btrim(p_phone)) > 50
     or p_address is not null and length(btrim(p_address)) > 255
     or p_area is not null and length(btrim(p_area)) > 120 then
    raise exception 'Office field is too long' using errcode = '22023';
  end if;

  insert into public.offices (
    name, responsible_person, phone, address, area, status
  ) values (
    btrim(p_name), nullif(btrim(p_responsible_person), ''),
    nullif(btrim(p_phone), ''), nullif(btrim(p_address), ''),
    nullif(btrim(p_area), ''), 'ACTIVE'::public.account_status
  ) returning * into v_office;

  perform private.record_admin_audit(
    'OFFICE_CREATED', 'OFFICE', v_office.id, v_reason, '{}'::jsonb,
    jsonb_build_object(
      'name', v_office.name, 'responsible_person', v_office.responsible_person,
      'phone', v_office.phone, 'address', v_office.address, 'area', v_office.area,
      'status', v_office.status::text
    ), jsonb_build_object('permission', 'offices.create')
  );
  return v_office;
end;
$function$;

create or replace function public.admin_update_office(
  p_office_id uuid,
  p_name text,
  p_responsible_person text default null,
  p_phone text default null,
  p_address text default null,
  p_area text default null,
  p_reason text default null
)
returns public.offices
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_office public.offices;
  v_old_value jsonb;
  v_reason text := private.admin_reason_required(p_reason);
begin
  if not private.has_platform_permission('offices.edit') then
    raise exception 'Office edit permission required' using errcode = '42501';
  end if;
  if nullif(btrim(p_name), '') is null or length(btrim(p_name)) > 120 then
    raise exception 'Invalid office name' using errcode = '22023';
  end if;
  if p_responsible_person is not null and length(btrim(p_responsible_person)) > 120
     or p_phone is not null and length(btrim(p_phone)) > 50
     or p_address is not null and length(btrim(p_address)) > 255
     or p_area is not null and length(btrim(p_area)) > 120 then
    raise exception 'Office field is too long' using errcode = '22023';
  end if;
  select * into v_office from public.offices where id = p_office_id for update;
  if not found then raise exception 'Office not found' using errcode = 'P0002'; end if;
  v_old_value := jsonb_build_object(
    'name', v_office.name, 'responsible_person', v_office.responsible_person,
    'phone', v_office.phone, 'address', v_office.address, 'area', v_office.area
  );
  update public.offices set
    name = btrim(p_name),
    responsible_person = nullif(btrim(p_responsible_person), ''),
    phone = nullif(btrim(p_phone), ''),
    address = nullif(btrim(p_address), ''),
    area = nullif(btrim(p_area), ''),
    updated_at = clock_timestamp()
  where id = v_office.id
  returning * into v_office;
  perform private.record_admin_audit(
    'OFFICE_UPDATED', 'OFFICE', v_office.id, v_reason, v_old_value,
    jsonb_build_object(
      'name', v_office.name, 'responsible_person', v_office.responsible_person,
      'phone', v_office.phone, 'address', v_office.address, 'area', v_office.area
    ), jsonb_build_object('permission', 'offices.edit')
  );
  return v_office;
end;
$function$;

create or replace function public.admin_suspend_office(
  p_office_id uuid,
  p_reason text
)
returns public.offices
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_office public.offices;
  v_reason text := private.admin_reason_required(p_reason);
begin
  if not private.has_platform_permission('offices.suspend') then
    raise exception 'Office suspension permission required' using errcode = '42501';
  end if;
  select * into v_office from public.offices where id = p_office_id for update;
  if not found then raise exception 'Office not found' using errcode = 'P0002'; end if;
  if v_office.status <> 'ACTIVE'::public.account_status then
    raise exception 'Only an active office can be suspended' using errcode = 'P0001';
  end if;
  update public.offices
  set status = 'SUSPENDED'::public.account_status, updated_at = clock_timestamp()
  where id = v_office.id
  returning * into v_office;
  perform private.record_admin_audit(
    'OFFICE_SUSPENDED', 'OFFICE', v_office.id, v_reason,
    jsonb_build_object('status', 'ACTIVE'),
    jsonb_build_object('status', v_office.status::text),
    jsonb_build_object('permission', 'offices.suspend', 'new_work_blocked', true)
  );
  return v_office;
end;
$function$;

create or replace function public.admin_restore_office(
  p_office_id uuid,
  p_reason text
)
returns public.offices
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_office public.offices;
  v_reason text := private.admin_reason_required(p_reason);
begin
  if not private.has_platform_permission('offices.suspend') then
    raise exception 'Office restore permission required' using errcode = '42501';
  end if;
  select * into v_office from public.offices where id = p_office_id for update;
  if not found then raise exception 'Office not found' using errcode = 'P0002'; end if;
  if v_office.status <> 'SUSPENDED'::public.account_status then
    raise exception 'Only a suspended office can be restored' using errcode = 'P0001';
  end if;
  update public.offices
  set status = 'ACTIVE'::public.account_status, updated_at = clock_timestamp()
  where id = v_office.id
  returning * into v_office;
  perform private.record_admin_audit(
    'OFFICE_RESTORED', 'OFFICE', v_office.id, v_reason,
    jsonb_build_object('status', 'SUSPENDED'),
    jsonb_build_object('status', v_office.status::text),
    jsonb_build_object('permission', 'offices.suspend')
  );
  return v_office;
end;
$function$;

-- Keep the latest lifecycle implementation, but let a driver finish an order
-- already assigned before its office was suspended. New work still requires an
-- active office in submit_offer/dispatch/online eligibility checks.
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
  select * into v_order from public.orders where id = p_order_id for update;
  if not found then raise exception 'Order not found' using errcode = 'P0002'; end if;
  if v_order.status <> p_expected then
    raise exception 'Order is not in the expected state' using errcode = 'P0001';
  end if;
  select * into v_driver
  from public.drivers where id = v_order.driver_id and user_id = v_uid for update;
  if not found then
    raise exception 'Only the assigned driver can perform this action' using errcode = '42501';
  end if;
  select p.status, p.profile_type into v_profile_status, v_profile_type
  from public.profiles p where p.id = v_driver.user_id;
  if v_driver.status <> 'ACTIVE'::public.driver_status
     or v_profile_status <> 'ACTIVE'::public.account_status
     or v_profile_type <> 'DRIVER'::public.profile_type
     or (
       v_driver.office_id is not null
       and not exists (
         select 1 from public.offices o
         where o.id = v_driver.office_id
           and o.status = 'ACTIVE'::public.account_status
       )
       and not (
         v_order.office_id = v_driver.office_id
         and v_order.status in (
           'DRIVER_ASSIGNED'::public.order_status,
           'DRIVER_ON_WAY'::public.order_status,
           'DRIVER_ARRIVED'::public.order_status,
           'IN_PROGRESS'::public.order_status
         )
       )
     ) then
    raise exception 'Assigned driver is not operationally valid' using errcode = '42501';
  end if;
  case p_next
    when 'DRIVER_ON_WAY'::public.order_status then
      update public.orders set status = p_next,
        driver_on_way_at = coalesce(driver_on_way_at, now()), updated_at = now()
      where id = v_order.id returning * into v_order;
    when 'DRIVER_ARRIVED'::public.order_status then
      update public.orders set status = p_next,
        driver_arrived_at = coalesce(driver_arrived_at, now()), updated_at = now()
      where id = v_order.id returning * into v_order;
    when 'IN_PROGRESS'::public.order_status then
      update public.orders set status = p_next,
        started_at = coalesce(started_at, now()), updated_at = now()
      where id = v_order.id returning * into v_order;
    when 'COMPLETED'::public.order_status then
      update public.orders set status = p_next,
        completed_at = coalesce(completed_at, now()), updated_at = now()
      where id = v_order.id returning * into v_order;
      update public.drivers set completed_trip_count = completed_trip_count + 1,
        updated_at = now() where id = v_driver.id;
  end case;
  return v_order;
end;
$function$;

create or replace function private.lock_driver_order(
  p_order_id uuid,
  p_service_code text,
  p_expected public.order_status
)
returns public.orders
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_uid uuid := (select auth.uid());
  v_order public.orders;
begin
  if v_uid is null then raise exception 'Authentication required' using errcode = '42501'; end if;
  select o.* into v_order
  from public.orders o
  join public.service_types s on s.id = o.service_type_id
  join public.drivers d on d.id = o.driver_id
  join public.profiles p on p.id = d.user_id
  where o.id = p_order_id
    and s.code = p_service_code
    and d.user_id = v_uid
    and d.status = 'ACTIVE'::public.driver_status
    and p.status = 'ACTIVE'::public.account_status
    and p.profile_type = 'DRIVER'::public.profile_type
    and (
      d.office_id is null
      or exists (
        select 1 from public.offices office
        where office.id = d.office_id
          and office.status = 'ACTIVE'::public.account_status
      )
      or (
        o.office_id = d.office_id
        and o.status in (
          'DRIVER_ASSIGNED'::public.order_status,
          'DRIVER_ON_WAY'::public.order_status,
          'DRIVER_ARRIVED'::public.order_status,
          'IN_PROGRESS'::public.order_status
        )
      )
    )
  for update of o;
  if not found then raise exception 'Assigned Driver action denied' using errcode = '42501'; end if;
  if v_order.status <> p_expected then
    raise exception 'Order is not in the expected state' using errcode = 'P0001';
  end if;
  return v_order;
end;
$function$;

revoke all on function public.admin_list_offices(text,public.account_status,uuid,integer,integer)
  from public, anon, authenticated;
revoke all on function public.admin_get_office(uuid) from public, anon, authenticated;
revoke all on function public.admin_create_office(text,text,text,text,text,text)
  from public, anon, authenticated;
revoke all on function public.admin_update_office(uuid,text,text,text,text,text,text)
  from public, anon, authenticated;
revoke all on function public.admin_suspend_office(uuid,text) from public, anon, authenticated;
revoke all on function public.admin_restore_office(uuid,text) from public, anon, authenticated;
grant execute on function public.admin_list_offices(text,public.account_status,uuid,integer,integer)
  to authenticated;
grant execute on function public.admin_get_office(uuid) to authenticated;
grant execute on function public.admin_create_office(text,text,text,text,text,text) to authenticated;
grant execute on function public.admin_update_office(uuid,text,text,text,text,text,text) to authenticated;
grant execute on function public.admin_suspend_office(uuid,text) to authenticated;
grant execute on function public.admin_restore_office(uuid,text) to authenticated;

revoke all on function private.advance_order_state(uuid,public.order_status,public.order_status)
  from public, anon, authenticated;
revoke all on function private.lock_driver_order(uuid,text,public.order_status)
  from public, anon, authenticated;
