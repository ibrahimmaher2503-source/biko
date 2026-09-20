-- ADM-10 follow-up: auth.users.email and role/profile labels are varchar in
-- the hosted catalog, while the RPC contract intentionally returns text.

create or replace function public.admin_list_office_staff(
  p_office_id uuid,
  p_search text default null,
  p_status public.account_status default null,
  p_limit integer default 50,
  p_offset integer default 0
)
returns table (
  membership_id uuid,
  user_id uuid,
  full_name text,
  email text,
  phone text,
  profile_status public.account_status,
  membership_status public.account_status,
  role_id uuid,
  role_code text,
  role_name text,
  role_scope_type text,
  created_at timestamptz,
  updated_at timestamptz,
  total_count bigint
)
language plpgsql
stable
security definer
set search_path = ''
as $function$
begin
  if p_office_id is null then
    raise exception 'Office is required' using errcode = '22023';
  end if;
  if p_limit is null or p_limit < 1 or p_limit > 100
     or p_offset is null or p_offset < 0 then
    raise exception 'Invalid staff pagination' using errcode = '22023';
  end if;
  if p_search is not null and length(btrim(p_search)) > 120 then
    raise exception 'Staff search is too long' using errcode = '22023';
  end if;
  if not private.can_access_office(p_office_id, 'office_members.manage') then
    raise exception 'Office staff-management access required' using errcode = '42501';
  end if;

  return query
  select om.id, p.id, p.full_name::text, au.email::text, p.phone::text,
    p.status, om.status, r.id, r.code::text, r.name::text,
    r.scope_type::text, om.created_at, om.updated_at, count(*) over ()::bigint
  from public.office_members om
  join public.profiles p on p.id = om.user_id
  join public.roles r on r.id = om.role_id
  join auth.users au on au.id = om.user_id
  where om.office_id = p_office_id
    and p.profile_type = 'STAFF'::public.profile_type
    and (p_status is null or om.status = p_status)
    and (
      nullif(btrim(p_search), '') is null
      or p.full_name ilike '%' || btrim(p_search) || '%'
      or coalesce(au.email, '') ilike '%' || btrim(p_search) || '%'
      or coalesce(p.phone, '') ilike '%' || btrim(p_search) || '%'
      or r.code ilike '%' || btrim(p_search) || '%'
    )
  order by p.full_name, p.id
  limit p_limit offset p_offset;
end;
$function$;

create or replace function public.admin_get_office_staff(
  p_office_id uuid,
  p_user_id uuid
)
returns table (
  membership_id uuid,
  user_id uuid,
  full_name text,
  email text,
  phone text,
  profile_status public.account_status,
  membership_status public.account_status,
  role_id uuid,
  role_code text,
  role_name text,
  role_scope_type text,
  created_at timestamptz,
  updated_at timestamptz,
  total_count bigint
)
language plpgsql
stable
security definer
set search_path = ''
as $function$
begin
  if p_office_id is null or p_user_id is null then
    raise exception 'Office and staff user are required' using errcode = '22023';
  end if;
  if not private.can_access_office(p_office_id, 'office_members.manage') then
    raise exception 'Office staff-management access required' using errcode = '42501';
  end if;

  return query
  select om.id, p.id, p.full_name::text, au.email::text, p.phone::text,
    p.status, om.status, r.id, r.code::text, r.name::text,
    r.scope_type::text, om.created_at, om.updated_at, 1::bigint
  from public.office_members om
  join public.profiles p on p.id = om.user_id
  join public.roles r on r.id = om.role_id
  join auth.users au on au.id = om.user_id
  where om.office_id = p_office_id
    and om.user_id = p_user_id
    and p.profile_type = 'STAFF'::public.profile_type;

  if not found then
    raise exception 'Office staff member not found' using errcode = 'P0002';
  end if;
end;
$function$;
