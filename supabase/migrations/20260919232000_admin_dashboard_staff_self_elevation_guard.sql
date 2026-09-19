-- ADM-08 hardening: changing a role assigned to the actor is self-elevation,
-- regardless of whether the change came through the trusted RPC or table DML.
create or replace function private.prevent_self_role_permission_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_role_id uuid := coalesce(new.role_id, old.role_id);
begin
  if (select auth.uid()) is not null and (
    exists (
      select 1 from public.user_roles ur
      where ur.user_id = (select auth.uid()) and ur.role_id = v_role_id
    )
    or exists (
      select 1 from public.office_members om
      where om.user_id = (select auth.uid())
        and om.role_id = v_role_id
        and om.status = 'ACTIVE'::public.account_status
    )
  ) then
    raise exception 'Self role permission changes are not allowed' using errcode = '42501';
  end if;
  if tg_op = 'DELETE' then return old; end if;
  return new;
end;
$function$;

drop trigger if exists role_permissions_prevent_self_change on public.role_permissions;
create trigger role_permissions_prevent_self_change
before insert or update or delete on public.role_permissions
for each row execute function private.prevent_self_role_permission_change();

revoke all on function private.prevent_self_role_permission_change()
from public, anon, authenticated;
