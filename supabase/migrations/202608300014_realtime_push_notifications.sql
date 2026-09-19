-- Milestone 9: stable waiting-offer paging, scoped Realtime signals, and durable Push intent.

create table public.user_push_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  token text not null,
  platform text not null check (platform in ('ANDROID', 'IOS')),
  app_kind text not null check (app_kind in ('USER', 'DRIVER')),
  enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now(),
  unique (token, app_kind),
  check (length(token) between 20 and 4096)
);

create index user_push_tokens_user_enabled_idx
  on public.user_push_tokens (user_id, app_kind)
  where enabled;

create table public.notification_outbox (
  id uuid primary key default gen_random_uuid(),
  event_key text not null unique,
  event_type text not null,
  audience text not null check (audience in ('USER', 'ELIGIBLE_DRIVERS')),
  target_user_id uuid references public.profiles(id) on delete cascade,
  target_app_kind text not null check (target_app_kind in ('USER', 'DRIVER')),
  target_type text not null check (target_type in ('ORDER', 'ACTIVE_ORDER', 'WAITING_OFFER', 'REQUESTS')),
  order_id uuid references public.orders(id) on delete cascade,
  offer_id uuid references public.offers(id) on delete cascade,
  title text not null check (length(title) between 1 and 80),
  body text not null check (length(body) between 1 and 240),
  status text not null default 'PENDING' check (status in ('PENDING', 'SENDING', 'SENT', 'FAILED')),
  attempt_count integer not null default 0 check (attempt_count between 0 and 5),
  next_attempt_at timestamptz not null default now(),
  last_attempt_at timestamptz,
  sent_at timestamptz,
  last_error_code text check (last_error_code is null or length(last_error_code) <= 80),
  created_at timestamptz not null default now(),
  check (
    (audience = 'USER' and target_user_id is not null)
    or (
      audience = 'ELIGIBLE_DRIVERS'
      and target_user_id is null
      and target_app_kind = 'DRIVER'
      and order_id is not null
    )
  )
);

create index notification_outbox_dispatch_idx
  on public.notification_outbox (status, next_attempt_at, created_at)
  where status in ('PENDING', 'FAILED', 'SENDING');

create index notification_outbox_user_created_idx
  on public.notification_outbox (target_user_id, created_at desc)
  where target_user_id is not null;

create table public.driver_work_signals (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (order_id)
);

alter table public.user_push_tokens enable row level security;
alter table public.notification_outbox enable row level security;
alter table public.driver_work_signals enable row level security;

revoke all privileges on table public.user_push_tokens,
  public.notification_outbox, public.driver_work_signals
from anon, authenticated;

grant select on table public.notification_outbox, public.driver_work_signals
to authenticated;

create policy notification_outbox_select_own
on public.notification_outbox
for select
to authenticated
using (target_user_id = (select auth.uid()));

create function private.can_receive_driver_work_signal(p_order_id uuid)
returns boolean
language sql stable security definer set search_path = ''
as $function$
  select exists (
    select 1
    from public.drivers d
    where d.user_id = (select auth.uid())
      and private.driver_is_geographically_eligible(d.id, p_order_id)
  );
$function$;

create policy driver_work_signals_select_eligible
on public.driver_work_signals
for select
to authenticated
using (private.can_receive_driver_work_signal(driver_work_signals.order_id));

create function public.register_push_token(
  p_token text,
  p_platform text,
  p_app_kind text
)
returns uuid
language plpgsql security definer set search_path = ''
as $function$
declare
  v_uid uuid := (select auth.uid());
  v_id uuid;
  v_token text := btrim(coalesce(p_token, ''));
  v_platform text := upper(btrim(coalesce(p_platform, '')));
  v_app_kind text := upper(btrim(coalesce(p_app_kind, '')));
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  if length(v_token) not between 20 and 4096
     or v_platform not in ('ANDROID', 'IOS')
     or v_app_kind not in ('USER', 'DRIVER') then
    raise exception 'Invalid Push token registration' using errcode = '22023';
  end if;

  insert into public.user_push_tokens (
    user_id, token, platform, app_kind, enabled, updated_at, last_seen_at
  ) values (
    v_uid, v_token, v_platform, v_app_kind, true, clock_timestamp(), clock_timestamp()
  )
  on conflict (token, app_kind) do update
  set user_id = excluded.user_id,
      platform = excluded.platform,
      enabled = true,
      updated_at = clock_timestamp(),
      last_seen_at = clock_timestamp()
  returning id into v_id;

  return v_id;
end;
$function$;

create function public.revoke_push_token(p_token text, p_app_kind text)
returns boolean
language plpgsql security definer set search_path = ''
as $function$
declare
  v_uid uuid := (select auth.uid());
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  update public.user_push_tokens
  set enabled = false, updated_at = clock_timestamp()
  where user_id = v_uid
    and token = btrim(coalesce(p_token, ''))
    and app_kind = upper(btrim(coalesce(p_app_kind, '')));
  return found;
end;
$function$;

drop function public.get_driver_active_offers(integer);

create function public.get_driver_active_offers(
  p_cursor_created_at timestamptz default null,
  p_cursor_id uuid default null,
  p_limit integer default 50
)
returns table (
  id uuid,
  order_id uuid,
  offered_price numeric,
  status public.offer_status,
  pickup_address text,
  destination_address text,
  created_at timestamptz
)
language sql stable security definer set search_path = ''
as $function$
  select f.id, f.order_id, f.offered_price, f.status,
    o.pickup_address, o.destination_address, f.created_at
  from public.drivers d
  join public.offers f on f.driver_id = d.id
  join public.orders o on o.id = f.order_id
  where d.user_id = (select auth.uid())
    and f.status = 'ACTIVE'::public.offer_status
    and o.status = 'BIDDING'::public.order_status
    and o.bidding_expires_at > clock_timestamp()
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
    and (
      (p_cursor_created_at is null and p_cursor_id is null)
      or (
        p_cursor_created_at is not null
        and p_cursor_id is not null
        and (f.created_at, f.id) < (p_cursor_created_at, p_cursor_id)
      )
    )
  order by f.created_at desc, f.id desc
  limit least(greatest(coalesce(p_limit, 50), 1), 50);
$function$;

create function private.enqueue_notification(
  p_event_key text,
  p_event_type text,
  p_audience text,
  p_target_user_id uuid,
  p_target_app_kind text,
  p_target_type text,
  p_order_id uuid,
  p_offer_id uuid,
  p_title text,
  p_body text
)
returns uuid
language plpgsql security definer set search_path = ''
as $function$
declare
  v_id uuid;
begin
  insert into public.notification_outbox (
    event_key, event_type, audience, target_user_id, target_app_kind,
    target_type, order_id, offer_id, title, body
  ) values (
    p_event_key, p_event_type, p_audience, p_target_user_id, p_target_app_kind,
    p_target_type, p_order_id, p_offer_id, p_title, p_body
  )
  on conflict (event_key) do nothing
  returning id into v_id;

  if v_id is null then
    select n.id into v_id
    from public.notification_outbox n
    where n.event_key = p_event_key;
  end if;
  return v_id;
end;
$function$;

create function private.enqueue_offer_notification()
returns trigger
language plpgsql security definer set search_path = ''
as $function$
declare
  v_customer_id uuid;
  v_driver_user_id uuid;
begin
  if tg_op = 'INSERT' and new.status = 'ACTIVE'::public.offer_status then
    select o.customer_id into v_customer_id
    from public.orders o where o.id = new.order_id;
    if v_customer_id is distinct from (select auth.uid()) then
      perform private.enqueue_notification(
        'offer:' || new.id || ':created:' || v_customer_id,
        'NEW_OFFER', 'USER', v_customer_id, 'USER', 'ORDER',
        new.order_id, new.id, 'عرض جديد', 'وصل عرض جديد لطلبك.'
      );
    end if;
  elsif tg_op = 'UPDATE'
        and old.status is distinct from new.status
        and new.status in ('SELECTED'::public.offer_status, 'CLOSED'::public.offer_status) then
    select d.user_id into v_driver_user_id
    from public.drivers d where d.id = new.driver_id;
    if v_driver_user_id is distinct from (select auth.uid()) then
      perform private.enqueue_notification(
        'offer:' || new.id || ':' || lower(new.status::text) || ':' || v_driver_user_id,
        case when new.status = 'SELECTED'::public.offer_status then 'OFFER_SELECTED' else 'OFFER_CLOSED' end,
        'USER', v_driver_user_id, 'DRIVER',
        case when new.status = 'SELECTED'::public.offer_status then 'ACTIVE_ORDER' else 'WAITING_OFFER' end,
        new.order_id, new.id,
        case when new.status = 'SELECTED'::public.offer_status then 'تم اختيار عرضك' else 'تم إغلاق العرض' end,
        case when new.status = 'SELECTED'::public.offer_status
          then 'افتح التطبيق لمراجعة الرحلة النشطة.'
          else 'لم يعد عرضك متاحًا. افتح التطبيق لتحديث الحالة.' end
      );
    end if;
  end if;
  return new;
end;
$function$;

create trigger offers_enqueue_notification
after insert or update of status on public.offers
for each row execute function private.enqueue_offer_notification();

create function private.enqueue_order_event_notifications()
returns trigger
language plpgsql security definer set search_path = ''
as $function$
declare
  v_order public.orders;
  v_driver_user_id uuid;
  v_title text;
  v_body text;
begin
  if new.event_type = 'BIDDING' then return new; end if;
  select * into v_order from public.orders o where o.id = new.order_id;
  if v_order.driver_id is not null then
    select d.user_id into v_driver_user_id
    from public.drivers d where d.id = v_order.driver_id;
  end if;

  v_title := case new.event_type
    when 'DRIVER_ASSIGNED' then 'تم تأكيد الرحلة'
    when 'DRIVER_ON_WAY' then 'السائق في الطريق'
    when 'DRIVER_ARRIVED' then 'وصل السائق'
    when 'IN_PROGRESS' then 'بدأت الرحلة'
    when 'COMPLETED' then 'اكتمل الطلب'
    when 'CANCELLED' then 'تم إلغاء الطلب'
    when 'EXPIRED' then 'انتهت مهلة الطلب'
    else 'تحديث على الطلب'
  end;
  v_body := 'افتح التطبيق لعرض الحالة الحالية.';

  if new.event_type in (
      'DRIVER_ASSIGNED', 'DRIVER_ON_WAY', 'DRIVER_ARRIVED',
      'IN_PROGRESS', 'COMPLETED', 'CANCELLED', 'EXPIRED'
    ) and v_order.customer_id is distinct from new.actor_user_id then
    perform private.enqueue_notification(
      'order-event:' || new.id || ':customer:' || v_order.customer_id,
      new.event_type, 'USER', v_order.customer_id, 'USER', 'ORDER',
      new.order_id, v_order.selected_offer_id, v_title, v_body
    );
  end if;

  if v_driver_user_id is not null
     and new.event_type in ('DRIVER_ASSIGNED', 'CANCELLED', 'EXPIRED')
     and v_driver_user_id is distinct from new.actor_user_id then
    perform private.enqueue_notification(
      'order-event:' || new.id || ':driver:' || v_driver_user_id,
      new.event_type, 'USER', v_driver_user_id, 'DRIVER', 'ACTIVE_ORDER',
      new.order_id, v_order.selected_offer_id, v_title, v_body
    );
  end if;
  return new;
end;
$function$;

create trigger order_events_enqueue_notifications
after insert on public.order_events
for each row execute function private.enqueue_order_event_notifications();

create function private.signal_new_driver_work()
returns trigger
language plpgsql security definer set search_path = ''
as $function$
declare
  v_notification_id uuid;
begin
  if new.status = 'BIDDING'::public.order_status then
    v_notification_id := private.enqueue_notification(
      'order:' || new.id || ':new-work', 'NEW_WORK', 'ELIGIBLE_DRIVERS',
      null, 'DRIVER', 'REQUESTS', new.id, null,
      'طلب جديد قريب', 'قد يوجد طلب مناسب بالقرب منك.'
    );
    insert into public.driver_work_signals (id, order_id)
    values (v_notification_id, new.id) on conflict (order_id) do nothing;
  end if;
  return new;
end;
$function$;

create trigger orders_signal_new_driver_work
after insert on public.orders
for each row execute function private.signal_new_driver_work();

create function public.claim_notification_outbox(p_limit integer default 20)
returns table (
  id uuid,
  event_type text,
  target_app_kind text,
  target_type text,
  order_id uuid,
  offer_id uuid,
  title text,
  body text,
  attempt_count integer,
  tokens text[]
)
language sql volatile security definer set search_path = ''
as $function$
  with candidates as (
    select n.id
    from public.notification_outbox n
    where n.attempt_count < 5
      and (
        (n.status in ('PENDING', 'FAILED') and n.next_attempt_at <= clock_timestamp())
        or (n.status = 'SENDING' and n.last_attempt_at < clock_timestamp() - interval '10 minutes')
      )
    order by n.created_at, n.id
    for update skip locked
    limit least(greatest(coalesce(p_limit, 20), 1), 50)
  ), claimed as (
    update public.notification_outbox n
    set status = 'SENDING',
        attempt_count = n.attempt_count + 1,
        last_attempt_at = clock_timestamp(),
        last_error_code = null
    from candidates c
    where n.id = c.id
    returning n.*
  )
  select c.id, c.event_type, c.target_app_kind, c.target_type, c.order_id, c.offer_id,
    c.title, c.body, c.attempt_count, coalesce(targets.tokens, '{}'::text[])
  from claimed c
  left join lateral (
    select array_agg(token_rows.token) as tokens
    from (
      select distinct t.token
      from public.user_push_tokens t
      where t.enabled
        and t.app_kind = c.target_app_kind
        and (
          (c.audience = 'USER' and t.user_id = c.target_user_id)
          or (
            c.audience = 'ELIGIBLE_DRIVERS'
            and exists (
              select 1 from public.drivers d
              where d.user_id = t.user_id
                and private.driver_is_geographically_eligible(d.id, c.order_id)
            )
          )
        )
      -- ponytail: bounded MVP fanout; shard outbox audiences if one order can exceed 200 devices.
      limit 200
    ) token_rows
  ) targets on true;
$function$;

create function public.complete_notification_outbox(
  p_id uuid,
  p_success boolean,
  p_error_code text default null,
  p_retry_after_seconds integer default 30
)
returns boolean
language plpgsql security definer set search_path = ''
as $function$
begin
  update public.notification_outbox
  set status = case when p_success then 'SENT' else 'FAILED' end,
      sent_at = case when p_success then clock_timestamp() else null end,
      next_attempt_at = case when p_success then next_attempt_at else
        clock_timestamp() + make_interval(secs => least(greatest(coalesce(p_retry_after_seconds, 30), 5), 300)) end,
      last_error_code = case when p_success then null else left(coalesce(p_error_code, 'FCM_UNAVAILABLE'), 80) end
  where id = p_id and status = 'SENDING';
  return found;
end;
$function$;

create function public.disable_push_token(p_token text, p_app_kind text)
returns boolean
language plpgsql security definer set search_path = ''
as $function$
begin
  update public.user_push_tokens
  set enabled = false, updated_at = clock_timestamp()
  where token = p_token and app_kind = upper(btrim(coalesce(p_app_kind, '')));
  return found;
end;
$function$;

do $publication$
begin
  alter publication supabase_realtime add table public.notification_outbox;
exception when duplicate_object then null;
end;
$publication$;

do $publication$
begin
  alter publication supabase_realtime add table public.driver_work_signals;
exception when duplicate_object then null;
end;
$publication$;

revoke all on function public.register_push_token(text,text,text),
  public.revoke_push_token(text,text),
  public.get_driver_active_offers(timestamptz,uuid,integer),
  public.claim_notification_outbox(integer),
  public.complete_notification_outbox(uuid,boolean,text,integer),
  public.disable_push_token(text,text),
  private.can_receive_driver_work_signal(uuid),
  private.enqueue_notification(text,text,text,uuid,text,text,uuid,uuid,text,text),
  private.enqueue_offer_notification(),
  private.enqueue_order_event_notifications(),
  private.signal_new_driver_work()
from public, anon, authenticated;

grant execute on function private.can_receive_driver_work_signal(uuid)
to authenticated;

grant execute on function public.register_push_token(text,text,text),
  public.revoke_push_token(text,text),
  public.get_driver_active_offers(timestamptz,uuid,integer)
to authenticated;

grant execute on function public.claim_notification_outbox(integer),
  public.complete_notification_outbox(uuid,boolean,text,integer),
  public.disable_push_token(text,text)
to service_role;
