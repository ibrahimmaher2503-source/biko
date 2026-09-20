# Development Dashboard Acceptance Fixture

Status: `PROVISIONED` / `ADM03_ACCEPTED`

The Development fixture was provisioned and accepted on 2026-09-20. Exact
non-secret identities and IDs are recorded in
`evidence/admin-dashboard-adm03-adm09-acceptance-20260920.json`.

## Environment gate (last observed)

The latest recorded environment sequence is:

```text
project_ref: jlkzgsgfzolhwraakhbt
initial_project_status: INACTIVE
current_coordinator_state: ACTIVE_HEALTHY
migration_inventory: admin Wave 1 plus admin_dashboard_offices applied
fixture_status: PROVISIONED
gate: ADM03_ACCEPTED / ADM09_ACCEPTED
```

The coordinator restored the exact Development project on 2026-09-19, then
applied the bounded admin migrations and provisioned run `ADM03-20260920`.
Email/password login, role context, office isolation, suspended identities,
Office A Browser access, and CUSTOMER denial were observed. D07 remains outside
this acceptance slice.

Recorded external dependencies:

- Hosted Auth redirect allowlist was not exposed by the available management
  connector: `BLOCKED_BY_AUTH_CONFIG_VISIBILITY`. Password login and logout are
  accepted; production redirect configuration still needs deployment evidence.
- No restricted browser Maps key/configuration was supplied:
  `BLOCKED_BY_MAPS_CONFIG`. No map or live-location acceptance is claimed.

ADM-03 is complete because the required fixture and role/scope evidence exist,
and unavailable external configuration is explicitly recorded rather than
silently treated as accepted.

## Reserved identity aliases

Aliases below map to the persistent Development fixture run `ADM03-20260920`.
Never put a password, access token, service-role key, or magic link in this file
or in evidence.

| Alias | Intended identity | Intended scope/status | Current state |
|---|---|---|---|
| `dash.qa.super_admin` | platform Super Admin | `PLATFORM`, active | `PROVISIONED` |
| `dash.qa.platform_ops` | platform Operations | `PLATFORM`, active | `PROVISIONED` |
| `dash.qa.verification` | platform Verification | `PLATFORM`, active | `PROVISIONED` |
| `dash.qa.support` | platform Support | `PLATFORM`, active | `PROVISIONED` |
| `dash.qa.office_a_admin` | Office Admin | `OFFICE:A`, active | `PROVISIONED` |
| `dash.qa.office_a_dispatcher` | Office Dispatcher | `OFFICE:A`, active | `PROVISIONED` |
| `dash.qa.office_a_accountant` | Office Accountant | `OFFICE:A`, active | `PROVISIONED` |
| `dash.qa.office_b_admin` | Office Admin | `OFFICE:B`, active | `PROVISIONED` |
| `dash.qa.office_b_accountant` | Office Accountant | `OFFICE:B`, active | `PROVISIONED` |
| `dash.qa.mixed_membership` | `OFFICE_ACCOUNTANT` in A plus `OFFICE_DISPATCHER` in B | A finance/reports/orders; B drivers/live/orders; no cross-role expansion | `PROVISIONED` |
| `dash.qa.suspended_staff` | suspended dashboard staff | no operational access | `PROVISIONED_DENIED_AS_EXPECTED` |
| `dash.qa.suspended_office` | staff in a suspended office/membership | office scope denied; active platform Super Admin recovery remains separately testable | `PROVISIONED_DENIED_AS_EXPECTED` |
| `dash.qa.customer` | CUSTOMER | no dashboard scope | `PROVISIONED_DENIED_AS_EXPECTED` |
| `dash.qa.driver_a` | OFFICE_DRIVER in Office A | driver self-scope; office data only through permitted staff | `PROVISIONED` |
| `dash.qa.driver_b` | OFFICE_DRIVER in Office B | driver self-scope; office data only through permitted staff | `PROVISIONED` |

`PLATFORM_OPERATIONS`, `SUPPORT`, and `VERIFICATION` must not be faked by
assigning `SUPER_ADMIN`. Their role/permission and trusted-action contracts
are ADM-04/ADM-08 work. The anonymous actor is not an account and must not be
provisioned.

## Office and data fixture aliases

Provisioning must generate a run key and record the actual UUIDs. The names
below are aliases only; no existing row may be assumed.

| Fixture alias | Intended data | Scope expectation |
|---|---|---|
| `office.qa.a` | `QA Dashboard Office A <run-key>` | visible to permitted A/platform users only |
| `office.qa.b` | `QA Dashboard Office B <run-key>` | visible to permitted B/platform users only |
| `driver.qa.a` | active Office A driver with one motorcycle | A/platform only |
| `driver.qa.b` | active Office B driver with one motorcycle | B/platform only |
| `customer.qa` | active customer with isolated test orders | own customer visibility only; no dashboard privilege |
| `order.qa.a` | an authorized Office A order fixture | A/platform only |
| `order.qa.b` | an authorized Office B order fixture | B/platform only |
| `document.qa.a` | current driver/motorcycle document in A | authorized reviewer/storage contract only |
| `document.qa.b` | current driver/motorcycle document in B | authorized reviewer/storage contract only |
| `audit.qa.*` | exact audit/event rows produced by this run | append-only policy; delete only if the Development contract permits it |

Create only the smallest rows needed by the scenario being accepted. Use the
trusted setup path for elevated profiles, office memberships, drivers,
orders, documents, and offers. Do not use public signup to create staff or
write protected tables from the browser.

## Expected scope matrix

| Actor | Allowed positive reads/actions | Required negative result |
|---|---|---|
| Super Admin | platform data and explicitly granted trusted actions | no unapproved generic status editor |
| Office A staff | A drivers, motorcycles, permitted documents, orders, offers, reports | B rows/API/storage denied |
| Office B staff | B equivalents | A rows/API/storage denied |
| Mixed membership | A Accountant may read A finance/reports/orders; B Dispatcher may read B drivers/live/orders | independently authorized A+B rows may be returned; UI selection is display/filter context, never authority |
| Suspended staff | no operational dashboard access | direct reads and actions denied |
| Suspended office staff | no office-scoped operational access | active platform Super Admin may retain permitted recovery visibility/actions |
| CUSTOMER | own customer contract only | dashboard route/data denied |
| DRIVER | own driver contract only | platform/other-office dashboard data denied |
| Anonymous | public login shell and permitted public reference reads | protected route/data, protected table/RPC, Storage, and Realtime access denied; `service_types` public reference read may remain allowed |

An office selector is a display/filter affordance, not a security authority.
Do not claim that changing it grants or revokes database privileges. If both
memberships authorize different rows, an authorized union is valid; record
the role-specific positive and negative results separately.

## Setup order and dependencies

1. Confirm the Development project is active and record the project ref,
   applied migration snapshot, environment URL, and timestamp. This gate passed
   on 2026-09-19; consult the catalog evidence before a later provisioning run.
2. Generate and record one run key. Preflight exact reserved aliases and run
   markers; stop on a collision. Capture baseline counts/IDs without broad
   cleanup queries.
3. Confirm Auth email/password is enabled. Confirm staff provisioning uses a
   trusted path and does not grant elevated metadata through public signup.
4. Confirm the exact web origin(s) and configure redirect allowlisting before
   password-reset acceptance. Do not use wildcard redirects.
5. Provision Office A/B and only the roles/contracts that exist in the
   Development schema. Provision the Super Admin and office memberships;
   leave Operations/Support/Verification unprovisioned until ADM-04/08 exists.
6. Provision the minimum A/B drivers, motorcycles, documents, customer, and
   order/offer rows through the approved trusted setup path. Record every
   generated ID immediately.
7. Run targeted security/API checks, then the browser journeys. A successful
   page render or historical build does not close this gate.

Dependencies: ADM-01/02 first; ADM-04 is required for trusted scope and
direct-API checks; ADM-05 is required before treating audit evidence as
complete; ADM-06 is required for browser session tests; ADM-13/14 are required
for document/storage scenarios. Maps acceptance additionally requires a
restricted web Maps key and an active Development environment.

## Targeted scenarios

Record each scenario as `NOT_RUN`, `PASS`, `FAIL`, or `BLOCKED_*` with the
exact actor alias, session/user ID, target IDs, request/action, observed
scope, and evidence path.

1. Anonymous and unauthenticated users reach login but cannot load protected
   routes, data, RPCs, Storage objects, or Realtime channels.
2. CUSTOMER and DRIVER sessions cannot enter the staff dashboard or read
   platform/other-office data.
3. Super Admin sees both offices and only the trusted actions granted by the
   backend contract.
4. Office A and Office B staff each see their own fixtures; reciprocal direct
   API/table/Storage attempts fail and return no foreign rows.
5. Mixed membership verifies A Accountant access to A finance/reports/orders
   and B Dispatcher access to B drivers/live/orders. Independently authorized
   A+B rows may be returned; the UI selector is not a security authority.
6. Suspended profile, suspended membership, and suspended-office staff cannot
   operate in the office scope; an active platform Super Admin may retain
   permitted recovery visibility/actions. An active trip may only continue
   where the frozen lifecycle rules explicitly allow it.
7. Verification review accepts/rejects only through the named trusted RPC,
   requires a rejection reason, preserves document expiry rules, and records
   actor/reason/before/after evidence. Office staff must be denied final
   approval.
8. Every sensitive mutation has one authoritative result and one audit/event
   record; retries and timeout reconciliation do not duplicate operational or
   financial effects.
9. Auth session restore, logout, user switching, and password reset do not
   reveal the previous user's data.
10. Maps is tested only when the restricted web key, exact origin restriction,
    required APIs, and active environment are evidenced. Otherwise mark the
    map/scoped-live-operations scenarios `BLOCKED_BY_MAPS_CONFIG`.

## Auth and Maps configuration evidence

Required Auth evidence fields:

```text
project_ref
observed_project_status
auth_email_password_enabled
staff_provisioning_path
web_origin_exact
password_reset_redirect_exact
redirect_allowlist_observed
email_confirmation_behavior_observed
captured_at
```

The dashboard may expose only the publishable Supabase URL/key variables. No
service-role key belongs in browser environment variables. Email/password is
the approved dashboard authentication method; do not add OTP, SMS, or Magic
Link.

Required Maps evidence fields:

```text
provider
web_origin_exact
browser_key_restriction_observed
enabled_web_apis
environment_status
key_value_recorded: false
captured_at
```

Record configuration state, never the key. Do not substitute fake driver
locations, routes, or ETA for a missing Maps/live-operations contract.

## Evidence record

At minimum, the run record must contain:

```text
run_key
project_ref
observed_project_status
applied_migrations_snapshot
captured_at
actor_alias
auth_user_id
profile_id
role_ids
office_membership_ids
office_ids
driver_ids
motorcycle_ids
document_ids
order_ids
offer_ids
audit_or_event_ids
target_id_and_scope_attempted
observed_result_status_or_error_code
browser_url_and_evidence_path
cleanup_status
```

Do not record passwords, tokens, signed URLs after expiry, service-role keys,
or unredacted personal data. Evidence is not a PASS until the relevant
scenario has real Development IDs and an observed result.

## Safe cleanup

Cleanup is permitted only after the run record contains the exact generated
IDs and a second check confirms they belong to the recorded run key. Never use
`TRUNCATE`, broad name/status deletion, wildcard email deletion, or a reset of
shared Development data.

Use the dependency order appropriate to the applied schema, normally:

1. Exact test audit/event/safety rows, only if the append-only/retention
   contract allows Development cleanup; otherwise record them as retained.
2. Exact offers, orders, and dependent delivery/tracking rows.
3. Exact documents/storage objects, motorcycles, and drivers.
4. Exact memberships, role assignments, profiles, and Auth users through the
   trusted administrative path.
5. Exact Office A/B rows last.

Record `cleanup_status`, exact deleted/retained IDs, actor/tool, timestamp,
and any residual rows. If the project is inactive or the cleanup capability
is unavailable, stop and report `BLOCKED_PROJECT_INACTIVE` or the precise
cleanup blocker; do not improvise recovery.
