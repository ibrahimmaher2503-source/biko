-- Customer self-service profile fields only. Identity and privileges stay server-owned.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'profile-photos', 'profile-photos', false, 2097152,
  array['image/jpeg', 'image/png', 'image/webp']::text[]
)
on conflict (id) do update set
  public = false,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create policy profile_photos_select_own
on storage.objects for select to authenticated
using (
  bucket_id = 'profile-photos'
  and owner_id = (select auth.uid())::text
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

create policy profile_photos_insert_own
on storage.objects for insert to authenticated
with check (
  bucket_id = 'profile-photos'
  and owner_id = (select auth.uid())::text
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

create policy profile_photos_delete_own
on storage.objects for delete to authenticated
using (
  bucket_id = 'profile-photos'
  and owner_id = (select auth.uid())::text
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

revoke update on public.profiles from anon, authenticated;

create or replace function private.update_own_profile(
  p_full_name text,
  p_phone text default null,
  p_photo_path text default null
)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := (select auth.uid());
  v_name text := nullif(btrim(p_full_name), '');
  v_phone text := nullif(btrim(p_phone), '');
  v_existing_photo_path text;
begin
  if v_user_id is null then
    raise exception 'Authentication is required' using errcode = '42501';
  end if;
  if v_name is null or char_length(v_name) > 100 then
    raise exception 'Name must be between 1 and 100 characters' using errcode = '22023';
  end if;
  if v_phone is not null and (
    v_phone !~ '^[+]?[0-9][0-9 ()-]*$'
    or char_length(regexp_replace(v_phone, '[^0-9]', '', 'g')) < 6
  ) then
    raise exception 'Phone must contain 6 to 32 phone characters' using errcode = '22023';
  end if;
  select profile_photo_url into v_existing_photo_path
  from public.profiles
  where id = v_user_id
    and profile_type = 'CUSTOMER'::public.profile_type
    and status = 'ACTIVE'::public.account_status;
  if not found then
    raise exception 'Profile is unavailable' using errcode = 'P0002';
  end if;
  if p_photo_path is not null
    and p_photo_path !~ ('^' || v_user_id::text || '/[^/]+[.](jpg|jpeg|png|webp)$')
    and p_photo_path is distinct from v_existing_photo_path then
    raise exception 'Photo path must belong to the current user' using errcode = '42501';
  end if;
  if p_photo_path is not null
    and p_photo_path is distinct from v_existing_photo_path
    and not exists (
    select 1 from storage.objects
    where bucket_id = 'profile-photos'
      and name = p_photo_path
      and owner_id = v_user_id::text
  ) then
    raise exception 'Photo object is unavailable' using errcode = '42501';
  end if;

  update public.profiles
  set full_name = v_name,
      phone = v_phone,
      profile_photo_url = p_photo_path
  where id = v_user_id
    and profile_type = 'CUSTOMER'::public.profile_type
    and status = 'ACTIVE'::public.account_status
  returning profile_photo_url into p_photo_path;

  return p_photo_path;
end;
$$;

revoke all on function private.update_own_profile(text, text, text) from public, anon, authenticated;
grant execute on function private.update_own_profile(text, text, text) to authenticated;

create or replace function public.update_own_profile(
  p_full_name text,
  p_phone text default null,
  p_photo_path text default null
)
returns text
language sql
security invoker
set search_path = ''
as $$
  select private.update_own_profile(p_full_name, p_phone, p_photo_path);
$$;

revoke all on function public.update_own_profile(text, text, text) from public, anon, authenticated;
grant execute on function public.update_own_profile(text, text, text) to authenticated;
