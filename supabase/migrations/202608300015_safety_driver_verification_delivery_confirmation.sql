-- Milestone 10: Driver verification, private documents, geofenced lifecycle,
-- and one final Delivery Confirmation Code. Auth remains Email + Password.

insert into public.platform_settings (key, value) values
  ('safety_pickup_geofence_meters', '200'::jsonb),
  ('safety_destination_geofence_meters', '300'::jsonb)
on conflict (key) do update set value = excluded.value, updated_at = clock_timestamp();

alter table public.notification_outbox
  drop constraint notification_outbox_target_type_check;
alter table public.notification_outbox
  add constraint notification_outbox_target_type_check check (
    target_type in ('ORDER', 'ACTIVE_ORDER', 'WAITING_OFFER', 'REQUESTS', 'PROFILE')
  );

alter table public.drivers
  add column date_of_birth date,
  add column verification_rejection_reason text,
  add column ride_safety_equipment_confirmed_at timestamptz,
  add constraint drivers_minimum_age_ck check (
    date_of_birth is null or date_of_birth <= current_date - interval '21 years'
  ),
  add constraint drivers_rejection_reason_ck check (
    status <> 'REJECTED'::public.driver_status
    or nullif(btrim(verification_rejection_reason), '') is not null
  );

alter table public.motorcycles
  add column verification_status public.document_status not null default 'PENDING',
  add column verification_rejection_reason text,
  add column verified_by uuid references public.profiles(id),
  add column verified_at timestamptz,
  add constraint motorcycles_verified_identity_ck check (
    verification_status <> 'APPROVED'::public.document_status
    or (
      nullif(btrim(plate_number), '') is not null
      and nullif(btrim(brand), '') is not null
      and nullif(btrim(model), '') is not null
    )
  ),
  add constraint motorcycles_rejection_reason_ck check (
    verification_status <> 'REJECTED'::public.document_status
    or nullif(btrim(verification_rejection_reason), '') is not null
  );

create unique index motorcycles_one_verified_active_per_driver_idx
  on public.motorcycles (driver_id)
  where driver_id is not null
    and status = 'ACTIVE'::public.motorcycle_status
    and verification_status = 'APPROVED'::public.document_status;

alter table public.driver_documents
  add column issued_at date,
  add column is_current boolean not null default true,
  add constraint driver_documents_type_ck check (
    document_type in ('NATIONAL_ID', 'DRIVING_LICENSE', 'DRIVER_SELFIE')
  ),
  add constraint driver_documents_dates_ck check (
    issued_at is null or expiry_date is null or issued_at <= expiry_date
  );

create unique index driver_documents_one_current_type_idx
  on public.driver_documents (driver_id, document_type)
  where is_current;

create table public.motorcycle_documents (
  id uuid primary key default gen_random_uuid(),
  motorcycle_id uuid not null references public.motorcycles(id) on delete cascade,
  document_type text not null check (document_type in (
    'MOTORCYCLE_REGISTRATION', 'OWNERSHIP_AUTHORIZATION',
    'MOTORCYCLE_PHOTO', 'INSURANCE', 'INSPECTION'
  )),
  file_path text not null,
  status public.document_status not null default 'PENDING',
  issued_at date,
  expiry_date date,
  rejection_reason text,
  verified_by uuid references public.profiles(id),
  verified_at timestamptz,
  is_current boolean not null default true,
  created_at timestamptz not null default clock_timestamp(),
  updated_at timestamptz not null default clock_timestamp(),
  constraint motorcycle_documents_dates_ck check (
    issued_at is null or expiry_date is null or issued_at <= expiry_date
  ),
  constraint motorcycle_documents_rejection_reason_ck check (
    status <> 'REJECTED'::public.document_status
    or nullif(btrim(rejection_reason), '') is not null
  )
);

create unique index motorcycle_documents_one_current_type_idx
  on public.motorcycle_documents (motorcycle_id, document_type)
  where is_current;
create index motorcycle_documents_motorcycle_status_idx
  on public.motorcycle_documents (motorcycle_id, status) where is_current;
create trigger motorcycle_documents_set_updated_at
before update on public.motorcycle_documents
for each row execute function public.set_updated_at();

alter table public.motorcycle_documents enable row level security;
revoke all on table public.motorcycle_documents from public, anon, authenticated;
grant select on table public.motorcycle_documents to authenticated;
create policy motorcycle_documents_select_permitted
on public.motorcycle_documents for select to authenticated
using (
  exists (
    select 1
    from public.motorcycles m
    join public.drivers d on d.id = m.driver_id
    where m.id = motorcycle_documents.motorcycle_id
      and d.user_id = (select auth.uid())
  )
  or private.is_super_admin()
);

alter table public.orders
  add column motorcycle_id uuid references public.motorcycles(id),
  add constraint orders_assigned_motorcycle_ck check (
    (status not in (
      'DRIVER_ASSIGNED'::public.order_status,
      'DRIVER_ON_WAY'::public.order_status,
      'DRIVER_ARRIVED'::public.order_status,
      'IN_PROGRESS'::public.order_status,
      'COMPLETED'::public.order_status
    ) or motorcycle_id is not null)
    and (status not in (
      'DRAFT'::public.order_status,
      'BIDDING'::public.order_status,
      'EXPIRED'::public.order_status
    ) or motorcycle_id is null)
  );

create table private.delivery_confirmation_secrets (
  order_id uuid primary key references public.orders(id) on delete cascade,
  code_hash text not null,
  code_value text not null check (code_value ~ '^[0-9]{4}$'),
  failed_attempts smallint not null default 0 check (failed_attempts between 0 and 4),
  locked_until timestamptz,
  consumed_at timestamptz,
  created_at timestamptz not null default clock_timestamp()
);
alter table private.delivery_confirmation_secrets enable row level security;
revoke all on table private.delivery_confirmation_secrets from public, anon, authenticated;

create table public.safety_overrides (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id),
  actor_user_id uuid not null references public.profiles(id),
  requested_action text not null check (requested_action in (
    'ARRIVE_RIDE', 'COMPLETE_RIDE', 'PICKUP_DELIVERY', 'COMPLETE_DELIVERY'
  )),
  reason text not null check (length(btrim(reason)) between 1 and 500),
  from_status public.order_status not null,
  to_status public.order_status not null,
  created_at timestamptz not null default clock_timestamp()
);
create index safety_overrides_order_created_idx
  on public.safety_overrides (order_id, created_at desc);
alter table public.safety_overrides enable row level security;
revoke all on table public.safety_overrides from public, anon, authenticated;

insert into storage.buckets (
  id, name, public, file_size_limit, allowed_mime_types
) values (
  'driver-documents', 'driver-documents', false, 10485760,
  array['image/jpeg', 'image/png', 'application/pdf']::text[]
)
on conflict (id) do update set
  public = false,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

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
  )
);

create policy driver_documents_storage_insert_own
on storage.objects for insert to authenticated
with check (
  bucket_id = 'driver-documents'
  and owner_id = (select auth.uid())::text
  and exists (
    select 1 from public.drivers d
    where d.user_id = (select auth.uid())
      and (storage.foldername(name))[1] = d.id::text
  )
);

create policy driver_documents_storage_update_own
on storage.objects for update to authenticated
using (
  bucket_id = 'driver-documents'
  and owner_id = (select auth.uid())::text
  and exists (
    select 1 from public.drivers d
    where d.user_id = (select auth.uid())
      and (storage.foldername(name))[1] = d.id::text
  )
)
with check (
  bucket_id = 'driver-documents'
  and owner_id = (select auth.uid())::text
  and exists (
    select 1 from public.drivers d
    where d.user_id = (select auth.uid())
      and (storage.foldername(name))[1] = d.id::text
  )
);

create policy driver_documents_storage_delete_own
on storage.objects for delete to authenticated
using (
  bucket_id = 'driver-documents'
  and owner_id = (select auth.uid())::text
  and exists (
    select 1 from public.drivers d
    where d.user_id = (select auth.uid())
      and (storage.foldername(name))[1] = d.id::text
  )
);

create function private.driver_safety_ineligibility(p_driver_id uuid)
returns text
language plpgsql stable security definer set search_path = ''
as $function$
declare
  v_driver public.drivers;
begin
  select d.* into v_driver
  from public.drivers d
  join public.profiles p on p.id = d.user_id
  where d.id = p_driver_id
    and d.status = 'ACTIVE'::public.driver_status
    and p.profile_type = 'DRIVER'::public.profile_type
    and p.status = 'ACTIVE'::public.account_status
    and (d.office_id is null or exists (
      select 1 from public.offices o
      where o.id = d.office_id and o.status = 'ACTIVE'::public.account_status
    ));
  if not found then return 'حساب السائق غير نشط.'; end if;
  if v_driver.date_of_birth is null
     or v_driver.date_of_birth > current_date - interval '21 years' then
    return 'بيانات العمر تحتاج مراجعة قبل الاتصال.';
  end if;
  if exists (
    select 1
    from (values
      ('NATIONAL_ID', false),
      ('DRIVING_LICENSE', true),
      ('DRIVER_SELFIE', false)
    ) required(document_type, expiry_required)
    where not exists (
      select 1 from public.driver_documents dd
      where dd.driver_id = v_driver.id
        and dd.document_type = required.document_type
        and dd.is_current
        and dd.status = 'APPROVED'::public.document_status
        and (
          (required.expiry_required and dd.expiry_date > current_date)
          or (not required.expiry_required and (dd.expiry_date is null or dd.expiry_date > current_date))
        )
    )
  ) then return 'أكمل المستندات المطلوبة وتأكد من اعتمادها وسريانها.'; end if;
  if not exists (
    select 1 from public.motorcycles m
    where m.driver_id = v_driver.id
      and m.status = 'ACTIVE'::public.motorcycle_status
      and m.verification_status = 'APPROVED'::public.document_status
      and not exists (
        select 1 from public.motorcycle_documents md
        where md.motorcycle_id = m.id and md.is_current
          and (
            md.status <> 'APPROVED'::public.document_status
            or (md.expiry_date is not null and md.expiry_date <= current_date)
          )
      )
  ) then return 'الدراجة أو مستنداتها تحتاج اعتمادًا ساريًا.'; end if;
  return null;
end;
$function$;

create function private.reconcile_driver_idle_availability(p_driver_id uuid)
returns void
language sql security definer set search_path = ''
as $function$
  update public.drivers d
  set is_online = false, updated_at = clock_timestamp()
  where d.id = p_driver_id
    and d.is_online
    and private.driver_safety_ineligibility(d.id) is not null
    and not exists (
      select 1 from public.orders o
      where o.driver_id = d.id
        and o.status in (
          'DRIVER_ASSIGNED'::public.order_status,
          'DRIVER_ON_WAY'::public.order_status,
          'DRIVER_ARRIVED'::public.order_status,
          'IN_PROGRESS'::public.order_status
        )
    );
$function$;

create or replace function private.ensure_fresh_location_before_online()
returns trigger
language plpgsql security definer set search_path = ''
as $function$
declare
  v_reason text;
begin
  if new.is_online and not old.is_online then
    v_reason := private.driver_safety_ineligibility(new.id);
    if v_reason is not null then
      raise exception 'Online eligibility denied' using errcode = 'P0001', hint = v_reason;
    end if;
    if not exists (
      select 1 from public.driver_latest_locations l
      where l.driver_id = new.id
        and l.updated_at >= clock_timestamp() - make_interval(
          secs => private.setting_positive_int('driver_location_freshness_seconds', 120)
        )
    ) then
      raise exception 'Online eligibility denied'
        using errcode = 'P0001', hint = 'حدّث موقعك الحالي ثم حاول الاتصال.';
    end if;
  end if;
  return new;
end;
$function$;

create or replace function public.set_driver_online(p_is_online boolean)
returns public.drivers
language plpgsql security definer set search_path = ''
as $function$
declare
  v_uid uuid := (select auth.uid());
  v_driver public.drivers;
  v_reason text;
begin
  if v_uid is null then raise exception 'Authentication required' using errcode = '42501'; end if;
  if p_is_online is null then raise exception 'Online state is required' using errcode = '22023'; end if;
  select * into v_driver from public.drivers where user_id = v_uid for update;
  if not found then raise exception 'Driver account required' using errcode = '42501'; end if;

  if p_is_online then
    v_reason := private.driver_safety_ineligibility(v_driver.id);
    if v_reason is not null then
      raise exception 'Online eligibility denied' using errcode = 'P0001', hint = v_reason;
    end if;
  end if;
  if exists (
    select 1 from public.orders o where o.driver_id = v_driver.id
      and o.status in (
        'DRIVER_ASSIGNED'::public.order_status,
        'DRIVER_ON_WAY'::public.order_status,
        'DRIVER_ARRIVED'::public.order_status,
        'IN_PROGRESS'::public.order_status
      )
  ) then
    if p_is_online then
      raise exception 'Online eligibility denied'
        using errcode = 'P0001', hint = 'لديك رحلة نشطة بالفعل.';
    end if;
    raise exception 'Cannot go offline during an active order' using errcode = 'P0001';
  end if;

  update public.drivers set is_online = p_is_online, updated_at = clock_timestamp()
  where id = v_driver.id returning * into v_driver;
  return v_driver;
end;
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
    join public.service_types service on service.id = o.service_type_id
    where d.id = p_driver_id
      and private.driver_safety_ineligibility(d.id) is null
      and d.is_online
      and (service.code <> 'RIDE' or d.ride_safety_equipment_confirmed_at is not null)
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
          extensions.st_makepoint(o.pickup_lng::double precision, o.pickup_lat::double precision), 4326
        )::extensions.geography
      )
      and extensions.st_dwithin(
        l.position,
        extensions.st_setsrid(
          extensions.st_makepoint(o.pickup_lng::double precision, o.pickup_lat::double precision), 4326
        )::extensions.geography,
        private.dispatch_radius_meters(o.created_at)
      )
  );
$function$;

create function public.confirm_ride_safety_equipment()
returns boolean
language plpgsql security definer set search_path = ''
as $function$
declare
  v_uid uuid := (select auth.uid());
begin
  if v_uid is null then raise exception 'Authentication required' using errcode = '42501'; end if;
  update public.drivers
  set ride_safety_equipment_confirmed_at = clock_timestamp(), updated_at = clock_timestamp()
  where user_id = v_uid;
  if not found then raise exception 'Driver account required' using errcode = '42501'; end if;
  return true;
end;
$function$;

create function public.submit_driver_document(
  p_document_type text,
  p_file_path text,
  p_expiry_date date default null,
  p_issued_at date default null
)
returns uuid
language plpgsql security definer set search_path = ''
as $function$
declare
  v_uid uuid := (select auth.uid());
  v_driver_id uuid;
  v_id uuid;
  v_type text := upper(btrim(coalesce(p_document_type, '')));
  v_path text := btrim(coalesce(p_file_path, ''));
begin
  if v_uid is null then raise exception 'Authentication required' using errcode = '42501'; end if;
  select d.id into v_driver_id from public.drivers d where d.user_id = v_uid;
  if v_driver_id is null then raise exception 'Driver account required' using errcode = '42501'; end if;
  if v_type not in ('NATIONAL_ID', 'DRIVING_LICENSE', 'DRIVER_SELFIE') then
    raise exception 'Unsupported Driver document type' using errcode = '22023';
  end if;
  if v_type = 'DRIVING_LICENSE' and (p_expiry_date is null or p_expiry_date <= current_date) then
    raise exception 'Driving licence expiry is required' using errcode = '22023';
  end if;
  if p_expiry_date is not null and p_expiry_date <= current_date then
    raise exception 'Document is already expired' using errcode = '22023';
  end if;
  if p_issued_at is not null and p_expiry_date is not null and p_issued_at > p_expiry_date then
    raise exception 'Invalid document dates' using errcode = '22023';
  end if;
  if v_path not like v_driver_id::text || '/driver/' || v_type || '/%' or not exists (
    select 1 from storage.objects o
    where o.bucket_id = 'driver-documents' and o.name = v_path and o.owner_id = v_uid::text
  ) then
    raise exception 'Driver-scoped uploaded file required' using errcode = '42501';
  end if;

  update public.driver_documents set is_current = false, updated_at = clock_timestamp()
  where driver_id = v_driver_id and document_type = v_type and is_current;
  insert into public.driver_documents (
    driver_id, document_type, file_path, status, expiry_date, issued_at, is_current
  ) values (
    v_driver_id, v_type, v_path, 'PENDING', p_expiry_date, p_issued_at, true
  ) returning id into v_id;
  perform private.reconcile_driver_idle_availability(v_driver_id);
  return v_id;
end;
$function$;

create function public.submit_motorcycle_document(
  p_motorcycle_id uuid,
  p_document_type text,
  p_file_path text,
  p_expiry_date date default null,
  p_issued_at date default null
)
returns uuid
language plpgsql security definer set search_path = ''
as $function$
declare
  v_uid uuid := (select auth.uid());
  v_driver_id uuid;
  v_id uuid;
  v_type text := upper(btrim(coalesce(p_document_type, '')));
  v_path text := btrim(coalesce(p_file_path, ''));
begin
  if v_uid is null then raise exception 'Authentication required' using errcode = '42501'; end if;
  select d.id into v_driver_id
  from public.drivers d join public.motorcycles m on m.driver_id = d.id
  where d.user_id = v_uid and m.id = p_motorcycle_id;
  if v_driver_id is null then raise exception 'Owned motorcycle required' using errcode = '42501'; end if;
  if v_type not in (
    'MOTORCYCLE_REGISTRATION', 'OWNERSHIP_AUTHORIZATION',
    'MOTORCYCLE_PHOTO', 'INSURANCE', 'INSPECTION'
  ) then raise exception 'Unsupported motorcycle document type' using errcode = '22023'; end if;
  if p_expiry_date is not null and p_expiry_date <= current_date then
    raise exception 'Document is already expired' using errcode = '22023';
  end if;
  if p_issued_at is not null and p_expiry_date is not null and p_issued_at > p_expiry_date then
    raise exception 'Invalid document dates' using errcode = '22023';
  end if;
  if v_path not like v_driver_id::text || '/motorcycle/' || p_motorcycle_id::text || '/' || v_type || '/%'
     or not exists (
       select 1 from storage.objects o
       where o.bucket_id = 'driver-documents' and o.name = v_path and o.owner_id = v_uid::text
     ) then raise exception 'Driver-scoped uploaded file required' using errcode = '42501'; end if;

  update public.motorcycle_documents set is_current = false, updated_at = clock_timestamp()
  where motorcycle_id = p_motorcycle_id and document_type = v_type and is_current;
  insert into public.motorcycle_documents (
    motorcycle_id, document_type, file_path, status, expiry_date, issued_at, is_current
  ) values (
    p_motorcycle_id, v_type, v_path, 'PENDING', p_expiry_date, p_issued_at, true
  ) returning id into v_id;
  perform private.reconcile_driver_idle_availability(v_driver_id);
  return v_id;
end;
$function$;

create function public.get_driver_verification_overview()
returns table (
  driver_status public.driver_status,
  date_of_birth date,
  safety_reason text,
  ride_safety_equipment_confirmed boolean,
  motorcycle jsonb,
  driver_documents jsonb,
  motorcycle_documents jsonb
)
language plpgsql stable security definer set search_path = ''
as $function$
declare
  v_uid uuid := (select auth.uid());
  v_driver public.drivers;
  v_motorcycle public.motorcycles;
begin
  if v_uid is null then raise exception 'Authentication required' using errcode = '42501'; end if;
  select * into v_driver from public.drivers d where d.user_id = v_uid;
  if not found then raise exception 'Driver account required' using errcode = '42501'; end if;
  select * into v_motorcycle from public.motorcycles m
  where m.driver_id = v_driver.id
  order by (m.status = 'ACTIVE'::public.motorcycle_status) desc, m.updated_at desc, m.id
  limit 1;
  return query select
    v_driver.status,
    v_driver.date_of_birth,
    private.driver_safety_ineligibility(v_driver.id),
    v_driver.ride_safety_equipment_confirmed_at is not null,
    case when v_motorcycle.id is null then null else jsonb_build_object(
      'id', v_motorcycle.id,
      'brand', v_motorcycle.brand,
      'model', v_motorcycle.model,
      'plate_number', v_motorcycle.plate_number,
      'status', v_motorcycle.status,
      'verification_status', v_motorcycle.verification_status,
      'rejection_reason', v_motorcycle.verification_rejection_reason
    ) end,
    coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', dd.id,
        'document_type', dd.document_type,
        'status', dd.status,
        'expiry_date', dd.expiry_date,
        'rejection_reason', dd.rejection_reason,
        'file_path', dd.file_path
      ) order by dd.document_type)
      from public.driver_documents dd
      where dd.driver_id = v_driver.id and dd.is_current
    ), '[]'::jsonb),
    coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', md.id,
        'motorcycle_id', md.motorcycle_id,
        'document_type', md.document_type,
        'status', md.status,
        'expiry_date', md.expiry_date,
        'rejection_reason', md.rejection_reason,
        'file_path', md.file_path
      ) order by md.document_type)
      from public.motorcycle_documents md
      join public.motorcycles m on m.id = md.motorcycle_id
      where m.driver_id = v_driver.id and md.is_current
    ), '[]'::jsonb);
end;
$function$;

create function public.review_driver_document(
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
  if not private.is_super_admin() then raise exception 'Trusted reviewer required' using errcode = '42501'; end if;
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

create function public.review_motorcycle_document(
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
  if not private.is_super_admin() then raise exception 'Trusted reviewer required' using errcode = '42501'; end if;
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

create function public.review_motorcycle(
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
  if not private.is_super_admin() then raise exception 'Trusted reviewer required' using errcode = '42501'; end if;
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

create function public.review_driver_verification(
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
  if not private.is_super_admin() then raise exception 'Trusted reviewer required' using errcode = '42501'; end if;
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

create function private.assign_verified_motorcycle()
returns trigger
language plpgsql security definer set search_path = ''
as $function$
begin
  if new.status = 'DRIVER_ASSIGNED'::public.order_status
     and old.status = 'BIDDING'::public.order_status then
    select m.id into new.motorcycle_id
    from public.motorcycles m
    where m.driver_id = new.driver_id
      and m.status = 'ACTIVE'::public.motorcycle_status
      and m.verification_status = 'APPROVED'::public.document_status
      and not exists (
        select 1 from public.motorcycle_documents md
        where md.motorcycle_id = m.id and md.is_current
          and (
            md.status <> 'APPROVED'::public.document_status
            or (md.expiry_date is not null and md.expiry_date <= current_date)
          )
      )
    order by m.updated_at desc, m.id
    limit 1;
    if new.motorcycle_id is null then
      raise exception 'Verified active motorcycle required' using errcode = '42501';
    end if;
  end if;
  return new;
end;
$function$;

create trigger orders_assign_verified_motorcycle
before update of status, driver_id on public.orders
for each row execute function private.assign_verified_motorcycle();

create function private.prepare_delivery_confirmation()
returns trigger
language plpgsql security definer set search_path = ''
as $function$
declare
  v_code text;
begin
  if new.status = 'DRIVER_ASSIGNED'::public.order_status
     and old.status = 'BIDDING'::public.order_status
     and exists (
       select 1 from public.service_types s
       where s.id = new.service_type_id and s.code = 'DELIVERY'
     ) then
    v_code := lpad((
      (get_byte(extensions.gen_random_bytes(2), 0) * 256
       + get_byte(extensions.gen_random_bytes(2), 1)) % 10000
    )::text, 4, '0');
    insert into private.delivery_confirmation_secrets (order_id, code_hash, code_value)
    values (new.id, extensions.crypt(v_code, extensions.gen_salt('bf', 8)), v_code);
  end if;
  return new;
end;
$function$;

create trigger orders_prepare_delivery_confirmation
after update of status on public.orders
for each row execute function private.prepare_delivery_confirmation();

create function public.get_delivery_confirmation_code(p_order_id uuid)
returns text
language plpgsql stable security definer set search_path = ''
as $function$
declare
  v_uid uuid := (select auth.uid());
  v_code text;
begin
  if v_uid is null then raise exception 'Authentication required' using errcode = '42501'; end if;
  select secret.code_value into v_code
  from public.orders o
  join public.service_types s on s.id = o.service_type_id and s.code = 'DELIVERY'
  join private.delivery_confirmation_secrets secret on secret.order_id = o.id
  where o.id = p_order_id and o.customer_id = v_uid
    and o.status in (
      'DRIVER_ASSIGNED'::public.order_status,
      'DRIVER_ON_WAY'::public.order_status,
      'DRIVER_ARRIVED'::public.order_status,
      'IN_PROGRESS'::public.order_status
    )
    and secret.consumed_at is null;
  if not found then raise exception 'Delivery Confirmation Code unavailable' using errcode = '42501'; end if;
  return v_code;
end;
$function$;

create function private.lock_driver_order(
  p_order_id uuid,
  p_service_code text,
  p_expected public.order_status
)
returns public.orders
language plpgsql security definer set search_path = ''
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
    and (d.office_id is null or exists (
      select 1 from public.offices office
      where office.id = d.office_id and office.status = 'ACTIVE'::public.account_status
    ))
  for update of o;
  if not found then raise exception 'Assigned Driver action denied' using errcode = '42501'; end if;
  if v_order.status <> p_expected then raise exception 'Order is not in the expected state' using errcode = 'P0001'; end if;
  return v_order;
end;
$function$;

create function private.assert_driver_geofence(
  p_driver_id uuid,
  p_order public.orders,
  p_target text
)
returns void
language plpgsql stable security definer set search_path = ''
as $function$
declare
  v_location public.driver_latest_locations;
  v_limit integer;
  v_target extensions.geography;
begin
  select * into v_location from public.driver_latest_locations l
  where l.driver_id = p_driver_id;
  if not found or v_location.updated_at < clock_timestamp() - make_interval(
    secs => private.setting_positive_int('driver_location_freshness_seconds', 120)
  ) then
    raise exception 'Driver location is stale'
      using errcode = 'P0001', hint = 'حدّث موقعك الحالي ثم حاول مرة أخرى.';
  end if;
  if p_target = 'PICKUP' then
    v_limit := private.setting_positive_int('safety_pickup_geofence_meters', 200);
    v_target := extensions.st_setsrid(
      extensions.st_makepoint(p_order.pickup_lng::double precision, p_order.pickup_lat::double precision), 4326
    )::extensions.geography;
  elsif p_target = 'DESTINATION' then
    v_limit := private.setting_positive_int('safety_destination_geofence_meters', 300);
    v_target := extensions.st_setsrid(
      extensions.st_makepoint(p_order.destination_lng::double precision, p_order.destination_lat::double precision), 4326
    )::extensions.geography;
  else
    raise exception 'Invalid geofence target' using errcode = '22023';
  end if;
  if not extensions.st_dwithin(v_location.position, v_target, v_limit) then
    raise exception 'Driver is outside the required geofence'
      using errcode = 'P0001', hint = case when p_target = 'PICKUP'
        then 'اقترب أكثر من نقطة الالتقاء لتأكيد الوصول.'
        else 'اقترب أكثر من نقطة التسليم لإكمال الطلب.' end;
  end if;
end;
$function$;

create or replace function public.driver_arrived(p_order_id uuid)
returns public.orders
language plpgsql security definer set search_path = ''
as $function$
declare
  v_order public.orders;
begin
  select * into v_order from private.lock_driver_order(
    p_order_id, 'RIDE', 'DRIVER_ON_WAY'::public.order_status
  );
  perform private.assert_driver_geofence(v_order.driver_id, v_order, 'PICKUP');
  update public.orders set
    status = 'DRIVER_ARRIVED'::public.order_status,
    driver_arrived_at = coalesce(driver_arrived_at, clock_timestamp()),
    updated_at = clock_timestamp()
  where id = v_order.id returning * into v_order;
  return v_order;
end;
$function$;

create or replace function public.start_order(p_order_id uuid)
returns public.orders
language plpgsql security definer set search_path = ''
as $function$
declare
  v_order public.orders;
begin
  select * into v_order from private.lock_driver_order(
    p_order_id, 'RIDE', 'DRIVER_ARRIVED'::public.order_status
  );
  update public.orders set
    status = 'IN_PROGRESS'::public.order_status,
    started_at = coalesce(started_at, clock_timestamp()),
    updated_at = clock_timestamp()
  where id = v_order.id returning * into v_order;
  return v_order;
end;
$function$;

create or replace function public.complete_order(p_order_id uuid)
returns public.orders
language plpgsql security definer set search_path = ''
as $function$
declare
  v_order public.orders;
begin
  select * into v_order from private.lock_driver_order(
    p_order_id, 'RIDE', 'IN_PROGRESS'::public.order_status
  );
  perform private.assert_driver_geofence(v_order.driver_id, v_order, 'DESTINATION');
  update public.orders set
    status = 'COMPLETED'::public.order_status,
    completed_at = coalesce(completed_at, clock_timestamp()),
    updated_at = clock_timestamp()
  where id = v_order.id returning * into v_order;
  update public.drivers set
    completed_trip_count = completed_trip_count + 1,
    updated_at = clock_timestamp()
  where id = v_order.driver_id;
  return v_order;
end;
$function$;

create function public.confirm_delivery_pickup(p_order_id uuid)
returns public.orders
language plpgsql security definer set search_path = ''
as $function$
declare
  v_order public.orders;
begin
  select * into v_order from private.lock_driver_order(
    p_order_id, 'DELIVERY', 'DRIVER_ON_WAY'::public.order_status
  );
  perform private.assert_driver_geofence(v_order.driver_id, v_order, 'PICKUP');
  update public.orders set
    status = 'DRIVER_ARRIVED'::public.order_status,
    driver_arrived_at = coalesce(driver_arrived_at, clock_timestamp()),
    updated_at = clock_timestamp()
  where id = v_order.id returning * into v_order;
  update public.orders set
    status = 'IN_PROGRESS'::public.order_status,
    started_at = coalesce(started_at, clock_timestamp()),
    updated_at = clock_timestamp()
  where id = v_order.id returning * into v_order;
  return v_order;
end;
$function$;

create function public.complete_delivery_with_code(
  p_order_id uuid,
  p_confirmation_code text
)
returns table (
  outcome text,
  order_status public.order_status,
  attempts_remaining integer,
  locked_until timestamptz
)
language plpgsql security definer set search_path = ''
as $function$
declare
  v_order public.orders;
  v_secret private.delivery_confirmation_secrets;
  v_failed integer;
  v_locked_until timestamptz;
begin
  select * into v_order from private.lock_driver_order(
    p_order_id, 'DELIVERY', 'IN_PROGRESS'::public.order_status
  );
  perform private.assert_driver_geofence(v_order.driver_id, v_order, 'DESTINATION');
  select * into v_secret from private.delivery_confirmation_secrets
  where order_id = v_order.id for update;
  if not found or v_secret.consumed_at is not null then
    raise exception 'Delivery Confirmation Code unavailable' using errcode = 'P0001';
  end if;
  if v_secret.locked_until is not null and v_secret.locked_until > clock_timestamp() then
    return query select 'LOCKED', v_order.status, 0, v_secret.locked_until;
    return;
  end if;
  if v_secret.locked_until is not null then
    update private.delivery_confirmation_secrets
    set failed_attempts = 0, locked_until = null
    where order_id = v_order.id;
    v_secret.failed_attempts := 0;
  end if;
  if p_confirmation_code is null
     or p_confirmation_code !~ '^[0-9]{4}$'
     or extensions.crypt(p_confirmation_code, v_secret.code_hash) <> v_secret.code_hash then
    v_failed := v_secret.failed_attempts + 1;
    if v_failed >= 5 then
      v_locked_until := clock_timestamp() + interval '15 minutes';
      update private.delivery_confirmation_secrets
      set failed_attempts = 0, locked_until = v_locked_until
      where order_id = v_order.id;
      return query select 'LOCKED', v_order.status, 0, v_locked_until;
    else
      update private.delivery_confirmation_secrets
      set failed_attempts = v_failed
      where order_id = v_order.id;
      return query select 'INVALID_CODE', v_order.status, 5 - v_failed, null::timestamptz;
    end if;
    return;
  end if;

  update private.delivery_confirmation_secrets
  set consumed_at = clock_timestamp(), failed_attempts = 0, locked_until = null
  where order_id = v_order.id;
  update public.orders set
    status = 'COMPLETED'::public.order_status,
    completed_at = coalesce(completed_at, clock_timestamp()),
    updated_at = clock_timestamp()
  where id = v_order.id returning * into v_order;
  update public.drivers set
    completed_trip_count = completed_trip_count + 1,
    updated_at = clock_timestamp()
  where id = v_order.driver_id;
  return query select 'COMPLETED', v_order.status, null::integer, null::timestamptz;
end;
$function$;

drop function public.get_customer_assigned_driver(uuid);
create function public.get_customer_assigned_driver(p_order_id uuid)
returns table (
  driver_public_id uuid,
  driver_first_name text,
  driver_photo_url text,
  driver_type public.driver_type,
  office_display_name text,
  completed_trip_count integer,
  driver_verified boolean,
  motorcycle_brand text,
  motorcycle_model text,
  motorcycle_plate_number text
)
language sql stable security definer set search_path = ''
as $function$
  select
    driver.id,
    split_part(btrim(profile.full_name), ' ', 1),
    profile.profile_photo_url,
    driver.driver_type,
    office.name,
    driver.completed_trip_count,
    driver.status = 'ACTIVE'::public.driver_status
      and motorcycle.verification_status = 'APPROVED'::public.document_status,
    motorcycle.brand,
    motorcycle.model,
    motorcycle.plate_number
  from public.orders customer_order
  join public.drivers driver on driver.id = customer_order.driver_id
  join public.profiles profile on profile.id = driver.user_id
  join public.motorcycles motorcycle on motorcycle.id = customer_order.motorcycle_id
  left join public.offices office on office.id = customer_order.office_id
  where customer_order.id = p_order_id
    and customer_order.customer_id = (select auth.uid())
    and customer_order.status in (
      'DRIVER_ASSIGNED'::public.order_status,
      'DRIVER_ON_WAY'::public.order_status,
      'DRIVER_ARRIVED'::public.order_status,
      'IN_PROGRESS'::public.order_status,
      'COMPLETED'::public.order_status,
      'CANCELLED'::public.order_status
    )
  limit 1;
$function$;

create function public.admin_safety_override(
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
  if not private.is_super_admin() then raise exception 'Privileged safety override required' using errcode = '42501'; end if;
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

create function public.enqueue_driver_document_expiry_notifications()
returns integer
language plpgsql security definer set search_path = ''
as $function$
declare
  v_record record;
  v_count integer := 0;
begin
  update public.driver_documents
  set status = 'EXPIRED'::public.document_status, updated_at = clock_timestamp()
  where is_current and status = 'APPROVED'::public.document_status
    and expiry_date is not null and expiry_date <= current_date;
  update public.motorcycle_documents
  set status = 'EXPIRED'::public.document_status, updated_at = clock_timestamp()
  where is_current and status = 'APPROVED'::public.document_status
    and expiry_date is not null and expiry_date <= current_date;
  update public.motorcycles m
  set verification_status = 'EXPIRED'::public.document_status, updated_at = clock_timestamp()
  where exists (
    select 1 from public.motorcycle_documents md
    where md.motorcycle_id = m.id and md.is_current
      and md.status = 'EXPIRED'::public.document_status
  );
  for v_record in
    select dd.id, d.id as driver_id, d.user_id,
      (dd.expiry_date - current_date)::integer as days_remaining,
      dd.document_type
    from public.driver_documents dd
    join public.drivers d on d.id = dd.driver_id
    where dd.is_current and dd.expiry_date is not null
      and (dd.expiry_date - current_date) in (30, 7, 1, 0)
    union all
    select md.id, d.id, d.user_id,
      (md.expiry_date - current_date)::integer,
      md.document_type
    from public.motorcycle_documents md
    join public.motorcycles m on m.id = md.motorcycle_id
    join public.drivers d on d.id = m.driver_id
    where md.is_current and md.expiry_date is not null
      and (md.expiry_date - current_date) in (30, 7, 1, 0)
    limit 500
  loop
    perform private.enqueue_notification(
      'driver-document:' || v_record.id || ':expiry:' || v_record.days_remaining,
      case when v_record.days_remaining = 0 then 'DOCUMENT_EXPIRED' else 'DOCUMENT_EXPIRING' end,
      'USER', v_record.user_id, 'DRIVER', 'PROFILE', null, null,
      case when v_record.days_remaining = 0 then 'انتهت صلاحية مستند' else 'مستند يقترب من الانتهاء' end,
      case when v_record.days_remaining = 0
        then 'حدّث المستند لاستقبال طلبات جديدة.'
        else 'راجع مستنداتك قبل موعد الانتهاء.' end
    );
    perform private.reconcile_driver_idle_availability(v_record.driver_id);
    v_count := v_count + 1;
  end loop;
  return v_count;
end;
$function$;

revoke all on function private.driver_safety_ineligibility(uuid),
  private.reconcile_driver_idle_availability(uuid),
  private.ensure_fresh_location_before_online(),
  private.driver_is_geographically_eligible(uuid,uuid),
  private.assign_verified_motorcycle(), private.prepare_delivery_confirmation(),
  private.lock_driver_order(uuid,text,public.order_status),
  private.assert_driver_geofence(uuid,public.orders,text),
  public.set_driver_online(boolean),
  public.confirm_ride_safety_equipment(),
  public.submit_driver_document(text,text,date,date),
  public.submit_motorcycle_document(uuid,text,text,date,date),
  public.get_driver_verification_overview(),
  public.review_driver_document(uuid,public.document_status,text),
  public.review_motorcycle_document(uuid,public.document_status,text),
  public.review_motorcycle(uuid,public.document_status,text),
  public.review_driver_verification(uuid,public.driver_status,date,text),
  public.driver_arrived(uuid), public.start_order(uuid), public.complete_order(uuid),
  public.confirm_delivery_pickup(uuid),
  public.complete_delivery_with_code(uuid,text),
  public.get_delivery_confirmation_code(uuid),
  public.get_customer_assigned_driver(uuid),
  public.admin_safety_override(uuid,text,text),
  public.enqueue_driver_document_expiry_notifications()
from public, anon, authenticated;

grant execute on function public.set_driver_online(boolean),
  public.confirm_ride_safety_equipment(),
  public.submit_driver_document(text,text,date,date),
  public.submit_motorcycle_document(uuid,text,text,date,date),
  public.get_driver_verification_overview(),
  public.review_driver_document(uuid,public.document_status,text),
  public.review_motorcycle_document(uuid,public.document_status,text),
  public.review_motorcycle(uuid,public.document_status,text),
  public.review_driver_verification(uuid,public.driver_status,date,text),
  public.driver_arrived(uuid), public.start_order(uuid), public.complete_order(uuid),
  public.confirm_delivery_pickup(uuid),
  public.complete_delivery_with_code(uuid,text),
  public.get_delivery_confirmation_code(uuid),
  public.get_customer_assigned_driver(uuid),
  public.admin_safety_override(uuid,text,text)
to authenticated;

grant execute on function public.enqueue_driver_document_expiry_notifications()
to service_role;
