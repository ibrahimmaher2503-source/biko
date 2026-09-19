-- User profile editing security contract. Fixtures roll back.
begin;

do $test$
declare
  customer_a uuid := '8a400000-0000-0000-0000-000000000001';
  customer_b uuid := '8a400000-0000-0000-0000-000000000002';
  photo_a text := '8a400000-0000-0000-0000-000000000001/avatar.jpg';
begin
  insert into auth.users(id, email, raw_user_meta_data) values
    (customer_a, 'profile-a@example.invalid', '{}'),
    (customer_b, 'profile-b@example.invalid', '{}');
  insert into storage.objects(bucket_id, name, owner_id, metadata)
  values ('profile-photos', photo_a, customer_a::text, '{"mimetype":"image/jpeg"}'::jsonb);

  perform set_config('request.jwt.claim.sub', customer_a::text, true);
  set local role authenticated;
  assert public.update_own_profile('عميل بيكو', '+20 100 123 4567', photo_a) = photo_a,
    'Owner can edit only their active CUSTOMER profile';
  assert (select full_name = 'عميل بيكو' and phone = '+20 100 123 4567'
    and profile_photo_url = photo_a from public.profiles where id = customer_a),
    'Whitelisted fields persist';
  begin
    perform public.update_own_profile('عميل بيكو', '++++++', photo_a);
    raise exception 'Phone without digits unexpectedly succeeded';
  exception when sqlstate '22023' then null;
  end;
  begin
    update public.profiles set status = 'SUSPENDED' where id = customer_a;
    raise exception 'Direct privileged profile update unexpectedly succeeded';
  exception when insufficient_privilege then null;
  end;
  reset role;

  update public.profiles
  set profile_photo_url = 'https://legacy.example.invalid/profile.jpg'
  where id = customer_a;
  perform set_config('request.jwt.claim.sub', customer_a::text, true);
  set local role authenticated;
  assert public.update_own_profile('اسم محدث', null, 'https://legacy.example.invalid/profile.jpg')
    = 'https://legacy.example.invalid/profile.jpg',
    'Existing legacy photo remains untouched during name-only edits';
  reset role;

  perform set_config('request.jwt.claim.sub', customer_b::text, true);
  set local role authenticated;
  begin
    perform public.update_own_profile('عميل آخر', null, photo_a);
    raise exception 'Foreign photo path unexpectedly succeeded';
  exception when insufficient_privilege then null;
  end;
  reset role;

  assert not has_table_privilege('authenticated', 'public.profiles', 'update'),
    'Clients cannot bypass the whitelist with direct profile UPDATE';
  assert (select not public and file_size_limit = 2097152
    and allowed_mime_types = array['image/jpeg', 'image/png', 'image/webp']::text[]
    from storage.buckets where id = 'profile-photos'),
    'Profile photo bucket remains private and MIME/size bounded';
  assert has_function_privilege('authenticated', 'public.update_own_profile(text, text, text)', 'execute'),
    'Authenticated customer can use the narrow public RPC';
  assert not has_function_privilege('anon', 'public.update_own_profile(text, text, text)', 'execute'),
    'Anonymous callers cannot edit profiles';
end;
$test$;

rollback;
