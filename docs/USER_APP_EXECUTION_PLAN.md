# Biko User App — Gap Analysis and Agent Execution Plan

Date: 2026-09-08. Status: **IMPLEMENTATION CHECKPOINT — LOCAL TESTS PASSED / DEVICE QA BLOCKED**.

> **Latest implementation supersession, 2026-09-08:** the older read-only
> Profile/History and “G01–G04 absent” snapshots below are historical planning
> evidence, not current code status. This checkpoint now includes owner-scoped
> historical details, guarded post-assignment Driver contact, foreground-only
> assigned-order tracking, and CUSTOMER self-service Profile editing. Profile
> writes use a narrow RPC and private storage, never Auth identity, role, or
> status. Local focused tests verify code contracts; hosted SQL/migration,
> device picker/dialer/maps, and live two-account acceptance remain unverified.

The initial audit was documentation-only. The owner subsequently approved execution with multiple Terra agents and root supervision. The approved code wave and targeted local verification are complete at this checkpoint; device visual acceptance is blocked by local Gradle and this is not hosted acceptance. Earlier local UI changes remain in place and must not be restarted or overwritten.

## 1. Authority and scope

1. Latest product-owner request: master redesign including up to three onboarding pages and one Auth choice.
2. `DESIGN.md` v2: current presentation authority.
3. `docs/BUSINESS_RULES_FREEZE_V1.md` and accepted `docs/DECISIONS.md`: business authority. Their implementation-status snapshots are not current-code evidence.
4. User functional/UI specifications: requirements input, subject to newer decisions.
5. Milestone reports: historical evidence with their stated external limitations.

Keep UI → Riverpod → Service → Supabase. No further folder refactor, repository/use-case layers, Driver redesign, Dashboard changes, payments, OTP, new backend rules, commits, pushes, or hosted mutations are authorized by this plan alone.

The approved design-board image is still unavailable in this task. DESIGN.md is enough for planning and functional work; exact board-family acceptance requires the image. Never claim reference-board compliance without inspecting it.

## 2. Current truth: do not rebuild these

| Area | Current source evidence | Actual status |
|---|---|---|
| Email/password, signup, forgot password | `packages/app_core/lib/app_core.dart:108` | Implemented modes; visual/interaction completion still needed |
| Recovery session and reset password | `packages/app_core/lib/auth_recovery.dart:183`, shared router `app_core.dart:68` | Implemented security flow; not a missing feature; hosted redirect/device acceptance separate |
| Shared Biko theme, Cairo, controls | `packages/app_core/lib/biko_design.dart`, `fonts/Cairo.ttf` | Implemented; preserve foundation |
| Ride/Delivery booking, parcel fields | `features/orders/create_order_page.dart`, `order_service.dart` | Implemented |
| Trusted quote / 70% floor | `order_service.dart:192`, `order_rules.dart`, migration `202608300013_maps_location_pricing_dispatch.sql` | Implemented client/server code; external configuration is a different gate |
| Bidding, offers, selection, cancellation | `order_status_page.dart`, `order_service.dart` | Implemented; visual and transition acceptance incomplete |
| Assigned identity / motorcycle / plate | `order_models.dart` DriverSummary; `widgets/assigned_driver_widgets.dart` | Implemented after assignment; nullable fields must remain honest |
| Delivery code | `order_status_page.dart:408`, `loadDeliveryConfirmationCode()` | Implemented final operational code; no Ride or pickup OTP |
| Book Again | `order_models.dart` bookAgainDraft; history and terminal actions | Implemented new draft requiring fresh quote; do not rebuild |
| Realtime/Push integration | `features/notifications/*`, `app/user_app.dart` | Implemented event refresh and safe fallback; live delivery acceptance pending |
| History/Profile | `order_history_view.dart`, `profile_view.dart`, `profile_service.dart` | Bounded list and read-only account/logout implemented |

Paths in feature rows are under `apps/user_app/lib/` unless stated otherwise.

## 3. Confirmed gaps and remaining work

### A. Ready to implement within approved mobile scope

| ID | Priority | Gap / remaining work | Evidence / boundary |
|---|---|---|---|
| U01 | High | Onboarding Hero/Value/Safety, skip/next, local completion, final Login/Register choice are absent | No onboarding in User lib; router directly builds EmailPasswordAuthPage |
| U02 | High | Auth presentation is one generic mode-based form; reset fields have no visibility control; keyboard submission/loading states need completion | `app_core.dart:280`, `auth_recovery.dart:267,281`; preserve AuthService/session validation |
| U03 | High | Home service row was compacted but has no pickup/destination entry; location icon is decorative, not real context | `home_view.dart:32`; reuse booking/draft flow, never invent current city/location |
| U04 | High | Quote pricing/action hierarchy and long Delivery form need runtime completion | Real earlier quote capture put editable price/CTA below map/summary; existing validators and quote ownership stay unchanged |
| U05 | High | Places no-results feedback is absent; failed/late searches and permission recovery require focused handling and runtime proof | `location_picker_page.dart:55,218`; existing permission messages present, not missing permission handling entirely |
| U06 | High | Offer comparison and assigned identity still need compact long-content layouts | `assigned_driver_widgets.dart` truncates name/model/plate; no fabricated fields before assignment |
| U07 | High | Completed/cancelled/expired branch was changed but new captures and real transition checks are incomplete | `order_status_page.dart:288,474`; verify real root active→terminal behavior, not only direct fixture |
| U08 | Medium | History/Profile visual completion: density, long identity/email, empty/error/loading, real bottom navigation | `order_history_view.dart`, `profile_view.dart`; keep read-only scope unless separately approved |
| U09 | High | Preview matrix is incomplete and some old screenshot names do not match contents | `test/ui_preview.dart:259` always returns bidding order on refresh; history/profile use separate frames, not real root shell |
| U10 | High | Final integration, actual keyboard/small-screen/text-scale/async acceptance is incomplete | Existing tests do not prove all runtime states; old screenshot count is not acceptance |
| U11 | Medium | Launcher/release identity still contains scaffold configuration | Android manifest label `user_app`; Gradle release uses debug signing; branding local work vs owner-held signing gate |
| U12 | Medium | Source-of-truth documentation drift | PRODUCT still mentions Ana Vodafone; old specs call implemented pricing/parcel/Book Again pending; correct current-status notes without erasing old evidence |

### B. Functional gaps that need a separate contract/decision gate

These are real differences from older functional specs, not automatic P1 defects and not permission to expand the visual wave.

| ID | Gap | Safe next step / gate |
|---|---|---|
| G01 | Historical order details are not openable; history only supports Book Again, last 30 items | Optional additive owned read-only details using current models/service first; no invented timestamps/payment/cancellation fields. Confirm inclusion, then central router integration. Pagination only if all-history access is required; do not load unlimited rows |
| G02 | Edit profile name/photo and account-deletion request absent | ProfileService exposes load only. Confirm product fields, deletion/retention behavior and trusted write/Storage contracts before implementation; never update protected profile columns or delete Auth users from mobile |
| G03 | Customer live driver-marker tracking absent | Current Realtime subscribes to notification_outbox, not location; active UI is status/identity, not live movement. Requires authorized assigned-customer location projection, freshness/lifetime rules, privacy tests and foreground cost budget. No fake marker/ETA, no background tracking |
| G04 | Post-assignment contact action absent | DriverSummary has no phone/contact contract. Confirm allowed disclosure and trusted endpoint; never expose phone before assignment; no chat/masking scope |
| G05 | Rating subsystem absent | DESIGN.md §49 explicitly excludes ratings until implemented later. Do NOT implement stars, fake averages, RatingSheet or schema as part of this plan's automatic wave |
| G06 | Notification target always falls back to /home after authoritative read | Currently safe behavior, not authorization bug. Exact historical deep link depends on G01. Preserve ownership/auth/dedupe and fallback for unavailable targets |
| G07 | Full localization keys absent | Arabic strings are inline; RTL exists. Defer broad ARB extraction until English/localization is requested; avoid touching every file for the current redesign |

### C. External acceptance, not absent implementation

Historical M8/M9 reports record pending Maps SDK/server keys, Places/Routes deployment, approved Ride/Delivery pricing values, Firebase/APNs/dispatcher configuration, and Auth redirect confirmation. These reports are not a fresh inspection of hosted configuration.

Before live acceptance: inspect the authorized Development environment once, request only missing configuration, never print secrets, never infer pricing or zone polygons. Do not rerun accepted SQL milestones merely for freshness. Production signing uses owner-controlled keys; an APK signed with debug keys is not a publishable release.

## 4. Existing fixes to preserve

- PrimaryButton, DestructiveButton, LocationField semantics expose enabled tap actions; targeted shared check passed 3/3 in this task history.
- LocationField floating label fixes rendered label/placeholder overlap.
- Map keyboard layout regression was reproduced at 360×640 with a 300px keyboard inset (34px overflow), then fixed; focused test passed 1/1. Actual docked Android keyboard acceptance is still pending.
- Terra's Home compact service row, compact bidding route, distinct terminal branch, removed nonfunctional notification placeholder and Auth visibility edits are persisted. Some post-change screenshots/tests remain unverified; do not blindly redo these patches.

## 5. Agent work packets

Use **gpt-5.6-terra** for implementation, medium reasoning by default and high for Auth/routing/recovery integration. No requirement for a second expensive model. Root reviews diffs, integrates shared contracts and decides acceptance.

At most three child agents in parallel. Every dispatch lists exact owned files. All agents share the same working directory; no two writers own the same file.

### A — User onboarding + Auth

- Own: new `features/onboarding/*` / User auth-entry file and dedicated User Auth/onboarding tests. Root is the sole writer for shared `app_core.dart` and `auth_recovery.dart`; request the smallest shared presentation seam rather than editing them independently.
- Scope: U01/U02. Three onboarding pages max, skip/next/already-account, local completed flag, final Auth choice. Reuse existing Auth forms and safe error mapper; new signup requirements forbidden.
- Implementation seam: User-only wrapper supplied to `authBuilder` at `/auth`; no new unauthenticated route/guard rewrite. Root owns `user_router.dart` integration. Recovery route retains higher priority. Restored signed-in user never sees onboarding; missing Supabase config keeps honest setup state.
- Persistence: `shared_preferences 2.5.5` already exists transitively in User lockfile. Prefer promoting that installed package to an explicit User dependency, not adding Hive/storage infrastructure. Root alone changes pubspec/lockfile once; no auth tokens stored in the onboarding flag.
- Shared Auth additions must preserve Driver defaults and recovery invariants. Return an additive initial Auth mode seam if final choice needs one; no duplicate login service/forms. Root explicitly reviews any shared recovery appearance change because Driver consumes that screen too, and runs the affected shared/Driver check if its behavior can change. User-only onboarding never becomes Driver onboarding.
- Acceptance: first launch, skip, completion, process restart, sign-out, valid/expired recovery, signup without session, login/register/forgot/reset loading/error, visibility, IME submit. Focused router/Auth tests; affected shared tests only.

### B — Home + booking + Maps + quote

- Own: `features/home/home_view.dart`, `features/orders/create_order_page.dart`, `features/maps/location_picker_page.dart`, `route_preview_map.dart`, dedicated booking/map tests.
- Scope: U03/U04/U05. Compact real pickup/destination entry with callbacks/new draft handoff; one dominant request action; suggested/minimum/editable proposed price easy to compare; Delivery grouping and scrolling.
- Preserve existing Geolocator/MapGateway, debounce/session semantics, current trusted quote, validation, 70% floor and create-intent recovery. No added Maps call on every rebuild, no routing API for candidate discovery.
- Add explicit search-empty feedback only after a completed matching query; preserve useful selected location. Reproduce late-query/error races before fixing them. Keyboard safe-area and attribution must remain visible.
- Root owns shared widgets and service/model contract edits; submit needed integration patch rather than editing someone else's files.
- Acceptance: empty/selected addresses, Places loading/results/empty/error, location off/denied/permanent denial, below/exact/above minimum, stale quote, Ride/Delivery validation, all relevant keyboards at small and typical sizes.

### C — Offers + active order + terminal

- Own: `features/orders/order_status_page.dart`, `widgets/offer_widgets.dart`, `widgets/assigned_driver_widgets.dart`, `widgets/order_status_actions.dart`, dedicated status tests.
- Scope: U06/U07. Compare one/three offers, large fare, office/independent, long identity/model/plate. Clear assigned/on-way/arrived/in-progress states and final code, distinct terminals with no stale actions.
- Preserve authoritative status/RPC calls and code visibility rule. UI-only work must not create new realtime subscriptions, modify cancellation rules, or fabricate unavailable identity fields.
- Reproduce refresh/transition flashes and content loss with delayed futures before altering presentation. Validate root active→terminal via QA/root integration, not just a direct terminal page.
- Acceptance: waiting/offer arrival/selection loading/error, near expiry, assignment, state refresh/error, cancelled/expired/completed, Book Again requiring fresh quote, no Ride/pickup OTP, Delivery code LTR.

### D — Secondary screens + document reconciliation

- Run when a slot frees; own `features/profile/profile_view.dart`, `features/orders/order_history_view.dart`, dedicated secondary tests, and narrowly scoped current-status doc notes.
- Scope: U08/U12; no ProfileService writes, rating or new settings. Improve compact receipts/long content and contextual empty/error states. Do not silently add G01/G02.
- Acceptance: empty/large bounded history, all terminal labels, long Arabic route/name/email, optional phone, logout busy/error, real Home/History/Profile navigation.
- Documentation: current overview points to DESIGN v2; mark stale pending claims with code/report references, preserving historical evidence and frozen rules. Root reviews all scope wording.

### E — Runtime gallery + acceptance runner

- Own only `test/ui_preview.dart`, dedicated fixture/preview tooling, screenshot evidence and acceptance ledger. No duplicate production UI.
- Start fixture preparation while A/B/C run if a slot is available; otherwise after the shortest packet. Capture acceptance only after merged relevant changes.
- Replace hidden fragile access with an explicit test-only selector outside screenshots. Use real UserShell/navigation/router where relevant. Make fake reads return the current selected fixture, not bidding for every refresh; use distinct IDs, bounded in-memory delayed/error states and deterministic expiry.
- Require an explicit debug-only entry guard; production `lib/main.dart` imports no preview code. Fake service overrides stay under test. Prefer platform fakes for denied/offline states over production debug branches.
- Use one emulator owner and one resident preview process. Do not run separate agents against the same device; do not rebuild per screenshot.
- Evidence ledger per state: exact source widget, fixture/live, viewport/keyboard, assessed defect, before/after file, result. Inspect pixels after save; filenames/hash counts are not proof.
- Mandatory after captures: onboarding hero/value/safety/auth choice, login/register/forgot/reset, Home empty/recent/active, Ride/Delivery booking, picker/search, quote, bidding empty/multiple, assigned/on-way/arrived/active Ride/Delivery/code, completed/cancelled/expired, History/Profile. Add captures for important error/loading/permission/recovery variants; common components may cover duplicates only with explicit mapping.

### F — Root integration + release-readiness boundary

- Exclusive ownership: `app/user_router.dart`, `app/user_app.dart`, `app/user_shell.dart`, `main.dart`, pubspec/lockfiles, shared `app_core.dart`, `auth_recovery.dart`, `biko_design.dart` and `order_presentation.dart`, any necessary model/service integration, platform config.
- Integrate A/B callbacks and preview seams; avoid a second state source or duplicate security guard. Check shared edits against Driver consumers without redesigning Driver.
- U11: replace scaffold display identity with Biko using approved owned assets; inspect launcher/splash. Release signing remains blocked on owner-held key/distribution choice; do not silently publish/debug-sign production.
- If G01–G06 are approved later, assign separate contract-audit → minimal implementation → trust-boundary verification packets. They do not slip into A–E.

## 6. Schedule and dependency order

1. **Preparation:** freeze file ownership, record existing untracked/dirty state, retain current evidence, confirm missing board affects only exact visual-reference acceptance. Root resolves any shared seams.
2. **Parallel implementation wave:** A (Auth/onboarding), B (Home/booking/maps), C (offers/lifecycle). Up to three Terra children; root integrates only non-owned shared files.
3. **Completion wave:** D (secondary/docs) and E (gallery/state matrix), while root reviews A–C output and handles integration. A–C do not repeatedly rerun full checks.
4. **Runtime wave:** E owns device; root reviews captures and assigns only reproduced defects back to file owner. Use small 360×640, typical 390×844, large 430×930 and a text-scale stress case.
5. **Verification checkpoint:** targeted changed tests once; `flutter analyze --no-pub` once for final User App and changed app_core. Driver check only if shared change can affect its behavior; no Dashboard/database gates for UI-only work.
6. **Live external checkpoint:** authorized Development credentials/config only; login/recovery, Maps/Places/quote, two-account order lifecycle, Realtime/Push/resume. Clearly separate fixture acceptance from actual server/device proof.
7. **Delivery:** changed-file summary, exact state inventory, before/after evidence, targeted test/analyze results, unresolved external/decision gates. Never call the whole User App complete while required states or live gates remain unknown.

## 7. Standard dispatch prompt

> Execute packet [ID] from docs/USER_APP_EXECUTION_PLAN.md. Read DESIGN.md, frozen rules and fast-execution/ponytail/impeccable first. Own only [exact files]. Preserve current edits and UI→Riverpod→Service→Supabase. Implement approved gaps, do not restart completed work. No unsupported features, business/security changes, new infrastructure or broad refactors. Request shared-file changes from root. Verify the smallest affected scope once after the meaningful wave. Return changed files, exact checks/results, observed evidence, unverified states and blockers; no PASS from source inspection alone.

## 8. Acceptance and cost controls

- Read-only audits do not authorize backend fixes. Missing API/field/policy returns to root for an explicit scoped decision.
- A test failure is first reproduced and traced; do not change a product CTA solely to satisfy a stale expectation. Latest DESIGN CTA wording wins, including `اختيار` when appropriate.
- No full source/history sent to every agent: pass packet + exact authority/owned-file paths. Reuse a finished Terra agent for the next bounded packet.
- No repeated pub get unless manifests/dependency errors demand it. No repeated full analyze/test/build after cosmetic tweaks. Re-run only failed checks after relevant fixes.
- No automatic paid services, resets, credit purchases or endless model retries when usage is unavailable. Record the checkpoint and resume the same packet when available.
- Current repository reports all project files untracked. Preserve that state; do not mass-add/commit or treat absent git diff as proof of no prior changes.
- Results vocabulary: IMPLEMENTED, NEEDS_RUNTIME_VERIFY, FIXTURE_VERIFIED, LIVE_VERIFIED, BLOCKED_BY_CONFIG, BLOCKEeD_BY_PRODUCT_DECISION. Avoid invented percentages of completion.

## 9. Decisions needed only for gated work

1. Supply approved design-board image for reference-family acceptance; until then use DESIGN.md, with no claimed board match.
2. Include historical read-only details now, or keep current bounded History + Book Again? This determines G01/G06, not the core redesign.
3. Explicit scope/contract approval before profile writes/deletion, live customer tracking, post-assignment contact, or ratings.
4. Approved Development pricing/key/deployment configuration and owner-controlled release-signing details at external/release checkpoints, not before local UI work.

No broad test/build/database command was run for the initial planning audit. Execution evidence is recorded below; historical PASS statements are not presented as fresh verification.

## 10. Execution checkpoint — 2026-09-08

The owner approved distribution and supervision. Three Terra agents executed isolated packets; root integrated shared Auth and routes. Existing untracked work was preserved. No backend, Driver UI, Dashboard, hosted data, commits or pushes were changed.

| Packet | Implemented | Evidence / remaining boundary |
|---|---|---|
| A | Three onboarding steps, persisted skip/completion, Auth choice, reuse shared forms | Onboarding 4/4; actual User router integration 3/3 with local SDK events. Live mail/recovery and process-restart device acceptance remain separate |
| B | Real Home location handoff; partial route preserved; quote/price hierarchy; Delivery grouping; Places empty state, late-search/detail guards, permission Settings recovery | Initial booking/map/pricing 6/6; final picker+secondary 5/5; root final Home tests 3/3, including partial-route cancel/reopen preservation. Device acceptance remains separate |
| C | Compact offer comparison, honest assigned identity/plate, real state headings, final Delivery code, stale supporting-read guards | Dedicated status presentation 4/4. No tracking/rating/contact fields fabricated |
| D | Responsive bounded History; compact read-only Profile with long Arabic/LTR content | Included in final picker+secondary 5/5; device navigation/logout still part of E |
| E | Debug-only deterministic preview, real shell, corrected scenario refreshes, clean test selector | Harness included in final clean User analyze. New gallery NOT captured: AVD booted, but assembleDebug stalled after a bounded diagnostic/retry. BLOCKED_BY_LOCAL_GRADLE; no old screenshot is substituted |
| F | User router and Home callback integrated; shared initial Auth mode, visibility/IME/busy controls; reset visibility; platform display name بيكو; PRODUCT authority reconciled | Shared recovery 8/8, Auth presentation 1/1, controls 3/3. Final app_core and User App analyze: no issues. User regression initial 16 pass/3 stale label-count failures; targeted 3/3 passed after selectors were scoped to the actual StatusChip |

### Verified boundaries and outstanding items

- Terminal presentation exists, but `loadActiveOrder()` excludes terminal records. Root returns to Home after the authoritative active-order result becomes null. A persistent receipt/detail route is **not implemented** and must not be inferred from direct terminal screenshots; G01 remains decision-gated.
- Auth choice has no separate back-to-choice button after mode selection; shared forms still switch login/signup/recovery. Router integration confirms authentication/recovery navigation is not trapped.
- Platform display names were updated. Existing launcher icon/splash assets were not replaced without an approved owned asset. Release signing remains owner-controlled and unverified.
- Shared default sign-in behavior and recovery guards are covered by affected shared tests; no Driver redesign or unrelated full Driver suite was run.
- No database schema/service changes: previous database evidence was not rerun because this wave cannot affect those contracts. Hosted Maps, pricing, mail, Push/Realtime and two-account lifecycle remain **not live-verified by this wave**.
- Skills applied: fast-execution for bounded verification; ponytail for reusing forms/storage/router rather than new layers; impeccable for DESIGN-driven hierarchy, RTL and constrained-layout review. No separate code-review skill is installed; root performed direct integration review.

### Next safe continuation

1. **Owner override: do not start the emulator again.** Device QA and Gradle troubleshooting are paused; continue code-only work until the owner explicitly changes that instruction.
2. Capture and inspect the remaining state/viewport/keyboard matrix from packet E. Current harness covers actual widget display and shell bottom navigation, not GoRouter booking navigation or hosted authentication.
3. Run the separately gated live Development acceptance only with approved configuration. Keep release identity/assets/signing and G01–G06 visibly open.

### Contact and historical details checkpoint — 2026-09-08

- Historical orders now use owner-scoped cursor pagination and an owner-fetched read-only detail route. The displayed route, status, dates, agreed/proposed fare, Cash method, cancellation reason, and Delivery fields come only from current order data. No tax, fee, card, or paid-status is inferred. Book Again creates a new draft and always requires a fresh quote.
- Driver contact is a separate narrow RPC, not an extension of offers or driver summaries. It returns the assigned Driver phone only to an active CUSTOMER owner while the order is `DRIVER_ASSIGNED`, `DRIVER_ON_WAY`, `DRIVER_ARRIVED`, or `IN_PROGRESS`. Every call tap rechecks that RPC before opening the native dialer; it never places a call automatically.
- Customer support uses only optional compile-time values: `--dart-define=BIKO_SUPPORT_PHONE=...`, `BIKO_SUPPORT_EMAIL=...`, and `BIKO_SUPPORT_URL=https://...`. Empty or malformed values, including non-HTTPS URLs, render the truthful unconfigured state. An official support destination has not been supplied, so no support endpoint is live-configured.
- NEEDS_RUNTIME_VERIFY: migration/test SQL and local widget tests cover the contract, but no hosted migration, support configuration, device dialer, email client, browser, emulator, or live two-account validation ran in this checkpoint.

## 11. Code-review fixes — 2026-09-08

The owner requested fixes for the six reviewed issues, without emulator work.

- Active-order expiry now uses the returned server state, retaining BIDDING/assigned results and dropping only terminal results. Repeated elapsed snapshots do not trigger an expiry retry loop.
- Changing either booking endpoint invalidates pending route quotes even when the new route cannot be quoted; loading is reset too.
- Full order refresh discards stale responses/errors after a newer snapshot and publishes authoritative order state before optional driver/code reads. Supporting-read failures no longer retain an obsolete bidding/cancellation UI.
- Ordinary location permission denial keeps its actionable message.
- The late-error presentation test now checks the real connection message and error icon, not an unrelated string.

Verification: 13 review regression cases plus 29 affected existing tests passed across scoped runs; the initial mock HTTP request-metadata and widget animation-timing failures were corrected in the test harness, then only failed cases were rerun. The final expiry adjustment also passed the two existing countdown/bidding checks. No device, build, hosted mutation, dependency change, Driver, Dashboard, or database-schema change was made. Client OrderService changed; the database RPC contract did not.

Final `flutter analyze --no-pub` for User App: **No issues found**. Applied fast-execution, ponytail and Supabase guidance; no new abstraction or server contract was needed.
