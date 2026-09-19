-- D06: flag a Driver after three post-assignment cancellations in seven days.
-- The flag row is also the immutable audit record; no generic case system is needed.
-- One row per Driver intentionally persists until a later trusted operations-resolution flow.

create table public.driver_cancellation_review_flags (
  id uuid primary key default gen_random_uuid(),
  driver_id uuid not null references public.drivers(id),
  trigger_order_id uuid not null references public.orders(id),
  cancellation_count integer not null check (cancellation_count >= 3),
  window_started_at timestamptz not null,
  actor_user_id uuid not null references public.profiles(id),
  reason text not null default 'Three post-assignment Driver cancellations in a rolling 7-day window'
    check (length(btrim(reason)) between 1 and 500),
  created_at timestamptz not null default clock_timestamp(),
  constraint driver_cancellation_review_flags_driver_uq unique (driver_id)
);

create index driver_cancellation_review_flags_created_idx
  on public.driver_cancellation_review_flags (created_at desc);

create index orders_driver_cancellation_review_window_idx
  on public.orders (driver_id, cancelled_at desc)
  where status = 'CANCELLED'::public.order_status
    and cancellation_type = 'DRIVER_CANCEL';

alter table public.driver_cancellation_review_flags enable row level security;
revoke all privileges on table public.driver_cancellation_review_flags from public, anon, authenticated;
grant select on table public.driver_cancellation_review_flags to service_role;

create function private.apply_driver_cancellation_review_flag()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_now timestamptz := clock_timestamp();
  v_actor_user_id uuid;
  v_count integer;
  v_window_started_at timestamptz;
begin
  if tg_op <> 'UPDATE'
     or old.status is not distinct from new.status
     or new.status <> 'CANCELLED'::public.order_status
     or new.cancellation_type is distinct from 'DRIVER_CANCEL'
     or new.driver_id is null then
    return new;
  end if;

  -- Serialize cancellations for this Driver, including cancellations of different orders.
  perform 1
  from public.drivers d
  where d.id = new.driver_id
  for update;

  if not found then
    return new;
  end if;

  v_actor_user_id := coalesce((select auth.uid()), new.cancelled_by);

  select count(*)::integer, min(o.cancelled_at)
  into v_count, v_window_started_at
  from public.orders o
  where o.driver_id = new.driver_id
    and o.status = 'CANCELLED'::public.order_status
    and o.cancellation_type = 'DRIVER_CANCEL'
    and o.cancelled_at >= v_now - interval '7 days';

  if v_count < 3 then
    return new;
  end if;

  if v_actor_user_id is null then
    raise exception 'Authenticated cancellation actor required' using errcode = '42501';
  end if;

  insert into public.driver_cancellation_review_flags (
    driver_id,
    trigger_order_id,
    cancellation_count,
    window_started_at,
    actor_user_id
  ) values (
    new.driver_id,
    new.id,
    v_count,
    v_window_started_at,
    v_actor_user_id
  ) on conflict (driver_id) do nothing;

  return new;
end;
$function$;

create trigger orders_apply_driver_cancellation_review_flag
after update of status on public.orders
for each row execute function private.apply_driver_cancellation_review_flag();

revoke all on function private.apply_driver_cancellation_review_flag() from public, anon, authenticated;
