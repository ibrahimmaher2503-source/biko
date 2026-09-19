# System Validation Gate 2 Report

Date: 2026-08-30  
Target: hosted Supabase Development project `biko-development` (`jlkzgsgfzolhwraakhbt`)  
Current decision: **PASS WITH ISSUES**  
Original gate decision: **FAIL**. Original evidence below is historical and retained unchanged.

The original Gate 2 run occurred before Milestone 7A and failed because three P1 issues affected the one-active-job invariant, Driver offer recovery, and mobile mutation reconciliation. Milestone 7A and remediation Waves A/B/C were completed later. User App Core has not started. The **Final Evidence Closure** section is the authoritative current decision; the original evidence remains historical.

## Entry State

| Check | Result | Evidence |
|---|---|---|
| Backend Gate 1 | PASS | `docs/IMPLEMENTATION_PROGRESS.md` records the hosted catalog, RLS, RPC, advisor, performance, Auth, and cleanup evidence. |
| Milestone 6 | COMPLETE | Driver App Core is recorded complete and remains present locally. |
| Documentation Sync | NOT COMPLETE | The freeze implementation snapshot and progress pending list still describe several hosted 6.1 behaviors as pending; see `SVG2-010`. |
| Milestone 6.1 | COMPLETE | Hosted migration `20260830010117_driver_business_freeze_reconciliation` is present and its delta passed again inside the coherent rollback scenario. |
| Hosted implementation drift | NONE | Hosted and local migration chains contain the same six migrations through 6.1. |
| Local pending migration | NONE | No seventh local migration exists. |

### Hosted migration chain

1. `20260829123858_foundation`
2. `20260829230833_authorization_rls`
3. `20260829232707_core_bidding_engine`
4. `20260829233756_order_state_machine`
5. `20260830001817_driver_app_core`
6. `20260830010117_driver_business_freeze_reconciliation`

### Local migration chain

1. `202608290001_foundation.sql`
2. `202608300001_authorization_rls.sql`
3. `202608300002_core_bidding_engine.sql`
4. `202608300003_order_state_machine.sql`
5. `202608300004_driver_app_core.sql`
6. `202608300005_driver_business_freeze_reconciliation.sql`

## Test Method and Actors

The main hosted scenario used one rollback-only dataset and the required identities: Customer A, Customer B, active independent Driver A, active Office 1 Driver B, pending Driver C, suspended Driver D, an active Driver attached to suspended Office 2, a third active offer driver, Office 1 Staff, Office 2 Staff, Super Admin, and anonymous/authenticated database roles. Trusted setup created the elevated identities; public-signup behavior was tested independently from that setup.

Two concurrency datasets were committed briefly because independent database sessions require shared rows. They were deleted immediately after inspection. All other operational scenarios used transaction rollback.

The previous fresh-account hosted Auth smoke remains valid because neither Auth configuration nor shared Auth code changed: signup, password login, session refresh/restore, sign-out, and final cleanup passed there. That evidence did not explicitly record a wrong-password attempt. Gate 2 revalidated hostile signup metadata, CUSTOMER trigger mapping, absence of injected roles/office/driver identity, and the shared session/router code. The current connected Supabase capability is database-only, so a new Auth HTTP lifecycle could not be added without changing the approved connection path. Group 1 is therefore marked FAIL for incomplete current-gate evidence, not for a confirmed Auth product defect.

## Scenario Results

| Group | Tested scenario | Result | Short evidence | Affected component / issue |
|---:|---|---|---|---|
| 1 | Authentication | FAIL — EVIDENCE GAP | Prior fresh-account signup/login/refresh/sign-out passed. Gate 2 rechecked hostile metadata mapping to CUSTOMER, no injected elevated rows, persisted-session use, auth-state route refresh, and sign-out routing, but could not execute the required wrong-password/new HTTP lifecycle through the database-only connection. | Supabase Auth, `app_core`; `SVG2-005`, `SVG2-013`. No Auth boundary defect was confirmed. |
| 2 | Profile / role escalation | PASS | Authenticated client UPDATE/INSERT attempts against `profiles`, `user_roles`, `office_members`, and `drivers` were denied by table privilege revokes; helper calls returned false and private schema is not an exposed API schema. | RLS/grants/private helpers. |
| 3 | Office isolation | PASS | Office 1 and Office 2 staff each saw only their own driver scope, could not update the other office, and could not self-promote. Super Admin saw all six gate drivers; anonymous protected access was absent. | Office RLS and role permissions. |
| 4 | Driver eligibility | FAIL | ACTIVE/PENDING/SUSPENDED/inactive-office online outcomes and Arabic hints were correct. However, the same ACTIVE driver was selected into two simultaneous active orders. | `accept_offer`, availability/candidate contract; `SVG2-001`. |
| 5 | Order creation | PASS | Eight RIDE/DELIVERY orders created through `create_order` derived customer ownership from `auth.uid()` and persisted BIDDING. Direct forged INSERT and protected price/status UPDATE were denied. | `create_order`, orders grants/RLS. |
| 6 | Candidate visibility | PASS WITH ISSUE | Candidate drivers saw allowed BIDDING rows; a non-candidate saw none; the driver could not read the customer profile or another independent driver. The underlying row grant still permits requesting `customer_id`. | Candidate RLS; `SVG2-009`. |
| 7 | Bidding | FAIL | Three drivers created owned ACTIVE offers, cross-customer visibility was denied, duplicate same-order offer was rejected, withdrawal/history/resubmission passed, and selected withdrawal failed. Driver App represents only one of multiple valid cross-order ACTIVE offers. | Offers and Driver waiting state; `SVG2-002`. |
| 8 | Atomic driver selection | PASS | Normal selection set one driver/offer/price/status and closed two losing offers. In the true competing acceptance race, one session committed and one was rejected; final state had one selected offer and one assignment event. | `accept_offer` same-order lock. |
| 9 | Driver App active trip | PASS WITH LIMITATION | Hosted full path reached ASSIGNED → ON_WAY → ARRIVED → IN_PROGRESS → COMPLETED with all timestamps and correct actor events. Model tests covered each Arabic CTA mapping; widget checks found one primary CTA and secondary cancellation. No Android device/emulator was available. | Driver models/screens and hosted lifecycle RPCs; `SVG2-008`, `SVG2-013`. |
| 10 | Invalid / hostile transitions | PASS | ASSIGNED → IN_PROGRESS, ON_WAY → COMPLETED, direct status UPDATE, and transitions from COMPLETED/CANCELLED/EXPIRED were rejected. | State-machine RPCs and grants. |
| 11 | Stale UI / double tap | PASS AT BACKEND | Submitting after another driver was selected and selecting a withdrawn offer both rejected cleanly. The lifecycle double-action race produced one ON_WAY mutation/event and one stale-state rejection. Widget busy guards suppress local double taps. | RPC locks/state checks and Driver local busy flags. |
| 12 | Network failure | FAIL | The service maps known PostgREST/Auth errors, but mutation catch paths show only a snackbar. They do not refresh authoritative state when the backend may have committed before the response was lost. | Driver service/screens; `SVG2-003`, `SVG2-007`. |
| 13 | Cancellation | PASS | Customer ownership/terminal rules passed. Assigned Driver cancellation required a reason, denied another driver and IN_PROGRESS, persisted CANCELLED, recorded actor/reason, and never returned to BIDDING. | Customer/Driver cancellation RPCs. |
| 14 | `order_events` | PASS | One full order produced exactly BIDDING, assignment, on-way, arrived, in-progress, and completed events with expected actors/timestamps. Cancellation and expiry each produced one representative event. Normal clients had no SELECT/INSERT/UPDATE/DELETE grant. | `order_events` trigger/table. |
| 15 | History | PASS WITH ISSUE | Hosted ownership/status data was correct; Driver query is explicit, bounded to 50, and excludes active/other-driver rows. Empty/error/data states exist. The plan uses indexes but performs a small status-merge sort. | Driver history/service; `SVG2-011`. |
| 16 | Earnings | PASS | Only COMPLETED rows contribute. Cancelled and active rows are excluded. Independent commission/net are explicitly deferred; Office Driver shows displayed completed gross only and no invented payroll/commission. | Driver earnings model/screen. |
| 17 | Privacy leak audit | PASS WITH ISSUE | Driver queries use explicit columns and do not request customer phone/profile, other offers, driver documents, office private data, or `select *`. Candidate table access can still reveal the order's customer UUID to a custom client. | Driver service and orders RLS; `SVG2-009`. |
| 18 | Database integrity | FAIL | Orphan offer, duplicate driver identity, null ownership, invalid driver/office relationship, duplicate same-order ACTIVE offer, and client terminal mutation were constrained. Same-driver dual active assignment and cross-order `selected_offer_id` were not constrained. | Orders/offers constraints and `accept_offer`; `SVG2-001`, `SVG2-004`. |
| 19 | Concurrency | PASS | Exactly two races ran: competing `accept_offer`, and double `driver_on_way`. Each had one winner, one safe rejection, one final state, and one side-effect event. | PostgreSQL row locking/state checks. |
| 20 | Performance | PASS WITH ISSUES | Hosted EXPLAIN used indexes for every inspected hot query and found no unbounded sequential scan. Offers/history require bounded sorts. No current data volume justifies an index migration. | Query/index design; `SVG2-011`. |
| 21 | API / cost | PASS WITH ISSUE | No polling, Google/paid routing, Redis, Edge Function, Realtime loop, or repeated timer exists. Online Home refresh is four calls; History and Earnings each repeat account + bounded history calls. | Driver service; `SVG2-011`. |
| 22 | Flutter architecture | FAIL | UI → Riverpod → DriverService → Supabase is respected and `main.dart` is small. Shared presentation/domain formatting remains Driver-only, and uncertain mutations lack a shared reconciliation contract. | Driver App / `app_core`; `SVG2-003`, `SVG2-006`, `SVG2-012`. |
| 23 | Driver UI / UX | PASS WITH ISSUES | RTL, hierarchy, 44px+ actions, bottom navigation, clear prices/statuses, disabled/busy states, one dominant trip CTA, and secondary cancellation passed code/widget review. Missing explicit no-internet/retrying states, scalar waiting offer, and Home-only active-trip restoration remain. | Driver UI; `SVG2-002`, `SVG2-007`, `SVG2-008`. |
| 24 | Business Freeze alignment | FAIL | Most current base and 6.1 deltas pass. The frozen one-active-job rule is contradicted by hosted behavior. Future milestone items remain classified as planned, not bugs. | Business rule enforcement; `SVG2-001`. |
| 25 | Document / code drift | FOUND | Hosted 6.1 behavior exists, while freeze/progress snapshots still list offer withdrawal and required events as pending; progress also points to generic Milestone 7 instead of the gated 7A sequence. | Documentation; `SVG2-010`. |

## Hosted Evidence Highlights

### Authorization and security

- Authenticated privilege escalation attempts failed through explicit privilege revokes; RLS then constrained allowed SELECTs.
- Anonymous had no protected table SELECT and no privileged RPC EXECUTE.
- All inspected sensitive functions are `SECURITY DEFINER` with `search_path=""`.
- Public and anonymous EXECUTE are false for every sensitive function.
- Authenticated EXECUTE exists only for intended client RPCs and the private boolean helpers used by RLS; trigger-only, state-core, event, and expiry internals are not client executable.
- Direct client writes to orders, offers, roles, memberships, drivers, and `order_events` remain denied.

### Historical Confirmed P1 — Original Gate: one driver could hold two active jobs

Driver A submitted offers on two separate BIDDING orders. Customer A selected the first offer; Customer B then selected the same driver's second offer. Both calls succeeded. Final evidence inside the rollback transaction:

- `single_active_job_invariant = false`
- active orders assigned to Driver A = `2`
- both orders were `DRIVER_ASSIGNED`

`accept_offer` locks the driver row but does not check for an existing active order after taking that lock, and the database has no partial uniqueness constraint over active `orders.driver_id` values. This violates the frozen MVP rule that one driver may hold only one active job.

### Concurrency test 1: competing acceptance

- Session A selected offer A and committed `DRIVER_ASSIGNED` at 100 EGP.
- Session B was rejected with `Order is no longer open for bidding` after the order lock was released.
- Final: one driver, one `selected_offer_id`, one agreed price, one SELECTED offer, two CLOSED offers, and one assignment event.

### Concurrency test 2: duplicate lifecycle action

- Session A committed `DRIVER_ON_WAY`.
- Session B was rejected with `Order is not in the expected state`.
- Final: one ON_WAY timestamp, one ON_WAY event, and the assigned driver as event actor.

### Stale and terminal behavior

- Driver submit after another driver was selected: rejected as not open for bidding.
- Customer select after offer withdrawal: rejected because an ACTIVE offer is required.
- EXPIRED customer cancel and new offer: both rejected.
- EXPIRED event: exactly one.
- COMPLETED and CANCELLED transitions: rejected.

## Flutter and Driver Service Evidence

- `flutter analyze` for `apps/driver_app`: PASS, no issues.
- Targeted existing + temporary gate widget/model checks: PASS, 7 tests.
- The temporary widget harness rendered compact RTL Request Details, Active Trip, History, and Office Earnings. It verified one dominant FilledButton on request/active screens, secondary cancellation, terminal status labels, and no invented Office commission.
- The temporary harness file was deleted after the pass; no production Flutter file changed.
- No Android device/emulator or `adb` was available. The project exposes Android/iOS targets only, so physical/emulator behavior, OS resume, and a real signed-in Driver App session against hosted Supabase remain runtime evidence limitations rather than claimed passes.

### Network uncertainty analysis

Success paths invalidate providers and refresh backend state. Failure paths for availability, submit, withdraw, lifecycle, and cancel only display `driverErrorMessage(error)`. If the database commits but the response is lost:

- submit may create an ACTIVE offer while the screen remains on Request Details; retry then reports an existing offer without navigating to it;
- lifecycle may advance while the screen retains the old CTA; retry reports stale state but still does not refresh;
- cancel/withdraw/availability may similarly leave the local screen inconsistent until manual navigation/refresh.

Backend constraints prevent duplicate same-order offers and duplicate lifecycle events, but the UI does not meet the required authoritative-reconciliation behavior. See `SVG2-003`.

## Performance and Cost Review

| Hot query | Hosted plan evidence | Result |
|---|---|---|
| Available BIDDING requests, latest 20 | `orders_bidding_created_idx` plus candidate/driver indexes; no sequential scan | PASS |
| Candidate membership | `order_driver_candidates_driver_order_idx`; index-only outer scan | PASS |
| Offers for order | `offers_order_status_created_idx`; bounded sort | PASS WITH MONITORING |
| Active assignment, latest 1 | `orders_driver_status_created_idx`; no sequential scan | PASS |
| Driver history / earnings, latest 50 | `orders_driver_status_created_idx`; bounded sort across two statuses | PASS WITH MONITORING |
| Office ACTIVE drivers, latest 50 | `drivers_office_status_idx`; no sequential scan | PASS |

One online Home load performs one driver-account read followed by three parallel reads: available requests, active assignment, and waiting offer. Offline Home performs three total reads. History and Earnings each perform an account read plus the same bounded terminal-order read. This is acceptable at the current scale, but the two tab providers duplicate terminal data and account lookup. There is no evidence yet to justify a new index, cache, Edge Function, Redis, or paid API.

## Flutter Architecture Review

### Good current structure

- Supabase calls are confined to `DriverService` except shared Auth/bootstrap wiring.
- Riverpod providers are thin and do not duplicate business mutations.
- Core enums and database values are shared in `app_core`.
- Driver service uses explicit projections and bounded lists.
- No polling, global mutable business state, speculative repository layer, or extra infrastructure exists.

### Before User App

- Establish one shared mutation-outcome/reconciliation pattern in `app_core` or a minimal shared service helper before User App copies the current catch/snackbar behavior (`SVG2-003`).
- Move only genuinely shared order status labels/colors, price formatting, and route/status primitives out of Driver-only UI before User App duplicates them (`SVG2-006`).
- Decide and encode the cross-order offer contract: list multiple waiting offers or enforce one global ACTIVE offer. The current database allows many while the Driver UI loads one (`SVG2-002`).

No broad refactor is recommended. `driver_screens.dart` can be split by feature later; it is not a prerequisite to fixing the P1 contracts.

## Driver UI / UX Review

| Screen | Result | Evidence / issue |
|---|---|---|
| Home | PASS WITH ISSUE | Online control is prominent, status is clear, active trip card exists, and manual refresh is available. Home still fetches/displays available requests while an active trip exists; this amplifies `SVG2-001`. |
| Available Requests | PASS | Explicit candidate-gated data, clear service/route/price cards, one details action. |
| Request Details | PASS | Compact RTL widget check; customer price is dominant; one primary accept action, one outlined counter action, one text ignore action; busy state disables all. |
| Waiting | FAIL | Only the latest ACTIVE offer is loaded and represented; older valid cross-order offers are hidden (`SVG2-002`). |
| Active Trip | PASS WITH ISSUE | One lifecycle CTA, secondary red text cancellation, correct Arabic status/price/route. Failure path does not reconcile uncertain mutations (`SVG2-003`). |
| History | PASS | Completed/cancelled cards, status/price/date, pull refresh, bounded data, empty/error states. |
| Earnings | PASS | Label says values are the completed trips currently displayed; Independent fields are deferred honestly; Office payroll/commission is explicitly not shown. |
| Profile | PASS WITH ISSUE | Clear identity/status/type/office and sign-out; shared Auth errors can expose backend English text (`SVG2-005`). |
| Cross-screen states | PASS WITH ISSUES | Loading/empty/error/disabled states exist. Dedicated No Internet, Retrying/Reconnecting, and skeleton variants from the UI specifications do not (`SVG2-007`). |

## Historical Business Freeze Alignment — Original Gate

The classifications in this table are the original Gate snapshot. The Final
Evidence Closure section records current implementation status.

| Frozen rule | Classification | Current evidence / milestone boundary |
|---|---|---|
| Email + password; no login OTP | IMPLEMENTED | Shared Auth service/router and prior hosted Auth smoke. |
| RIDE and DELIVERY from development start | IMPLEMENTED / PARTIAL DELIVERY DETAIL | Both service types and generic order creation work. Parcel/recipient fields are planned. |
| Customer-owned atomic offer acceptance | IMPLEMENTED | Same-order normal and competing acceptance passed. |
| One ACTIVE offer per Driver/Order | IMPLEMENTED | RPC denial plus partial unique index. |
| Offer withdrawal then new offer | IMPLEMENTED | Hosted withdrawal/history/resubmission passed. |
| One driver may hold only one active job | **CONFLICTING IMPLEMENTATION** | Hosted backend allowed two active assignments; `SVG2-001`. |
| Driver pre-IN_PROGRESS cancellation with reason; no return to bidding | IMPLEMENTED | Hosted 6.1 scenario passed. |
| Required lifecycle/cancellation/expiry events | IMPLEMENTED FOR CURRENT ACTIONS | Append-only current lifecycle, cancellation, and expiry evidence passed; future admin recovery remains planned. |
| Base Online eligibility | PARTIALLY IMPLEMENTED | Account/driver/office/no-active-order toggle checks pass; selection invariant fails and document/motorcycle eligibility is planned. |
| Suggested Price and 70% floor | PLANNED / FUTURE MILESTONE | Do not classify as current defect. |
| 90-second bidding and 2/4/6/8 km progressive PostGIS dispatch | PLANNED / FUTURE MILESTONE | Current migration intentionally uses 30 minutes and trusted candidates. |
| Driver/motorcycle documents, age, expiry, helmet | PLANNED — Milestone 11 | Explicitly deferred. |
| Ride/Delivery verification OTPs | PLANNED — verification milestone | Operational trip codes, not Auth OTP. |
| 200m/300m geofences, ETA, overrides | PLANNED — Maps milestone | Explicitly deferred. |
| One parcel, 8 kg, 3,000 EGP, recipient fields | PLANNED — User/backend delta | Generic DELIVERY exists without these frozen fields. |
| Cancellation reasons, cooldowns, abuse flags, Book Again | PLANNED — User/operations milestones | Basic customer and Driver terminal rules exist. |
| Independent 10%, Office 7%, promotion, ledger/settlement | PLANNED — Finance milestone | Driver UI does not invent these values. |
| East Cairo operating zones | PLANNED — Maps/operations | No current zone enforcement. |

## Historical Document / Code Drift — Resolved by CR-024

1. `docs/BUSINESS_RULES_FREEZE_V1.md` implementation snapshot listed offer withdrawal/new-offer and required `order_events` as pending, although hosted 6.1 implemented and verified both.
2. `docs/IMPLEMENTATION_PROGRESS.md` repeated offer withdrawal and required events as pending while recording 6.1 complete.
3. Older backend/database/workflow specifications retained pending labels for hosted 6.1 behavior.
4. Progress named generic Milestone 7 as next even though Gate 2 and the controlled sequence referred to Milestone 7A.
5. UI edge-state Auth examples mentioned login OTP states, while `DEC-001` and the Business Freeze made email/password authoritative. This was documentation drift, not a request to add login OTP.

This was the original `SVG2-010` finding. Final Evidence Closure resolved it
without deleting the historical evidence or changing frozen product behavior.

## Historical Issue Summary and Original Gate Decision

### P0

None.

### P1 — block User App

- `SVG2-001`: one driver can be selected into two active orders.
- `SVG2-002`: backend allows multiple cross-order ACTIVE offers while Driver App exposes one.
- `SVG2-003`: uncertain mutation results are not reconciled from the hosted source of truth.

### P2

- `SVG2-004` through `SVG2-010`: selected-offer relational integrity, shared Auth error localization, shared presentation extraction, explicit network states, active-trip restoration, candidate customer UUID exposure, and documentation drift.

### P3

- `SVG2-011` through `SVG2-013`: bounded query/tab duplication, large Driver screens file, and incomplete Auth/Android runtime evidence in this environment.

Gate result is **FAIL**. Milestone 7A and User App implementation remain blocked until all three P1 issues are resolved and targeted hosted/Flutter verification proves their contracts.

## Cleanup

- Main and stale/terminal datasets: transaction rollback.
- Two concurrency datasets: explicitly deleted after inspection.
- Temporary Flutter widget harness: deleted after the passing run.
- Final hosted cleanup audit: Auth users `0`, profiles `0`, offices `0`, drivers `0`, orders `0`, offers `0` for every Gate 2 identifier/prefix.

## Historical Remediation Result — Before Final Evidence Closure

Date: 2026-08-30. This is targeted SVG2-001–010 remediation, not a rerun of System Validation Gate 2.

**At this historical checkpoint: INCOMPLETE.** SVG2-002–009 were resolved with targeted evidence. SVG2-001 was implemented and its invariant/eligibility tests passed, but required true cross-order concurrency evidence was missing. SVG2-010 final specification sync was deferred until backend verification completed. The Final Evidence Closure section supersedes this checkpoint.

### Implementation and verification

| Issue | Remediation | Evidence / current status |
|---|---|---|
| SVG2-001 | Partial unique active-Driver index, order -> Driver lock/recheck, atomic other-offer closure, assignment disables new work, active-job submit/candidate denial | Hosted A/B/D PASS. Test C NOT PROVEN: submitted sessions did not overlap. |
| SVG2-002 | Paged multiple waiting offers, route identity, individual withdrawal, active-trip refresh clears waiting list | Hosted A/B and Driver F PASS. |
| SVG2-003 | Shared outcome classifier/controller, one path for all eight Driver mutations, authoritative refresh, no write retry, session revalidation | Shared and Driver G/H PASS. |
| SVG2-004 | Composite (order id, selected offer id) FK to offers(order_id, id) | Hosted manual cross-order write rejected; normal acceptance PASS. |
| SVG2-005 | Safe Arabic Auth error mapper in shared Auth UI | Shared J PASS, 8 error cases. |
| SVG2-006 | Shared status/price/date/route/service presentation; Driver behavior stays local | Shared M and affected Driver widgets PASS. |
| SVG2-007 | Checking, unavailable, manual read retry, recovered state, loading skeleton; no automatic provider read loop | Shared/Driver I PASS. |
| SVG2-008 | Authoritative authenticated bootstrap routes to active trip or Home | Driver K active/none/terminal cases PASS; no loop. |
| SVG2-009 | Safe explicit-column candidate RPC; candidate raw-order SELECT removed; assigned/customer/office policies retained | Hosted L and changed-object grant/search-path checks PASS. |
| SVG2-010 | Evidence ledgers updated accurately; broader specification sync not yet performed | OPEN until complete backend verification. |

Hosted migration: `20260830021017_gate_2_remediation` from local `202608300008_gate_2_remediation.sql`. The already-applied 7A migrations `20260830014754_user_flow_backend_delta` and `20260830015129_user_flow_privacy_hardening` were preserved, not rebuilt or reclassified as newly completed.

### Exact concurrency limitation

Two calls were submitted together through the connected Supabase tool, but recorded database times show serialization:

- Session 74036: 02:14:56.120671–02:14:59.130297 UTC, SUCCESS.
- Session 74041: 02:15:01.173019–02:15:01.178771 UTC, `Active offer for this order required`.
- Final offer states: one SELECTED, one CLOSED. This is a sequential stale-offer rejection, **not proof of the required overlapping two-customer race**.
- No installed `dblink`/`pg_background` test capability is available. No extension, CLI, direct HTTP path, or infrastructure was introduced. Approval for an additional concurrency-capable test path is required.

The first race fixture setup had a UUID cast error and rolled back before any acceptance call. The corrected setup ran once; no successful overlapping race is being claimed.

### Mobile checks, scope, and cleanup

- Five shared-core and seven Driver targeted checks passed. The Driver test wave exposed and corrected a constrained skeleton overflow and automatic provider read retries; harness-only route/timer/scroll synchronization issues were corrected before the failed tests passed.
- `flutter analyze --no-pub` ran once in app_core and Driver App. Five lint findings were fixed; `dart analyze` on only the affected diagnostic files/providers then reported no issues. No full analysis loop ran.
- Main backend A/B/D/E/L/security test: transaction rollback. Committed race actors/orders/offers: explicitly deleted. Final cleanup audit: Auth users 0, profiles 0, Drivers 0, orders 0, offers 0, events 0.
- No User App/Dashboard/Maps work, pub get, full Auth smoke, old bidding race, full RLS/state-machine suite, Backend Gate 1, or full System Validation Gate ran.
- Previously verified unaffected behavior was not rerun because these changes do not affect it.
- SVG2-011, SVG2-012, SVG2-013 remain OPEN and non-blocking at their existing timing. No new P0/P1 defect was observed in the targeted checks; unproven concurrency prevents gate completion.

## Final Evidence Closure

This section supersedes earlier current-decision wording while preserving the original Gate and remediation evidence above.

- **Wave A:** hosted migration `20260830133522_wave_a_security_transaction_integrity`; CR-001/002/003/009 and assignment integrity passed their targeted hosted checks.
- **Wave B:** hosted migration `20260830135840_wave_b_recovery_auth_contracts`; CR-004/005/011/012/013/018 are resolved. CR-006 application recovery is implemented; hosted Auth redirect allowlist inspection remains externally unavailable.
- **Wave C:** hosted migration `20260830143750_wave_c_read_correctness`; CR-010/019/026 passed hosted/Flutter targeted verification with zero residual fixtures.
- **CR-008/SVG2-001:** RESOLVED using two independent authenticated HTTPS clients through the hosted publishable application path. B ran `14:46:29.735678–14:46:30.817925 UTC`; A ran `14:46:29.736612–14:46:30.818234 UTC`, proving genuine overlap. A succeeded with HTTP 200; B failed deterministically with HTTP 400 / `P0001`, `Driver already has an active assignment`.
- **Final assignment truth:** exactly one active Driver job, one assigned order, one complete assignment bundle, one SELECTED offer, one CLOSED competing offer, one untouched BIDDING losing order, and one `DRIVER_ASSIGNED` event. No deadlock or contradictory assignment was observed.
- **Cleanup:** zero reserved CR-008 Auth users, profiles, Drivers, orders, offers, candidates, Delivery details, or order events remain.
- **CR-006:** IMPLEMENTED — EXTERNAL AUTH REDIRECT CONFIRMATION PENDING. Manually confirm `biko-driver-dev://auth-callback/` and `biko-user-dev://auth-callback/` before full password-reset E2E/release acceptance.
- **CR-024/SVG2-010:** RESOLVED by focused current-status reconciliation. Milestone 7A, 90-second bidding, Delivery recipient/parcel validation, offer withdrawal, `order_events`, one-active-job protection, multiple cross-order offers until assignment, competing-offer closure, safe projections, creation-intent recovery, bounded mutation recovery, authoritative waiting state, completion counts, offer eligibility, and Email + Password Auth are recorded as current implementation.
- **Before Maps:** CR-014.
- **Before Realtime:** CR-015, CR-016, CR-017.
- **Before Public Launch:** CR-007; remaining CR-020 trusted-recovery/legacy exception review; CR-023, CR-027, CR-030.
- **Safe to defer:** CR-025, CR-028, CR-029, CR-031, CR-032.
- **Retained test debt:** CR-021/022 remain partially open for broader regression/integration coverage. Existing targeted assets improved the boundary evidence; this closure does not falsely resolve their remaining scope.
- **New P0/P1:** none in Waves B/C or Evidence Closure.

Current decision: **System Validation Gate 2 = PASS WITH ISSUES**. Remaining issues are milestone-scoped/non-blocking under the approved closure rule. **Milestone 7A remains COMPLETE; User App Core is UNBLOCKED.** Next: **Milestone 7 — User App Core**.
