# Backend & Supabase
## Technical Requirements Specification

**Project:** Motorcycle Mobility & Delivery Platform  
**Component:** Backend / Supabase  
**Version:** 1.0  
**Status:** MVP Technical Specification  
**Date:** August 28, 2026

---

## Current Hosted Contract Snapshot — 2026-08-30

Milestone 7A and remediation Waves A/B/C are implemented on Development.
Current contracts include Email + Password Auth; caller-stable order creation
intent; Ride/Delivery creation with protected recipient/parcel validation;
server-owned 90-second bidding; immutable customer proposal; offer withdrawal
and replacement; one active job per Driver; multiple cross-order offers until
assignment; closure of competing offers for the order and winning Driver;
privacy-safe Driver/customer projections; frozen customer/Driver cancellation;
`order_events`; exact `completed_trip_count`; and current customer-offer
eligibility filtering. Client mutation/recovery requests are bounded and
authoritative waiting-offer state is re-read after uncertain outcomes. Hosted
Auth redirect allowlist confirmation remains external. Maps and Realtime are
implemented with external configuration pending. Milestone 10 implements
trusted geofences and one final Delivery Confirmation Code; Ride and Delivery
Pickup use no OTP.

---

# 1. Objective

Provide one secure backend for:

- User App.
- Driver App.
- Unified Admin/Office Dashboard.

The backend must support:

- Authentication.
- Offices.
- Drivers.
- Motorcycles.
- Orders.
- Bidding.
- Atomic assignment.
- Realtime updates.
- Live location.
- Notifications.
- Roles & Permissions.
- RLS.
- Audit logging.
- Basic reporting.

---

# 2. Recommended Backend

Use **Supabase**.

Components:

```text
Supabase Auth
PostgreSQL
Realtime
Storage
RLS
Database Functions / RPC
Edge Functions
```

No separate PostgreSQL server is required.

---

# 3. Backend Design Principles

1. Database is the source of truth.
2. Client apps must not control sensitive state transitions directly.
3. Critical actions must be atomic.
4. Authorization is enforced at database/backend level.
5. Office isolation is mandatory.
6. Realtime is used for state delivery, not business-rule ownership.
7. Push notifications complement Realtime.
8. Business rules should be centralized.
9. Critical operations should be idempotent.
10. Database migrations must recreate the environment.

---

# 4. Authentication

Use Supabase Auth.

User types include:

- Customer.
- Driver.
- Dashboard staff.

A central `profiles` table may extend auth users.

Recommended fields:

```text
id = auth.users.id
full_name
phone
profile_type
status
created_at
updated_at
```

---

# 5. Roles & Permissions

Recommended entities:

```text
roles
permissions
role_permissions
user_roles
office_members
```

Authorization should evaluate:

```text
Authenticated User
+ Role
+ Permission
+ Data Scope
```

---

# 6. Row Level Security

RLS must be enabled on sensitive tables.

Examples:

## Customer

Can access:

- Own profile.
- Own orders.
- Offers for own orders.
- Own ratings.

## Driver

Can access:

- Own driver profile.
- Own offers.
- Eligible requests through approved mechanism.
- Assigned orders.
- Own motorcycle/documents.

## Office User

Can access only records where:

```text
office_id = current_user_office_id
```

subject to permissions.

## Platform Admin

Broader access based on authorized role.

---

# 7. Core Domain Tables

Minimum core entities:

```text
profiles
offices
office_members
drivers
motorcycles
driver_documents
service_types
orders
offers
driver_locations
ratings
roles
permissions
role_permissions
user_roles
notifications
system_settings
audit_logs
```

---

# 8. Order Creation

Customer creates order through a trusted function or validated insert.

Required validations:

- Customer active.
- Service enabled.
- Pickup valid.
- Destination valid.
- Proposed price valid.
- No invalid duplicate submission.
- Operating zone valid if enforced.

Initial state:

```text
BIDDING
```

The proposed price must be at least 70% of the configurable Suggested Price
and becomes immutable after `BIDDING`. There is no business maximum, though
technical anti-abuse limits may apply. Store a 90-second bidding expiration.
The server-owned 90-second timeout is **IMPLEMENTED**. Suggested
Price/minimum validation remains **PENDING IMPLEMENTATION**.

---

# 9. Dispatch Eligibility

Backend determines eligible drivers using:

- `ACTIVE`.
- `ONLINE`.
- Within the active 2/4/6/8 km radius.
- Service allowed.
- No active order.
- Motorcycle valid/operational.
- Required driver and motorcycle documents approved and unexpired.
- Ride eligibility includes the required extra passenger helmet.
- Zone rules.
- Office rules.

The radius expands approximately every 20 seconds during the 90-second
window. Nearby discovery must use PostGIS/database logic, not paid routing
APIs. This progressive dispatch is **PENDING IMPLEMENTATION**.

---

# 10. Bidding Engine

Driver actions:

```text
ACCEPT CUSTOMER PRICE
COUNTER OFFER
REJECT / IGNORE
```

Offer rules:

- One active offer per driver/order.
- Order must be `BIDDING`.
- Offer amount valid.
- Driver eligible.
- Offer not expired.
- Offer expires with the order bidding window.
- Active offers cannot be edited; an unselected offer may be withdrawn while
  the order is `BIDDING`, after which the driver may submit a new offer.

Withdrawal/new-offer behavior is **IMPLEMENTED** for an owned ACTIVE,
unselected offer while its order remains unexpired `BIDDING`.

---

# 11. Atomic Offer Acceptance

Critical function:

```text
accept_offer(order_id, offer_id)
```

It must:

1. Lock/validate order.
2. Derive customer identity from `auth.uid()` and verify order ownership.
3. Verify order is `BIDDING`.
4. Verify offer active.
5. Verify driver still eligible.
6. Set selected offer.
7. Set driver.
8. Set office if applicable.
9. Set agreed price.
10. Set status `DRIVER_ASSIGNED`.
11. Set assigned timestamp.
12. Close remaining offers.
13. Prevent concurrent double assignment.
14. Return final order state.

This operation must execute atomically.

---

# 12. Order State Machine

Required states:

```text
DRAFT
BIDDING
DRIVER_ASSIGNED
DRIVER_ON_WAY
DRIVER_ARRIVED
IN_PROGRESS
COMPLETED
CANCELLED
EXPIRED
```

State transitions must be validated centrally.

---

# 13. Driver Status Actions

Secure functions may include:

```text
driver_go_online()
driver_go_offline()
driver_on_way(order_id)
driver_arrived(order_id)
start_order(order_id, verification?)
complete_order(order_id, proof?)
```

Each must validate:

- Caller identity.
- Assigned driver.
- Current order state.
- Required conditions.
- Duplicate/retry behavior.

Ride start requires no OTP after trusted Pickup arrival. Delivery start also
requires no Pickup OTP. Delivery completion requires one backend-validated
4-digit Customer Confirmation Code. Milestone 10 enforces the 200-meter
Pickup and 300-meter Destination geofences with Retry and audited trusted
overrides.

---

# 14. Cancellation

Recommended function:

```text
cancel_order(order_id, actor, reason)
```

Backend enforces:

- Customer: `BIDDING` free; `DRIVER_ASSIGNED` with reason;
  `DRIVER_ON_WAY`/`DRIVER_ARRIVED` with reason and `LATE_CANCEL`;
  no direct `IN_PROGRESS` cancellation.
- Three customer late cancellations in a rolling 7 days cause a 24-hour
  booking cooldown and support review.
- Driver: cancellation before `IN_PROGRESS` with mandatory reason; a
  post-assignment cancellation sets `CANCELLED`, never rebids the same order,
  and enables client-side Book Again.
- Three post-assignment driver cancellations in a rolling 7 days flag the
  account for operations review without automatic suspension.
- Cash MVP has no cancellation fee or cancellation debt/wallet logic.

The current backend implements the listed customer state/reason/type matrix
and pre-`IN_PROGRESS` Driver cancellation. Rolling cooldowns and operational
abuse flags remain **PENDING IMPLEMENTATION**.

---

# 15. Expiration

Bidding orders receive a server-owned 90-second expiry. Eligibility checks
reject elapsed orders and trusted expiry closes their ACTIVE offers. Scheduled
cleanup/alerts remain **PENDING IMPLEMENTATION**.

Possible mechanism:

- Scheduled function.
- Cron/pg_cron.
- Edge Function.
- Lazy validation combined with scheduled cleanup.

Expired order:

```text
status = EXPIRED
```

Active offers close.

---

# 16. Realtime

Use Realtime for:

- New offers to customer.
- Offer status to driver.
- Order state changes.
- Driver assignment.
- Driver live location.
- Account status where useful.

Clients must re-fetch authoritative state after reconnect.

---

# 17. Driver Location

Recommended table:

```text
driver_locations
```

Fields:

```text
driver_id
latitude
longitude
heading
speed
accuracy
updated_at
```

MVP may keep only the latest location per driver.

Do not store unlimited location history unless required.

---

# 18. Storage

Supabase Storage buckets may include:

```text
profile-images
driver-documents
motorcycle-images
delivery-proof
```

Storage policies must enforce ownership and authorized admin access.

---

# 19. Notifications

Store device tokens.

Recommended table:

```text
device_tokens
```

Push events include:

- New request.
- New offer.
- Offer selected.
- Driver on way.
- Driver arrived.
- Trip started.
- Trip completed.
- Cancellation.
- Expiration.
- Driver approval/suspension.

FCM sending may be implemented through Edge Functions or secure server-side logic.

---

# 20. Suggested Price

Suggested Price is informational guidance and is calculated from configurable
Base + Distance Component values.

If enabled, backend may calculate:

```text
base + distance component
```

It must not override bidding.

Customer may submit a proposal at or above 70% of Suggested Price. There is
no business maximum. The proposal is immutable after `BIDDING`.

The Suggested Price engine and minimum rule are **PENDING IMPLEMENTATION**.

---

# 21. Commission

Commission values are configurable and must not be hardcoded in clients:

- Independent Driver: 10% of `agreed_price`; first 14 days 0%.
- Office business: 7% of `agreed_price` Platform-to-Office; first month 5%.

Required financial concepts include:

```text
platform_commission_amount
office_commission_amount
driver_net_amount
commission_due
platform_balance
```

Cash collection uses a limited Commission Ledger, manual/approved initial
top-up, configurable Independent-driver credit threshold, and weekly Office
settlement/invoice. It is not a full wallet or payment engine. This financial
backend is **PENDING IMPLEMENTATION**.

---

# 22. Audit Logging

Sensitive backend actions should create audit events.

Use explicit trusted operations rather than a generic status editor.
Examples:

- Driver approval.
- Office suspension.
- Permission change.
- `admin_cancel_order`.
- `admin_suspend_driver` / `admin_restore_driver`.
- `admin_correct_order_data`.
- Settings change.

Each event requires actor, reason, timestamp, and before/after values.

`order_events` is **IMPLEMENTED** for order creation/status transitions,
cancellation, and expiry. Explicit trusted admin recovery actions and their
additional audit detail remain **PENDING IMPLEMENTATION**.

---

# 23. System Settings

Recommended key/value configuration:

```text
ride_enabled
delivery_enabled
initial_dispatch_radius_km
max_dispatch_radius_km
dispatch_radius_step_km
dispatch_radius_step_seconds
bidding_duration_seconds
offer_duration_seconds
suggested_price_enabled
commission_enabled
platform_commission_percent
office_commission_percent
independent_promo_days
office_promo_days
operating_zones
```

Frozen defaults are 2/4/6/8 km approximately every 20 seconds, 90-second
bidding/offer expiry, and the commission/promotion values above. Operating
zones initially cover Nasr City, Heliopolis, and New Cairo. Settings remain
**PENDING IMPLEMENTATION** unless listed as current in the canonical freeze.

---

# 24. Idempotency

Critical actions should protect against duplicate requests:

- Order creation.
- Offer creation/update.
- Offer acceptance.
- Start trip.
- Complete trip.
- Cancellation.

Use operation IDs or deterministic uniqueness where practical.

---

# 25. Error Model

Return consistent errors such as:

```text
ORDER_NOT_FOUND
ORDER_NOT_BIDDING
OFFER_EXPIRED
OFFER_NOT_ACTIVE
DRIVER_NOT_ELIGIBLE
ORDER_ALREADY_ASSIGNED
INVALID_STATUS_TRANSITION
PERMISSION_DENIED
OFFICE_SCOPE_VIOLATION
DRIVER_SUSPENDED
CUSTOMER_SUSPENDED
```

Clients should not need to infer errors from raw SQL messages.

---

# 26. Database Migrations

All schema changes must be version-controlled.

Delivery must include:

- Tables.
- Enums.
- Indexes.
- Constraints.
- Functions.
- Triggers.
- RLS policies.
- Seed data where useful.

---

# 27. Performance

Important indexes likely include:

- orders.status
- orders.customer_id
- orders.driver_id
- orders.office_id
- orders.created_at
- offers.order_id
- offers.driver_id
- drivers.office_id
- drivers.status
- driver_locations.driver_id

PostGIS/geospatial indexing is required for nearby-driver discovery and is
**PENDING IMPLEMENTATION**.

---

# 28. Environments

Use separate:

```text
Development
Staging/Test
Production
```

At minimum Development and Production credentials must be isolated.

---

# 29. Backend Acceptance Criteria

Backend is accepted when:

- Auth works.
- RLS prevents cross-user and cross-office access.
- Order creation works.
- Dispatch eligibility works.
- Driver offers work.
- Realtime offers work.
- Atomic offer acceptance prevents double assignment.
- State machine rejects invalid transitions.
- Driver location updates work.
- Cancellation works.
- Expiration works.
- Notifications trigger correctly.
- Audit logs record sensitive actions.
- Migrations rebuild the schema.
- No privileged key exists in mobile/web clients.

---

# 30. Definition of Done

Backend feature is Done only when:

- Schema exists.
- Validation exists.
- Authorization exists.
- RLS exists.
- Errors are defined.
- Race conditions are considered.
- Realtime behavior works when required.
- Tests cover critical paths.
- Migration is committed.

---

**End of Backend & Supabase Technical Requirements Specification**
