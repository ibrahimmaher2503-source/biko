-- Milestone 6.1: reconcile Driver Core with Business Rules Freeze v1.0.

alter table public.orders
  add column cancelled_by uuid references public.profiles(id),
  add column cancellation_reason text,
  add constraint orders_cancellation_reason_length_ck
    check (
      cancellation_reason is null
      or length(btrim(cancellation_reason)) between 1 and 500
    );

create table public.order_events (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  event_type text not null,
  actor_user_id uuid references public.profiles(id),
  from_status public.order_status,
  to_status public.order_status not null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index order_events_order_created_idx
  on public.order_events (order_id, created_at desc);

alter table public.order_events enable row level security;
revoke all privileges on table public.order_events from anon, authenticated;

create or replace function private.record_order_event()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
begin
  if tg_op = 'INSERT' or old.status is distinct from new.status then
    insert into public.order_events (
      order_id,
      event_type,
      actor_user_id,
      from_status,
      to_status,
      metadata
    )
    values (
      new.id,
      new.status::text,
      coalesce((select auth.uid()), new.cancelled_by),
      case when tg_op = 'UPDATE' then old.status end,
      new.status,
      case
        when new.status = 'CANCELLED'::public.order_status
          then jsonb_build_object('reason', new.cancellation_reason)
        else '{}'::jsonb
      end
    );
  end if;

  return new;
end;
$function$;

create trigger orders_record_event
after insert or update of status on public.orders
for each row execute function private.record_order_event();

revoke all on function private.record_order_event() from public, anon, authenticated;

create or replace function public.submit_offer(
  p_order_id uuid,
  p_offered_price numeric
)
returns public.offers
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_uid uuid := (select auth.uid());
  v_order public.orders;
  v_driver public.drivers;
  v_offer public.offers;
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  if p_offered_price is null or p_offered_price <= 0 or p_offered_price = 'NaN'::numeric then
    raise exception 'Invalid offer price' using errcode = '22023';
  end if;

  select * into v_order
  from public.orders
  where id = p_order_id
  for update;

  if not found then
    raise exception 'Order not found' using errcode = 'P0002';
  end if;
  if v_order.status <> 'BIDDING'::public.order_status then
    raise exception 'Order is not open for bidding' using errcode = 'P0001';
  end if;

  select * into v_driver
  from public.drivers
  where user_id = v_uid
  for update;

  if not found
     or v_driver.status <> 'ACTIVE'::public.driver_status
     or not v_driver.is_online
     or not exists (
       select 1 from public.profiles p
       where p.id = v_uid
         and p.profile_type = 'DRIVER'::public.profile_type
         and p.status = 'ACTIVE'::public.account_status
     ) then
    raise exception 'Eligible active driver required' using errcode = '42501';
  end if;

  if not exists (
    select 1
    from public.order_driver_candidates c
    where c.order_id = p_order_id
      and c.driver_id = v_driver.id
  ) then
    raise exception 'Driver is not eligible for this order' using errcode = '42501';
  end if;

  if exists (
    select 1
    from public.offers o
    where o.order_id = p_order_id
      and o.driver_id = v_driver.id
      and o.status = 'ACTIVE'::public.offer_status
  ) then
    raise exception 'Active offer already exists; withdraw it before submitting a new offer'
      using errcode = 'P0001';
  end if;

  insert into public.offers (order_id, driver_id, office_id, offered_price, status)
  values (
    p_order_id,
    v_driver.id,
    v_driver.office_id,
    p_offered_price,
    'ACTIVE'::public.offer_status
  )
  returning * into v_offer;

  return v_offer;
end;
$function$;

create or replace function public.withdraw_offer(p_offer_id uuid)
returns public.offers
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_uid uuid := (select auth.uid());
  v_order_id uuid;
  v_order public.orders;
  v_offer public.offers;
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  select o.order_id into v_order_id
  from public.offers o
  where o.id = p_offer_id;

  if not found then
    raise exception 'Offer not found' using errcode = 'P0002';
  end if;

  select * into v_order
  from public.orders
  where id = v_order_id
  for update;

  select * into v_offer
  from public.offers o
  where o.id = p_offer_id
    and exists (
      select 1
      from public.drivers d
      where d.id = o.driver_id
        and d.user_id = v_uid
    )
  for update;

  if not found then
    raise exception 'Only the offer driver can withdraw it' using errcode = '42501';
  end if;
  if v_order.status <> 'BIDDING'::public.order_status then
    raise exception 'Order is not open for bidding' using errcode = 'P0001';
  end if;
  if v_offer.status <> 'ACTIVE'::public.offer_status
     or v_order.selected_offer_id = v_offer.id then
    raise exception 'Only an active unselected offer can be withdrawn' using errcode = 'P0001';
  end if;

  update public.offers
  set status = 'WITHDRAWN'::public.offer_status,
      updated_at = now()
  where id = v_offer.id
  returning * into v_offer;

  return v_offer;
end;
$function$;

create or replace function public.driver_cancel_order(
  p_order_id uuid,
  p_reason text
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
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  if nullif(btrim(p_reason), '') is null or length(btrim(p_reason)) > 500 then
    raise exception 'Cancellation reason is required and must not exceed 500 characters'
      using errcode = '22023';
  end if;

  select * into v_order
  from public.orders
  where id = p_order_id
  for update;

  if not found then
    raise exception 'Order not found' using errcode = 'P0002';
  end if;
  if not exists (
    select 1
    from public.drivers d
    where d.id = v_order.driver_id
      and d.user_id = v_uid
  ) then
    raise exception 'Only the assigned driver can cancel this order' using errcode = '42501';
  end if;
  if v_order.status not in (
    'DRIVER_ASSIGNED'::public.order_status,
    'DRIVER_ON_WAY'::public.order_status,
    'DRIVER_ARRIVED'::public.order_status
  ) then
    raise exception 'Driver cannot cancel this order in its current state' using errcode = 'P0001';
  end if;

  update public.orders
  set status = 'CANCELLED'::public.order_status,
      cancelled_by = v_uid,
      cancellation_reason = btrim(p_reason),
      cancelled_at = coalesce(cancelled_at, now()),
      updated_at = now()
  where id = v_order.id
  returning * into v_order;

  update public.offers
  set status = 'CLOSED'::public.offer_status,
      updated_at = now()
  where order_id = v_order.id
    and status = 'ACTIVE'::public.offer_status;

  return v_order;
end;
$function$;

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

  if p_is_online and v_driver.status <> 'ACTIVE'::public.driver_status then
    raise exception 'Online eligibility denied'
      using errcode = 'P0001', hint = 'حساب السائق غير نشط.';
  end if;
  if p_is_online and not exists (
    select 1
    from public.profiles p
    where p.id = v_uid
      and p.profile_type = 'DRIVER'::public.profile_type
      and p.status = 'ACTIVE'::public.account_status
  ) then
    raise exception 'Online eligibility denied'
      using errcode = 'P0001', hint = 'ملف السائق غير مؤهل للاتصال.';
  end if;
  if p_is_online and v_driver.office_id is not null and not exists (
    select 1
    from public.offices o
    where o.id = v_driver.office_id
      and o.status = 'ACTIVE'::public.account_status
  ) then
    raise exception 'Online eligibility denied'
      using errcode = 'P0001', hint = 'المكتب المرتبط بالحساب غير نشط.';
  end if;
  if p_is_online and exists (
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
    raise exception 'Online eligibility denied'
      using errcode = 'P0001', hint = 'لديك رحلة نشطة بالفعل.';
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

revoke all on function public.submit_offer(uuid, numeric) from public, anon, authenticated;
revoke all on function public.withdraw_offer(uuid) from public, anon, authenticated;
revoke all on function public.driver_cancel_order(uuid, text) from public, anon, authenticated;
revoke all on function public.set_driver_online(boolean) from public, anon, authenticated;
grant execute on function public.submit_offer(uuid, numeric) to authenticated;
grant execute on function public.withdraw_offer(uuid) to authenticated;
grant execute on function public.driver_cancel_order(uuid, text) to authenticated;
grant execute on function public.set_driver_online(boolean) to authenticated;
