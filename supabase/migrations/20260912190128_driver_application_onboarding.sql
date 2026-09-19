-- Packet A: an authenticated user may submit an Independent Driver application.
-- Public Auth signup remains CUSTOMER; this creates only a PENDING identity.

create or replace function public.submit_independent_driver_application(
  p_full_name text,
  p_phone text,
  p_date_of_birth date,
  p_plate_number text,
  p_brand text,
  p_model text,
  p_color text,
  p_model_year integer
)
returns table (
  driver_id uuid,
  motorcycle_id uuid,
  driver_status public.driver_status,
  motorcycle_verification_status public.document_status
)
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_uid uuid := (select auth.uid());
  v_name text := nullif(btrim(p_full_name), '');
  v_phone text := nullif(btrim(p_phone), '');
  v_plate text := nullif(btrim(p_plate_number), '');
  v_brand text := nullif(btrim(p_brand), '');
  v_model text := nullif(btrim(p_model), '');
  v_color text := nullif(btrim(p_color), '');
  v_driver public.drivers;
  v_motorcycle public.motorcycles;
begin
  if v_uid is null then
    raise exception 'Authentication is required' using errcode = '42501';
  end if;

  if v_name is null or char_length(v_name) > 100 then
    raise exception 'Name must be between 1 and 100 characters' using errcode = '22023';
  end if;
  if v_phone is not null and (v_phone !~ '^[+]?[0-9][0-9 ()-]*$'
     or char_length(regexp_replace(v_phone, '[^0-9]', '', 'g')) < 6
     or char_length(regexp_replace(v_phone, '[^0-9]', '', 'g')) > 32) then
    raise exception 'Phone must contain 6 to 32 phone characters' using errcode = '22023';
  end if;
  if p_date_of_birth is null
     or p_date_of_birth > (current_date - interval '21 years')::date then
    raise exception 'Driver must be at least 21' using errcode = '22023';
  end if;
  if v_plate is null or char_length(v_plate) > 32 then
    raise exception 'Plate number must be between 1 and 32 characters' using errcode = '22023';
  end if;
  if v_brand is null or char_length(v_brand) > 60 then
    raise exception 'Motorcycle brand must be between 1 and 60 characters' using errcode = '22023';
  end if;
  if v_model is null or char_length(v_model) > 60 then
    raise exception 'Motorcycle model must be between 1 and 60 characters' using errcode = '22023';
  end if;
  if v_color is null or char_length(v_color) > 40 then
    raise exception 'Motorcycle color must be between 1 and 40 characters' using errcode = '22023';
  end if;
  if p_model_year is not null and (p_model_year < 1950 or p_model_year > 2100) then
    raise exception 'Motorcycle model year is invalid' using errcode = '22023';
  end if;

  -- Auth signup starts as CUSTOMER; this validated application is the trusted
  -- transition to the separate DRIVER identity. STAFF can never apply here.
  if not exists (
    select 1
    from public.profiles p
    where p.id = v_uid
      and p.status = 'ACTIVE'::public.account_status
      and p.profile_type in ('CUSTOMER'::public.profile_type, 'DRIVER'::public.profile_type)
  ) then
    raise exception 'Profile is unavailable' using errcode = 'P0002';
  end if;

  update public.profiles
  set full_name = v_name,
      phone = v_phone,
      profile_type = 'DRIVER'::public.profile_type,
      updated_at = clock_timestamp()
  where id = v_uid;

  -- The unique user_id constraint serializes first application and retries.
  insert into public.drivers (
    user_id, driver_type, office_id, status, date_of_birth, is_online
  ) values (
    v_uid, 'INDEPENDENT'::public.driver_type, null, 'PENDING'::public.driver_status,
    p_date_of_birth, false
  )
  on conflict (user_id) do update
    set date_of_birth = excluded.date_of_birth,
        updated_at = clock_timestamp()
  returning * into v_driver;

  if v_driver.driver_type <> 'INDEPENDENT'::public.driver_type
     or v_driver.office_id is not null then
    raise exception 'Independent Driver application is not available for this account'
      using errcode = 'P0001';
  end if;
  if v_driver.status <> 'PENDING'::public.driver_status then
    raise exception 'Driver application cannot be changed in its current status'
      using errcode = 'P0001';
  end if;

  -- Reuse the existing pending motorcycle on retries; the driver-row lock
  -- prevents two concurrent calls from creating two pending motorcycles.
  select m.* into v_motorcycle
  from public.motorcycles m
  where m.driver_id = v_driver.id
    and m.verification_status = 'PENDING'::public.document_status
  order by m.updated_at desc, m.id
  limit 1
  for update;

  if not found then
    insert into public.motorcycles (
      driver_id, office_id, plate_number, brand, model, color, model_year,
      status, verification_status
    ) values (
      v_driver.id, null, v_plate, v_brand, v_model, v_color, p_model_year,
      'INACTIVE'::public.motorcycle_status, 'PENDING'::public.document_status
    ) returning * into v_motorcycle;
  else
    if exists (
      select 1 from public.motorcycle_documents md
      where md.motorcycle_id = v_motorcycle.id and md.is_current
    ) and (
      v_motorcycle.plate_number is distinct from v_plate
      or v_motorcycle.brand is distinct from v_brand
      or v_motorcycle.model is distinct from v_model
      or v_motorcycle.color is distinct from v_color
      or v_motorcycle.model_year is distinct from p_model_year
    ) then
      raise exception 'Motorcycle details cannot change after documents are uploaded'
        using errcode = 'P0001';
    end if;

    update public.motorcycles
    set office_id = null,
        plate_number = v_plate,
        brand = v_brand,
        model = v_model,
        color = v_color,
        model_year = p_model_year,
        status = 'INACTIVE'::public.motorcycle_status,
        verification_status = 'PENDING'::public.document_status,
        verification_rejection_reason = null,
        verified_by = null,
        verified_at = null,
        updated_at = clock_timestamp()
    where id = v_motorcycle.id
    returning * into v_motorcycle;
  end if;

  return query
  select v_driver.id, v_motorcycle.id, v_driver.status, v_motorcycle.verification_status;
end;
$function$;

revoke all on function public.submit_independent_driver_application(
  text, text, date, text, text, text, text, integer
) from public, anon, authenticated;
grant execute on function public.submit_independent_driver_application(
  text, text, date, text, text, text, text, integer
) to authenticated;

-- Serialize document registration with pending motorcycle identity edits.
create or replace function public.submit_motorcycle_document(
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
  from public.drivers d
  where d.user_id = v_uid
  for update;
  if v_driver_id is null then raise exception 'Owned motorcycle required' using errcode = '42501'; end if;
  perform 1 from public.motorcycles m
  where m.driver_id = v_driver_id and m.id = p_motorcycle_id
  for update;
  if not found then raise exception 'Owned motorcycle required' using errcode = '42501'; end if;
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
