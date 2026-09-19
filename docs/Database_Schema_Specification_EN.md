# Database Schema Specification
## Motorcycle Mobility & Delivery Platform

**Version:** 1.0  
**Database:** PostgreSQL via Supabase  
**Date:** August 28, 2026

> This document defines the recommended MVP relational schema. Field names may be refined during implementation, but the entities, relationships, ownership model, and security boundaries are required.

> Business Rules Freeze v1.0 is authoritative. Sections labelled **PENDING SCHEMA** describe approved requirements that are not present in the current hosted schema; they must not be reported as implemented.

> **Current hosted snapshot — 2026-08-30:** the schema includes server-owned
> 90-second order expiry, customer-scoped `creation_intent_id`, protected
> `order_delivery_details`, cancellation metadata, `order_events`, one-active-
> job and complete assignment constraints, withdrawal-capable offers, and a
> transactionally maintained `drivers.completed_trip_count`. Safe RPCs provide
> explicit Driver-request and customer-offer projections. Historical/recommended
> field lists below do not override this current snapshot.

---

# 1. Enums

Recommended enums:

```text
profile_type:
CUSTOMER
DRIVER
STAFF

account_status:
ACTIVE
SUSPENDED
DELETED

driver_type:
INDEPENDENT
OFFICE_DRIVER

driver_status:
PENDING
ACTIVE
SUSPENDED
REJECTED

document_status:
PENDING
APPROVED
REJECTED
EXPIRED

motorcycle_status:
ACTIVE
INACTIVE
SUSPENDED

service_type:
RIDE
DELIVERY

order_status:
DRAFT
BIDDING
DRIVER_ASSIGNED
DRIVER_ON_WAY
DRIVER_ARRIVED
IN_PROGRESS
COMPLETED
CANCELLED
EXPIRED

offer_status:
ACTIVE
SELECTED
REJECTED
WITHDRAWN
EXPIRED
CLOSED

payment_method:
CASH
ONLINE
WALLET
```

MVP uses `CASH`.

`ONLINE` and `WALLET` are future expansion values only. MVP has no card
payments, customer wallet, driver withdrawal/cash-out, or debt engine.

---

# 2. profiles

Extends `auth.users`.

```text
id uuid PK -> auth.users.id
full_name text
phone text
profile_type
status
profile_photo_url text null
created_at timestamptz
updated_at timestamptz
```

Indexes:

```text
phone
profile_type
status
```

---

# 3. offices

```text
id uuid PK
name text
responsible_person text null
phone text
address text null
area text null
status text
commission_config jsonb null
created_at timestamptz
updated_at timestamptz
```

---

# 4. office_members

```text
id uuid PK
office_id uuid FK -> offices.id
user_id uuid FK -> profiles.id
role_id uuid FK -> roles.id
status text
created_at timestamptz
updated_at timestamptz
```

Constraint:

```text
unique(office_id, user_id)
```

---

# 5. drivers

```text
id uuid PK
user_id uuid UNIQUE FK -> profiles.id
driver_type
office_id uuid null FK -> offices.id
status driver_status
rating numeric default 0
rating_count integer default 0
completed_trip_count integer default 0
is_online boolean default false
created_at timestamptz
updated_at timestamptz
```

Constraint:

```text
INDEPENDENT => office_id IS NULL
OFFICE_DRIVER => office_id IS NOT NULL
```

An Office Driver belongs to one office maximum. Office changes use a trusted
Platform-Admin-approved Change Request, and historical orders retain the
original `office_id` snapshot. The Change Request structure is **PENDING
SCHEMA**.

---

# 6. motorcycles

```text
id uuid PK
driver_id uuid null FK -> drivers.id
office_id uuid null FK -> offices.id
plate_number text null
brand text null
model text null
color text
model_year integer null
photo_url text null
status motorcycle_status
created_at timestamptz
updated_at timestamptz
```

---

# 7. driver_documents

```text
id uuid PK
driver_id uuid FK -> drivers.id
document_type text
file_path text
status document_status
rejection_reason text null
expiry_date date null
verified_by uuid null FK -> profiles.id
verified_at timestamptz null
created_at timestamptz
updated_at timestamptz
```

Required types cover National ID, valid driving licence, and driver/profile
selfie. Minimum age is 21; criminal-record evidence is a public-launch gate
subject to legal confirmation. Expiry alerts at 30/7/1 days and eligibility
enforcement are **PENDING IMPLEMENTATION**.

## 7A. motorcycle_documents — PENDING SCHEMA

A dedicated table is required; motorcycle evidence must not be mixed into
`driver_documents`.

```text
id uuid PK
motorcycle_id uuid FK -> motorcycles.id
document_type text
file_path text
status document_status
rejection_reason text null
expiry_date date null
verified_by uuid null FK -> profiles.id
verified_at timestamptz null
created_at timestamptz
updated_at timestamptz
```

---

# 8. service_types

```text
id uuid PK
code text UNIQUE
name_ar text
name_en text
is_enabled boolean
config jsonb null
created_at timestamptz
updated_at timestamptz
```

Seed:

```text
RIDE
DELIVERY
```

---

# 9. orders

```text
id uuid PK
customer_id uuid FK -> profiles.id
service_type_id uuid FK -> service_types.id

pickup_lat numeric
pickup_lng numeric
pickup_address text

destination_lat numeric
destination_lng numeric
destination_address text

customer_offered_price numeric
agreed_price numeric null

selected_offer_id uuid null
driver_id uuid null FK -> drivers.id
office_id uuid null FK -> offices.id
motorcycle_id uuid null FK -> motorcycles.id

status order_status
payment_method payment_method default CASH

notes text null
delivery_item_description text null
recipient_name text null
recipient_phone text null
parcel_weight_kg numeric null
declared_value numeric null

bidding_expires_at timestamptz null

created_at timestamptz
assigned_at timestamptz null
on_way_at timestamptz null
arrived_at timestamptz null
started_at timestamptz null
completed_at timestamptz null
cancelled_at timestamptz null
expired_at timestamptz null

cancelled_by uuid null FK -> profiles.id
cancellation_reason text null

platform_commission_amount numeric null
office_commission_amount numeric null
driver_net_amount numeric null

updated_at timestamptz
```

Delivery recipient and parcel fields are **IMPLEMENTED** in the protected
`order_delivery_details` table, with one parcel, maximum 8 kg and 3,000 EGP
declared value. Cancellation metadata is also implemented. Ride/Delivery
verification-code storage must use server-safe hashed/derived values rather
than readable client data; OTP and geofence fields remain **PENDING SCHEMA**.

The frozen server-owned 90-second bidding window is **IMPLEMENTED**.
`customer_offered_price`
is immutable after `BIDDING`, `agreed_price` after `DRIVER_ASSIGNED`, and
driver assignment after `IN_PROGRESS` except controlled recovery.

Important indexes:

```text
customer_id
driver_id
office_id
status
created_at
bidding_expires_at
```

---

# 10. offers

```text
id uuid PK
order_id uuid FK -> orders.id
driver_id uuid FK -> drivers.id
office_id uuid null FK -> offices.id
amount numeric
status offer_status
expires_at timestamptz null
created_at timestamptz
updated_at timestamptz
```

Important constraint:

```text
one active offer per driver per order
```

Implementation may use partial unique index.

Active offers cannot be edited. They may be withdrawn only while unselected
and the order remains `BIDDING`; a new offer may then be inserted. Offer
expiry equals order bidding expiry. Withdrawal/new-offer enforcement is
**IMPLEMENTED**.

Indexes:

```text
order_id
driver_id
status
```

---

# 11. driver_locations

MVP may store only latest location.

```text
driver_id uuid PK FK -> drivers.id
latitude numeric
longitude numeric
heading numeric null
speed numeric null
accuracy numeric null
updated_at timestamptz
```

A PostGIS geography column/index is required for the 2/4/6/8 km progressive
candidate search. It is **PENDING SCHEMA**.

---

# 12. ratings

```text
id uuid PK
order_id uuid UNIQUE FK -> orders.id
customer_id uuid FK -> profiles.id
driver_id uuid FK -> drivers.id
rating smallint
comment text null
created_at timestamptz
updated_at timestamptz
```

Constraint:

```text
rating between 1 and 5
```

---

# 13. roles

```text
id uuid PK
code text UNIQUE
name text
scope_type text
created_at timestamptz
```

---

# 14. permissions

```text
id uuid PK
code text UNIQUE
description text null
created_at timestamptz
```

Examples:

```text
orders.view
orders.cancel
drivers.view
drivers.verify
offices.manage
reports.view
settings.manage
```

---

# 15. role_permissions

```text
role_id uuid FK -> roles.id
permission_id uuid FK -> permissions.id
PRIMARY KEY(role_id, permission_id)
```

---

# 16. user_roles

For platform-wide role assignments.

```text
id uuid PK
user_id uuid FK -> profiles.id
role_id uuid FK -> roles.id
created_at timestamptz
```

Office-specific roles should normally use `office_members`.

---

# 17. device_tokens

```text
id uuid PK
user_id uuid FK -> profiles.id
platform text
token text UNIQUE
is_active boolean
last_seen_at timestamptz
created_at timestamptz
```

---

# 18. notifications

```text
id uuid PK
user_id uuid FK -> profiles.id
type text
title text
body text
data jsonb null
read_at timestamptz null
created_at timestamptz
```

---

# 19. system_settings

```text
key text PK
value jsonb
updated_by uuid null FK -> profiles.id
updated_at timestamptz
```

Examples:

```text
ride_enabled
delivery_enabled
bidding_duration_seconds
initial_dispatch_radius_km
suggested_price_enabled
suggested_price_base
suggested_price_distance_component
minimum_proposal_percent
dispatch_radius_steps_km
dispatch_radius_step_seconds
independent_commission_percent
office_commission_percent
independent_promo_days
office_promo_days
operating_zones
```

Frozen defaults include 90 seconds; 2/4/6/8 km approximately every 20
seconds; 70% minimum proposal; Independent 0% for 14 days then 10%; Office
5% for one month then 7%; and East Cairo pilot zones. Settings storage is
**PENDING SCHEMA** where absent.

---

# 20. audit_logs

```text
id uuid PK
actor_user_id uuid null FK -> profiles.id
actor_role text null
office_id uuid null FK -> offices.id
action text
entity_type text
entity_id uuid null
old_value jsonb null
new_value jsonb null
metadata jsonb null
created_at timestamptz
```

---

# 21. order_events — IMPLEMENTED

Every meaningful transition, cancellation, expiry, and trusted admin recovery
must create an event for support, disputes, debugging, and dashboard timeline.

```text
id uuid PK
order_id uuid FK -> orders.id
event_type text
actor_user_id uuid null
from_status order_status null
to_status order_status null
metadata jsonb null
created_at timestamptz
```

## 21A. commission_ledger — PENDING SCHEMA

Cash MVP requires a limited ledger, not a full wallet:

```text
id uuid PK
driver_id uuid null FK -> drivers.id
office_id uuid null FK -> offices.id
order_id uuid null FK -> orders.id
commission_due numeric
platform_balance_delta numeric
entry_type text
created_at timestamptz
```

Independent-driver credit thresholds and manual approved top-up, plus weekly
Office settlement/invoice, remain **PENDING IMPLEMENTATION**.

---

# 22. Core Relationships

```text
profiles
  |
  +--> customer orders
  |
  +--> driver profile
  |
  +--> staff roles
  |
  +--> office membership

offices
  |
  +--> office_members
  +--> drivers
  +--> motorcycles
  +--> orders
  +--> offers

drivers
  |
  +--> motorcycles
  +--> driver_documents
  +--> motorcycle_documents (PENDING SCHEMA)
  +--> offers
  +--> orders
  +--> driver_locations
  +--> ratings

orders
  |
  +--> offers
  +--> selected driver
  +--> selected offer
  +--> motorcycle
  +--> rating
  +--> order_events
```

---

# 23. RLS Ownership Rules

## profiles

User reads/updates permitted own fields.

## orders

Customer:

```text
customer_id = auth.uid()
```

Driver:

Can read assigned order or eligible bidding data through approved query/function.

Office user:

```text
office_id = current_office_id
```

Admin:

According to role.

## offers

Customer can read offers where the related order belongs to customer.

Driver can read/write own offers subject to bidding state.

Office user may read office-driver offers if permitted.

## drivers

Driver reads own profile.

Office users read office drivers.

Platform admins read according to permission.

---

# 24. Critical Constraints

Must prevent:

- Two selected offers for one order.
- Two drivers assigned to one order.
- Duplicate rating for same order.
- Independent driver with office_id.
- Office driver without office_id.
- Invalid order status values.
- Non-positive offer amounts.
- Non-positive customer price.
- Invalid rating values.
- More than one active job for a driver.
- Customer proposal edits after `BIDDING`.
- Agreed-price edits after `DRIVER_ASSIGNED`.
- Driver reassignment after `IN_PROGRESS` outside controlled recovery.

---

# 25. Recommended Indexes

At minimum:

```text
orders(customer_id, created_at desc)
orders(driver_id, status)
orders(office_id, created_at desc)
orders(status, created_at)
offers(order_id, status)
offers(driver_id, status)
drivers(office_id, status)
drivers(status, is_online)
driver_documents(driver_id, status)
office_members(office_id, user_id)
audit_logs(entity_type, entity_id, created_at)
```

Use a PostGIS/geospatial index for driver proximity. This index is **PENDING
SCHEMA**.

---

# 26. Migration Requirements

Schema delivery must include reproducible migrations for:

- Extensions.
- Enums.
- Tables.
- Foreign keys.
- Indexes.
- Constraints.
- Triggers.
- Functions.
- RLS.
- Seed roles/permissions.
- Seed service types.

---

# 27. Acceptance Criteria

Database schema is accepted when:

- All core entities exist.
- Relationships are enforced.
- Office ownership is enforceable.
- Atomic assignment is supported.
- RLS can protect user/driver/office boundaries.
- Indexes support main query patterns.
- Migrations rebuild database.
- No core business logic depends on client-only validation.

---

**End of Database Schema Specification**
