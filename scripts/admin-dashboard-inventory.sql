-- ADM-01: read-only Development catalog snapshot. No user data or credentials.
begin;
set transaction read only;
set local statement_timeout = '20s';
select jsonb_build_object(
  'captured_at', clock_timestamp(),
  'tables', (select jsonb_agg(jsonb_build_object(
    'name', c.relname, 'rls', c.relrowsecurity, 'force_rls', c.relforcerowsecurity,
    'authenticated_select', has_table_privilege('authenticated', c.oid, 'SELECT'),
    'authenticated_insert', has_table_privilege('authenticated', c.oid, 'INSERT'),
    'authenticated_update', has_table_privilege('authenticated', c.oid, 'UPDATE'),
    'authenticated_delete', has_table_privilege('authenticated', c.oid, 'DELETE'),
    'columns', (select jsonb_agg(jsonb_build_object('name', a.attname, 'type', format_type(a.atttypid,a.atttypmod), 'not_null', a.attnotnull) order by a.attnum)
      from pg_attribute a where a.attrelid=c.oid and a.attnum>0 and not a.attisdropped)
    ) order by c.relname)
    from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='public' and c.relkind in ('r','p')),
  'policies', (select jsonb_agg(to_jsonb(p) order by p.schemaname,p.tablename,p.policyname)
    from pg_policies p where p.schemaname='public'
      or (p.schemaname='storage' and p.tablename='objects')),
  'functions', (select jsonb_agg(jsonb_build_object(
    'schema', n.nspname, 'name', p.proname,
    'arguments', pg_get_function_identity_arguments(p.oid),
    'result', pg_get_function_result(p.oid),
    'security_definer', p.prosecdef, 'config', p.proconfig,
    'authenticated_execute', has_function_privilege('authenticated',p.oid,'EXECUTE'),
    'anon_execute', has_function_privilege('anon',p.oid,'EXECUTE'),
    'definition_md5', md5(pg_get_functiondef(p.oid))
    ) order by n.nspname,p.proname,p.oid)
    from pg_proc p join pg_namespace n on n.oid=p.pronamespace
    where n.nspname in ('public','private') and p.prokind='f'
      and not exists (select 1 from pg_depend d where d.classid='pg_proc'::regclass and d.objid=p.oid and d.deptype='e')),
  'roles', (select jsonb_agg(jsonb_build_object('code',r.code,'scope_type',r.scope_type,
    'permissions',(select jsonb_agg(p.code order by p.code)
      from public.role_permissions rp join public.permissions p on p.id=rp.permission_id where rp.role_id=r.id))
    order by r.code) from public.roles r),
  'critical_definitions', (select jsonb_object_agg(n.nspname||'.'||p.proname,pg_get_functiondef(p.oid))
    from pg_proc p join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='private' and p.proname in ('is_super_admin','has_permission','is_office_member','can_access_office'))
) as inventory;
commit;
