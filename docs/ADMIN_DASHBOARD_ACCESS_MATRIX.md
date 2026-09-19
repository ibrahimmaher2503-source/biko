# Admin / Office Dashboard Access Matrix

**Status:** Source/target specification only — no SQL, role seed, RLS policy, or
remote environment change is made by this document.

**Scope:** The single Admin/Office Dashboard required by
`Unified_Admin_Office_Dashboard_Requirements_EN.md`.

## How to read this document

- **Frozen** means the product rule is already approved in
  `BUSINESS_RULES_FREEZE_V1.md` and must not be changed here.
- **Existing** means the key or role is present in the local foundation seed
  (`supabase/migrations/202608290001_foundation.sql`). It is not proof that the
  Dashboard UI or a trusted write function exists.
- **Proposed** means a least-privilege implementation shape needed to cover the
  Dashboard requirements. It is not a new product approval and must not be
  treated as a granted role until its backend function, RLS, audit behavior, and
  acceptance evidence exist.
- **R** = permitted read, **W** = permitted create/edit/manage, **A** = a
  sensitive action through an explicit trusted function. `—` is deny by default.
- A cell marked **opt-in** is deliberately not part of a baseline role grant.

## Non-negotiable scope rules

1. There is one Dashboard frontend for platform and office staff. There is no
   separate Office Dashboard.
2. `PLATFORM` scope is available only to an active staff identity with an
   explicitly assigned platform role. `OFFICE:<office_id>` requires the active
   profile, an active `office_members` row for that exact office, the active
   office, and the permission on that membership's role.
3. Selecting an office in a filter, URL, or form **never grants access**. It is
   only a requested target; the server must re-evaluate membership, role, and
   permission for every read and write. A valid membership is not revoked by
   changing or clearing the UI selection; the selector may narrow presentation,
   never broaden authorization.
4. The effective Wave A authorization path is `private.can_access_office()` for
   office data. `private.has_permission()` is not sufficient for office data;
   Wave A explicitly documents it as a global/reference permission check.
5. Wave A requires an active profile, active office membership, and active office
   for office-role access. An inactive profile or inactive membership denies
   access. An inactive office denies office-role access; an active Super Admin
   remains platform-scoped and may retain suspended-office recovery visibility,
   subject to trusted action and audit rules. An inactive profile also denies
   Super Admin recognition.
6. Customer, Driver, and anonymous identities are not Dashboard staff. Anonymous
   access is limited to the explicitly public reference read for `service_types`.
   The current helper predicates do not themselves check `profiles.profile_type`;
   a Dashboard guard and trusted staff-role assignment path must enforce
   `STAFF` before claiming this boundary is complete.
7. Existing authenticated table privileges are read-oriented. Dashboard writes
   and sensitive actions must use trusted server functions with actor, reason,
   timestamp, before/after values, and audit evidence. No generic order-status
   editor is allowed.

## Evidence baseline

| Source | Relevant evidence |
|---|---|
| `docs/Unified_Admin_Office_Dashboard_Requirements_EN.md:15-167` | One frontend; roles, permission model, `PLATFORM`/`OFFICE`/`SELF`/`CUSTOM` scope, Email + Password. |
| `docs/Unified_Admin_Office_Dashboard_Requirements_EN.md:297-363` | Office Admin may prepare drivers; only trusted Platform verification roles perform final driver transitions; office-change workflow is pending. |
| `docs/Unified_Admin_Office_Dashboard_Requirements_EN.md:408-467` | Platform-level office management and conditional office staff management. |
| `docs/Unified_Admin_Office_Dashboard_Requirements_EN.md:519-586` | Role management, audit fields, explicit trusted actions, RLS and server-side checks. |
| `docs/BUSINESS_RULES_FREEZE_V1.md:32-54` | One office per Office Driver; trusted office change; Office Admin cannot final-approve. |
| `docs/BUSINESS_RULES_FREEZE_V1.md:102-140` | Cash-only finance, office permissions, lifecycle timeline, explicit trusted admin operations. |
| `supabase/migrations/202608290001_foundation.sql:10-135,199-269` | Current roles, current permission keys, table shape, and current role seeds. |
| `supabase/migrations/202608300001_authorization_rls.sql:1-93,106-237` | Initial helper predicates, grants, and SELECT RLS. |
| `supabase/migrations/202608300009_wave_a_security_transaction_integrity.sql:1-67` | Effective Wave A active-profile/member/office checks and office-scoped authorization. |
| `docs/evidence/admin-dashboard-wave0-catalog-20260919.json` | Read-only catalog snapshot: `ACTIVE_HEALTHY`, 17 applied migrations through the M10 legacy fix, exactly four seeded roles and 26 seeded permissions; no behavioral acceptance was rerun. |

## Current role seeds (Existing, not a completion claim)

Only these four roles are seeded locally. `PLATFORM_OPERATIONS`, `SUPPORT_AGENT`,
and `VERIFICATION_AGENT` are proposed role names; they are absent from the
foundation seed and must not be presented as live roles.

| Role | Scope type | Existing seeded keys |
|---|---|---|
| `SUPER_ADMIN` | `PLATFORM` | All 26 existing foundation keys listed below. This does not include proposed keys. |
| `OFFICE_ADMIN` | `OFFICE` | `dashboard.view`, `orders.view`, `orders.manage`, `orders.cancel`, `bids.view`, `drivers.view`, `drivers.create`, `drivers.edit`, `motorcycles.view`, `motorcycles.create`, `motorcycles.edit`, `reports.view`, `finance.view`. |
| `OFFICE_DISPATCHER` | `OFFICE` | `dashboard.view`, `orders.view`, `orders.manage`, `bids.view`, `drivers.view`, `motorcycles.view`. |
| `OFFICE_ACCOUNTANT` | `OFFICE` | `dashboard.view`, `orders.view`, `reports.view`, `finance.view`. |

The existing `OFFICE_ADMIN.finance.view` grant is recorded and preserved as a
seed fact. This document neither removes nor broadens it; finance remains
office-scoped and read-only unless a separate trusted financial operation is
implemented.

### Existing permission keys

`dashboard.view`, `orders.view`, `orders.manage`, `orders.cancel`, `bids.view`,
`drivers.view`, `drivers.create`, `drivers.edit`, `drivers.verify`,
`drivers.activate`, `drivers.suspend`, `motorcycles.view`, `motorcycles.create`,
`motorcycles.edit`, `users.view`, `offices.view`, `offices.create`,
`offices.edit`, `offices.suspend`, `reports.view`, `finance.view`, `roles.view`,
`roles.manage`, `settings.view`, `settings.manage`, `audit.view`.

### Proposed permission keys

These keys are recommended by the Dashboard requirements but are absent from
the foundation seed:

| Proposed key | Why it is needed | Default grant |
|---|---|---|
| `orders.override` | Explicit trusted recovery/correction path; never a generic status editor. | None; explicit opt-in only. |
| `bids.manage` | Requirements mention bid management, but frozen rules prohibit generic manual bidding-result changes. | None until a named trusted operation exists. |
| `motorcycles.verify` | Separate motorcycle evidence/review action. | Verification role only, after backend support. |
| `users.manage` / `users.suspend` | Support/customer lifecycle actions when explicitly approved. | None; opt-in trusted actions only. |
| `office_members.manage` | Conditional Office Admin staff management from the requirements. | Office Admin on its own office only, after backend support; no self-elevation. |
| `finance.credit_topup` | Approved/manual Independent-driver platform-credit top-up. | None; Super Admin opt-in trusted operation only until workflow exists. |
| `finance.office_settle` | Record confirmed weekly Office settlement/collection. | None; proposed trusted Platform finance action only. Office Accountant reads its own statement; it cannot approve its own payment or clear its own liability. |
| `drivers.office_change.request` | Trusted Office Driver change request. | None; proposed Office Admin own-office request only after the change-request workflow exists. |
| `drivers.office_change.approve` | Platform approval with historical order-office snapshots. | None; proposed Super Admin/trusted Platform approver only after the workflow exists. |
| `drivers.restore` | Explicit driver restore/reactivation action, distinct from initial activation. | None; proposed trusted Platform Verification/Super Admin operation only. |

All proposed financial and office-change keys are action grants, not additions
to `finance.view`; none is present in the current foundation seed.

`drivers.verify`, `drivers.activate`, and `drivers.suspend` already exist as
permission keys but are not seeded to Office Admin, Dispatcher, or Accountant.
They belong to the proposed trusted Platform Verification role, not to office
roles.

### Proposed baseline role assignments (not granted)

The following lists make the proposal reviewable without implying that any
missing role or key already exists. `opt-in` remains outside the baseline.

| Proposed role | Proposed baseline keys |
|---|---|
| `PLATFORM_OPERATIONS` | `dashboard.view`, `orders.view`, `orders.manage`, `bids.view`, `drivers.view`, `motorcycles.view`, `users.view`, `offices.view`, `reports.view`. `audit.view` is opt-in. No `finance.view`, `roles.*`, `settings.*`, `orders.cancel`, or `orders.override`. |
| `SUPPORT_AGENT` | `dashboard.view`, `orders.view`, `bids.view`, `drivers.view`, `users.view`. `audit.view` is opt-in. `orders.override`, cancellation/recovery, suspension, and safety override are separate opt-in trusted actions. |
| `VERIFICATION_AGENT` | `dashboard.view`, `drivers.view`, `drivers.verify`, `drivers.activate`, `drivers.suspend`, `motorcycles.view`. `motorcycles.verify` and `audit.view` require explicit backend support/approval. |

The existing office role assignments remain the seed facts shown above. The
only proposed addition to Office Admin is conditional
`office_members.manage`, limited to the member's own office and unable to grant
platform roles or elevate the acting user.

## Role and scope target matrix

This is the least-privilege target shape. `Existing` identifies current seed
facts; `Proposed` identifies an implementation proposal only.

| Role | Seed status | Target scope | Baseline target capabilities |
|---|---|---|---|
| Super Admin | Existing `SUPER_ADMIN` | `PLATFORM` | Existing platform-wide keys; proposed trusted functions for verification, recovery, role/settings changes, and audit. No proposed key is assumed granted. |
| Platform Operations | **Proposed role; absent** | `PLATFORM` | Proposed operational reads and permitted operational management: dashboard, orders, bids read, drivers/motorcycles read, users/offices read, operational reports. No finance, roles, settings, or override by default. |
| Support Agent | **Proposed role; absent** | `PLATFORM` or explicit `CUSTOM` target | Proposed support reads for users, orders, bids, permitted operational history. `orders.override`, cancellation/recovery, suspension, and safety override are opt-in trusted actions, never blanket defaults. |
| Verification Agent | **Proposed role; absent** | `PLATFORM` | Proposed driver/document review and final verification transitions; motorcycle review only after `motorcycles.verify` and its trusted function exist. No office finance or role management. |
| Office Admin | Existing `OFFICE_ADMIN` | `OFFICE:<membership.office_id>` | Existing office driver/motorcycle/order/report keys. Staff management is conditional on proposed `office_members.manage`; no final driver approval, no office reassignment, no platform settings/roles. |
| Office Dispatcher | Existing `OFFICE_DISPATCHER` | `OFFICE:<membership.office_id>` | Existing orders, bids read, drivers/motorcycles, and permitted live operations. No finance, staff, verification, or platform settings. |
| Office Accountant | Existing `OFFICE_ACCOUNTANT` | `OFFICE:<membership.office_id>` | Existing orders/report/finance summaries for the member office only. No operational mutation, verification, staff, or role management. |

## Read / write / action matrix

`E` = existing seeded capability for that role; `P` = proposed least-privilege
capability; `O` = explicit opt-in only; `F` = frozen action rule that still
requires a trusted backend operation; `—` = deny by default. All office cells
mean the exact active membership office, never an office selected by the UI.

| Domain | Super Admin (`PLATFORM`) | Platform Operations (`PLATFORM`, proposed) | Support (`PLATFORM`/`CUSTOM`, proposed) | Verification (`PLATFORM`, proposed) | Office Admin (`OFFICE`) | Dispatcher (`OFFICE`) | Accountant (`OFFICE`) |
|---|---|---|---|---|---|---|---|
| Overview / scoped KPIs | R E | R P | R P | R P | R E | R E | R E |
| Live operations: permitted orders/drivers | R E | R P | R O | — | R E | R E | — |
| Orders: list/detail/timeline | R E | R P | R P | — | R E | R E | R E |
| Orders: permitted operational management | W E | W P | — | — | W E | W E | — |
| Orders: cancellation | A E/F; trusted function only | O; named function only | O; named function only | — | A E/F; trusted function only | — | — |
| Orders: override/recovery/correction | A O/P; `orders.override` absent today | O/P; explicit grant only | O/P; explicit grant only | — | — | — | — |
| Bids/offers: view | R E | R P | R P | — | R E | R E | — |
| Bids/offers: manage result | —; generic change forbidden | — | — | — | — | — | — |
| Drivers: list/detail/history | R E | R P | R P | R P | R E | R E | — |
| Drivers: create/edit/invite | W E | O/P | — | — | W E | — | — |
| Driver verification/rejection/activation/suspension | A E/F; trusted verifier function | — | — | A P/F; trusted verifier function | — | — | — |
| Driver restore/reactivation | A O/P; `drivers.restore` proposed | — | — | A O/P; explicit trusted function | — | — | — |
| Driver office-change request | A O/P; `drivers.office_change.request` proposed | — | — | — | A O/P on own office only | — | — |
| Driver office-change approval/snapshot | A O/P; `drivers.office_change.approve` proposed | O/P only if separately appointed approver | — | — | — | — | — |
| Motorcycles: list/detail | R E | R P | O/P | R P | R E | R E | — |
| Motorcycles: create/edit | W E | O/P | — | — | W E | — | — |
| Motorcycle evidence verification | A O/P | — | — | A O/P; `motorcycles.verify` proposed | — | — | — |
| Customers/users: view | R E | R P | R P | — | — | — | — |
| Customers/users: manage/suspend | A O/P | — | O/P; `users.manage`/`users.suspend` proposed | — | — | — | — |
| Offices: list/detail | R E | R P | — | — | R E via own office scope where policy allows | — | — |
| Offices: create/edit/suspend | W E | — | — | — | — | — | — |
| Office staff / `office_members` | W O/P; platform role assignment | — | — | — | W O/P on own office only | — | — |
| Reports | R E | R P | O/P | — | R E | — | R E |
| Finance summaries / ledger views | R E | — | — | — | R E* | — | R E |
| Independent-driver credit top-up | A O/P; `finance.credit_topup` proposed | — | — | — | — | — | — |
| Weekly Office settlement/invoice | A O/P; `finance.office_settle` proposed | — | — | — | R E within finance scope | — | R E on own office; no self-approval of collection |
| Roles and permissions | W E | — | — | — | — | — | — |
| Platform settings | W E | — | — | — | — | — | — |
| Audit log | R E | O/P | O/P | O/P | — | — | — |

`*` The existing Office Admin `finance.view` seed is intentionally shown, not
endorsed as a new product decision. It remains a current scoped read seed;
finance is cash-only and does not imply wallet, cash-out, payroll, or advanced
settlement. Any future seed change needs its own implementation decision.

### Existing policy/target mismatch: Accountant offer reads

The current applied-migration source grants office `offers` SELECT through
`private.can_access_office(office_id, 'orders.view')`. Therefore an existing
Office Accountant with `orders.view` can currently SELECT permitted office
offers even though the Accountant seed does not include `bids.view`. The matrix
target keeps offer reads separate from order reads, but this is a policy/target
mismatch, **not** evidence that the current database already denies the read.
Resolve it with an explicit projection/RLS policy decision before claiming the
target matrix is accepted; no SQL change is made here.

## Required negative and mixed-membership cases

### Accountant A + Dispatcher B

Assume one active staff profile has two active memberships:

- Office A membership: `OFFICE_ACCOUNTANT`.
- Office B membership: `OFFICE_DISPATCHER`.

The effective result is evaluated per target office and per membership role:

| Target | Allowed baseline | Denied baseline |
|---|---|---|
| Office A | `dashboard.view`, `orders.view`, `reports.view`, `finance.view` from the Accountant membership. | `orders.manage`, `bids.view`, driver/motorcycle operational reads, staff management, and verification. |
| Office B | `dashboard.view`, `orders.view`, `orders.manage`, `bids.view`, `drivers.view`, `motorcycles.view` from the Dispatcher membership. | `reports.view`, `finance.view`, staff management, verification, and platform settings. |
| Any other office C | Nothing unless a separate active C membership exists with the required role permission. | All reads and writes. |

The global availability of a permission in `has_permission()` must not turn the
Accountant A membership into Accountant B access; office rows use
`can_access_office(target_office, permission)`.

### Inactive identities and memberships

| State | Required result |
|---|---|
| Inactive/suspended profile | No Dashboard operation; no Super Admin recognition; no office access. |
| Active profile + inactive `office_members` row | No access to that membership's office. |
| Active profile + active membership + inactive/suspended office | No office-role access to that office; an active Super Admin remains platform-scoped under the Wave A recovery rule. |
| Active profile + active membership + active office | Evaluate the membership role's permission for the exact target office. |
| Suspended/deleted staff with a stale browser session | Server rejects reads and writes; UI hiding is not the security boundary. |

### Non-staff identities

| Identity | Dashboard result |
|---|---|
| Anonymous | Deny Dashboard; only public `service_types` reference read remains. |
| Customer | Deny Dashboard; no staff role or office membership. Customer app ownership rules remain separate. |
| Driver | Deny Dashboard; Driver app scope remains separate. A driver must not receive Dashboard access merely because `drivers.office_id` is set. |
| Staff without a role | Deny Dashboard except an explicit bootstrap path that assigns a role through trusted administration. |

## Acceptance checklist for this matrix

1. Verify the two seeded office roles and one seeded accountant against the
   exact office scope; verify Super Admin platform scope.
2. Verify Accountant A + Dispatcher B with positive reads in A/B and negative
   cross-permission reads in each office.
3. Verify inactive profile, inactive member, inactive office, stale session,
   Customer, Driver, and anonymous denial.
4. Verify an office selector and a forged office ID do not change server-side
   authorization.
5. Verify Office Admin can prepare/submit a driver for review but cannot execute
   final approval, rejection, or suspension.
6. Verify Support/Operations cannot invoke safety override or order recovery
   without an explicit trusted permission/function, reason, actor, timestamp,
   before/after values, and audit record.
7. Verify no generic order-status editor, role self-elevation, cross-office
   office-member write, or browser Service Role Key exists.

## Explicit non-claims

- This document does not claim that the proposed platform roles, proposed keys,
  trusted admin functions, audit table, office-change workflow, or complete
  Dashboard UI are implemented.
- No live behavioral acceptance was performed for this artifact. The local
  catalog snapshot is inventory evidence only; deployment must revalidate the
  applied migration state and behavior before acceptance.
- No SQL, code, seed, RLS, remote, or build change is authorized by this file.
- This document is not an authorization gate and must never be used as one; the
  applied backend/RLS/trusted functions enforce access, while the frozen rules
  document remains the product-behavior authority.
