-- ADM-05: protected, append-only audit records for sensitive Dashboard mutations.
-- This migration does not expose table DML to clients or store document/storage secrets.

insert into public.permissions (code, description)
values
  ('motorcycles.verify', 'Verify motorcycle evidence and identity'),
  ('orders.override', 'Perform an explicit trusted order safety override')
on conflict (code) do update
  set description = excluded.description;

insert into public.role_permissions (role_id, permission_id)
select r.id, p.id
from public.roles r
join public.permissions p on p.code = 'motorcycles.verify'
where r.code in ('SUPER_ADMIN', 'VERIFICATION_AGENT')
on conflict do nothing;

insert into public.role_permissions (role_id, permission_id)
select r.id, p.id
from public.roles r
join public.permissions p on p.code = 'orders.override'
where r.code = 'SUPER_ADMIN'
on conflict do nothing;

create table public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  actor_user_id uuid references public.profiles(id),
  actor_role text,
  office_id uuid references public.offices(id),
  action text not null,
  entity_type text not null,
  entity_id uuid,
  reason text,
  old_value jsonb,
  new_value jsonb,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default clock_timestamp(),
  constraint audit_logs_action_ck check (nullif(btrim(action), '') is not null),
  constraint audit_logs_entity_type_ck check (nullif(btrim(entity_type), '') is not null),
  constraint audit_logs_reason_ck check (
    reason is null or length(btrim(reason)) between 1 and 500
  )
);

create index audit_logs_entity_created_idx
  on public.audit_logs (entity_type, entity_id, created_at desc);
create index audit_logs_actor_created_idx
  on public.audit_logs (actor_user_id, created_at desc);

alter table public.audit_logs enable row level security;
revoke all on table public.audit_logs from public, anon, authenticated;
grant select on table public.audit_logs to service_role;

create or replace function private.prevent_audit_log_mutation()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
begin
  raise exception 'Audit logs are append-only' using errcode = '42501';
end;
$function$;

drop trigger if exists audit_logs_no_update_delete on public.audit_logs;
create trigger audit_logs_no_update_delete
before update or delete on public.audit_logs
for each row execute function private.prevent_audit_log_mutation();

create or replace function private.record_admin_audit(
  p_action text,
  p_entity_type text,
  p_entity_id uuid,
  p_reason text,
  p_old_value jsonb,
  p_new_value jsonb,
  p_metadata jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_uid uuid := (select auth.uid());
  v_actor_role text;
  v_office_id uuid;
  v_audit_id uuid;
begin
  if v_uid is null then
    raise exception 'Authenticated actor required' using errcode = '42501';
  end if;
  if nullif(btrim(p_action), '') is null
     or nullif(btrim(p_entity_type), '') is null then
    raise exception 'Audit action and entity type are required' using errcode = '22023';
  end if;
  if p_reason is not null and length(btrim(p_reason)) > 500 then
    raise exception 'Audit reason is too long' using errcode = '22023';
  end if;
  if coalesce(p_old_value, '{}'::jsonb) ?| array[
    'file_path', 'code_hash', 'code_value', 'delivery_code',
    'password', 'token', 'secret'
  ] or coalesce(p_new_value, '{}'::jsonb) ?| array[
    'file_path', 'code_hash', 'code_value', 'delivery_code',
    'password', 'token', 'secret'
  ] then
    raise exception 'Audit snapshots cannot contain secrets' using errcode = '22023';
  end if;

  if not exists (
    select 1
    from public.profiles p
    where p.id = v_uid
      and p.profile_type = 'STAFF'::public.profile_type
      and p.status = 'ACTIVE'::public.account_status
  ) then
    raise exception 'Active staff actor required' using errcode = '42501';
  end if;

  select string_agg(r.code, ',' order by r.code)
    into v_actor_role
  from public.user_roles ur
  join public.roles r on r.id = ur.role_id and r.scope_type = 'PLATFORM'
  where ur.user_id = v_uid;

  select om.office_id
    into v_office_id
  from public.office_members om
  join public.offices o
    on o.id = om.office_id
   and o.status = 'ACTIVE'::public.account_status
  where om.user_id = v_uid
    and om.status = 'ACTIVE'::public.account_status
  order by om.office_id
  limit 1;

  insert into public.audit_logs (
    actor_user_id, actor_role, office_id, action, entity_type, entity_id,
    reason, old_value, new_value, metadata
  ) values (
    v_uid, v_actor_role, v_office_id, btrim(p_action), btrim(p_entity_type),
    p_entity_id, nullif(btrim(p_reason), ''), p_old_value, p_new_value,
    coalesce(p_metadata, '{}'::jsonb)
  ) returning id into v_audit_id;

  return v_audit_id;
end;
$function$;

-- Client code can call the named trusted RPCs only; the generic recorder is internal.
revoke all on function private.prevent_audit_log_mutation() from public, anon, authenticated;
revoke all on function private.record_admin_audit(text,text,uuid,text,jsonb,jsonb,jsonb)
from public, anon, authenticated;

create or replace function public.review_driver_document(
  p_document_id uuid,
  p_status public.document_status,
  p_rejection_reason text default null
)
returns public.driver_documents
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_document public.driver_documents;
  v_old_value jsonb;
  v_new_value jsonb;
begin
  if not private.has_platform_permission('drivers.verify') then
    raise exception 'Trusted reviewer required' using errcode = '42501';
  end if;
  if p_status not in ('APPROVED'::public.document_status, 'REJECTED'::public.document_status) then
    raise exception 'Invalid review status' using errcode = '22023';
  end if;
  select * into v_document
  from public.driver_documents
  where id = p_document_id and is_current
  for update;
  if not found then raise exception 'Current document not found' using errcode = 'P0002'; end if;
  if p_status = 'APPROVED'::public.document_status
     and v_document.document_type = 'DRIVING_LICENSE'
     and (v_document.expiry_date is null or v_document.expiry_date <= current_date) then
    raise exception 'Valid driving licence expiry required' using errcode = '22023';
  end if;
  if p_status = 'REJECTED'::public.document_status
     and nullif(btrim(p_rejection_reason), '') is null then
    raise exception 'Rejection reason required' using errcode = '22023';
  end if;
  v_old_value := jsonb_build_object(
    'status', v_document.status::text,
    'rejection_reason', v_document.rejection_reason,
    'verified_at', v_document.verified_at
  );
  update public.driver_documents set
    status = p_status,
    rejection_reason = case when p_status = 'REJECTED' then btrim(p_rejection_reason) end,
    verified_by = (select auth.uid()),
    verified_at = clock_timestamp(),
    updated_at = clock_timestamp()
  where id = v_document.id
  returning * into v_document;
  perform private.reconcile_driver_idle_availability(v_document.driver_id);
  v_new_value := jsonb_build_object(
    'status', v_document.status::text,
    'rejection_reason', v_document.rejection_reason,
    'verified_at', v_document.verified_at
  );
  perform private.record_admin_audit(
    'DRIVER_DOCUMENT_REVIEW', 'DRIVER_DOCUMENT', v_document.id,
    case when p_status = 'REJECTED' then p_rejection_reason end,
    v_old_value, v_new_value,
    jsonb_build_object('document_type', v_document.document_type, 'permission', 'drivers.verify')
  );
  return v_document;
end;
$function$;

create or replace function public.review_motorcycle_document(
  p_document_id uuid,
  p_status public.document_status,
  p_rejection_reason text default null
)
returns public.motorcycle_documents
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_document public.motorcycle_documents;
  v_driver_id uuid;
  v_old_value jsonb;
  v_new_value jsonb;
begin
  if not private.has_platform_permission('motorcycles.verify') then
    raise exception 'Trusted reviewer required' using errcode = '42501';
  end if;
  if p_status not in ('APPROVED'::public.document_status, 'REJECTED'::public.document_status) then
    raise exception 'Invalid review status' using errcode = '22023';
  end if;
  select * into v_document
  from public.motorcycle_documents
  where id = p_document_id and is_current
  for update;
  if not found then raise exception 'Current document not found' using errcode = 'P0002'; end if;
  if p_status = 'APPROVED'::public.document_status
     and v_document.expiry_date is not null and v_document.expiry_date <= current_date then
    raise exception 'Valid document expiry required' using errcode = '22023';
  end if;
  if p_status = 'REJECTED'::public.document_status
     and nullif(btrim(p_rejection_reason), '') is null then
    raise exception 'Rejection reason required' using errcode = '22023';
  end if;
  v_old_value := jsonb_build_object(
    'status', v_document.status::text,
    'rejection_reason', v_document.rejection_reason,
    'verified_at', v_document.verified_at
  );
  update public.motorcycle_documents set
    status = p_status,
    rejection_reason = case when p_status = 'REJECTED' then btrim(p_rejection_reason) end,
    verified_by = (select auth.uid()),
    verified_at = clock_timestamp(),
    updated_at = clock_timestamp()
  where id = v_document.id
  returning * into v_document;
  select m.driver_id into v_driver_id
  from public.motorcycles m
  where m.id = v_document.motorcycle_id;
  perform private.reconcile_driver_idle_availability(v_driver_id);
  v_new_value := jsonb_build_object(
    'status', v_document.status::text,
    'rejection_reason', v_document.rejection_reason,
    'verified_at', v_document.verified_at
  );
  perform private.record_admin_audit(
    'MOTORCYCLE_DOCUMENT_REVIEW', 'MOTORCYCLE_DOCUMENT', v_document.id,
    case when p_status = 'REJECTED' then p_rejection_reason end,
    v_old_value, v_new_value,
    jsonb_build_object('document_type', v_document.document_type, 'permission', 'motorcycles.verify')
  );
  return v_document;
end;
$function$;

create or replace function public.review_motorcycle(
  p_motorcycle_id uuid,
  p_status public.document_status,
  p_rejection_reason text default null
)
returns public.motorcycles
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_motorcycle public.motorcycles;
  v_old_value jsonb;
  v_new_value jsonb;
begin
  if not private.has_platform_permission('motorcycles.verify') then
    raise exception 'Trusted reviewer required' using errcode = '42501';
  end if;
  if p_status not in ('APPROVED'::public.document_status, 'REJECTED'::public.document_status) then
    raise exception 'Invalid review status' using errcode = '22023';
  end if;
  select * into v_motorcycle
  from public.motorcycles
  where id = p_motorcycle_id
  for update;
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
  if p_status = 'REJECTED'::public.document_status
     and nullif(btrim(p_rejection_reason), '') is null then
    raise exception 'Rejection reason required' using errcode = '22023';
  end if;
  v_old_value := jsonb_build_object(
    'verification_status', v_motorcycle.verification_status::text,
    'verification_rejection_reason', v_motorcycle.verification_rejection_reason,
    'verified_at', v_motorcycle.verified_at
  );
  update public.motorcycles set
    verification_status = p_status,
    verification_rejection_reason = case when p_status = 'REJECTED' then btrim(p_rejection_reason) end,
    verified_by = (select auth.uid()),
    verified_at = clock_timestamp(),
    updated_at = clock_timestamp()
  where id = v_motorcycle.id
  returning * into v_motorcycle;
  perform private.reconcile_driver_idle_availability(v_motorcycle.driver_id);
  v_new_value := jsonb_build_object(
    'verification_status', v_motorcycle.verification_status::text,
    'verification_rejection_reason', v_motorcycle.verification_rejection_reason,
    'verified_at', v_motorcycle.verified_at
  );
  perform private.record_admin_audit(
    'MOTORCYCLE_REVIEW', 'MOTORCYCLE', v_motorcycle.id,
    case when p_status = 'REJECTED' then p_rejection_reason end,
    v_old_value, v_new_value,
    jsonb_build_object('permission', 'motorcycles.verify')
  );
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
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_driver public.drivers;
  v_reason text;
  v_permission text;
  v_old_value jsonb;
  v_new_value jsonb;
begin
  v_permission := case p_status
    when 'ACTIVE'::public.driver_status then 'drivers.activate'
    when 'SUSPENDED'::public.driver_status then 'drivers.suspend'
    else 'drivers.verify'
  end;
  if not private.has_platform_permission(v_permission) then
    raise exception 'Trusted reviewer required' using errcode = '42501';
  end if;
  if p_status not in (
    'ACTIVE'::public.driver_status,
    'REJECTED'::public.driver_status,
    'SUSPENDED'::public.driver_status
  ) then raise exception 'Invalid Driver review status' using errcode = '22023'; end if;
  if p_date_of_birth is null or p_date_of_birth > current_date - interval '21 years' then
    raise exception 'Driver must be at least 21' using errcode = '22023';
  end if;
  if p_status in ('REJECTED'::public.driver_status, 'SUSPENDED'::public.driver_status)
     and nullif(btrim(p_reason), '') is null then
    raise exception 'Review reason required' using errcode = '22023';
  end if;
  select * into v_driver
  from public.drivers
  where id = p_driver_id
  for update;
  if not found then raise exception 'Driver not found' using errcode = 'P0002'; end if;
  v_old_value := jsonb_build_object(
    'status', v_driver.status::text,
    'verification_rejection_reason', v_driver.verification_rejection_reason,
    'is_online', v_driver.is_online
  );
  update public.drivers set
    date_of_birth = p_date_of_birth,
    status = p_status,
    verification_rejection_reason = case
      when p_status in ('REJECTED'::public.driver_status, 'SUSPENDED'::public.driver_status)
        then btrim(p_reason)
      else null
    end,
    is_online = case when p_status = 'ACTIVE'::public.driver_status then is_online else false end,
    updated_at = clock_timestamp()
  where id = v_driver.id
  returning * into v_driver;
  if p_status = 'ACTIVE'::public.driver_status then
    v_reason := private.driver_safety_ineligibility(v_driver.id);
    if v_reason is not null then
      raise exception 'Driver verification incomplete' using errcode = 'P0001', hint = v_reason;
    end if;
  end if;
  v_new_value := jsonb_build_object(
    'status', v_driver.status::text,
    'verification_rejection_reason', v_driver.verification_rejection_reason,
    'is_online', v_driver.is_online
  );
  perform private.record_admin_audit(
    'DRIVER_VERIFICATION', 'DRIVER', v_driver.id,
    case when p_status in ('REJECTED'::public.driver_status, 'SUSPENDED'::public.driver_status)
      then p_reason end,
    v_old_value, v_new_value,
    jsonb_build_object('permission', v_permission)
  );
  return v_driver;
end;
$function$;

create or replace function public.admin_safety_override(
  p_order_id uuid,
  p_requested_action text,
  p_reason text
)
returns public.orders
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_order public.orders;
  v_from public.order_status;
  v_action text := upper(btrim(coalesce(p_requested_action, '')));
  v_override_id uuid;
  v_service text;
  v_old_value jsonb;
  v_new_value jsonb;
begin
  if not private.has_platform_permission('orders.override') then
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
  where o.id = p_order_id
  for update;
  if not found then raise exception 'Order not found' using errcode = 'P0002'; end if;
  select s.code into v_service from public.service_types s where s.id = v_order.service_type_id;
  v_from := v_order.status;
  v_old_value := jsonb_build_object('status', v_from::text);

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
    v_order.id, (select auth.uid()), v_action, btrim(p_reason), v_from, v_order.status
  ) returning id into v_override_id;
  insert into public.order_events (
    order_id, event_type, actor_user_id, from_status, to_status, metadata
  ) values (
    v_order.id, 'SAFETY_OVERRIDE', (select auth.uid()), v_from, v_order.status,
    jsonb_build_object('override_id', v_override_id, 'action', v_action, 'reason', btrim(p_reason))
  );
  v_new_value := jsonb_build_object('status', v_order.status::text);
  perform private.record_admin_audit(
    'SAFETY_OVERRIDE', 'ORDER', v_order.id, p_reason,
    v_old_value, v_new_value,
    jsonb_build_object('action', v_action, 'permission', 'orders.override')
  );
  return v_order;
end;
$function$;

