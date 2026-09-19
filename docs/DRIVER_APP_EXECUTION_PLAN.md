# Biko Driver App — Completion and Supervised Agent Plan

Date: 2026-09-13. Status: **WAVE 3 PARTIAL — LOCATION FIX, FINANCE IMPLEMENTATION, AND EXTERNAL ACCEPTANCE OPEN**.

This plan is based on the current repository, not the old milestone checklist.
The Driver operational core is implemented and historically verified, but the
application is not release-complete until the product gaps and real Android
acceptance below are closed.

## 1. Authority and scope

1. `docs/BUSINESS_RULES_FREEZE_V1.md` and accepted `docs/DECISIONS.md` own MVP business behavior.
2. `DESIGN.md` and `docs/Driver_App_UI_Specification_AR.md` own the current Driver presentation direction.
3. `docs/Driver_App_Requirements_Specification_EN.md` supplies acceptance requirements, subject to newer frozen decisions.
4. Current code and the latest milestone reports are implementation evidence; old unchecked roadmap boxes are not current truth.
5. `COST_AND_PERFORMANCE_RULES.md` and `DATABASE_ENGINEERING_RULES.md` govern location, realtime, database, and external API work.

Keep the existing Flutter UI -> Riverpod -> `DriverService` -> Supabase flow.
Do not introduce repositories/use cases, a second state layer, polling, Redis,
paid dispatch APIs, a second Driver app, or a new design system.

## 2. Current truth: preserve and do not rebuild

| Area | Current evidence | Status |
|---|---|---|
| Email/password Auth, reset flow, session restoration | `apps/driver_app/lib/main.dart`, shared `app_core` Auth | Implemented; hosted redirect and device E2E remain |
| Driver account read and trusted eligibility | `driver_service.dart`, `driver_providers.dart` | Implemented |
| Online/offline and fresh foreground location | `driver_location.dart`, M8 migration | Implemented in foreground; background/OS lifecycle incomplete |
| Geographic request read and bounded PostGIS candidacy | `get_driver_requests`, M8 report | Implemented; timed expansion delivery is incomplete |
| Accept price, counter-offer, multiple waiting offers, withdrawal | Driver request/waiting screens and RPCs | Implemented |
| Atomic assignment, one active job, competing-offer closure | Gate 2 remediation and Gate 7B | Hosted evidence PASS; do not redesign |
| Ride/Delivery lifecycle, cancellation boundaries, recovery without mutation replay | Active screen, Wave B, Gate 7B | Implemented |
| Driver/motorcycle document upload, safety readiness, geofence, final Delivery code | Driver verification screen and M10 | Implemented; physical upload/GPS and operations configuration remain |
| Realtime invalidation, Push token/outbox client code | Driver operational events and M9 | Implemented code; live FCM delivery not configured/proven |
| Bounded History and gross Earnings display | Driver activity screens | Implemented as a limited interim view, not frozen finance completion |
| Arabic-first Biko theme and main navigation | shared design foundation and Driver screens | Implemented; device visual acceptance remains |

Historical checks must not be rerun merely for freshness. Wave 1 added seven
focused Driver checks and the complete Driver test folder now contains 42
tests. The repository is currently entirely untracked; preserve that state and
do not mass-add, commit, or push.

## 3. Confirmed completion gaps

### A. Product/backend gaps

| ID | Priority | Gap | Minimum completion boundary |
|---|---|---|---|
| D01 | P0 | There is no usable trusted onboarding journey to create a `PENDING` Driver identity, profile, and motorcycle. The app only signs in and reports that creation happens through a trusted party | Approve one path: independent application request and office invite, or trusted operations-only creation. Public Auth signup must remain CUSTOMER-only and no driver may self-approve |
| D02 | P0 | Active-trip location is foreground-only and Home/Active screens can own competing location lifecycles | One session-owned location coordinator using the installed location stack; offline = no writes, idle = low frequency/significant movement, active trip = useful 5-10 second updates; Android-first background/restore evidence |
| D03 | P0 | Radius eligibility is calculated from order age, but farther drivers receive no new stage event when 2 km expands to 4/6/8 km | One trusted scheduled PostgreSQL/Edge dispatch tick at the existing 20-second stages; idempotent bounded signals, no client polling and no Google routing for discovery |
| D04 | P1 | The request/waiting experience omits useful server-owned deadline presentation and Delivery-safe request details; the waiting summary does not compare customer price with the Driver offer | Extend only the safe request/offer projections needed by the UI, retain pre-assignment identity/phone privacy, and render an authoritative countdown with expiry refresh |
| D05 | P1 | Assigned/active Driver UI has no approved customer contact/details contract | Decide the minimum post-assignment disclosure, then expose it through one auth-derived RPC. Never expose customer identity/phone before assignment; chat and call masking stay out of MVP |
| D06 | P1 | Frozen cancellation abuse handling is incomplete | Three post-assignment Driver cancellations in rolling 7 days create an operations-review flag only; add the smallest atomic server rule and notification/audit evidence, without automatic suspension |
| D07 | P1 | Frozen independent commission/promotion/ledger/net earnings are absent; current screen intentionally shows gross-only placeholders | Implement server-configured commission snapshots and limited commission ledger. Independent sees gross/commission/net; Office Driver remains gross-only. No wallet, payout, payroll, or settlement platform |
| D08 | P2 | Trusted recovery/legacy assignment exceptions and safe operation diagnostics remain partially open (`CR-020`, `CR-023`) | Focused invariant review plus redacted operation/read context using existing logging; never log tokens, phone, or payloads |
| D09 | P2 | Current-status documents disagree on some resolved Maps/UI items and still label implemented pricing/dispatch pieces as pending | One narrow documentation reconciliation after code decisions; preserve historical reports instead of rewriting them |

### B. Driver UI completion

| ID | Priority | Gap | Boundary |
|---|---|---|---|
| U01 | P0 | Onboarding/application, Driver type, profile data, and motorcycle entry screens are absent | Build only after D01 contract approval; reuse shared Auth and current verification upload screen |
| U02 | P1 | Home lacks the specified compact map/current-position context and accurate Trips/Earnings Today summary | Reuse current map and terminal-order data or one compact existing-backend summary; do not add repeated reads or an embedded navigation stack |
| U03 | P1 | Request/waiting screens need countdown, long-address/large-price states, and Delivery-safe details | Implement with D04; preserve one dominant CTA and uncertain-outcome blocking |
| U04 | P1 | Active trip needs clearer assigned contact/details, current-location state, ETA freshness, permission recovery, and single ownership of tracking | Implement with D02/D05; server remains lifecycle/geofence authority |
| U05 | P2 | History lacks an order detail view; Earnings lacks day/week/date-range presentation and final independent split | Reuse the bounded terminal model until D07 supplies financial truth; add paging only when all-history access is required |
| U06 | P2 | Small/typical/large Android, keyboard, text scale, RTL/LTR numbers, denied permissions, reconnect, and process restore are not visually accepted | One deterministic Driver state gallery followed by one real-device journey; screenshots alone do not prove live services |

### C. External/release gates, not missing core code

- Supabase URL and publishable-key settings are present locally. Do not expose them in logs or documents.
- Android/iOS restricted Maps keys are absent locally; deploy/configure Places and Route Quote before live map acceptance.
- Android `google-services.json` and iOS `GoogleService-Info.plist` are absent; configure Firebase/APNs, hosted `FIREBASE_SERVICE_ACCOUNT_JSON`, deploy `push-dispatch`, and schedule it before live Push acceptance.
- Schedule `enqueue_driver_document_expiry_notifications` through a trusted service path.
- Confirm hosted Auth redirect allowlist for `biko-driver-dev://auth-callback/`.
- Resolve legal document/criminal-record launch requirements and trusted operations review UI.
- Android release currently uses debug signing. Configure owner-controlled protected release signing and fail a release build when it is missing.
- No Android emulator or physical device is currently connected; only Windows, Chrome, and Edge are visible.

## 4. Explicitly excluded from this plan

Do not build ratings, customer/Driver chat, call masking, wallet, cash-out,
subscriptions, incentives, heat maps, AI forecasting, multi-order batching,
multi-stop/scheduled delivery, advanced route optimization, office payroll, or
complex settlement. Rating is deferred by the newer product/design authority
despite older Driver requirement text.

## 5. Supervised agent work packets

All implementation agents use **`gpt-5.6-luna` with `xhigh` reasoning** as
requested. Root is the supervisor: it freezes file ownership, reviews every
diff and every changed trust boundary, rejects unsupported scope, integrates
shared files, and owns the final acceptance decision.

The current runtime has four total concurrency slots, including root, so the
safe maximum is **three child agents at once**. If capacity changes later, the
plan may use up to five children only when file ownership remains disjoint.

### Packet A — Trusted onboarding and account

- Own: new Driver onboarding/application presentation and dedicated tests.
- Backend candidate: one focused new migration for the approved application/invite contract.
- Root owns changes to `main.dart`, `driver_models.dart`, `driver_service.dart`, and `driver_providers.dart` after reviewing the agent's requested seam.
- Covers D01/U01. No public role escalation, self-approval, or duplicate Auth implementation.

### Packet B — Requests, offers, and Home

- Own: `presentation/driver_home_screen.dart`, `request_details_screen.dart`, `offer_waiting_screen.dart`, and dedicated presentation tests.
- Covers D04/U02/U03. Request any projection/model change from root; do not edit a shared RPC concurrently with another packet.
- Reuse existing Maps widget, price formatter, countdown timing, and mutation recovery.

### Packet C — Location and active trip

- Own: `driver_location.dart`, `driver_maps.dart`, `presentation/active_order_screen.dart`, and focused lifecycle/location tests.
- Root owns `main.dart` and platform manifest/build integration.
- Covers D02/D05/U04. One location owner only; no GPS history and no client polling.

### Packet D — Earnings, cancellation flag, and secondary screens

- Starts after a slot frees.
- Own: `presentation/driver_activity_screens.dart` and dedicated tests.
- Backend work is split into separate focused migrations for D06 and D07; do not combine finance with cancellation logic.
- Root owns shared service/model integration and verifies money/concurrency logic.

### Packet E — External configuration and Android acceptance

- Starts after merged functional waves.
- Own: bounded configuration checklist, device fixture/state gallery, Android evidence ledger, README/release instructions.
- One agent owns the emulator/device at a time. No parallel rebuilds or competing app sessions.
- Covers U06 and every external/release gate. Secrets and signing files never enter source control or agent output.

## 6. Execution order

1. **Gate 0 — decisions and ownership:** resolve D01 onboarding path, D05 contact disclosure, and legal document categories. Record exact existing untracked state.
2. **Parallel Wave 1:** Packet A, Packet B, and Packet C run under three Luna xhigh agents. Root reviews continuously and integrates only shared seams.
3. **Trust-boundary checkpoint:** run only the focused onboarding/projection/location SQL contracts that changed; adversarial roles and offline-vs-active location cases are mandatory.
4. **Wave 2:** Packet D runs while Packet E prepares deterministic states and configuration inventory. Root closes D08/D09 only where current changes require them.
5. **External configuration:** Maps/Edge/Firebase/Auth redirect/schedulers/pricing/zone values are configured once in authorized Development. Never guess keys, prices, polygons, or legal choices.
6. **Integrated Flutter checkpoint:** changed targeted tests first; then Driver App `flutter analyze --no-pub` once and the complete Driver test folder once after the meaningful merged wave. Analyze `app_core` only if shared code changed. Do not run Dashboard/User checks unless their consumed contract changed.
7. **Real Android acceptance:** login -> restore -> onboarding/approved fixture -> Online -> staged request -> offer -> selection -> assigned -> Ride and Delivery lifecycle -> background location -> final Delivery code -> terminal History/Earnings -> reconnect/session loss -> sign out.
8. **Release checkpoint:** protected signed Android artifact, merged release permissions, clean secret scan, exact artifact path/hash/signature, and known external limitations.

## 7. Root verification contract

An agent report is never acceptance by itself. Root must:

1. Inspect the diff and every caller of changed shared functions.
2. Confirm business behavior against the frozen rules and reject speculative additions.
3. Confirm no overlapping file ownership or unrelated dirty-file overwrite.
4. Run the smallest independent integrated verification once; do not repeat an already-passing unchanged command.
5. For RLS, assignment, location, cancellation, and money, require targeted hostile/concurrency/rollback evidence.
6. For UI/runtime, inspect the actual Android screen and state; source or widget evidence alone is not live acceptance.
7. Report `IMPLEMENTED`, `FIXTURE_VERIFIED`, `LIVE_VERIFIED`, `BLOCKED_BY_CONFIG`, or `BLOCKED_BY_PRODUCT_DECISION`. Never use an invented completion percentage.

## 8. Definition of Driver App complete

The Driver App is complete only when:

- D01-D08 and U01-U06 are closed or explicitly removed from MVP by the product owner.
- Frozen authorization, one-active-job, lifecycle, geofence, cancellation, and money rules pass targeted server checks.
- Maps, Realtime, Push, foreground/background location, document upload, and Auth recovery work on a real Android device.
- An Independent Driver and an Office Driver complete the relevant journeys with `PENDING`, `ACTIVE`, `REJECTED`, and `SUSPENDED` coverage.
- A protected installable Android release is produced with no committed secrets.
- Remaining legal/operations dependencies are named as launch blockers, not silently marked complete.

## 9. Standard dispatch prompt

> Execute Packet [ID] from `docs/DRIVER_APP_EXECUTION_PLAN.md` using gpt-5.6-luna with xhigh reasoning. Read `AGENTS.md`, `fast-execution`, `ponytail`, the frozen rules, and only the relevant Driver/design/database rules. Own only the listed files, preserve all existing untracked changes, and request shared-file edits from root. Reuse the current UI -> Riverpod -> DriverService -> Supabase flow. Do not rebuild closed contracts, add dependencies/infrastructure, expose secrets, touch Production, commit, or push. Implement one meaningful unit, run the smallest affected check once, and return changed files, exact evidence, blockers, and unverified states. Root will independently review and decide acceptance.

## 10. Wave 1 checkpoint — 2026-09-12

| Slice | Status | Evidence / remaining boundary |
|---|---|---|
| Independent Driver application | IMPLEMENTED | Authenticated CUSTOMER can submit one PENDING Independent Driver and Motorcycle application; STAFF, Office Driver, and non-PENDING mutation paths are denied. Approval remains trusted-only. Hosted/local SQL execution is still open because no PostgreSQL runtime is connected. |
| Driver request and waiting UX | FIXTURE_VERIFIED | Server-owned bidding deadline is rendered, expiry refreshes state, long content is bounded, dispatch internals stay hidden, and waiting view compares customer and Driver prices using the existing offer RPC. |
| Foreground location ownership | FIXTURE_VERIFIED | Home and active-trip screens share one process session, use idle/active movement thresholds, recover permissions through settings, and avoid unnecessary stationary writes. Background/terminated Android acceptance remains open. |
| Integrated Flutter | FIXTURE_VERIFIED | `flutter analyze --no-pub` passed. All 42 Driver tests passed across the integrated run and focused reruns after correcting two fixture scrolling issues. |
| Database contract | BLOCKED_BY_CONFIG | The rollback SQL asset is retained, but `npx supabase status` confirmed no Docker/Podman-backed local PostgreSQL runtime. No hosted mutation was attempted. |

Wave 1 does not close D02 background restore, D03 staged dispatch signals,
D05 post-assignment contact, D06 cancellation review flags, D07 commission
truth, or real-device/release acceptance.

## 11. Wave 2 checkpoint — 2026-09-12

| Slice | Status | Evidence / remaining boundary |
|---|---|---|
| D03 progressive dispatch | SOURCE_IMPLEMENTED | One trusted, bounded PostGIS tick records newly eligible candidates and emits targeted 4/6/8 km `NEW_WORK` signals without client polling or paid routing. The original generic signal remains fixed to the initial 2 km audience. Repeated/concurrent ticks deduplicate through candidate and outbox uniqueness. |
| D03 scheduling | BLOCKED_BY_CONFIG | Invoke `public.run_driver_progressive_dispatch_tick()` approximately every 20 seconds through a trusted Development scheduler. No cron job was embedded in the migration because environment scheduling is deployment configuration. |
| D06 cancellation review | SOURCE_IMPLEMENTED | The third post-assignment `DRIVER_CANCEL` in a rolling 7-day window creates one service-role-only immutable operations-review flag. Driver serialization plus a unique constraint prevents duplicate flags. It does not suspend the Driver or return the order to bidding. No Driver notification was invented because the current apps have no valid operations-review consumer or route. |
| Database runtime | BLOCKED_BY_CONFIG | Focused rollback SQL contracts are retained. Local PostgreSQL remains unavailable from the previously confirmed no-Docker/no-Podman runtime, and no hosted migration or Production mutation was attempted. |
| Flutter | PREVIOUSLY_VERIFIED | Not rerun because Wave 2 changes only new database migrations/tests and this plan; Driver App code and consumed notification types were not changed. |

Wave 2 source closes D03 and D06 implementation only. D02 background restore,
D05 post-assignment contact, D07 commission truth, operations resolution UI,
Development migration/scheduler acceptance, and real-device/release acceptance remain open.

## 12. Wave 3 checkpoint — 2026-09-13

| Slice | Status | Evidence / remaining boundary |
|---|---|---|
| D05 assigned customer contact | FIXTURE_VERIFIED | Narrow auth-derived name/phone RPC and four-active-state contact card implemented. Tap performs a fresh server recheck before opening the dialer. Focused contact test and Driver analyze passed. Final independent review and hosted SQL execution remain open. |
| D02 Android active-trip tracking | FIXTURE_VERIFIED / DEVICE_OPEN | Shared-session mode changes now invalidate stale writes, stop active-trip foreground streaming when returning idle in background, and never create a new location foreground service from background with while-in-use permission. The focused lifecycle suite passed 6/6 and Driver analyze passed. Physical-device/background/terminated acceptance is not claimed. |
| D07 commission truth | SOURCE_IMPLEMENTED / SQL_TEST_OPEN | DEC-006 starts promotion at trusted first approval/ACTIVE activation without reset on restoration; legacy completed orders receive no retrospective charges and missing financial values remain unknown. The source now includes immutable completion snapshots, bounded earnings, commission facts, a separate signed Driver-credit ledger, service-role-only manual top-up, commission debit, and configurable Independent candidate/offer threshold gates. It is not runtime-accepted until the focused rollback SQL contract executes. |
| D07 Driver earnings UI | FIXTURE_VERIFIED / BACKEND_OPEN | Driver App now consumes one bounded earnings RPC. Independent accounts show gross, commission, and net while legacy unknown rows remain explicitly non-retrospective; Office Drivers show gross only. Focused model test passed and Driver analyze passed. Runtime depends on the unaccepted D07 backend migration. |
| Agent capacity | BLOCKED_BY_USAGE | Contact review worker hit the Luna usage limit on continuation. Do not substitute another model or redeem credits without owner direction. |

The initial location continuation was interrupted after no checkpoint, but its
bounded source edits were recovered, root-reviewed, corrected to keep the
permission check before foreground stream creation, and fixture-verified.
Root also reviewed the contact UI, provider, model, fresh-read/dialer path, and
SQL test; no further contact change was required.

After DEC-006 acceptance, finance, location, and a fresh contact review were
dispatched to Luna xhigh again. Location and contact are now accepted at the
source/fixture boundary. Finance produced a draft migration, which root corrected
to prevent spoofed activation timestamps and preserve authoritative lifecycle
behavior. Root then added the minimal credit ledger/top-up/threshold gates; the
focused rollback SQL contract and database runtime execution remain open.
The account usage read showed 92% of the five-hour allowance consumed and
one available usage-reset credit. No reset was redeemed without permission.

Previously passing contact checks were not rerun because no relevant contact
code changed. Database runtime, scheduler, Maps/Push configuration, real
Android acceptance, and protected release signing remain unverified/open.

## 13. Wave 4 UI checkpoint — 2026-09-13

| Slice | Status | Evidence / remaining boundary |
|---|---|---|
| U02 Driver Home | FIXTURE_VERIFIED | Home reuses the bounded earnings provider for Trips Today and truthful net-today (Independent) or gross-trip-value-today (Office) summaries. Unknown legacy Independent finance is shown as not calculated, never zero. The existing active route map is shown only with authoritative coordinates; current location is enabled only after location startup succeeds. |
| U05 History detail | FIXTURE_VERIFIED | Tapping a history card opens the existing native bottom-sheet pattern with only authoritative service, status, date, pickup, destination, and price. No customer identity, contact, or invented finance is exposed. |
| U06 resilience source QA | FIXTURE_VERIFIED / DEVICE_OPEN | Focused coverage proves denied-permission recovery copy, one reconnect action, long Arabic addresses and large price at 2x text scale, and active-order startup routing. The Android acceptance ledger explicitly keeps permission Settings return, offline/reconnect, GPS, Maps, and process restore open for a real device. |
| Integrated Driver check | FIXTURE_VERIFIED | The three focused Wave 4 files passed together (6 tests), then `flutter analyze --no-pub` passed with no issues. |

No dependency, backend, router, polling, or new state layer was added in Wave 4.
Maps/Push configuration, real Android lifecycle acceptance, database deployment,
and protected release signing remain external/open gates.
