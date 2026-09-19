-- D07: CASH commission snapshots and the smallest immutable commission ledger.
-- Existing COMPLETED orders stay UNKNOWN; this migration performs no backfill.

insert into public.platform_settings (key, value)
values
  ('independent_commission_percent', '10'::jsonb),
  ('independent_promotion_percent', '0'::jsonb),
  ('independent_promotion_days', '14'::jsonb),
  ('office_commission_percent', '7'::jsonb),
  ('office_promotion_percent', '5'::jsonb),
  ('office_promotion_days', '30'::jsonb),
  ('independent_min_platform_balance', '0'::jsonb)
on conflict (key) do nothing;

-- NULL means no trusted activation evidence exists yet. In particular, existing
-- ACTIVE rows are deliberately not backfilled from created_at.
alter table public.drivers
  add column commission_promotion_started_at timestamptz;
alter table public.offices
  add column commission_promotion_started_at timestamptz;

create function private.capture_driver_commission_activation()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
begin
  if tg_op = 'INSERT' then
    if new.status = 'ACTIVE'::public.driver_status then
      new.commission_promotion_started_at := clock_timestamp();
    else
      new.commission_promotion_started_at := null;
    end if;
    return new;
  end if;

  if old.commission_promotion_started_at is not null then
    new.commission_promotion_started_at := old.commission_promotion_started_at;
  elsif old.status <> 'ACTIVE'::public.driver_status
        and new.status = 'ACTIVE'::public.driver_status then
    new.commission_promotion_started_at := clock_timestamp();
  else
    new.commission_promotion_started_at := null;
  end if;
  return new;
end;
$function$;

create trigger drivers_capture_commission_activation
before insert or update of status, commission_promotion_started_at on public.drivers
for each row execute function private.capture_driver_commission_activation();

create function private.capture_office_commission_activation()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
begin
  if tg_op = 'INSERT' then
    if new.status = 'ACTIVE'::public.account_status then
      new.commission_promotion_started_at := clock_timestamp();
    else
      new.commission_promotion_started_at := null;
    end if;
    return new;
  end if;

  if old.commission_promotion_started_at is not null then
    new.commission_promotion_started_at := old.commission_promotion_started_at;
  elsif old.status <> 'ACTIVE'::public.account_status
        and new.status = 'ACTIVE'::public.account_status then
    new.commission_promotion_started_at := clock_timestamp();
  else
    new.commission_promotion_started_at := null;
  end if;
  return new;
end;
$function$;

create trigger offices_capture_commission_activation
before insert or update of status, commission_promotion_started_at on public.offices
for each row execute function private.capture_office_commission_activation();

alter table public.orders
  add column financial_snapshot_status text not null default 'UNKNOWN',
  add column platform_commission_amount numeric(12,2),
  add column office_commission_amount numeric(12,2),
  add column driver_net_amount numeric(12,2),
  add column commission_driver_type public.driver_type,
  add column commission_standard_rate_percent numeric(7,4),
  add column commission_rate_percent numeric(7,4),
  add column commission_promotion_rate_percent numeric(7,4),
  add column commission_promotion_days integer,
  add column commission_promotion_applied boolean,
  add column commission_promotion_started_at timestamptz,
  add column commission_snapshot_at timestamptz,
  add constraint orders_financial_snapshot_status_ck check (
    financial_snapshot_status in ('UNKNOWN', 'SNAPSHOTTED')
  ),
  add constraint orders_financial_amounts_ck check (
    (platform_commission_amount is null or (
      platform_commission_amount >= 0 and platform_commission_amount <> 'NaN'::numeric
    ))
    and (office_commission_amount is null or (
      office_commission_amount >= 0 and office_commission_amount <> 'NaN'::numeric
    ))
    and (driver_net_amount is null or (
      driver_net_amount >= 0 and driver_net_amount <> 'NaN'::numeric
    ))
  ),
  add constraint orders_financial_rates_ck check (
    (commission_standard_rate_percent is null
      or commission_standard_rate_percent between 0 and 100)
    and (commission_rate_percent is null or commission_rate_percent between 0 and 100)
    and (commission_promotion_rate_percent is null
      or commission_promotion_rate_percent between 0 and 100)
    and (commission_promotion_days is null
      or commission_promotion_days between 1 and 3650)
  ),
  add constraint orders_financial_snapshot_bundle_ck check (
    (
      financial_snapshot_status = 'UNKNOWN'
      and commission_snapshot_at is null
      and platform_commission_amount is null
      and office_commission_amount is null
      and driver_net_amount is null
      and commission_driver_type is null
      and commission_standard_rate_percent is null
      and commission_rate_percent is null
      and commission_promotion_rate_percent is null
      and commission_promotion_days is null
      and commission_promotion_applied is null
      and commission_promotion_started_at is null
    )
    or (
      financial_snapshot_status = 'SNAPSHOTTED'
      and commission_snapshot_at is not null
      and platform_commission_amount is not null
      and commission_driver_type is not null
      and commission_standard_rate_percent is not null
      and commission_rate_percent is not null
      and commission_promotion_rate_percent is not null
      and commission_promotion_days is not null
      and commission_promotion_applied is not null
      and commission_promotion_started_at is not null
      and (
        commission_driver_type = 'INDEPENDENT'::public.driver_type
        or (
          driver_net_amount is null
          and office_commission_amount is null
        )
      )
      and (
        commission_driver_type = 'OFFICE_DRIVER'::public.driver_type
        or driver_net_amount is not null
      )
    )
  );

create table public.commission_ledger (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null unique references public.orders(id),
  driver_id uuid not null references public.drivers(id),
  office_id uuid references public.offices(id),
  driver_type public.driver_type not null,
  gross_fare numeric(12,2) not null check (gross_fare > 0 and gross_fare <> 'NaN'::numeric),
  commission_standard_rate_percent numeric(7,4) not null check (
    commission_standard_rate_percent between 0 and 100
  ),
  commission_rate_percent numeric(7,4) not null check (
    commission_rate_percent between 0 and 100
  ),
  commission_promotion_rate_percent numeric(7,4) not null check (
    commission_promotion_rate_percent between 0 and 100
  ),
  commission_promotion_days integer not null check (commission_promotion_days between 1 and 3650),
  commission_promotion_applied boolean not null,
  commission_promotion_started_at timestamptz not null,
  platform_commission_amount numeric(12,2) not null check (
    platform_commission_amount >= 0 and platform_commission_amount <> 'NaN'::numeric
  ),
  office_commission_amount numeric(12,2),
  driver_net_amount numeric(12,2),
  commission_due numeric(12,2) not null check (
    commission_due >= 0 and commission_due <> 'NaN'::numeric
  ),
  platform_balance_delta numeric(12,2) not null check (
    platform_balance_delta >= 0 and platform_balance_delta <> 'NaN'::numeric
  ),
  entry_type text not null default 'TRIP_COMMISSION'
    check (entry_type = 'TRIP_COMMISSION'),
  completed_at timestamptz not null,
  created_at timestamptz not null default clock_timestamp(),
  constraint commission_ledger_scope_ck check (
    (driver_type = 'INDEPENDENT'::public.driver_type and office_id is null)
    or (driver_type = 'OFFICE_DRIVER'::public.driver_type and office_id is not null)
  ),
  constraint commission_ledger_net_ck check (
    (driver_type = 'INDEPENDENT'::public.driver_type
      and driver_net_amount is not null
      and office_commission_amount is null
      and driver_net_amount = gross_fare - platform_commission_amount)
    or (driver_type = 'OFFICE_DRIVER'::public.driver_type
      and driver_net_amount is null
      and office_commission_amount is null)
  ),
  constraint commission_ledger_due_ck check (
    commission_due = platform_commission_amount
    and platform_balance_delta = commission_due
  )
);

create index commission_ledger_driver_completed_idx
  on public.commission_ledger (driver_id, completed_at desc, id desc);
create index commission_ledger_office_completed_idx
  on public.commission_ledger (office_id, completed_at desc, id desc)
  where office_id is not null;

alter table public.commission_ledger enable row level security;
revoke all privileges on table public.commission_ledger from public, anon, authenticated;

create function private.financial_setting_percent(p_key text, p_default numeric)
returns numeric
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
  v_value jsonb;
  v_percent numeric;
begin
  select s.value into v_value
  from public.platform_settings s
  where s.key = p_key;
  if not found then return p_default; end if;
  if jsonb_typeof(v_value) <> 'number' then
    raise exception 'Invalid financial setting: %', p_key using errcode = '22023';
  end if;
  v_percent := (v_value #>> '{}')::numeric;
  if v_percent < 0 or v_percent > 100 then
    raise exception 'Invalid financial setting: %', p_key using errcode = '22023';
  end if;
  return v_percent;
end;
$function$;

create function private.financial_setting_days(p_key text, p_default integer)
returns integer
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
  v_value jsonb;
  v_days numeric;
begin
  select s.value into v_value
  from public.platform_settings s
  where s.key = p_key;
  if not found then return p_default; end if;
  if jsonb_typeof(v_value) <> 'number' then
    raise exception 'Invalid financial setting: %', p_key using errcode = '22023';
  end if;
  v_days := (v_value #>> '{}')::numeric;
  if v_days <> trunc(v_days) or v_days < 1 or v_days > 3650 then
    raise exception 'Invalid financial setting: %', p_key using errcode = '22023';
  end if;
  return v_days::integer;
end;
$function$;

create function private.financial_setting_amount(p_key text, p_default numeric)
returns numeric
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
  v_value jsonb;
  v_amount numeric;
begin
  select s.value into v_value from public.platform_settings s where s.key = p_key;
  if not found then return p_default; end if;
  if jsonb_typeof(v_value) <> 'number' then
    raise exception 'Invalid financial setting: %', p_key using errcode = '22023';
  end if;
  v_amount := (v_value #>> '{}')::numeric;
  if v_amount < 0 or v_amount > 1000000 then
    raise exception 'Invalid financial setting: %', p_key using errcode = '22023';
  end if;
  return v_amount;
end;
$function$;

create function private.snapshot_order_financials()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_driver public.drivers;
  v_office public.offices;
  v_driver_type public.driver_type;
  v_standard_percent numeric;
  v_promotion_percent numeric;
  v_promotion_days integer;
  v_promotion_started_at timestamptz;
  v_completed_at timestamptz;
  v_rate_percent numeric;
  v_gross numeric(12,2);
  v_commission numeric(12,2);
begin
  if tg_op = 'UPDATE' then
    if old.financial_snapshot_status is distinct from new.financial_snapshot_status
       or old.platform_commission_amount is distinct from new.platform_commission_amount
       or old.office_commission_amount is distinct from new.office_commission_amount
       or old.driver_net_amount is distinct from new.driver_net_amount
       or old.commission_driver_type is distinct from new.commission_driver_type
       or old.commission_standard_rate_percent is distinct from new.commission_standard_rate_percent
       or old.commission_rate_percent is distinct from new.commission_rate_percent
       or old.commission_promotion_rate_percent is distinct from new.commission_promotion_rate_percent
       or old.commission_promotion_days is distinct from new.commission_promotion_days
       or old.commission_promotion_applied is distinct from new.commission_promotion_applied
       or old.commission_promotion_started_at is distinct from new.commission_promotion_started_at
       or old.commission_snapshot_at is distinct from new.commission_snapshot_at then
      if not (
        new.status = 'COMPLETED'::public.order_status
        and old.status is distinct from new.status
        and old.financial_snapshot_status = 'UNKNOWN'
      ) then
        raise exception 'Financial snapshot is immutable' using errcode = '42501';
      end if;
    end if;
  end if;

  if new.status = 'COMPLETED'::public.order_status
     and (tg_op = 'INSERT' or old.status is distinct from new.status) then
    if new.driver_id is null or new.agreed_price is null then
      raise exception 'Completed order requires an assigned fare and driver' using errcode = '23514';
    end if;
    if new.financial_snapshot_status <> 'UNKNOWN'
       or new.platform_commission_amount is not null
       or new.office_commission_amount is not null
       or new.driver_net_amount is not null
       or new.commission_snapshot_at is not null then
      raise exception 'Financial snapshot is server generated' using errcode = '42501';
    end if;

    select d.* into v_driver
    from public.drivers d
    where d.id = new.driver_id;
    if not found then
      raise exception 'Completed order driver not found' using errcode = '23503';
    end if;

    v_driver_type := case
      when new.office_id is null then 'INDEPENDENT'::public.driver_type
      else 'OFFICE_DRIVER'::public.driver_type
    end;
    if v_driver.driver_type <> v_driver_type
       or (v_driver_type = 'OFFICE_DRIVER'::public.driver_type
           and v_driver.office_id is distinct from new.office_id)
       or (v_driver_type = 'INDEPENDENT'::public.driver_type
           and v_driver.office_id is not null) then
      raise exception 'Completed order assignment scope is invalid' using errcode = '23514';
    end if;

    if v_driver_type = 'OFFICE_DRIVER'::public.driver_type then
      select o.* into v_office
      from public.offices o
      where o.id = new.office_id;
      if not found then
        raise exception 'Completed office order requires a valid office' using errcode = '23503';
      end if;
      v_promotion_started_at := v_office.commission_promotion_started_at;
      v_standard_percent := private.financial_setting_percent('office_commission_percent', 7);
      v_promotion_percent := private.financial_setting_percent('office_promotion_percent', 5);
      v_promotion_days := private.financial_setting_days('office_promotion_days', 30);
    else
      v_promotion_started_at := v_driver.commission_promotion_started_at;
      v_standard_percent := private.financial_setting_percent('independent_commission_percent', 10);
      v_promotion_percent := private.financial_setting_percent('independent_promotion_percent', 0);
      v_promotion_days := private.financial_setting_days('independent_promotion_days', 14);
    end if;

    -- No activation evidence means UNKNOWN, never a guessed standard/promo rate.
    if v_promotion_started_at is null then
      new.financial_snapshot_status := 'UNKNOWN';
      return new;
    end if;

    v_completed_at := coalesce(new.completed_at, clock_timestamp());
    v_rate_percent := case
      when v_completed_at < v_promotion_started_at + make_interval(days => v_promotion_days)
        then v_promotion_percent
      else v_standard_percent
    end;
    v_gross := round(new.agreed_price, 2);
    v_commission := round(v_gross * v_rate_percent / 100, 2);

    new.completed_at := v_completed_at;
    new.financial_snapshot_status := 'SNAPSHOTTED';
    new.commission_driver_type := v_driver_type;
    new.commission_standard_rate_percent := v_standard_percent;
    new.commission_rate_percent := v_rate_percent;
    new.commission_promotion_rate_percent := v_promotion_percent;
    new.commission_promotion_days := v_promotion_days;
    new.commission_promotion_applied :=
      v_completed_at < v_promotion_started_at + make_interval(days => v_promotion_days);
    new.commission_promotion_started_at := v_promotion_started_at;
    new.platform_commission_amount := v_commission;
    -- The freeze does not define an office payroll/share split. Keep it unknown.
    new.office_commission_amount := null;
    new.driver_net_amount := case
      when v_driver_type = 'INDEPENDENT'::public.driver_type
        then v_gross - v_commission
      else null
    end;
    new.commission_snapshot_at := v_completed_at;
  end if;

  return new;
end;
$function$;

create trigger orders_snapshot_financials
before insert or update on public.orders
for each row execute function private.snapshot_order_financials();

create function private.assert_commission_ledger_insert()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_order public.orders;
begin
  select o.* into v_order
  from public.orders o
  where o.id = new.order_id
    and o.status = 'COMPLETED'::public.order_status
    and o.financial_snapshot_status = 'SNAPSHOTTED';
  if not found
     or new.driver_id is distinct from v_order.driver_id
     or new.office_id is distinct from v_order.office_id
     or new.driver_type is distinct from v_order.commission_driver_type
     or new.gross_fare is distinct from v_order.agreed_price
     or new.commission_standard_rate_percent is distinct from v_order.commission_standard_rate_percent
     or new.commission_rate_percent is distinct from v_order.commission_rate_percent
     or new.commission_promotion_rate_percent is distinct from v_order.commission_promotion_rate_percent
     or new.commission_promotion_days is distinct from v_order.commission_promotion_days
     or new.commission_promotion_applied is distinct from v_order.commission_promotion_applied
     or new.commission_promotion_started_at is distinct from v_order.commission_promotion_started_at
     or new.platform_commission_amount is distinct from v_order.platform_commission_amount
     or new.office_commission_amount is distinct from v_order.office_commission_amount
     or new.driver_net_amount is distinct from v_order.driver_net_amount
     or new.commission_due is distinct from v_order.platform_commission_amount
     or new.platform_balance_delta is distinct from v_order.platform_commission_amount
     or new.completed_at is distinct from v_order.completed_at
     or new.entry_type <> 'TRIP_COMMISSION' then
    raise exception 'Commission ledger rows must match a completed order snapshot'
      using errcode = '42501';
  end if;
  return new;
end;
$function$;

create function private.reject_commission_ledger_mutation()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
begin
  raise exception 'Commission ledger is immutable' using errcode = '42501';
end;
$function$;

create trigger commission_ledger_insert_guard
before insert on public.commission_ledger
for each row execute function private.assert_commission_ledger_insert();
create trigger commission_ledger_immutable
before update or delete on public.commission_ledger
for each row execute function private.reject_commission_ledger_mutation();

create table public.driver_credit_ledger (
  id uuid primary key default gen_random_uuid(),
  driver_id uuid not null references public.drivers(id),
  order_id uuid references public.orders(id),
  entry_type text not null check (entry_type in ('TOP_UP', 'TRIP_COMMISSION')),
  balance_delta numeric(12,2) not null check (
    balance_delta <> 0 and balance_delta <> 'NaN'::numeric
  ),
  actor_id uuid references public.profiles(id),
  reason text,
  created_at timestamptz not null default clock_timestamp(),
  constraint driver_credit_ledger_shape_ck check (
    (entry_type = 'TOP_UP' and order_id is null and balance_delta > 0
      and actor_id is not null and nullif(btrim(reason), '') is not null)
    or
    (entry_type = 'TRIP_COMMISSION' and order_id is not null and balance_delta < 0
      and actor_id is null and reason is null)
  )
);

create unique index driver_credit_ledger_order_commission_uidx
  on public.driver_credit_ledger (order_id)
  where entry_type = 'TRIP_COMMISSION';
create index driver_credit_ledger_driver_created_idx
  on public.driver_credit_ledger (driver_id, created_at desc, id desc);

alter table public.driver_credit_ledger enable row level security;
revoke all privileges on table public.driver_credit_ledger from public, anon, authenticated;
grant select on table public.driver_credit_ledger to service_role;

create function private.driver_platform_balance(p_driver_id uuid)
returns numeric
language sql
stable
security definer
set search_path = ''
as $function$
  select coalesce(sum(entry.balance_delta), 0)::numeric
  from public.driver_credit_ledger entry
  where entry.driver_id = p_driver_id;
$function$;

create function private.driver_meets_credit_threshold(p_driver_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $function$
  select coalesce(
    (select d.driver_type = 'OFFICE_DRIVER'::public.driver_type
      or private.driver_platform_balance(d.id) >=
        private.financial_setting_amount('independent_min_platform_balance', 0)
     from public.drivers d where d.id = p_driver_id),
    false
  );
$function$;

create function public.record_driver_credit_top_up(
  p_driver_id uuid,
  p_amount numeric,
  p_actor_id uuid,
  p_reason text
)
returns public.driver_credit_ledger
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_entry public.driver_credit_ledger;
begin
  if p_amount is null or p_amount <= 0 or p_amount = 'NaN'::numeric
     or nullif(btrim(p_reason), '') is null
     or not exists (
       select 1 from public.profiles p
       where p.id = p_actor_id
         and p.profile_type = 'STAFF'::public.profile_type
         and p.status = 'ACTIVE'::public.account_status
     )
     or not exists (
       select 1 from public.drivers d
       where d.id = p_driver_id
         and d.driver_type = 'INDEPENDENT'::public.driver_type
     ) then
    raise exception 'Invalid trusted Driver credit top-up' using errcode = '22023';
  end if;

  insert into public.driver_credit_ledger (
    driver_id, entry_type, balance_delta, actor_id, reason
  ) values (
    p_driver_id, 'TOP_UP', round(p_amount, 2), p_actor_id, btrim(p_reason)
  ) returning * into v_entry;
  return v_entry;
end;
$function$;

create function private.debit_driver_trip_commission()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
begin
  if new.driver_type = 'INDEPENDENT'::public.driver_type
     and new.platform_commission_amount > 0 then
    insert into public.driver_credit_ledger (
      driver_id, order_id, entry_type, balance_delta
    ) values (
      new.driver_id, new.order_id, 'TRIP_COMMISSION', -new.platform_commission_amount
    ) on conflict (order_id) where entry_type = 'TRIP_COMMISSION' do nothing;
  end if;
  return new;
end;
$function$;

create trigger commission_ledger_debit_driver_credit
after insert on public.commission_ledger
for each row execute function private.debit_driver_trip_commission();

create function private.enforce_driver_credit_threshold()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
begin
  if not private.driver_meets_credit_threshold(new.driver_id) then
    raise exception 'Driver platform credit is below the required threshold'
      using errcode = '42501';
  end if;
  return new;
end;
$function$;

create trigger offers_enforce_driver_credit_threshold
before insert on public.offers
for each row execute function private.enforce_driver_credit_threshold();
create trigger candidates_enforce_driver_credit_threshold
before insert on public.order_driver_candidates
for each row execute function private.enforce_driver_credit_threshold();

create function private.write_commission_ledger()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
begin
  if new.status = 'COMPLETED'::public.order_status
     and new.financial_snapshot_status = 'SNAPSHOTTED'
     and (tg_op = 'INSERT' or old.status is distinct from new.status) then
    insert into public.commission_ledger (
      order_id, driver_id, office_id, driver_type, gross_fare,
      commission_standard_rate_percent, commission_rate_percent,
      commission_promotion_rate_percent, commission_promotion_days,
      commission_promotion_applied, commission_promotion_started_at,
      platform_commission_amount, office_commission_amount, driver_net_amount,
      commission_due, platform_balance_delta, completed_at
    ) values (
      new.id, new.driver_id, new.office_id, new.commission_driver_type,
      new.agreed_price, new.commission_standard_rate_percent,
      new.commission_rate_percent, new.commission_promotion_rate_percent,
      new.commission_promotion_days, new.commission_promotion_applied,
      new.commission_promotion_started_at, new.platform_commission_amount,
      new.office_commission_amount, new.driver_net_amount,
      new.platform_commission_amount, new.platform_commission_amount,
      new.completed_at
    ) on conflict (order_id) do nothing;
  end if;
  return new;
end;
$function$;

create trigger orders_write_commission_ledger
after insert or update on public.orders
for each row execute function private.write_commission_ledger();

create function public.get_driver_earnings(p_limit integer default 50)
returns table (
  order_id uuid,
  completed_at timestamptz,
  driver_type public.driver_type,
  gross_fare numeric(12,2),
  financial_status text,
  platform_commission_amount numeric(12,2),
  driver_net_amount numeric(12,2)
)
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_driver_id uuid;
begin
  if (select auth.uid()) is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  if p_limit is null or p_limit < 1 or p_limit > 50 then
    raise exception 'Invalid earnings limit' using errcode = '22023';
  end if;

  select d.id into v_driver_id
  from public.drivers d
  where d.user_id = (select auth.uid());
  if not found then
    raise exception 'Driver account required' using errcode = '42501';
  end if;

  return query
  select
    o.id,
    o.completed_at,
    case when o.office_id is null
      then 'INDEPENDENT'::public.driver_type
      else 'OFFICE_DRIVER'::public.driver_type
    end,
    o.agreed_price,
    o.financial_snapshot_status,
    case when o.office_id is null then o.platform_commission_amount
      else null::numeric(12,2) end,
    case when o.office_id is null then o.driver_net_amount
      else null::numeric(12,2) end
  from public.orders o
  where o.driver_id = v_driver_id
    and o.status = 'COMPLETED'::public.order_status
  order by o.completed_at desc nulls last, o.id desc
  limit p_limit;
end;
$function$;

revoke all on function private.capture_driver_commission_activation(),
  private.capture_office_commission_activation(),
  private.financial_setting_percent(text, numeric),
  private.financial_setting_days(text, integer),
  private.financial_setting_amount(text, numeric),
  private.snapshot_order_financials(),
  private.assert_commission_ledger_insert(),
  private.reject_commission_ledger_mutation(),
  private.write_commission_ledger(),
  private.driver_platform_balance(uuid),
  private.driver_meets_credit_threshold(uuid),
  private.debit_driver_trip_commission(),
  private.enforce_driver_credit_threshold()
from public, anon, authenticated;

revoke all on function public.record_driver_credit_top_up(uuid, numeric, uuid, text)
from public, anon, authenticated;
grant execute on function public.record_driver_credit_top_up(uuid, numeric, uuid, text)
to service_role;

revoke all on function public.get_driver_earnings(integer)
from public, anon, authenticated;
grant execute on function public.get_driver_earnings(integer) to authenticated;

comment on table public.commission_ledger is
  'Immutable CASH trip commission facts only; not a wallet, payout, payroll, or settlement ledger.';
