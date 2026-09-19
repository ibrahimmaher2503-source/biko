create extension if not exists pgcrypto with schema extensions;

create type public.profile_type as enum ('CUSTOMER', 'DRIVER', 'STAFF');
create type public.account_status as enum ('ACTIVE', 'SUSPENDED', 'DELETED');
create type public.driver_type as enum ('INDEPENDENT', 'OFFICE_DRIVER');
create type public.driver_status as enum ('PENDING', 'ACTIVE', 'SUSPENDED', 'REJECTED');
create type public.document_status as enum ('PENDING', 'APPROVED', 'REJECTED', 'EXPIRED');
create type public.motorcycle_status as enum ('ACTIVE', 'INACTIVE', 'SUSPENDED');

create table public.roles (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  scope_type text not null check (scope_type in ('PLATFORM', 'OFFICE', 'SELF', 'CUSTOM')),
  created_at timestamptz not null default now()
);

create table public.permissions (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  description text,
  created_at timestamptz not null default now()
);

create table public.role_permissions (
  role_id uuid not null references public.roles(id) on delete cascade,
  permission_id uuid not null references public.permissions(id) on delete cascade,
  primary key (role_id, permission_id)
);

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  phone text,
  profile_type public.profile_type not null default 'CUSTOMER',
  status public.account_status not null default 'ACTIVE',
  profile_photo_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.offices (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  responsible_person text,
  phone text,
  address text,
  area text,
  status public.account_status not null default 'ACTIVE',
  commission_config jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.office_members (
  id uuid primary key default gen_random_uuid(),
  office_id uuid not null references public.offices(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  role_id uuid not null references public.roles(id),
  status public.account_status not null default 'ACTIVE',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (office_id, user_id)
);

create table public.drivers (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references public.profiles(id) on delete cascade,
  driver_type public.driver_type not null,
  office_id uuid references public.offices(id),
  status public.driver_status not null default 'PENDING',
  rating numeric(3, 2) not null default 0 check (rating between 0 and 5),
  rating_count integer not null default 0 check (rating_count >= 0),
  completed_trip_count integer not null default 0 check (completed_trip_count >= 0),
  is_online boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint drivers_office_ownership check (
    (driver_type = 'INDEPENDENT' and office_id is null)
    or (driver_type = 'OFFICE_DRIVER' and office_id is not null)
  ),
  constraint drivers_online_only_when_active check (not is_online or status = 'ACTIVE')
);

create table public.motorcycles (
  id uuid primary key default gen_random_uuid(),
  driver_id uuid references public.drivers(id) on delete set null,
  office_id uuid references public.offices(id) on delete set null,
  plate_number text,
  brand text,
  model text,
  color text not null,
  model_year integer check (model_year between 1950 and 2100),
  photo_url text,
  status public.motorcycle_status not null default 'INACTIVE',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.driver_documents (
  id uuid primary key default gen_random_uuid(),
  driver_id uuid not null references public.drivers(id) on delete cascade,
  document_type text not null,
  file_path text not null,
  status public.document_status not null default 'PENDING',
  rejection_reason text,
  expiry_date date,
  verified_by uuid references public.profiles(id),
  verified_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint rejected_document_requires_reason check (
    status <> 'REJECTED' or nullif(trim(rejection_reason), '') is not null
  )
);

create table public.service_types (
  id uuid primary key default gen_random_uuid(),
  code text not null unique check (code in ('RIDE', 'DELIVERY')),
  name_ar text not null,
  name_en text not null,
  is_enabled boolean not null default true,
  config jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.user_roles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  role_id uuid not null references public.roles(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (user_id, role_id)
);

create index profiles_phone_idx on public.profiles(phone) where phone is not null;
create index profiles_type_status_idx on public.profiles(profile_type, status);
create index offices_status_idx on public.offices(status);
create index office_members_office_user_idx on public.office_members(office_id, user_id);
create index drivers_office_status_idx on public.drivers(office_id, status);
create index drivers_status_online_idx on public.drivers(status, is_online);
create index motorcycles_driver_idx on public.motorcycles(driver_id);
create index motorcycles_office_idx on public.motorcycles(office_id);
create index driver_documents_driver_status_idx on public.driver_documents(driver_id, status);
create index user_roles_user_idx on public.user_roles(user_id);

create function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_set_updated_at before update on public.profiles
for each row execute function public.set_updated_at();
create trigger offices_set_updated_at before update on public.offices
for each row execute function public.set_updated_at();
create trigger office_members_set_updated_at before update on public.office_members
for each row execute function public.set_updated_at();
create trigger drivers_set_updated_at before update on public.drivers
for each row execute function public.set_updated_at();
create trigger motorcycles_set_updated_at before update on public.motorcycles
for each row execute function public.set_updated_at();
create trigger driver_documents_set_updated_at before update on public.driver_documents
for each row execute function public.set_updated_at();
create trigger service_types_set_updated_at before update on public.service_types
for each row execute function public.set_updated_at();

create function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, full_name, phone)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', ''),
    new.phone
  );
  return new;
end;
$$;

create trigger auth_user_created
after insert on auth.users
for each row execute function public.handle_new_auth_user();

insert into public.service_types (code, name_ar, name_en)
values
  ('RIDE', 'رحلة راكب', 'Passenger Ride'),
  ('DELIVERY', 'توصيل طرد', 'Parcel Delivery');

insert into public.roles (code, name, scope_type)
values
  ('SUPER_ADMIN', 'Super Admin', 'PLATFORM'),
  ('OFFICE_ADMIN', 'Office Admin', 'OFFICE'),
  ('OFFICE_DISPATCHER', 'Office Dispatcher', 'OFFICE'),
  ('OFFICE_ACCOUNTANT', 'Office Accountant', 'OFFICE');

insert into public.permissions (code, description)
values
  ('dashboard.view', 'View dashboard'),
  ('orders.view', 'View orders'),
  ('orders.manage', 'Manage permitted orders'),
  ('orders.cancel', 'Cancel permitted orders'),
  ('bids.view', 'View bids and offers'),
  ('drivers.view', 'View drivers'),
  ('drivers.create', 'Create drivers'),
  ('drivers.edit', 'Edit drivers'),
  ('drivers.verify', 'Verify drivers and documents'),
  ('drivers.activate', 'Activate drivers'),
  ('drivers.suspend', 'Suspend drivers'),
  ('motorcycles.view', 'View motorcycles'),
  ('motorcycles.create', 'Create motorcycles'),
  ('motorcycles.edit', 'Edit motorcycles'),
  ('users.view', 'View customers'),
  ('offices.view', 'View offices'),
  ('offices.create', 'Create offices'),
  ('offices.edit', 'Edit offices'),
  ('offices.suspend', 'Suspend offices'),
  ('reports.view', 'View reports'),
  ('finance.view', 'View permitted financial summaries'),
  ('roles.view', 'View roles and permissions'),
  ('roles.manage', 'Manage roles and permissions'),
  ('settings.view', 'View platform settings'),
  ('settings.manage', 'Manage platform settings'),
  ('audit.view', 'View audit log');

insert into public.role_permissions (role_id, permission_id)
select roles.id, permissions.id
from public.roles
cross join public.permissions
where roles.code = 'SUPER_ADMIN';

insert into public.role_permissions (role_id, permission_id)
select roles.id, permissions.id
from public.roles
join public.permissions on permissions.code in (
  'dashboard.view', 'orders.view', 'orders.manage', 'orders.cancel', 'bids.view',
  'drivers.view', 'drivers.create', 'drivers.edit', 'motorcycles.view',
  'motorcycles.create', 'motorcycles.edit', 'reports.view', 'finance.view'
)
where roles.code = 'OFFICE_ADMIN';

insert into public.role_permissions (role_id, permission_id)
select roles.id, permissions.id
from public.roles
join public.permissions on permissions.code in (
  'dashboard.view', 'orders.view', 'orders.manage', 'bids.view',
  'drivers.view', 'motorcycles.view'
)
where roles.code = 'OFFICE_DISPATCHER';

insert into public.role_permissions (role_id, permission_id)
select roles.id, permissions.id
from public.roles
join public.permissions on permissions.code in (
  'dashboard.view', 'orders.view', 'reports.view', 'finance.view'
)
where roles.code = 'OFFICE_ACCOUNTANT';

alter table public.profiles enable row level security;
alter table public.offices enable row level security;
alter table public.office_members enable row level security;
alter table public.drivers enable row level security;
alter table public.motorcycles enable row level security;
alter table public.driver_documents enable row level security;
alter table public.roles enable row level security;
alter table public.permissions enable row level security;
alter table public.role_permissions enable row level security;
alter table public.user_roles enable row level security;

comment on function public.handle_new_auth_user() is
  'Creates a CUSTOMER profile only. Elevated profile types require trusted backend logic.';

