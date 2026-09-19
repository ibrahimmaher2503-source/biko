-- ADM-04: bounded Dashboard context and platform-role scope.
-- This migration does not create generic table DML or broaden office roles.

insert into public.roles (code, name, scope_type)
values
  ('PLATFORM_OPERATIONS', 'Platform Operations', 'PLATFORM'),
  ('SUPPORT_AGENT', 'Support Agent', 'PLATFORM'),
  ('VERIFICATION_AGENT', 'Verification Agent', 'PLATFORM')
on conflict (code) do update
  set name = excluded.name,
      scope_type = excluded.scope_type;

insert into public.permissions (code, description)
values
  ('motorcycles.verify', 'Verify motorcycle evidence and identity'),
  ('orders.override', 'Perform an explicitly trusted order safety override')
on conflict (code) do update
  set description = excluded.description;

insert into public.role_permissions (role_id, permission_id)
select r.id, p.id
from public.roles r
join public.permissions p on p.code = any (
  case r.code
    when 'PLATFORM_OPERATIONS' then array[
      'dashboard.view', 'orders.view', 'orders.manage', 'bids.view',
      'drivers.view', 'motorcycles.view', 'users.view', 'offices.view',
      'reports.view'
    ]
    when 'SUPPORT_AGENT' then array[
      'dashboard.view', 'orders.view', 'bids.view', 'drivers.view',
      'users.view'
    ]
    when 'VERIFICATION_AGENT' then array[
      'dashboard.view', 'drivers.view', 'drivers.verify', 'drivers.activate',
      'drivers.suspend', 'motorcycles.view', 'motorcycles.verify'
    ]
  end
)
where r.code in ('PLATFORM_OPERATIONS', 'SUPPORT_AGENT', 'VERIFICATION_AGENT')
on conflict do nothing;

-- Privileged Dashboard helpers require an active STAFF profile. A stale role
-- on CUSTOMER or DRIVER must never become a platform authorization path.
create or replace function private.is_super_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $function$
  select exists (
    select 1
    from public.user_roles ur
    join public.profiles p
      on p.id = ur.user_id
     and p.status = 'ACTIVE'::public.account_status
     and p.profile_type = 'STAFF'::public.profile_type
    join public.roles r
      on r.id = ur.role_id
     and r.scope_type = 'PLATFORM'
    where ur.user_id = (select auth.uid())
      and r.code = 'SUPER_ADMIN'
  );
$function$;

create or replace function private.has_platform_permission(p_permission_code text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $function$
  select exists (
    select 1
    from public.profiles profile
    join public.user_roles ur on ur.user_id = profile.id
    join public.roles r
      on r.id = ur.role_id
     and r.scope_type = 'PLATFORM'
    join public.role_permissions rp on rp.role_id = r.id
    join public.permissions permission on permission.id = rp.permission_id
    where profile.id = (select auth.uid())
      and profile.status = 'ACTIVE'::public.account_status
      and profile.profile_type = 'STAFF'::public.profile_type
      and permission.code = p_permission_code
  );
$function$;

-- This remains a metadata helper. It may report an office permission for the
-- caller, but office-row authorization must use can_access_office below.
create or replace function private.has_permission(permission_code text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $function$
  select exists (
    select 1
    from public.profiles profile
    where profile.id = (select auth.uid())
      and profile.status = 'ACTIVE'::public.account_status
      and profile.profile_type = 'STAFF'::public.profile_type
      and (
        exists (
          select 1
          from public.user_roles ur
          join public.roles r
            on r.id = ur.role_id
           and r.scope_type = 'PLATFORM'
          join public.role_permissions rp on rp.role_id = ur.role_id
          join public.permissions permission on permission.id = rp.permission_id
          where ur.user_id = profile.id
             and permission.code = has_permission.permission_code
        )
        or exists (
          select 1
          from public.office_members om
          join public.offices o
            on o.id = om.office_id
           and o.status = 'ACTIVE'::public.account_status
          join public.role_permissions rp on rp.role_id = om.role_id
          join public.permissions permission on permission.id = rp.permission_id
          where om.user_id = profile.id
            and om.status = 'ACTIVE'::public.account_status
            and permission.code = has_permission.permission_code
        )
      )
  );
$function$;

create or replace function private.is_office_member(target_office_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $function$
  select exists (
    select 1
    from public.office_members om
    join public.profiles p
      on p.id = om.user_id
     and p.status = 'ACTIVE'::public.account_status
     and p.profile_type = 'STAFF'::public.profile_type
    join public.offices o
      on o.id = om.office_id
     and o.status = 'ACTIVE'::public.account_status
    where om.user_id = (select auth.uid())
      and om.office_id = target_office_id
      and om.status = 'ACTIVE'::public.account_status
  );
$function$;

-- Office authorization is deliberately independent from has_permission().
-- A permission on Office B must not launder access to Office A. A platform
-- role can read an active target office only when it owns that permission.
create or replace function private.can_access_office(
  target_office_id uuid,
  permission_code text
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $function$
  select private.is_super_admin()
    or (
      exists (
        select 1
        from public.offices o
        where o.id = target_office_id
          and o.status = 'ACTIVE'::public.account_status
      )
       and private.has_platform_permission(can_access_office.permission_code)
    )
    or exists (
      select 1
      from public.office_members om
      join public.profiles profile
        on profile.id = om.user_id
       and profile.status = 'ACTIVE'::public.account_status
       and profile.profile_type = 'STAFF'::public.profile_type
      join public.offices o
        on o.id = om.office_id
       and o.status = 'ACTIVE'::public.account_status
      join public.role_permissions rp on rp.role_id = om.role_id
      join public.permissions permission on permission.id = rp.permission_id
      where om.user_id = (select auth.uid())
        and om.office_id = target_office_id
        and om.status = 'ACTIVE'::public.account_status
        and permission.code = can_access_office.permission_code
    );
$function$;

-- One bounded read for the Dashboard shell. The function is SECURITY DEFINER
-- only to assemble role/membership context; it returns the caller's own rows
-- after an explicit active STAFF check and has no mutation surface.
create or replace function public.get_dashboard_context()
returns jsonb
language sql
stable
security definer
set search_path = ''
as $function$
  with caller as (
    select p.id, p.profile_type, p.status
    from public.profiles p
    where p.id = (select auth.uid())
      and p.status = 'ACTIVE'::public.account_status
      and p.profile_type = 'STAFF'::public.profile_type
  ),
  platform_roles as (
    select coalesce(
      jsonb_agg(
        jsonb_build_object(
          'code', r.code,
          'name', r.name,
          'scope_type', r.scope_type,
          'permissions', coalesce((
            select jsonb_agg(permission.code order by permission.code)
            from public.role_permissions rp
            join public.permissions permission on permission.id = rp.permission_id
            where rp.role_id = r.id
          ), '[]'::jsonb)
        ) order by r.code
      ),
      '[]'::jsonb
    ) as value
    from public.user_roles ur
    join public.roles r
      on r.id = ur.role_id
     and r.scope_type = 'PLATFORM'
    where ur.user_id = (select id from caller)
  ),
  office_memberships as (
    select coalesce(
      jsonb_agg(
        jsonb_build_object(
          'office_id', om.office_id,
          'office_name', o.name,
          'role_code', r.code,
          'role_name', r.name,
          'permissions', coalesce((
            select jsonb_agg(permission.code order by permission.code)
            from public.role_permissions rp
            join public.permissions permission on permission.id = rp.permission_id
            where rp.role_id = om.role_id
          ), '[]'::jsonb)
        ) order by o.name, om.office_id
      ),
      '[]'::jsonb
    ) as value
    from public.office_members om
    join public.offices o
      on o.id = om.office_id
     and o.status = 'ACTIVE'::public.account_status
    join public.roles r on r.id = om.role_id
    where om.user_id = (select id from caller)
      and om.status = 'ACTIVE'::public.account_status
  )
  select jsonb_build_object(
    'authenticated', (select (select auth.uid()) is not null),
    'staff', exists (select 1 from caller),
    'user_id', case when exists (select 1 from caller)
      then to_jsonb((select id from caller)) else 'null'::jsonb end,
    'profile_type', case when exists (select 1 from caller)
      then to_jsonb((select profile_type::text from caller)) else 'null'::jsonb end,
    'status', case when exists (select 1 from caller)
      then to_jsonb((select status::text from caller)) else 'null'::jsonb end,
    'platform_roles', (select value from platform_roles),
    'office_memberships', (select value from office_memberships)
  );
$function$;

revoke all on function private.is_super_admin() from public, anon, authenticated;
revoke all on function private.has_platform_permission(text) from public, anon, authenticated;
revoke all on function private.has_permission(text) from public, anon, authenticated;
revoke all on function private.is_office_member(uuid) from public, anon, authenticated;
revoke all on function private.can_access_office(uuid, text) from public, anon, authenticated;
grant execute on function private.is_super_admin() to authenticated;
grant execute on function private.has_platform_permission(text) to authenticated;
grant execute on function private.has_permission(text) to authenticated;
grant execute on function private.is_office_member(uuid) to authenticated;
grant execute on function private.can_access_office(uuid, text) to authenticated;

revoke all on function public.get_dashboard_context() from public, anon, authenticated;
grant execute on function public.get_dashboard_context() to authenticated;

-- Platform permissions are platform-wide, including independent records whose
-- office_id is NULL. Office memberships remain exact-office checks.
drop policy if exists profiles_select_permitted on public.profiles;
create policy profiles_select_permitted
on public.profiles
for select
to authenticated
using (
  id = (select auth.uid())
  or private.is_super_admin()
  or private.has_platform_permission('users.view')
  or exists (
    select 1
    from public.office_members om
    where om.user_id = profiles.id
      and (
        private.has_platform_permission('offices.view')
        or private.is_office_member(om.office_id)
      )
  )
  or exists (
    select 1
    from public.drivers d
    where d.user_id = profiles.id
      and (
        private.has_platform_permission('drivers.view')
        or private.can_access_office(d.office_id, 'drivers.view')
      )
  )
);

drop policy if exists offices_select_permitted on public.offices;
create policy offices_select_permitted
on public.offices
for select
to authenticated
using (
  private.is_super_admin()
  or private.has_platform_permission('offices.view')
  or private.is_office_member(id)
);

drop policy if exists office_members_select_permitted on public.office_members;
create policy office_members_select_permitted
on public.office_members
for select
to authenticated
using (
  user_id = (select auth.uid())
  or private.is_super_admin()
  or private.has_platform_permission('offices.view')
  or private.is_office_member(office_id)
);

drop policy if exists drivers_select_permitted on public.drivers;
create policy drivers_select_permitted
on public.drivers
for select
to authenticated
using (
  user_id = (select auth.uid())
  or private.is_super_admin()
  or private.has_platform_permission('drivers.view')
  or private.can_access_office(office_id, 'drivers.view')
);

drop policy if exists motorcycles_select_permitted on public.motorcycles;
create policy motorcycles_select_permitted
on public.motorcycles
for select
to authenticated
using (
  exists (
    select 1
    from public.drivers d
    where d.id = motorcycles.driver_id
      and d.user_id = (select auth.uid())
  )
  or private.is_super_admin()
  or private.has_platform_permission('motorcycles.view')
  or private.can_access_office(office_id, 'motorcycles.view')
);

drop policy if exists driver_documents_select_permitted on public.driver_documents;
create policy driver_documents_select_permitted
on public.driver_documents
for select
to authenticated
using (
  exists (
    select 1
    from public.drivers d
    where d.id = driver_documents.driver_id
      and d.user_id = (select auth.uid())
  )
  or private.is_super_admin()
  or private.has_platform_permission('drivers.view')
  or exists (
    select 1
    from public.drivers d
    where d.id = driver_documents.driver_id
      and private.can_access_office(d.office_id, 'drivers.view')
  )
);

drop policy if exists motorcycle_documents_select_permitted on public.motorcycle_documents;
create policy motorcycle_documents_select_permitted
on public.motorcycle_documents
for select
to authenticated
using (
  exists (
    select 1
    from public.motorcycles m
    join public.drivers d on d.id = m.driver_id
    where m.id = motorcycle_documents.motorcycle_id
      and d.user_id = (select auth.uid())
  )
  or private.is_super_admin()
  or private.has_platform_permission('motorcycles.view')
  or exists (
    select 1
    from public.motorcycles m
    join public.drivers d on d.id = m.driver_id
    where m.id = motorcycle_documents.motorcycle_id
      and private.can_access_office(d.office_id, 'motorcycles.view')
  )
);

drop policy if exists orders_select_permitted on public.orders;
create policy orders_select_permitted
on public.orders
for select
to authenticated
using (
  customer_id = (select auth.uid())
  or private.is_super_admin()
  or private.has_platform_permission('orders.view')
  or private.can_access_office(office_id, 'orders.view')
);

drop policy if exists offers_select_permitted on public.offers;
create policy offers_select_permitted
on public.offers
for select
to authenticated
using (
  private.is_super_admin()
  or private.has_platform_permission('orders.view')
  or private.can_access_office(office_id, 'orders.view')
  or exists (
    select 1
    from public.drivers d
    where d.id = offers.driver_id
      and d.user_id = (select auth.uid())
  )
);

drop policy if exists order_driver_candidates_select_permitted on public.order_driver_candidates;
create policy order_driver_candidates_select_permitted
on public.order_driver_candidates
for select
to authenticated
using (
  private.is_super_admin()
  or private.has_platform_permission('orders.view')
  or exists (
    select 1
    from public.drivers d
    where d.id = order_driver_candidates.driver_id
      and d.user_id = (select auth.uid())
  )
  or exists (
    select 1
    from public.drivers d
    where d.id = order_driver_candidates.driver_id
      and private.can_access_office(d.office_id, 'orders.view')
  )
);

-- Timeline reads are still read-only and use the same office/platform scope as
-- their parent order. Event writes remain trigger/trusted-function only.
revoke all privileges on table public.order_events from anon, authenticated;
grant select on table public.order_events to authenticated;
drop policy if exists order_events_select_permitted on public.order_events;
create policy order_events_select_permitted
on public.order_events
for select
to authenticated
using (
  private.is_super_admin()
  or private.has_platform_permission('orders.view')
  or exists (
    select 1
    from public.orders o
    where o.id = order_events.order_id
      and private.can_access_office(o.office_id, 'orders.view')
  )
);

-- Keep the private bucket and owner-only writes. Platform verification roles
-- may read evidence; Operations/Support permissions do not grant file access.
drop policy if exists driver_documents_storage_select_own on storage.objects;
create policy driver_documents_storage_select_own
on storage.objects for select to authenticated
using (
  bucket_id = 'driver-documents'
  and (
    (
      owner_id = (select auth.uid())::text
      and exists (
        select 1 from public.drivers d
        where d.user_id = (select auth.uid())
          and (storage.foldername(name))[1] = d.id::text
      )
    )
    or private.is_super_admin()
    or private.has_platform_permission('drivers.verify')
    or private.has_platform_permission('motorcycles.verify')
  )
);

-- The trusted review RPCs keep their existing validation and write paths, but
-- delegate authorization to the least-privilege platform action key.
create or replace function public.review_driver_document(
  p_document_id uuid,
  p_status public.document_status,
  p_rejection_reason text default null
)
returns public.driver_documents
language plpgsql security definer set search_path = ''
as $function$
declare
  v_uid uuid := (select auth.uid());
  v_document public.driver_documents;
begin
  if not private.is_super_admin()
     and not private.has_platform_permission('drivers.verify') then
    raise exception 'Trusted reviewer required' using errcode = '42501';
  end if;
  if p_status not in ('APPROVED'::public.document_status, 'REJECTED'::public.document_status) then
    raise exception 'Invalid review status' using errcode = '22023';
  end if;
  select * into v_document from public.driver_documents where id = p_document_id and is_current for update;
  if not found then raise exception 'Current document not found' using errcode = 'P0002'; end if;
  if p_status = 'APPROVED'::public.document_status
     and v_document.document_type = 'DRIVING_LICENSE'
     and (v_document.expiry_date is null or v_document.expiry_date <= current_date) then
    raise exception 'Valid driving licence expiry required' using errcode = '22023';
  end if;
  if p_status = 'REJECTED'::public.document_status and nullif(btrim(p_rejection_reason), '') is null then
    raise exception 'Rejection reason required' using errcode = '22023';
  end if;
  update public.driver_documents set
    status = p_status,
    rejection_reason = case when p_status = 'REJECTED' then btrim(p_rejection_reason) end,
    verified_by = v_uid,
    verified_at = clock_timestamp(),
    updated_at = clock_timestamp()
  where id = v_document.id returning * into v_document;
  perform private.reconcile_driver_idle_availability(v_document.driver_id);
  return v_document;
end;
$function$;

create or replace function public.review_motorcycle_document(
  p_document_id uuid,
  p_status public.document_status,
  p_rejection_reason text default null
)
returns public.motorcycle_documents
language plpgsql security definer set search_path = ''
as $function$
declare
  v_uid uuid := (select auth.uid());
  v_document public.motorcycle_documents;
  v_driver_id uuid;
begin
  if not private.is_super_admin()
     and not private.has_platform_permission('motorcycles.verify') then
    raise exception 'Trusted reviewer required' using errcode = '42501';
  end if;
  if p_status not in ('APPROVED'::public.document_status, 'REJECTED'::public.document_status) then
    raise exception 'Invalid review status' using errcode = '22023';
  end if;
  select * into v_document from public.motorcycle_documents where id = p_document_id and is_current for update;
  if not found then raise exception 'Current document not found' using errcode = 'P0002'; end if;
  if p_status = 'APPROVED'::public.document_status
     and v_document.expiry_date is not null and v_document.expiry_date <= current_date then
    raise exception 'Valid document expiry required' using errcode = '22023';
  end if;
  if p_status = 'REJECTED'::public.document_status and nullif(btrim(p_rejection_reason), '') is null then
    raise exception 'Rejection reason required' using errcode = '22023';
  end if;
  update public.motorcycle_documents set
    status = p_status,
    rejection_reason = case when p_status = 'REJECTED' then btrim(p_rejection_reason) end,
    verified_by = v_uid,
    verified_at = clock_timestamp(),
    updated_at = clock_timestamp()
  where id = v_document.id returning * into v_document;
  select m.driver_id into v_driver_id from public.motorcycles m where m.id = v_document.motorcycle_id;
  perform private.reconcile_driver_idle_availability(v_driver_id);
  return v_document;
end;
$function$;

create or replace function public.review_motorcycle(
  p_motorcycle_id uuid,
  p_status public.document_status,
  p_rejection_reason text default null
)
returns public.motorcycles
language plpgsql security definer set search_path = ''
as $function$
declare
  v_uid uuid := (select auth.uid());
  v_motorcycle public.motorcycles;
begin
  if not private.is_super_admin()
     and not private.has_platform_permission('motorcycles.verify') then
    raise exception 'Trusted reviewer required' using errcode = '42501';
  end if;
  if p_status not in ('APPROVED'::public.document_status, 'REJECTED'::public.document_status) then
    raise exception 'Invalid review status' using errcode = '22023';
  end if;
  select * into v_motorcycle from public.motorcycles where id = p_motorcycle_id for update;
  if not found then raise exception 'Motorcycle not found' using errcode = 'P0002'; end if;
  if p_status = 'APPROVED'::public.document_status and (
    nullif(btrim(v_motorcycle.plate_number), '') is null
    or nullif(btrim(v_motorcycle.brand), '') is null
    or nullif(btrim(v_motorcycle.model), '') is null
    or exists (
      select 1 from public.motorcycle_documents md
      where md.motorcycle_id = v_motorcycle.id and md.is_current
        and (
          md.status <> 'APPROVED'::public.document_status
          or (md.expiry_date is not null and md.expiry_date <= current_date)
        )
    )
  ) then raise exception 'Motorcycle identity or documents are not valid' using errcode = '22023'; end if;
  if p_status = 'REJECTED'::public.document_status and nullif(btrim(p_rejection_reason), '') is null then
    raise exception 'Rejection reason required' using errcode = '22023';
  end if;
  update public.motorcycles set
    verification_status = p_status,
    verification_rejection_reason = case when p_status = 'REJECTED' then btrim(p_rejection_reason) end,
    verified_by = v_uid,
    verified_at = clock_timestamp(),
    updated_at = clock_timestamp()
  where id = v_motorcycle.id returning * into v_motorcycle;
  perform private.reconcile_driver_idle_availability(v_motorcycle.driver_id);
  return v_motorcycle;
end;
$function$;

create or replace function public.review_driver_verification(
  p_driver_id uuid,
  p_status public.driver_status,
  p_date_of_birth date,
  p_reason text default null
)
returns public.drivers
language plpgsql security definer set search_path = ''
as $function$
declare
  v_driver public.drivers;
  v_reason text;
begin
  if p_status not in (
    'ACTIVE'::public.driver_status,
    'REJECTED'::public.driver_status,
    'SUSPENDED'::public.driver_status
  ) then raise exception 'Invalid Driver review status' using errcode = '22023'; end if;
  if not private.is_super_admin()
     and (
       (p_status = 'ACTIVE'::public.driver_status
        and not private.has_platform_permission('drivers.activate'))
       or (p_status = 'SUSPENDED'::public.driver_status
        and not private.has_platform_permission('drivers.suspend'))
       or (p_status = 'REJECTED'::public.driver_status
        and not private.has_platform_permission('drivers.verify'))
     ) then
    raise exception 'Trusted reviewer required' using errcode = '42501';
  end if;
  if p_date_of_birth is null or p_date_of_birth > current_date - interval '21 years' then
    raise exception 'Driver must be at least 21' using errcode = '22023';
  end if;
  if p_status in ('REJECTED'::public.driver_status, 'SUSPENDED'::public.driver_status)
     and nullif(btrim(p_reason), '') is null then
    raise exception 'Review reason required' using errcode = '22023';
  end if;
  update public.drivers set
    date_of_birth = p_date_of_birth,
    status = p_status,
    verification_rejection_reason = case when p_status = 'REJECTED' then btrim(p_reason) end,
    is_online = case when p_status = 'ACTIVE' then is_online else false end,
    updated_at = clock_timestamp()
  where id = p_driver_id returning * into v_driver;
  if not found then raise exception 'Driver not found' using errcode = 'P0002'; end if;
  if p_status = 'ACTIVE'::public.driver_status then
    v_reason := private.driver_safety_ineligibility(v_driver.id);
    if v_reason is not null then raise exception 'Driver verification incomplete' using errcode = 'P0001', hint = v_reason; end if;
  end if;
  return v_driver;
end;
$function$;

create or replace function public.admin_safety_override(
  p_order_id uuid,
  p_requested_action text,
  p_reason text
)
returns public.orders
language plpgsql security definer set search_path = ''
as $function$
declare
  v_uid uuid := (select auth.uid());
  v_order public.orders;
  v_from public.order_status;
  v_action text := upper(btrim(coalesce(p_requested_action, '')));
  v_override_id uuid;
  v_service text;
begin
  if not private.is_super_admin()
     and not private.has_platform_permission('orders.override') then
    raise exception 'Privileged safety override required' using errcode = '42501';
  end if;
  if v_action not in ('ARRIVE_RIDE', 'COMPLETE_RIDE', 'PICKUP_DELIVERY', 'COMPLETE_DELIVERY') then
    raise exception 'Unsupported safety override action' using errcode = '22023';
  end if;
  if nullif(btrim(p_reason), '') is null or length(btrim(p_reason)) > 500 then
    raise exception 'Safety override reason required' using errcode = '22023';
  end if;
  select o.* into v_order
  from public.orders o
  where o.id = p_order_id for update;
  if not found then raise exception 'Order not found' using errcode = 'P0002'; end if;
  select s.code into v_service from public.service_types s where s.id = v_order.service_type_id;
  v_from := v_order.status;

  if v_action = 'ARRIVE_RIDE' and v_service = 'RIDE' and v_order.status = 'DRIVER_ON_WAY' then
    update public.orders set status = 'DRIVER_ARRIVED', driver_arrived_at = coalesce(driver_arrived_at, clock_timestamp())
    where id = v_order.id returning * into v_order;
  elsif v_action = 'COMPLETE_RIDE' and v_service = 'RIDE' and v_order.status = 'IN_PROGRESS' then
    update public.orders set status = 'COMPLETED', completed_at = coalesce(completed_at, clock_timestamp())
    where id = v_order.id returning * into v_order;
    update public.drivers set completed_trip_count = completed_trip_count + 1 where id = v_order.driver_id;
  elsif v_action = 'PICKUP_DELIVERY' and v_service = 'DELIVERY' and v_order.status = 'DRIVER_ON_WAY' then
    update public.orders set status = 'DRIVER_ARRIVED', driver_arrived_at = coalesce(driver_arrived_at, clock_timestamp())
    where id = v_order.id returning * into v_order;
    update public.orders set status = 'IN_PROGRESS', started_at = coalesce(started_at, clock_timestamp())
    where id = v_order.id returning * into v_order;
  elsif v_action = 'COMPLETE_DELIVERY' and v_service = 'DELIVERY' and v_order.status = 'IN_PROGRESS' then
    update private.delivery_confirmation_secrets set consumed_at = clock_timestamp() where order_id = v_order.id;
    update public.orders set status = 'COMPLETED', completed_at = coalesce(completed_at, clock_timestamp())
    where id = v_order.id returning * into v_order;
    update public.drivers set completed_trip_count = completed_trip_count + 1 where id = v_order.driver_id;
  else
    raise exception 'Safety override does not match service or lifecycle' using errcode = 'P0001';
  end if;

  insert into public.safety_overrides (
    order_id, actor_user_id, requested_action, reason, from_status, to_status
  ) values (
    v_order.id, v_uid, v_action, btrim(p_reason), v_from, v_order.status
  ) returning id into v_override_id;
  insert into public.order_events (
    order_id, event_type, actor_user_id, from_status, to_status, metadata
  ) values (
    v_order.id, 'SAFETY_OVERRIDE', v_uid, v_from, v_order.status,
    jsonb_build_object('override_id', v_override_id, 'action', v_action, 'reason', btrim(p_reason))
  );
  return v_order;
end;
$function$;
