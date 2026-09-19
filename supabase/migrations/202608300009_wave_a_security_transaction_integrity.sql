-- Wave A: CR-001/002/003/009/020. No previously applied migration is edited.
-- Office permissions must originate in the membership for the target office.
create or replace function private.is_super_admin()
returns boolean language sql stable security definer set search_path = ''
as $function$
  select exists (
    select 1 from public.user_roles ur
    join public.profiles p on p.id = ur.user_id and p.status = 'ACTIVE'
    join public.roles r on r.id = ur.role_id
    where ur.user_id = (select auth.uid()) and r.code = 'SUPER_ADMIN'
  );
$function$;

-- This reports permission availability for global reference metadata only.
-- Office data authorization must use can_access_office, never this helper alone.
create or replace function private.has_permission(permission_code text)
returns boolean language sql stable security definer set search_path = ''
as $function$
  select exists (
    select 1 from public.profiles profile
    where profile.id = (select auth.uid()) and profile.status = 'ACTIVE'
      and (
        exists (
          select 1 from public.user_roles ur
          join public.role_permissions rp on rp.role_id = ur.role_id
          join public.permissions p on p.id = rp.permission_id
          where ur.user_id = profile.id and p.code = permission_code
        )
        or exists (
          select 1 from public.office_members om
          join public.offices o on o.id = om.office_id and o.status = 'ACTIVE'
          join public.role_permissions rp on rp.role_id = om.role_id
          join public.permissions p on p.id = rp.permission_id
          where om.user_id = profile.id and om.status = 'ACTIVE'
            and p.code = permission_code
        )
      )
  );
$function$;

create or replace function private.is_office_member(target_office_id uuid)
returns boolean language sql stable security definer set search_path = ''
as $function$
  select exists (
    select 1 from public.office_members om
    join public.profiles p on p.id = om.user_id and p.status = 'ACTIVE'
    join public.offices o on o.id = om.office_id and o.status = 'ACTIVE'
    where om.user_id = (select auth.uid()) and om.office_id = target_office_id
      and om.status = 'ACTIVE'
  );
$function$;

create or replace function private.can_access_office(
  target_office_id uuid, permission_code text
)
returns boolean language sql stable security definer set search_path = ''
as $function$
  select private.is_super_admin() or exists (
    select 1 from public.office_members om
    join public.profiles profile on profile.id = om.user_id and profile.status = 'ACTIVE'
    join public.offices o on o.id = om.office_id and o.status = 'ACTIVE'
    join public.role_permissions rp on rp.role_id = om.role_id
    join public.permissions p on p.id = rp.permission_id
    where om.user_id = (select auth.uid()) and om.office_id = target_office_id
      and om.status = 'ACTIVE' and p.code = permission_code
  );
$function$;

-- Validate existing data, without silently repairing/reassigning any order.
-- A cancelled order preserves its complete historical assignment, if assigned.
alter table public.orders
  add constraint orders_assignment_bundle_ck check (
    (driver_id is null and selected_offer_id is null and agreed_price is null
      and assigned_at is null and office_id is null)
    or (driver_id is not null and selected_offer_id is not null
      and agreed_price is not null and assigned_at is not null)
  ),
  add constraint orders_assignment_state_ck check (
    (status not in ('DRAFT','BIDDING','EXPIRED') or selected_offer_id is null)
    and (status not in ('DRIVER_ASSIGNED','DRIVER_ON_WAY','DRIVER_ARRIVED','IN_PROGRESS','COMPLETED')
      or selected_offer_id is not null)
  );

-- Replace the old same-order key rather than retain two redundant indexes.
-- This also protects selected offer driver/price from later trusted edits.
alter table public.orders drop constraint orders_selected_offer_same_order_fk;
alter table public.offers
  drop constraint offers_order_id_id_key,
  add constraint offers_assignment_key unique (order_id, id, driver_id, offered_price);
alter table public.orders
  add constraint orders_selected_offer_assignment_fk
  foreign key (id, selected_offer_id, driver_id, agreed_price)
  references public.offers (order_id, id, driver_id, offered_price);

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
  if v_order.status <> 'BIDDING'::public.order_status
     or v_order.bidding_expires_at <= clock_timestamp() then
    raise exception 'Order is not open for bidding' using errcode = 'P0001';
  end if;

  select * into v_driver
  from public.drivers
  where user_id = v_uid
  for update;

  if exists (
    select 1 from public.orders o where o.driver_id = v_driver.id
      and o.status in ('DRIVER_ASSIGNED', 'DRIVER_ON_WAY', 'DRIVER_ARRIVED', 'IN_PROGRESS')
  ) then
    raise exception 'Driver already has an active assignment' using errcode = 'P0001';
  end if;

  if not found
     or v_driver.status <> 'ACTIVE'::public.driver_status
     or not v_driver.is_online
     or (v_driver.office_id is not null and not exists (
       select 1 from public.offices o where o.id = v_driver.office_id and o.status = 'ACTIVE'
     ))
     or not exists (
       select 1
       from public.profiles p
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

  -- The Driver lock can wait past the initial check.
  if v_order.bidding_expires_at <= clock_timestamp() then
    raise exception 'Order is not open for bidding' using errcode = 'P0001';
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

create or replace function public.accept_offer(
  p_order_id uuid,
  p_offer_id uuid
)
returns public.orders
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_uid uuid := (select auth.uid());
  v_order public.orders;
  v_offer public.offers;
  v_driver public.drivers;
  v_profile_status public.account_status;
  v_profile_type public.profile_type;
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  select * into v_order
  from public.orders
  where id = p_order_id
  for update;

  if not found then
    raise exception 'Order not found' using errcode = 'P0002';
  end if;
  if v_order.customer_id <> v_uid then
    raise exception 'Only the order customer can accept an offer' using errcode = '42501';
  end if;
  if v_order.status <> 'BIDDING'::public.order_status
     or v_order.bidding_expires_at <= clock_timestamp() then
    raise exception 'Order is no longer open for bidding' using errcode = 'P0001';
  end if;

  select * into v_offer
  from public.offers
  where id = p_offer_id
    and order_id = p_order_id;
  -- Do not lock the offer before the Driver: another selection must be able
  -- to close this Driver's cross-order offers while we wait on the Driver.

  if not found or v_offer.status <> 'ACTIVE'::public.offer_status then
    raise exception 'Active offer for this order required' using errcode = 'P0001';
  end if;

  select * into v_driver
  from public.drivers
  where id = v_offer.driver_id
  for update;

  if not found then
    raise exception 'Offer driver not found' using errcode = 'P0002';
  end if;

  if exists (
    select 1 from public.orders o where o.driver_id = v_driver.id
      and o.status in ('DRIVER_ASSIGNED', 'DRIVER_ON_WAY', 'DRIVER_ARRIVED', 'IN_PROGRESS')
  ) then
    raise exception 'Driver already has an active assignment' using errcode = 'P0001';
  end if;

  -- Refresh after the Driver lock, including changes committed while waiting.
  select o.* into v_offer from public.offers o
  where o.id = p_offer_id and o.order_id = p_order_id;
  if v_offer.status <> 'ACTIVE' then
    raise exception 'Active offer for this order required' using errcode = 'P0001';
  end if;

  select p.status, p.profile_type
  into v_profile_status, v_profile_type
  from public.profiles p
  where p.id = v_driver.user_id;

  if v_driver.status <> 'ACTIVE'::public.driver_status
     or not v_driver.is_online
     or v_profile_status <> 'ACTIVE'::public.account_status
     or v_profile_type <> 'DRIVER'::public.profile_type
     or not exists (
       select 1
       from public.order_driver_candidates c
       where c.order_id = p_order_id
         and c.driver_id = v_driver.id
     )
     or (
       v_driver.office_id is not null
       and not exists (
         select 1
         from public.offices o
         where o.id = v_driver.office_id
           and o.status = 'ACTIVE'::public.account_status
       )
     ) then
    raise exception 'Offer driver is no longer eligible' using errcode = '42501';
  end if;

  -- Lock the entire affected offer set in a consistent order.
  perform o.id from public.offers o
  where o.status = 'ACTIVE' and (o.order_id = p_order_id or o.driver_id = v_driver.id)
  order by o.id for update;

  -- Decide admission only after every order/Driver/offer lock has been acquired.
  if v_order.bidding_expires_at <= clock_timestamp() then
    raise exception 'Order is no longer open for bidding' using errcode = 'P0001';
  end if;
  if not exists (
    select 1 from public.profiles p
    where p.id = v_uid and p.profile_type = 'CUSTOMER' and p.status = 'ACTIVE'
  ) then
    raise exception 'Active customer profile required' using errcode = '42501';
  end if;

  update public.orders
  set selected_offer_id = v_offer.id,
      driver_id = v_driver.id,
      office_id = v_driver.office_id,
      agreed_price = v_offer.offered_price,
      status = 'DRIVER_ASSIGNED'::public.order_status,
      assigned_at = now(),
      updated_at = now()
  where id = v_order.id
  returning * into v_order;

  update public.offers
  set status = case when id = v_offer.id then 'SELECTED'::public.offer_status
                    else 'CLOSED'::public.offer_status end,
      updated_at = now()
  where status = 'ACTIVE'
    and (order_id = v_order.id or driver_id = v_driver.id);

  update public.drivers set is_online = false, updated_at = now()
  where id = v_driver.id;

  return v_order;
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
  if v_order.status <> 'BIDDING'::public.order_status
     or v_order.bidding_expires_at <= clock_timestamp() then
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

revoke all on function private.is_super_admin(), private.has_permission(text),
  private.is_office_member(uuid), private.can_access_office(uuid,text),
  public.submit_offer(uuid,numeric), public.accept_offer(uuid,uuid), public.withdraw_offer(uuid)
from public, anon, authenticated;
grant execute on function private.is_super_admin(), private.has_permission(text),
  private.is_office_member(uuid), private.can_access_office(uuid,text),
  public.submit_offer(uuid,numeric), public.accept_offer(uuid,uuid), public.withdraw_offer(uuid)
to authenticated;

