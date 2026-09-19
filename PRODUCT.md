# PRODUCT.md
## Motorcycle Mobility & Delivery Platform

## Product Goal
Build a motorcycle-only mobility and delivery platform with two MVP services:

1. Passenger Ride
2. Parcel Delivery

## Core Business Model

```text
Customer creates order
→ Customer proposes price
→ Eligible drivers receive request
→ Driver accepts customer price OR submits counter-offer
→ Customer sees multiple offers
→ Customer selects one offer
→ Exactly one driver is assigned
→ Trip / Delivery progresses to completion
```

There is no mandatory fixed fare in the MVP.

A configurable Suggested Price (`Base + Distance Component`) provides guidance only. Customer proposals start at 70% of that guidance, and the customer manually selects the winning driver offer.

## User Types

### Customer
- Email + Password authentication
- Create Ride or Delivery orders
- Select pickup and destination
- Propose a price
- Receive multiple driver offers
- Select one driver
- Track order state
- Rating is deferred (not part of the current MVP; see DESIGN.md §49)
- View order history

### Driver
Types:
- Independent Driver
- Office Driver

Lifecycle:

```text
Account
→ Driver Application
→ Motorcycle
→ Documents
→ PENDING
→ Review
→ ACTIVE / REJECTED / SUSPENDED
```

Only ACTIVE drivers may go Online and receive requests.

### Office
Can manage office-scoped:
- Drivers
- Motorcycles
- Orders
- Staff

An Office Driver belongs to one office at most. Platform-to-Office commission is separate from the office's internal driver compensation.

### Platform Admin
Platform-wide management according to roles and permissions.

## Authentication

MVP:

```text
Email + Password
```

Phone OTP / SMS:

```text
OUT OF MVP SCOPE
```

Reason: avoid recurring SMS cost.

## Dashboard Model

ONE unified dashboard codebase.

Access is controlled by:

```text
Role + Permissions + Data Scope
```

Roles:

```text
SUPER_ADMIN
OFFICE_ADMIN
OFFICE_DISPATCHER
OFFICE_ACCOUNTANT
```

Office data isolation must be enforced by Supabase RLS/backend.

## Core Order States

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

Normal flow:

```text
BIDDING
→ DRIVER_ASSIGNED
→ DRIVER_ON_WAY
→ DRIVER_ARRIVED
→ IN_PROGRESS
→ COMPLETED
```

## Offer States

```text
ACTIVE
SELECTED
REJECTED
WITHDRAWN
EXPIRED
CLOSED
```

Exactly one offer may win.

`accept_offer()` must be atomic and prevent double assignment.

## MVP Payment

```text
CASH
```

Wallet and online payment are deferred.

Commercial model:

```text
Independent Driver → 10% Platform commission
Office Driver      → 7% Platform-to-Office commission
```

Launch promotions and commission collection use configurable settings and a limited commission ledger, not a full wallet or payment engine.

## Initial Market Rollout

The pilot market is East Cairo: Nasr City, Heliopolis, and New Cairo. Both Ride and Delivery remain in development scope. Delivery soft-launches first; Ride is publicly enabled after operational, safety, legal, and licensing launch gates pass.

Detailed frozen behavior is defined in `docs/BUSINESS_RULES_FREEZE_V1.md`.

## Technology Stack

```text
User App       → Flutter
Driver App     → Flutter
State          → Riverpod
Navigation     → go_router
Backend        → Supabase
Database       → PostgreSQL inside Supabase
Realtime       → Supabase Realtime
Storage        → Supabase Storage
Maps           → Google Maps
Location       → geolocator
Push           → Firebase Cloud Messaging
Dashboard      → Next.js + TypeScript
Dashboard UI   → Tailwind + shadcn/ui
```

## UI Product Reference

The current mobile presentation authority is `DESIGN.md` v2: Biko's own red,
charcoal and white identity, Cairo typography, and Arabic-first RTL experience.
The earlier Ana Vodafone reference is superseded; it is not a current acceptance
target. The approved reference board still needs to be supplied for exact visual
comparison. Current execution and verification status lives in
`docs/USER_APP_EXECUTION_PLAN.md`.

Retain these practical layout principles:

- dashboard-style home
- clean white surfaces
- modular rounded cards
- quick-action tiles
- strong visual hierarchy
- compact information blocks
- clear bottom navigation
- prominent top summary area
- practical Arabic-first RTL experience
- polished but not visually overloaded

Use the project’s own name, logo, content, icons, and product-specific data.

Do not include Vodafone branding assets.

## Product Priority

```text
1. Working backend core
2. Secure bidding
3. Correct driver assignment
4. Complete trip lifecycle
5. Functional Driver App
6. Functional User App
7. Apply the Biko UI system in DESIGN.md v2
8. Maps + live location
9. Realtime
10. Push notifications
11. Unified Dashboard
12. Verification / operations
13. Basic finance
14. Security hardening
15. Production release
```

## First Major Product Checkpoint

```text
Customer creates order
→ Multiple drivers submit offers
→ Customer selects one
→ Exactly one driver is assigned
→ Driver completes the order
```

## Out of MVP Scope

- Phone OTP / SMS
- Wallet
- Online payments
- Promo codes
- Loyalty
- Subscriptions
- Advanced chat
- Multi-stop orders
- Scheduled orders
- AI dispatch
- Advanced settlement
- Advanced accounting
- Referral system
- Advanced BI
- Call masking
- Multiple active driver jobs
