# Unified Admin / Office Dashboard
## Product & Functional Requirements Specification

**Project:** Motorcycle Mobility & Delivery Platform  
**Component:** Unified Admin / Office Web Dashboard  
**Version:** 1.0  
**Status:** MVP Implementation Specification  
**Recommended Stack:** Next.js + TypeScript + Supabase  
**Date:** August 28, 2026

> **Purpose:** Define a single dashboard codebase that serves platform administration and delivery offices through Roles, Permissions, and Data Scope.

---

# 1. Core Architecture Principle

There must be **one dashboard application and one codebase**.

The same frontend serves:

- Super Admin.
- Platform Operations.
- Support.
- Verification Staff.
- Office Admin.
- Office Dispatcher.
- Office Accountant.
- Future roles.

Access is controlled by:

```text
Role
+ Permissions
+ Data Scope
```

No separate Office Dashboard frontend should be built for the MVP.

---

# 2. Primary Roles

## 2.1 Super Admin

Platform-wide access according to assigned permissions.

## 2.2 Platform Operations

Can manage operational data without necessarily accessing sensitive financial/security settings.

## 2.3 Verification Agent

Can review driver and motorcycle documents.

## 2.4 Support Agent

Can inspect users, orders, bids, and operational history according to permission.

## 2.5 Office Admin

Can access only the office's own drivers, motorcycles, staff, orders, and
reports, subject to permissions.

## 2.6 Office Dispatcher

Can access only the office's own orders, drivers, and live operations,
subject to permissions.

## 2.7 Office Accountant

Can access only the office's own finance and reports, subject to permissions.

---

# 3. Permission Model

Recommended permission keys:

```text
dashboard.view

orders.view
orders.manage
orders.cancel
orders.override

bids.view
bids.manage

drivers.view
drivers.create
drivers.edit
drivers.verify
drivers.activate
drivers.suspend

motorcycles.view
motorcycles.create
motorcycles.edit
motorcycles.verify

users.view
users.manage
users.suspend

offices.view
offices.create
offices.edit
offices.suspend

reports.view
finance.view

roles.view
roles.manage

settings.view
settings.manage

audit.view
```

Permissions determine **what action can be performed**.

---

# 4. Data Scope Model

Data Scope determines **which records can be accessed**.

Recommended scopes:

```text
PLATFORM
OFFICE:<office_id>
SELF
CUSTOM
```

Examples:

```text
Super Admin
scope = PLATFORM

Office Admin
scope = OFFICE:15

Office Dispatcher
scope = OFFICE:15

Office Accountant
scope = OFFICE:15
```

Office users must never access another office's protected data, even through direct API calls.

---

# 5. Authentication

Use Supabase Auth.

Dashboard MVP authentication uses Email + Password. Phone OTP / SMS and
Magic Link are out of the approved MVP authentication scope. Privileged
administrative MFA may be required before public launch.

---

# 6. Main Navigation

Recommended sections:

1. Overview
2. Live Operations
3. Orders
4. Drivers
5. Motorcycles
6. Users
7. Offices
8. Bids / Offers
9. Verification
10. Reports
11. Roles & Permissions
12. Settings
13. Audit Log

Navigation items must be permission-aware.

---

# 7. Overview Dashboard

Possible KPI cards:

- Total orders today.
- Active orders.
- Bidding orders.
- Completed orders.
- Cancelled orders.
- Online drivers.
- Active drivers.
- Independent drivers.
- Office drivers.
- Active offices.
- Gross completed order value.

Office-scoped users see only office-scoped KPIs.

---

# 8. Live Operations

Live operational view should include:

- Map.
- Online drivers.
- Assigned drivers.
- Active rides/deliveries.
- Pickup/destination markers where permitted.
- Order status.
- Driver status.
- Office filter for Platform users.
- Service Type filter.
- Status filter.

Office users only see their own drivers/orders.

---

# 9. Orders Management

Order list columns may include:

```text
Order ID
Service Type
Customer
Driver
Office
Customer Offer
Agreed Price
Status
Created At
Assigned At
Completed At
```

Filters:

- Date.
- Status.
- Service Type.
- Office.
- Driver.
- Customer.
- Payment Method.

Order details should include:

- Full lifecycle timeline.
- Pickup and destination.
- Customer proposed price.
- Selected offer.
- Agreed price.
- Driver.
- Motorcycle.
- Office.
- Bid history.
- Cancellation details.
- Core timestamps.
- Audit events related to manual intervention.

---

# 10. Bids / Offers

Admin/support may view:

- Order.
- Driver.
- Office.
- Offered amount.
- Offer status.
- Created/updated time.
- Selected offer.

The dashboard must clearly identify the winning offer.

There is no generic manual change to bidding results. Any recovery must use
an explicit trusted action with actor, reason, timestamp, before/after values,
and audit log.

---

# 11. Driver Management

Driver list may include:

```text
Driver ID
Name
Phone
Driver Type
Office
Status
Online Status
Rating
Completed Trips
Motorcycle
```

Available actions depend on permission:

- View.
- Create.
- Edit.
- Submit for verification.
- Review documents.
- View history.
- View current location.
- Request office change through the trusted Change Request workflow.

Office Admin may create/invite drivers, review their data, assist with
documents, and submit them for verification. Only trusted Platform
verification roles may perform `PENDING -> ACTIVE`, `PENDING -> REJECTED`,
or `ACTIVE -> SUSPENDED`. An Office Driver belongs to one office maximum;
office changes require Platform Admin approval and preserve historical order
office snapshots. The change-request/snapshot workflow is **PENDING
IMPLEMENTATION**.

---

# 12. Driver Verification

Verification page should support:

- Driver identity documents.
- Driving license.
- Motorcycle documents.
- Driver photo.
- Document status.
- Expiry date.
- Rejection reason.
- Verification actor.
- Verification timestamp.

Recommended document statuses:

```text
PENDING
APPROVED
REJECTED
EXPIRED
```

Verification actions must be auditable.

Motorcycle evidence belongs in a dedicated `motorcycle_documents` concept/
table. This schema/workflow is **PENDING IMPLEMENTATION**.

---

# 13. Motorcycle Management

Motorcycle fields may include:

- Plate.
- Brand.
- Model.
- Color.
- Model year.
- Driver.
- Office.
- Status.
- Photos.
- Document status.

Office Admin may manage only office motorcycles.

---

# 14. User Management

Customer list:

- User ID.
- Name.
- Phone.
- Status.
- Total orders.
- Completed orders.
- Cancelled orders.
- Created date.

Allowed actions may include:

- View profile.
- View order history.
- Suspend/activate customer.
- Review support issues.

Sensitive personal data must be minimized.

---

# 15. Office Management

Platform-level page only unless specific permission exists.

Office data:

```text
Office ID
Office Name
Responsible Person
Phone
Address/Area
Status
Driver Count
Motorcycle Count
Completed Orders
Created At
```

Actions:

- Create office.
- Edit office.
- Activate.
- Suspend.
- View office drivers.
- View office motorcycles.
- View office orders.
- View office reports.
- Configure office-specific commission if enabled.

The frozen platform commission is 7% of `agreed_price` for Office business,
with a configurable launch rate of 5% for the first month. The relationship
is Platform-to-Office; internal driver compensation remains the Office's
responsibility. Ledger/settlement implementation is **PENDING
IMPLEMENTATION**.

---

# 16. Office Staff

The system should support multiple users under one office.

Recommended entity:

```text
office_members
```

Fields:

```text
user_id
office_id
role_id
status
created_at
```

Office Admin may manage staff only if permission is enabled.

---

# 17. Reports

MVP reports:

- Orders by date/status.
- Ride vs Delivery.
- Completed orders.
- Cancelled/Expired orders.
- Gross agreed price value.
- Drivers by Independent/Office.
- Drivers by office.
- Online drivers.
- Offers per order.
- Average agreed price.
- Office performance.
- Driver performance.
- Ratings.

Reports must automatically respect Data Scope.

---

# 18. Settings

Recommended Admin settings:

- Ride enabled/disabled.
- Delivery enabled/disabled.
- Dispatch radii: 2/4/6/8 km, expanding approximately every 20 seconds.
- Bidding and offer expiration: 90 seconds.
- Suggested Price: configurable Base + Distance Component with 70% minimum
  customer proposal.
- Frozen customer and driver cancellation thresholds/reasons.
- Driver required documents.
- Motorcycle required documents.
- Commission and launch-promotion configuration (Independent 0% for 14 days,
  then 10%; Office 5% for one month, then 7%).
- Operating zones, initially Nasr City, Heliopolis, and New Cairo.
- Location tracking settings.
- Notification toggles.

Only authorized roles may edit settings.

These configurable settings are **PENDING IMPLEMENTATION** unless explicitly
listed as implemented in `BUSINESS_RULES_FREEZE_V1.md`.

---

# 19. Roles & Permissions Management

Super Admin may:

- Create Role.
- Rename Role.
- Assign permissions.
- Remove permissions.
- Assign role to user.
- Assign office-scoped role.

The system should not hardcode all authorization logic directly into UI components.

---

# 20. Audit Log

Audit log should record sensitive actions such as:

- Login where needed.
- Role change.
- Permission change.
- Driver approval/rejection.
- Driver suspension.
- Office suspension.
- Explicit trusted order cancellation/recovery.
- Driver restore/suspension and approved office-change requests.
- Corrective order-data actions.
- Settings change.

Recommended fields:

```text
id
actor_user_id
actor_role
office_id
action
entity_type
entity_id
old_value
new_value
reason
ip_address_if_available
created_at
```

Do not provide a generic "change order status to anything" editor. Sensitive
changes use explicit trusted functions and always capture actor, reason,
timestamp, and before/after values.

---

# 21. Security Requirements

Mandatory:

- Supabase Auth.
- RLS.
- Server-side permission validation.
- Office data isolation.
- No Service Role Key in browser.
- Sensitive actions use secure functions.
- Authorization checks cannot rely only on hidden buttons.
- All lists and detail pages must respect scope.
- Suspended dashboard users cannot operate.

---

# 22. UI Requirements

- Responsive desktop/tablet design.
- Arabic-first with RTL.
- English-ready localization.
- Tables with filters.
- Search.
- Pagination.
- Clear status badges.
- Confirmation dialogs for sensitive actions.
- Toast/error feedback.
- Loading/skeleton states.
- Empty states.
- Permission-aware navigation.

---

# 23. MVP Acceptance Criteria

The Dashboard is accepted when:

- Super Admin sees platform-wide data.
- Office Admin uses the same dashboard codebase.
- Office Admin sees only their office data.
- Office user direct API attempts against another office fail.
- Driver CRUD and verification work.
- Motorcycle management works.
- Orders and bids are visible with correct relations.
- Live Operations shows permitted active drivers/orders.
- Roles & Permissions correctly affect UI and backend access.
- Basic reports work.
- Settings can be changed by authorized users.
- Audit events are recorded for sensitive actions.

---

# 24. Explicitly Out of MVP Unless Approved

- Advanced BI.
- Complex accounting.
- Payroll.
- Advanced settlement engine.
- White-label office dashboards.
- Separate office frontend.
- AI operations.
- Complex CRM.
- Advanced support ticketing.

---

# 25. Definition of Done

A dashboard feature is Done only when:

- UI works.
- Backend integration works.
- Permission checks work.
- Data Scope works.
- RLS works.
- Loading/error states exist.
- Audit is recorded when required.
- Tested with at least Super Admin and Office Admin accounts.

---

**End of Unified Admin / Office Dashboard Requirements Specification**
