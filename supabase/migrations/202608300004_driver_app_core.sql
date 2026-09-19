-- Milestone 6: the minimum trusted Driver App availability and read surfaces.

create policy orders_select_assigned_driver
on public.orders
for select
to authenticated
using (
  exists (
    select 1
    from public.drivers d
    where d.id = orders.driver_id
      and d.user_id = (select auth.uid())
  )
);

create or replace function public.set_driver_online(p_is_online boolean)
returns public.drivers
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_uid uuid := (select auth.uid());
  v_driver public.drivers;
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  if p_is_online is null then
    raise exception 'Online state is required' using errcode = '22023';
  end if;

  select * into v_driver
  from public.drivers
  where user_id = v_uid
  for update;

  if not found then
    raise exception 'Driver account required' using errcode = '42501';
  end if;

  if p_is_online and (
    v_driver.status <> 'ACTIVE'::public.driver_status
    or not exists (
      select 1
      from public.profiles p
      where p.id = v_uid
        and p.profile_type = 'DRIVER'::public.profile_type
        and p.status = 'ACTIVE'::public.account_status
    )
    or (
      v_driver.office_id is not null
      and not exists (
        select 1
        from public.offices o
        where o.id = v_driver.office_id
          and o.status = 'ACTIVE'::public.account_status
      )
    )
  ) then
    raise exception 'Active driver account required' using errcode = '42501';
  end if;

  if not p_is_online and exists (
    select 1
    from public.orders o
    where o.driver_id = v_driver.id
      and o.status in (
        'DRIVER_ASSIGNED'::public.order_status,
        'DRIVER_ON_WAY'::public.order_status,
        'DRIVER_ARRIVED'::public.order_status,
        'IN_PROGRESS'::public.order_status
      )
  ) then
    raise exception 'Cannot go offline during an active order' using errcode = 'P0001';
  end if;

  update public.drivers
  set is_online = p_is_online,
      updated_at = now()
  where id = v_driver.id
  returning * into v_driver;

  return v_driver;
end;
$function$;

revoke all on function public.set_driver_online(boolean) from public, anon, authenticated;
grant execute on function public.set_driver_online(boolean) to authenticated;
