# Implementation Progress

## Current Milestone

Milestone 6 — Driver App Core (complete)

Milestone 6.1 — Driver App Business Freeze Reconciliation (complete)

Milestone 7A — User Flow Backend Delta (complete)

Wave A — Security + Transaction Integrity — **COMPLETE**

Wave B — Recovery + Auth Reliability — **COMPLETE WITH EXTERNAL AUTH CONFIGURATION PENDING**

Wave C — Read Correctness + Small High-Value Fixes — **COMPLETE**

Deep Code Review Evidence Closure — **COMPLETE**

System Validation Gate 2 — **PASS WITH ISSUES**

Milestone 7 — User App Core (complete)

User App Core — **COMPLETE**

Gate 7B — User + Driver Core End-to-End Integration — **PASS**

Milestone 8 — Maps + Location + Route Quote + Suggested Pricing + PostGIS Dispatch — **COMPLETE WITH EXTERNAL CONFIGURATION PENDING**

Milestone 9 — Realtime + Push Notifications — **COMPLETE WITH EXTERNAL CONFIGURATION PENDING**

Milestone 10 — Safety + Driver Verification + Geofence Enforcement + Delivery Confirmation — **COMPLETE WITH EXTERNAL CONFIGURATION PENDING**

UI/UX Excellence — User + Driver Apps — **COMPLETE WITH EXTERNAL VISUAL ACCEPTANCE PENDING**

Biko Visual Redesign — Foundation — **COMPLETE**

## UI/UX Excellence — User + Driver Apps

- Audited the implemented Arabic-first User and Driver journeys only. No new screen, backend contract, dependency, business rule, Auth flow, pricing rule, lifecycle transition, or notification behavior was introduced.
- Driver Home now prioritizes the active trip, availability shows honest transition/eligibility states with one actionable verification reason, and request cards expose the already-projected pickup/route distance and duration without dispatch internals. Lifecycle CTAs use imperative operational copy and retain the existing trusted actions.
- Customer assigned-Driver identity now gives the motorcycle plate a dedicated comparison row. Ride still has no OTP UI; Delivery still has no Pickup OTP UI and retains only the final Delivery Confirmation Code.
- CR-028 is resolved: shared price, route, service, and order-status presentation inherits each app's `ColorScheme`, while both app themes own the warning, success, and error semantics.
- App Core and User App test suites passed. All Driver test files passed, including the focused Home priority, verification blocker, request metadata, lifecycle copy, and recovery widget checks. `flutter analyze` reports no issues for App Core, User App, and Driver App.
- No Android emulator or physical device was connected. Live small/typical/large-phone visual acceptance, Maps, Push, and device permission behavior remain external acceptance work; no live visual claim is made.

## Biko Visual Redesign — Foundation

- **COMPLETE** on 2026-08-31. `DESIGN.md` is the approved Biko V2 source of truth: Biko red, soft neutral surfaces, charcoal text, semantic success/warning/error/info colors, Cairo-first Arabic typography, compact task-first layout, RTL/LTR exceptions, and 150/250/350ms motion guidance.
- Added the shared `packages/app_core/lib/biko_design.dart` foundation with centralized color, spacing, radius, and motion tokens plus Theme-native `AppTopBar`, `AppBottomNavigation`, `PrimaryButton`, `SecondaryButton`, `AppTextField`, `ServiceCard`, `StatusChip`, `EmptyState`, and `ErrorState` components.
- Both User and Driver themes now consume the same Biko foundation. Existing service contracts, Supabase, Auth, RLS, pricing, lifecycle, maps, realtime, push, and verification behavior were not changed.
- Removed scattered legacy blue/teal visual tokens from the affected theme surfaces and routed shared status/loading presentation through the centralized semantic vocabulary.
- Focused App Core, User App, and Driver App widget tests passed before the final token-only refinement. Additional tests and Flutter analysis were intentionally not run after the visual-only refinement per the user's direction.

## Milestone 10 — Safety + Driver Verification + Geofence Enforcement + Delivery Confirmation

- Hosted Development migrations **`20260830185634_safety_driver_verification_delivery_confirmation`** and **`20260830190204_m10_legacy_assigned_driver_read_fix`** are applied. They extend the existing Driver/Motorcycle/Document model, add private `motorcycle_documents`, the private `driver-documents` Storage bucket, expiry reconciliation/outbox integration, trusted Ride/Delivery geofences, the audited Admin safety-override RPC, and preserve assigned-driver reads for historical orders without a motorcycle snapshot.
- Online eligibility now requires ACTIVE account/profile/office state, minimum age, approved current National ID/driving licence/selfie, an approved active motorcycle, and no active order. Ride discovery additionally requires a recorded helmet/equipment acknowledgement. Existing active trips are allowed to finish after document expiry.
- Ride lifecycle uses trusted 200m Pickup arrival and 300m Destination completion with no OTP. Delivery uses one geofenced Pickup action with no Pickup OTP and one final 4-digit private Customer Confirmation Code at the 300m Destination boundary. Codes are hashed for verification, kept out of ordinary order rows and notification payloads, rate-limited after five failures, and consumed on completion.
- Driver App now exposes verification status, expiry/rejection reasons, helmet acknowledgement, private JPG/PNG/PDF upload and replacement, service-sensitive active-trip controls, and the final Delivery Confirmation Code entry. User App presents verified assigned Driver identity/vehicle fields and the one final Delivery code only for active Delivery orders.
- Targeted hosted verification passed once in rollback, then once against the applied migration: 40 safety/verification/geofence/code/privacy/grant invariants, with zero temporary Auth users or operational rows remaining. Focused Driver and User contract tests passed; affected Driver/User analyses report no issues. The structural Auth OTP gate passed after narrowing it to forbidden login/SMS APIs.
- External configuration remains: trusted daily invocation of `enqueue_driver_document_expiry_notifications`, operations/Admin review UI, final legal confirmation of motorcycle document categories/criminal-record launch gate, and physical-device Storage/GPS acceptance. No Ride OTP, Delivery Pickup OTP, or full Dashboard/Finance work was added.

## Milestone 9 — Realtime + Push Notifications

- Hosted Development migration **`20260830174205_realtime_push_notifications`** is applied. It adds authenticated Push-token registration/revocation, a durable bounded notification outbox, safe Driver work signals, the `(created_at,id)` waiting-offer cursor, service-only dispatcher RPCs, RLS/grants, safe `search_path`, and only `notification_outbox` plus `driver_work_signals` in the Realtime publication.
- CR-015 is resolved with descending `(created_at,id)` keyset pagination and a 50-row page bound. CR-016 is resolved with a first-page/session generation guard that also resets loading/error state; delayed old pages cannot append. CR-017 is resolved with mutation-specific refresh scopes and one shared bounded terminal-order dataset for History/Earnings. A representative offer mutation now performs two post-write authoritative reads (three requests including the mutation), down from the previously measured eight total requests.
- User Realtime observes only the authenticated user's durable operational notification rows. Driver Realtime observes only own notifications plus RLS-filtered lightweight new-work signals. Both treat events as invalidation hints, keep manual refresh, refresh once on resume/reconnect, clean channels on session/dispose, and never subscribe to Profile, History, Earnings, or location writes.
- Realtime and FCM use the same stable outbox ID; a bounded in-memory identity set suppresses duplicate refresh/local presentation. Validated notification targets are fetched through existing owned/geographic read contracts before routing, and stale/inaccessible targets fall back to Home. No Push/Realtime payload performs a business mutation.
- Shared mobile Push support now covers contextual Arabic permission prompts, granted/provisional/denied behavior, token rotation/upsert, multiple devices, best-effort bounded sign-out revocation, Android notification channel/permission/desugaring, iOS remote-notification mode/entitlements, restrained foreground presentation, background tap handling, and terminated-launch deferral until Auth bootstrap.
- The narrow local **`push-dispatch`** Edge Function claims at most five intents, resolves at most 200 eligible tokens per intent in PostgreSQL, mints an FCM HTTP v1 access token only inside the server boundary, disables clearly unregistered tokens, records redacted retry status, and never participates in an order transaction.
- Hosted rollback verification passed on the corrected run and two explicit reruns, the final one adding actual outbox/work-signal RLS visibility checks. It covered own token register/upsert/revoke, multiple devices, cross-user/anon/direct-write denial, service-only dispatch grants, outbox identity deduplication, Push-failure isolation, invalid-token disablement, shared new-work identity, order-events append-only protection, and a 60-offer keyset boundary with an earlier offer disappearing. Cleanup is zero and both Realtime tables are published.
- Focused Flutter verification passed: App Core **11/11** across notification/session identity plus affected Auth recovery, User event mapping **2/2**, Driver event/pagination plus affected recovery **23/23**, and the corrected delayed-page seam **5/5**. `flutter analyze` reports no issues for App Core, User App, and Driver App.
- External configuration remains: Firebase app values for both apps, Firebase/APNs project setup, hosted `FIREBASE_SERVICE_ACCOUNT_JSON`, hosted deployment and trusted scheduled invocation of `push-dispatch`, plus physical-device foreground/background/terminated Push acceptance. No live FCM delivery claim is made.
- Full evidence: `docs/MILESTONE_9_REALTIME_PUSH_REPORT.md`.

## Milestone 8 — Maps + Location + Route Quote + Suggested Pricing + PostGIS Dispatch

- Hosted Development migration **`20260830163437_maps_location_pricing_dispatch`** is applied. It installs PostGIS 3.3.7, one UPSERT row per Driver location, centralized 120-second freshness and 20-second dispatch-step settings, GiST spatial indexes, server-time 2/4/6/8 km discovery, candidate maintenance, geographic offer/assignment guards, trusted route quotes, per-service pricing configuration, exact 70% minimum enforcement, and stable-intent-first recovery.
- The rollback-only hosted verification passed once after one corrected harness assertion: own-vs-Customer location writes, one-row UPSERT, fresh/stale/offline/suspended/active-job exclusions, 2/4/6/8 km stages, outside-8-km exclusion, candidate privacy, RIDE/DELIVERY pricing isolation, exact/below/above 70%, quote ownership/coordinates/expiry, stable retry after expiry, direct-write denial, anon denial, RLS, grants, and safe `search_path`. No temporary rows or test pricing survived rollback.
- User App now has real map pickup/destination selection, current-location permission handling, 350 ms Places debounce, route preview, trusted distance/duration quote state, Suggested Price/minimum/proposed-price presentation, client minimum validation, quote invalidation on route edits, quote-aware stable creation intent, and Book Again fresh-quote behavior.
- Driver App now uploads foreground location immediately, on movement (50 m filter, 15-second upload floor), and with a 90-second foreground heartbeat so a stationary Driver remains inside the centralized 120-second freshness window. It requires a usable fresh location before going Online, consumes the geographic request projection, shows request/active route maps, and opens external Google Maps navigation. Assigned Drivers may continue foreground uploads.
- CR-014 is resolved through auto-disposed detail families, manual detail refresh, app-resume invalidation, and active User detail replacement. CR-007 main-manifest INTERNET declarations are implemented for both apps; merged release-manifest/device acceptance remains pending.
- Focused verification passed: hosted SQL contract, 16 User core/maps tests, Places debounce widget test, uncertain stable-intent widget test, active-detail freshness widget test, 4 Driver model tests, and clean `flutter analyze --no-pub` for both apps. Previously passed Milestone 7/7B suites were not rerun.
- External configuration remains: restricted Android/iOS Maps SDK keys, `GOOGLE_MAPS_SERVER_API_KEY`, deployment of the two narrow Edge Functions, authoritative RIDE and DELIVERY Base/distance values in `service_types.config`, and an approved operating-zone polygon. No live Google Maps/Places/Routes smoke or production/release-device claim is made.
- Full evidence: `docs/MILESTONE_8_MAPS_LOCATION_PRICING_DISPATCH_REPORT.md`.

## Gate 7B — User + Driver Core End-to-End Integration

- **PASS** on 2026-08-30. Hosted migration parity was confirmed through **`20260830151837_user_app_core_bridge`**; Gate 7B required no backend migration or production Flutter change.
- One rollback-only hosted harness used isolated Customer A/B and Driver A/B identities. Trusted setup added only candidate relationships; all business actions used the current `create_order`, Driver request/offer, withdrawal, acceptance, lifecycle, cancellation, expiry, and customer/Driver read contracts.
- Ride and Delivery creation, stable creation intent, two-Driver offers, withdrawal/replacement, atomic assignment, cross-order offer closure, one-active-job denial, full Driver lifecycle, Customer/Driver cancellation propagation, authoritative expiry, Book Again, ownership/privacy negatives, stale-offer rejection, event recording, and consistent terminal history all passed once.
- Restoration/recovery evidence passed at the current architecture seam: 9 focused User widget checks, 11 focused Driver router/state checks, and 2 App Core recovery/presentation checks. User BIDDING plus all active statuses and Driver assigned/on-way/arrived/in-progress restoration passed; one uncertain User creation and one lost Driver lifecycle response reconciled without replay.
- Cleanup audit returned zero reserved Gate 7B Auth users, profiles, Drivers, candidates, orders, offers, Delivery details, events, offices, or memberships. No physical-device run, Maps, Realtime, old gate suite, full app suite, or Flutter analysis was run because production code did not change.
- No new P0/P1 or non-blocking integration defect was found. **Milestone 8 is unblocked.** Full evidence: `docs/GATE_7B_TWO_APP_INTEGRATION_REPORT.md`.

## Milestone 7 — User App Core

- Preserved the existing shared email/password Auth, session restoration, password recovery, safe error mapping, bounded mutation recovery, and Arabic RTL foundation.
- Added the User App core journey: dashboard Home, Ride/Delivery forms, development-only location selections, hosted `create_order` integration with stable `creation_intent_id`, server-expiry bidding countdown, privacy-safe offer cards, atomic `accept_offer`, assigned-order lifecycle display, frozen customer cancellation, terminal states, Book Again with a new booking flow, bounded history, profile, and reachable sign-out.
- Added the focused hosted bridge migration **`20260830151837_user_app_core_bridge`** for customer-owned expiry reconciliation and assigned-driver public summary reads. Both functions use safe `search_path`, deny anon execution, and grant only authenticated execution.
- Targeted User App verification passed: 24 focused Flutter tests covering Ride/Delivery contracts, validation limits, stable-intent uncertain recovery without replay, countdown refresh-at-zero, offer empty/multiple states, privacy-safe driver data, assigned rendering, cancellation boundaries, terminal cleanup, Book Again prefill, bounded history, and independent profile/sign-out access.
- `flutter analyze` passed for `apps/user_app`. App Core, Driver App, Dashboard, full backend gates, Auth smoke, Maps, Realtime, push, OTP, ratings, payments, and other deferred milestones were not rerun or implemented.

## Authorized Remediation Waves — Historical Checkpoints

- Selected sequence: Wave A security/transactions → Wave B mutation/Auth/network recovery → Wave C Driver data/state → targeted pre-User-App revalidation. Do not assume PASS or start User Core while a required gate is unproven.
- Applied local `202608300009_wave_a_security_transaction_integrity.sql` to connected Development as **`20260830133522_wave_a_security_transaction_integrity`**.
- CR-001/002: office permission and target membership are correlated; active profile/membership/office status is enforced by existing private helpers. Active platform administrators retain suspended-office recovery visibility; suspended/deleted administrators do not retain elevated reads.
- CR-003: submit/withdraw/accept use wall-clock expiry checks. Submission rechecks after the Driver lock; acceptance rechecks after the complete affected-offer lock set. No lock/uniqueness protection was removed.
- CR-009 pulled forward from pre-User-App P2 work: acceptance requires the owning active CUSTOMER profile from auth context.
- CR-020: added complete-or-empty assignment/state CHECKs and replaced the old same-order FK/index with a same-order/Driver/price FK/index. Normal cancellation retains assigned history; no generic state editor or recovery bypass was added.
- Hosted preflight found zero malformed assignments. `supabase/tests/wave_a_security_transaction_integrity.sql` passed once: scoped positive/negative reads; inactive staff/membership/office/admin denial; three elapsed-window denials; customer-status/ownership denial; malformed assignment rejection; normal assignment/cancellation/lifecycle snapshots; changed-object grants/search paths; direct client write denial.
- Existing retained Gate 2 SQL fixtures were adapted to complete assignment fields/new FK name, but the Gate 2 suite was not rerun or marked PASS.
- **Historical CR-008 checkpoint:** the connected-tool capability probe serialized two independently submitted calls. Session 122199 ran 13:29:54.163988–13:29:56.175597 UTC; session 122200 ran 13:29:56.429924–13:29:58.432510 UTC on 2026-08-30. These intervals did not overlap. Final Evidence Closure later resolved CR-008 through the authenticated HTTPS application path.
- All verification fixtures rolled back. Follow-up cleanup returned zero reserved Auth users, profiles, offices, Drivers, documents, orders, offers, and events. No temporary infrastructure, CLI, dependency, Production change, or applied-migration edit.
- At this historical checkpoint Wave A remained partial on CR-008 evidence only. Final Evidence Closure below supersedes it. Existing hosted 6.1/7A migrations remained complete and were not rebuilt.

### Wave B — Recovery + Auth Reliability

- Applied local `202608300010_wave_b_recovery_auth_contracts.sql` to Development as **`20260830135840_wave_b_recovery_auth_contracts`**. Its focused hosted rollback checks passed earlier and were not repeated.
- CR-004: Customer creation now uses a caller-stable intent UUID. Same customer/key/payload returns one logical order; changed payload conflicts; a new key allows an intentional identical booking. Database uniqueness is the concurrency boundary.
- CR-005: installed PostgREST transport is configured with an eight-second timeout and no automatic retries. Mutation and recovery-read waits are independently bounded; timeout remains uncertain, never triggers write replay, and an unchanged snapshot cannot falsely unlock it. Exhausted recovery keeps navigation, Profile, retry, and sign-out available.
- CR-006: shared recovery callback routing, trusted recovery-session validation, new/confirm password form, duplicate-submit guard, `updateUser`, safe Arabic errors, and success state are implemented in both apps. Android/iOS callback XML and local Supabase redirect configuration contain `biko-driver-dev://auth-callback/` and `biko-user-dev://auth-callback/`. The connected tools cannot inspect hosted Auth URL Configuration, so **manual hosted redirect allowlist confirmation remains required** and full hosted end-to-end reset acceptance is not claimed.
- CR-011: one privacy-safe owned-offer read returns offer status plus authoritative order status/expiry/assignment/route summary. Valid waiting, elapsed, cancelled, selected-active, and withdrawn states remove stale actions correctly.
- CR-012: startup depends only on Driver account and active assigned order. Available-request and waiting-offer failures remain local; Profile/sign-out do not depend on operational feeds.
- CR-013/018: typed safe read failures distinguish unavailable, forbidden, Auth, connection, and generic failure. One shared Auth subscription handles its error channel, preserves valid sessions for retryable failures, and routes definitive invalid sessions without leaking raw errors.
- Focused verification passed: 13 App Core recovery/Auth tests, 14 Driver recovery/state tests, XML parse for both Android manifests and both iOS plists, and Flutter analysis for App Core, Driver App, and User App. No new P0/P1 was found in the changed scope.
- Final hosted cleanup returned zero reserved Wave B Auth users, profiles, Drivers, orders, offers, Delivery details, and order events.
- At the Wave B checkpoint CR-008 remained open. Final Evidence Closure later resolved it. CR-007 remains before Public Launch because `android.permission.INTERNET` is still absent from both main manifests; release build/signing verification was not pulled into Wave B.

### Wave C — Read Correctness + Small High-Value Fixes

- Applied local `202608300011_wave_c_read_correctness.sql` to Development as **`20260830143750_wave_c_read_correctness`**.
- CR-010: the guarded `IN_PROGRESS → COMPLETED` transaction now increments `drivers.completed_trip_count` exactly once. A set-based migration reconciliation aligns every stored count with actual completed orders. Hosted preflight and postflight both found zero mismatches; Development had zero Driver rows requiring correction.
- CR-026: the existing compact customer offer RPC now filters ACTIVE offers by the same current Driver eligibility used by selection: unexpired BIDDING order, online ACTIVE Driver/profile/office, current candidate, and no active assigned job. Offline or active-job offers remain ACTIVE and can reappear when eligibility returns; `accept_offer` still performs its own write-time revalidation.
- CR-019: the counter-offer sheet and completed-trip summary reuse the existing `formatAmount`; no formatter or presentation abstraction was added. The focused widget test preserved `105.50` in both locations and rejected whole-pound display.
- Hosted rollback verification passed exact 1/2 completion counts, stale repeat denial, cancellation/expiry exclusion, eligible/offline/candidate/account/office/active-job offer filtering, offline acceptance denial, customer ownership, the unchanged eight-field privacy projection, and changed-function grants/search paths. The first attempt stopped on an invalid test-only SUSPENDED+online fixture; the corrected rollback proof passed.
- Final hosted cleanup returned zero reserved Wave C Auth users, profiles, Drivers, offices, orders, offers, candidates, or order events, with zero completed-count mismatches. Driver App focused Flutter test and one Driver App analysis passed. App Core was unchanged and was not reanalyzed.
- At the Wave C checkpoint CR-008 and CR-024 remained open. Final Evidence Closure below supersedes that checkpoint.

### Deep Code Review Evidence Closure

- CR-008: RESOLVED using two independent authenticated HTTPS clients and the existing Development publishable application configuration. B ran `14:46:29.735678–14:46:30.817925 UTC`; A ran `14:46:29.736612–14:46:30.818234 UTC`, proving genuine overlap.
- Concurrent result: A returned HTTP 200; B returned HTTP 400 / `P0001`, `Driver already has an active assignment`. Final hosted truth was exactly one active Driver job, one complete assigned bundle, one SELECTED offer, one CLOSED competing offer, one untouched BIDDING losing order, and one assignment event, with no deadlock.
- Cleanup returned zero reserved CR-008 Auth users, profiles, Drivers, orders, offers, candidates, Delivery details, or events.
- CR-006 remains implemented with manual hosted Auth redirect confirmation required for `biko-driver-dev://auth-callback/` and `biko-user-dev://auth-callback/`. This does not block User App Core but must be confirmed before full password-reset E2E/release acceptance.
- CR-024: RESOLVED through focused current-status reconciliation. Historical Gate findings remain preserved and are explicitly labelled; current implementation and issue timing are authoritative.
- Remaining: CR-007, remaining CR-020 recovery/legacy review, and CR-023/027/030 before Public Launch; CR-025/028/029/031/032 remain safe to defer. CR-021/022 remain partially open for broader test evidence and are not falsely marked resolved. CR-014/015/016/017 are resolved by Milestones 8/9.
- No new P0/P1 was found. **System Validation Gate 2 = PASS WITH ISSUES; Milestone 7A = COMPLETE; User App Core = UNBLOCKED.**

## System Validation Gate 2 Remediation — Historical Checkpoint

- Applied local `202608300008_gate_2_remediation.sql` to Development as `20260830021017_gate_2_remediation`.
- SVG2-002–009 resolved: multiple cross-order waiting offers, shared mutation reconciliation/recovery, selected-offer composite FK, safe Arabic Auth errors, shared presentation, active-trip bootstrap restoration, and private candidate request RPC boundary.
- SVG2-001 implementation added database active-job uniqueness, Driver lock/recheck, other-offer closure, unavailable-after-assignment, and active-job eligibility denial. At this checkpoint the overlapping race remained unproven; Final Evidence Closure later passed it.
- The two submitted race calls ran sequentially according to recorded backend timestamps (first ended 02:14:59.130297 UTC; second began 02:15:01.173019 UTC). Do not report this as concurrency PASS. An additional authorized concurrent-session test path is required.
- Hosted A/B/D/E/L and changed-object security checks passed in a rollback transaction. Five shared-core and seven Driver checks passed. Full Flutter analysis ran once per affected scope; only the flagged files/providers were rechecked after lint fixes and reported no issues.
- All committed race fixtures were explicitly deleted; cleanup audit returned zero test identities and operational records. No dependencies, CLI, infrastructure, or future-milestone feature was added.
- SVG2-010 final specification sync waits for complete backend verification. SVG2-011–013 remain OPEN, unchanged. Detailed evidence is in the issue register and appended report remediation section.
- Existing Milestone 7A completion and hosted migrations are preserved as historical completed work, not newly implemented in this remediation.

## System Validation Gate 2 — Original Evidence

- Gate result: **FAIL** on 2026-08-30. Hosted/local migration parity is clean through `20260830010117_driver_business_freeze_reconciliation`; no hosted implementation drift exists.
- P1 `SVG2-001`: hosted `accept_offer` allowed one Driver to be selected into two simultaneous active orders.
- P1 `SVG2-002`: the backend permits multiple cross-order ACTIVE offers while Driver App loads only one scalar waiting offer.
- P1 `SVG2-003`: uncertain Driver mutations do not refresh authoritative hosted state before allowing user recovery/retry.
- A later explicit 6.1-only entry gate authorized Milestone 7A after the hosted 6.1 migration was confirmed. Milestone 7A is complete; the three existing Gate 2 P1 contracts were not changed or reverified by this backend delta.
- Full evidence: `docs/SYSTEM_VALIDATION_GATE_2_REPORT.md`; concise issues: `docs/CURRENT_ISSUES_REGISTER.md`.
- Cleanup audit passed with zero Gate 2 Auth users, profiles, offices, drivers, orders, or offers left hosted.

## Milestone 7A — User Flow Backend Delta

- **COMPLETE** on 2026-08-30 after hosted migration and one rollback-based targeted verification wave.
- Applied `202608300006_user_flow_backend_delta.sql` to hosted `biko-development` as `20260830014754_user_flow_backend_delta`.
- Applied the necessary follow-up `202608300007_user_flow_privacy_hardening.sql` as `20260830015129_user_flow_privacy_hardening` after the initial delta exposed newly added recipient columns through the existing candidate-row RLS boundary.
- New orders receive a server-controlled 90-second `bidding_expires_at`; `submit_offer`, `withdraw_offer`, and `accept_offer` reject elapsed bidding windows without cron or Edge Functions.
- Extended the existing `create_order` RPC for Delivery recipient name/phone, parcel weight above 0 through 8 kg, and declared value from 0 through 3,000 EGP. Ride calls retain the original compact contract through defaulted Delivery arguments.
- Delivery recipient and parcel data is stored in one RLS-protected `order_delivery_details` row per Delivery order. Customers can include it in the normal owned-order relational read for Book Again; pre-assignment Drivers cannot read it.
- Added frozen customer cancellation behavior: BIDDING without a reason, DRIVER_ASSIGNED with a reason, DRIVER_ON_WAY/DRIVER_ARRIVED with a reason and `LATE_CANCEL`, and denial from IN_PROGRESS or terminal states.
- Reused `order_events`; cancellation events now include useful reason/type metadata while normal clients retain no direct event writes.
- Added `get_customer_order_offers(order_id)` as the single compact pre-selection read model. It returns only offer price, Driver public reference/first name/photo/type, Office display name, and completed-trip count. Raw customer offer-row access was removed; ratings remain deferred because no real rating model exists.
- Existing authenticated table grants already make persisted `proposed_price` immutable to clients. Terminal orders remain terminal and retain Ride/Delivery prefill data for a new normal `create_order` call.
- No new speculative index was added: offer listing reuses the existing order/offer indexes, and Delivery details use their one-to-one primary key. No paid API, Realtime, polling, cron, Edge Function, or extra client round trip was introduced.
- Hosted verification passed the 20 requested invariants once, plus elapsed-window offer submission/acceptance checks and the changed-object grant/search-path delta. Cleanup confirmed zero temporary Auth users, profiles, offices, drivers, orders, offers, Delivery details, or order events remained.

Deferred from Milestone 7A:

- At that checkpoint: Suggested Price, 70% minimum, Maps/Places, distance/ETA, progressive dispatch, geofences, Realtime, FCM, safety verification, Ratings, finance/commission, cancellation cooldown, and operating zones. Milestones 8–10 now supersede the Maps/Realtime/Safety portion.

## Milestone 6.1 — Business Freeze Reconciliation

- Milestone 6 Core remains complete and was not rebuilt or reverified.
- Added one focused local migration for append-only `order_events`, trusted offer withdrawal, trusted pre-trip Driver cancellation with a required reason, non-editable active offers, and backend-provided Online denial reasons.
- Added restrained Arabic secondary actions for `سحب العرض` and `إلغاء الرحلة`; the primary lifecycle action remains dominant.
- Decoupled Active Trip UI actions from RPC names inside the model so later verification steps can be inserted in the service layer without rebuilding the screen.
- Prepared Earnings presentation by Driver type without inventing financial values: Independent shows deferred commission/net labels; Office Driver shows gross completed-trip value only.
- Applied `202608300005_driver_business_freeze_reconciliation.sql` to hosted `biko-development` as `20260830010117_driver_business_freeze_reconciliation` and passed the targeted rollback-based database verification.

Historical deferrals at the 6.1 checkpoint (later milestone status is recorded above):

- Maps / Location milestone: 200m Pickup arrival, 300m Destination completion, GPS Retry, audited geofence override, progressive 2/4/6/8 km PostGIS dispatch, 20-second expansion, and ETA.
- Verification / Safety milestone: superseded by DEC-005 and Milestone 10 — no Ride or Pickup OTP, one final Delivery Confirmation Code, trusted geofences, and no proof photo.
- Driver/Motorcycle Verification: completed in Milestone 10 with `motorcycle_documents`, document completeness/expiry, minimum age, motorcycle validity, and passenger helmet eligibility.
- Finance milestone: Independent 10%, Office 7%, launch promotion, commission ledger, `commission_due`, `platform_balance`, settlement, and real gross/commission/net calculations.
- Operations / Audit milestone: cancellation abuse flag, operations review, and controlled Admin override actions.

## Business Rules Freeze

- Business Rules Freeze v1.0 adopted on 2026-08-30. Canonical reference: `docs/BUSINESS_RULES_FREEZE_V1.md`.
- This documentation decision does not change completed milestone evidence or mark newly frozen behavior as implemented.
- Subsequent milestones incorporated Suggested Price/minimum, progressive PostGIS dispatch, offer withdrawal, document/motorcycle enforcement, trusted geofences, parcel constraints, cancellation controls, and required events. Remaining work includes commission ledger, broader operations/Admin UI, external schedulers/configuration, and East Cairo zone configuration. DEC-005 replaces trip OTPs with one final Delivery Confirmation Code.

## Completed Tasks

- Initialized the Git repository and required monorepo structure.
- Moved the eight unique supplied specifications into `docs/`.
- Scaffolded separate User and Driver Flutter apps for Android/iOS.
- Scaffolded the shared `app_core` package.
- Scaffolded the unified Next.js + TypeScript + Tailwind dashboard.
- Added placeholder-only environment templates and secret exclusions.
- Added Supabase local configuration, the foundation migration, reference roles, permissions, and service types.
- Added Arabic-first RTL setup screens that remain safe without credentials.
- Removed OTP from current implementation scope by explicit product-owner decision.
- Connected the hosted Supabase Development project `biko-development` (`jlkzgsgfzolhwraakhbt`, `eu-west-1`, `ACTIVE_HEALTHY`).
- Applied `202608290001_foundation.sql` to the hosted Development database as migration `20260829123858_foundation`.
- Verified all 11 foundation tables, 6 enums, constraints, 10 named indexes, the auth/profile trigger, seed data, and the migration-defined RLS state against the hosted database.
- Added the shared `app_core` email/password `AuthService`, auth-state listener, and protected `go_router` route factory.
- Added Arabic RTL sign-in, sign-up, forgot-password, authenticated-home, and logout flows to both Flutter apps.
- Kept public signup limited to email and password; no client role or account-type metadata is sent.
- Preserved the database trigger that creates a `CUSTOMER` profile and requires trusted logic for elevated identities.
- Verified `auth.users` maps to exactly one `public.profiles` row with `CUSTOMER` as the default, including when privileged metadata is supplied.
- Verified duplicate profile IDs and duplicate driver identities are rejected by the existing primary-key and unique constraints.
- Verified trusted backend driver creation for both `INDEPENDENT` (without office) and `OFFICE_DRIVER` (linked to one office), with `PENDING` as the default status.
- Added the focused authorization migration `202608300001_authorization_rls.sql` with minimal private security-definer helpers, explicit execute grants, protected-table least-privilege SELECT policies, and no client DML privileges for roles or office membership.
- Applied `202608300001_authorization_rls.sql` to hosted `biko-development` (recorded remotely as `20260829230833_authorization_rls`) and verified role/permission mappings, office membership scope, customer and driver isolation, anonymous denial, and Super Admin global access in one rolled-back transaction.
- Revoked public and authenticated EXECUTE access to the existing `handle_new_auth_user` trigger function; it remains trigger-only and is not an RPC surface.
- Added `202608300002_core_bidding_engine.sql` with `orders`, `offers`, and trusted `order_driver_candidates` eligibility boundaries, reusing the existing customer/driver/profile model.
- Added the `create_order`, `submit_offer`, and atomic `accept_offer` RPCs. Client identity is derived from `auth.uid()`, direct order/offer writes are revoked, and active offers are unique per driver/order.
- Added targeted RLS for customer-owned orders/offers, candidate-gated driver visibility, driver-owned offers, and office/Super Admin scope without exposing all BIDDING orders globally.
- Added `202608300003_order_state_machine.sql` without editing the applied Milestone 4 migration. It adds lifecycle timestamps, a default 30-minute `bidding_expires_at`, and an expiry index.
- Added trusted locked driver transition RPCs: `driver_on_way`, `driver_arrived`, `start_order`, and `complete_order`.
- Added customer-owned `cancel_order` for eligible pre-trip states and trusted `expire_order` for stale BIDDING orders; both close remaining ACTIVE offers and make terminal states final.
- Completed Backend Gate 1 database inspection against hosted `biko-development`: all four migrations through Milestone 5 are applied, all 14 expected public tables use RLS, protected tables have no anonymous grants or authenticated DML grants, and all sensitive RPC grants/search paths match their intended trust boundaries.
- Confirmed 38 relevant integrity constraints, all 10 hot-path indexes, no deployed Edge Functions, and no remaining Backend Gate temporary rows.
- Ran the Supabase Security Advisor once. Its only findings are expected warnings for the intentional authenticated `SECURITY DEFINER` RPC boundaries; anonymous execution is denied and every RPC has a safe `search_path`.
- Recorded the auditable result in `docs/BACKEND_GATE_1_REPORT.md`.
- Passed the single fresh-account hosted Auth smoke after development email confirmation was disabled: immediate signup session, exactly one CUSTOMER profile with no privileged identity, sign-out, password sign-in, valid session, refresh-token session restore, and final sign-out. The exact test identity and cascaded data were deleted afterward.
- Added the Arabic RTL Driver App shell with protected Home, Trips, Earnings, Profile, Request Details, Offer Waiting, and Active Trip routes.
- Implemented trusted Online/Offline control, candidate-gated available requests, customer-price acceptance, counter-offers through `submit_offer`, manual offer/assignment refresh, and active-trip recovery from hosted state.
- Connected the single-action trip lifecycle to `driver_on_way`, `driver_arrived`, `start_order`, and `complete_order`, with loading, stale-state, completion, empty, error, and retry handling.
- Added bounded Driver history, clearly labelled recent gross earnings, driver status/type/office relationship, and shared Auth sign-out access without Maps, Realtime, Firebase, polling, onboarding, or advanced finance.
- Applied hosted migration `driver_app_core` (`20260830001817`) with the trusted `set_driver_online` RPC and assigned-driver order read policy.

## In Progress

- None.

## Blocked

- No blocker remains for Milestone 2A.
- No Backend Gate 1 blocker remains.
- No Milestone 6 blocker remains.
- No Milestone 6.1 blocker remains.
- No Milestone 7A blocker remains.
- No System Validation Gate 2 blocker remains for User App Core. CR-008/SVG2-001 and CR-024/SVG2-010 are resolved; Gate 2 is PASS WITH ISSUES and User App Core is unblocked.
- Wave B hosted password-recovery acceptance requires manually allowlisting `biko-driver-dev://auth-callback/` and `biko-user-dev://auth-callback/` under Supabase Authentication → URL Configuration; the connected database tools cannot inspect or edit that setting.

## Tests Passed

- Wave B focused Flutter verification: 13 App Core recovery/Auth tests and 14 Driver recovery/state tests passed. These include never-settling mutation/read budgets, no replay, late-commit reconciliation, typed read errors, the actual Supabase Auth SDK request/router seam, recovery-session and duplicate-submit denial, terminal offer truth, critical bootstrap independence, and Profile/sign-out independence.
- Wave B Flutter analysis passed for `packages/app_core`, `apps/driver_app`, and `apps/user_app`. Driver/User passed on the single run; App Core passed when only its failed style-only run was repeated after six exact brace fixes.
- Both Android main manifests and both iOS Info.plists parse as XML, and local Supabase configuration contains both exact Development callback redirects. Hosted Auth allowlist acceptance remains unconfirmed.

- `flutter analyze` and `flutter test` for `packages/app_core`.
- `flutter analyze` and `flutter test` for `apps/user_app`.
- `flutter analyze` and `flutter test` for `apps/driver_app`.
- `npm run lint` and `npm run build` for `apps/dashboard`.
- `scripts/check-foundation.ps1` for required tables, identity constraints, RLS enablement, auth trigger, and absence of OTP implementation code.
- PostgreSQL syntax parse of all 56 statements in the foundation migration.
- Hosted Supabase verification: 11 tables, 6 enums, 11 primary keys, 14 foreign keys, 6 unique constraints, 9 check constraints, and 10 named indexes.
- Hosted Supabase seed verification: 2 service types, 4 roles, 26 permissions, and the expected role-permission counts.
- Hosted Supabase trigger/RLS verification: `auth_user_created` is enabled; RLS is enabled on all 11 foundation tables, with `service_types` retaining explicit public read-only reference-data access.
- Static auth wiring check: both apps initialize Supabase from client-safe compile-time environment values and use the shared auth service/router; no role metadata is sent by signup.
- Previously passed Flutter analysis/tests were not rerun because the current verification gap is hosted Auth behavior, not unrelated foundation code.
- Targeted hosted verification passed in a rolled-back transaction: CUSTOMER profile mapping, duplicate protection, trusted driver links, `PENDING` defaults, independent drivers without offices, and office drivers linked to one office.
- Post-rollback hosted counts confirmed no temporary profiles, drivers, or offices remained.
- Targeted hosted authorization verification passed: own-vs-other customer profiles, own-vs-other driver records, office scope isolation, Super Admin global scope, anonymous SELECT denial, and revoked authenticated role/membership writes.
- Security helper verification passed: all four helpers are `SECURITY DEFINER` with `search_path=''`, callable only by `authenticated`; the auth trigger is no longer executable by `anon` or `authenticated`.
- Hosted Milestone 4 verification passed in a rolled-back transaction: customer BIDDING order creation, private order/offers isolation, candidate-gated driver visibility, active/inactive driver offer validation, offer ownership, cross-order acceptance rejection, assignment fields, and terminal offer statuses.
- Hosted concurrent acceptance verification passed with two overlapping sessions: one acceptance committed and the competing acceptance was rejected after the locked order transitioned, leaving exactly one selected offer and one closed offer.
- Post-verification cleanup confirmed all Milestone 4 test users, orders, and offers were removed.
- Hosted Milestone 5 verification passed in a rolled-back transaction: all four valid driver transitions, assigned-driver authorization, invalid jump rejection, pre-trip customer cancellation, in-progress/completed cancellation rejection, stale BIDDING expiry, offer closure, terminal-state protection, lifecycle timestamps, and direct lifecycle-write denial.
- Hosted concurrent stale-transition verification passed with two overlapping `complete_order` calls: one succeeded, one was rejected after the row lock/state check, and the final order was `COMPLETED` with one completion timestamp.
- Post-verification cleanup confirmed all Milestone 5 test users and orders were removed.
- Backend Gate catalog verification passed: four expected migrations, 14 RLS tables, zero protected anonymous table grants, zero authenticated DML grants, 38 relevant constraints, 10 hot-path indexes, correct sensitive-RPC grants/search paths, and zero gate temporary rows.
- Representative hosted EXPLAIN statements completed for customer orders, driver candidates, offers by order/driver, and office drivers. No new index or infrastructure was required.
- Milestone 4 and Milestone 5 acceptance/concurrency suites were previously verified and were not rerun because no related schema or function changed.
- Hosted Auth smoke passed with one fresh account; Forgot Password and all previously passed Backend Gate sections were not rerun. Cleanup confirmed zero remaining auth, profile, role, driver, or office-membership rows for the test identity.
- `flutter analyze` passed for affected `packages/app_core` and `apps/driver_app` scopes after the implementation wave.
- Targeted `app_core` enum and Driver App lifecycle/account eligibility/widget tests passed (4 tests total across the affected scopes).
- Hosted Milestone 6 verification passed in one rolled-back transaction: ACTIVE availability toggle, PENDING denial, assigned-driver order visibility, other-driver isolation, active-trip Offline denial, RPC grants/search path, and cleanup.
- Hosted Milestone 6.1 verification passed in one rolled-back transaction: own-offer withdrawal and resubmission, cross-driver and selected-offer denial, reasoned pre-trip Driver cancellation, IN_PROGRESS and cross-driver denial, terminal CANCELLED behavior, assignment/cancellation events, Online eligibility hints, and the new-object security grants/search paths. Cleanup confirmed zero temporary identities remained.
- Hosted Milestone 7A verification passed in a rollback-based transaction: Ride and Delivery creation boundaries, 90-second server expiry, immutable proposed price, the frozen customer cancellation matrix, cancellation events, own-vs-other compact offer visibility, no private offer fields, pre-assignment recipient/profile isolation, terminal Book Again prefill, and changed-object grants/search paths. The initial verification batch had a test-harness parse error and executed no data; the corrected functional/RLS assertions passed, and cleanup confirmed zero temporary identities or operational rows remained.
- A single `UI_QA_Checklist_AR.md` review confirmed RTL, hierarchy, reusable components, minimum action sizing, loading/empty/error/disabled/stale states, keyboard-safe counter-offer input, and one primary trip action per state.

## Files Changed

- `apps/driver_app`.
- `apps/user_app` shared Auth callback wiring only; User App Core was not started.
- `packages/app_core`.
- `supabase/config.toml`.
- `supabase/migrations/202608300010_wave_b_recovery_auth_contracts.sql`.
- `supabase/migrations/202608300011_wave_c_read_correctness.sql`.
- `supabase/tests/wave_c_read_correctness.sql`.
- Focused Wave B SQL/Flutter tests and retained fixture contract adaptations.
- `supabase/migrations/202608300004_driver_app_core.sql`.
- `supabase/migrations/202608300005_driver_business_freeze_reconciliation.sql`.
- `supabase/migrations/202608300006_user_flow_backend_delta.sql`.
- `supabase/migrations/202608300007_user_flow_privacy_hardening.sql`.
- `docs/CODE_IMPROVEMENT_BACKLOG.md`.
- `docs/BUSINESS_RULES_FREEZE_V1.md`.
- `docs/CURRENT_ISSUES_REGISTER.md`.
- `docs/SYSTEM_VALIDATION_GATE_2_REPORT.md`.
- `docs/DEEP_CODE_REVIEW_REPORT.md`.
- `docs/Backend_Supabase_Requirements_EN.md`.
- `docs/Database_Schema_Specification_EN.md`.
- `docs/System_Workflows_State_Machines_EN.md`.
- `docs/IMPLEMENTATION_PROGRESS.md`.

## Next Task

Milestone 7 — User App Core. Hosted Auth redirect allowlist confirmation remains required before full password-reset E2E/release acceptance; milestone-scoped Maps, Realtime, and Public Launch findings retain their documented timing.
