# Deep Code Review

Historical review snapshot. Subsequent authorized Waves A/B/C and Final Evidence Closure remediated the selected findings. Original findings, scores, and reproduction probes below remain historical evidence (the old defect-demonstration probes are not current regression tests). CR-008 now has genuine overlapping-session proof and CR-024 is reconciled. See [current backlog](C:/projects/biko/docs/CODE_IMPROVEMENT_BACKLOG.md) and [progress](C:/projects/biko/docs/IMPLEMENTATION_PROGRESS.md) for authoritative live status.

## Executive Summary

Date: 2026-08-30. Workspace: `C:\projects\biko`. **Review COMPLETE; code health FAIR.** This is a review result, not a release approval or a System Validation Gate pass.

There are **32 findings: P0 0, P1 8, P2 19, P3 5**. Eight P1 findings include one explicitly identified concurrency **evidence gap**, not eight newly reproduced production failures. No public/anonymous privilege bypass or currently reproducible double assignment was established. Two concrete privileged-read authorization defects were reproduced.

The architecture is appropriately small: Flutter UI → Riverpod → service → Supabase; trusted PostgreSQL transactions own mutations. Keep that architecture. The highest-value work is repairing specific authorization/recovery contracts, not introducing repositories, use-case layers, a universal state engine, or new infrastructure.

The current 6.1 and 7A work is present. The Gate 2 remediation has implemented one-active-job uniqueness and cross-order offer closure; its changed overlapping race remains unproven. Do not re-report the old missing index, scalar waiting offer, raw candidate customer UUID, or snackbar-only mutation implementation as still present. This review does not close the gate or start User App.

Fast-execution kept verification focused; ponytail limited recommendations to existing helpers, native constraints, and installed-client capabilities; impeccable was used for **interaction/state logic**, not a redesign or a claimed device/browser acceptance. The requested `code-review` skill was unavailable, so an evidence-based review was used. Supabase security/performance guidance informed the database review.

### Scope and evidence boundary

- Read the requested authoritative project, design, freeze, cost/database, decisions, progress, gate, and issue documents.
- Reviewed all implemented Dart application/shared source (10 files), all six Dart test files, the three Dashboard source files, all nine migrations in order, the retained SQL test, the foundation script, package/lock configuration, environment templates, and Android/iOS bootstrap/configuration. Dashboard has no implemented authenticated operations; Edge Functions contains only a README.
- Excluded generated/build/cache implementation from the repository review. Inspected only the installed SDK implementation/plugin metadata needed to resolve timeout, retry, Auth-stream, sign-out, and manifest questions. No dependency upgrade/security-advisor/build claim is made.
- Reviewed the **effective latest function definitions**, not just historical migration text. Read the hosted four authorization helper definitions to confirm that the suspected source defects are current.
- Ran two small **rollback-only Development probes** to confirm suspected findings. Did not run Backend Gate 1, Gate 2, a full RLS suite, Auth smoke, Flutter analysis/tests, Dashboard builds, a concurrency suite, CLI installation, or a direct HTTP database path.
- Previously verified unaffected behavior was **not rerun because current review changes do not affect it**. Prior evidence is labeled historical, not fresh PASS.
- No application/schema/migration fix was made. The two new review documents are the only repository changes from this review. Final SHA-256 comparison confirmed that all 223 pre-existing non-generated files were unchanged, with no additions or deletions outside these two documents; the original untracked worktree was preserved.

### Fresh targeted evidence

| Probe | Observed result | Interpretation |
|---|---|---|
| Accountant in A, Dispatcher in B | Reads 1 A Driver-document row | CR-001: permissions leak across memberships. |
| Suspended staff profile | Reads 1 protected document | CR-002: profile suspension is absent from authorization. |
| Staff of suspended office | Reads 1 protected document | CR-002: office suspension is absent too. |
| Suspended Super Admin | is_super_admin=true; reads 1 protected document | CR-002: elevated role persists despite suspension. |
| Acceptance after wall-clock expiry inside an older transaction | wall-clock-past=true; status=DRIVER_ASSIGNED | CR-003: transaction-start deadline check is insufficient. This was **not** a concurrent-session test. |
| Two identical create calls | Different order IDs | CR-004: no stable intent deduplication/correlation; identical deliberate Book Again bookings remain legitimate. |
| Complete one order | Completed orders=1; stored completed_trip_count=0 | CR-010: public count drifts. Lifecycle calls were setup for this specific counter finding, not a rerun of a lifecycle suite. |
| Driver goes offline after offering | Customer offer rows=1 | CR-026: fresh listing/selection eligibility differ. |
| Suspended customer selects | status=DRIVER_ASSIGNED | CR-009: new-work acceptance ignores customer status. |
| Cleanup | Review Auth users/profiles/offices/Drivers/documents/orders/offers all 0 | Both probes rolled back; no committed verification data or schema objects. |

Reproduction SQL is retained in this document under Tests. These deliberately demonstrate current problems; they are **not passing acceptance tests**.

## Overall Code Health

Scores are engineering judgments about implemented code and evidence, not a coverage percentage. Deferred milestones are not deducted simply for being absent.

| Dimension | Score / 10 | Reason |
|---|---:|---|
| Architecture | 7 | Clear small service boundary and reusable core; Dashboard aggregate/recovery responsibilities are too coupled. |
| Business Logic | 6 | Strong ownership/state guards and cancellation contract; deadline, eligibility-read, and public-statistics defects remain. |
| Database Integrity | 6.5 | Useful FKs, exact numeric storage, active-offer/job uniqueness; incomplete assignment bundles remain possible through trusted writes. |
| Security | 4 | Good RPC/grant/privacy foundations, but reproduced mixed-office and suspended-privilege reads are material. |
| Concurrency Safety | 6 | Real locks, rechecks and uniqueness backstop; final deadline recheck and required cross-order race proof are missing. |
| Flutter State Management | 5.5 | Central mutation barrier and session invalidation are useful; persistent detail caches, paging races and aggregate failure coupling remain. |
| Network Reliability | 4.5 | No blind mutation replay; unbounded waits and incomplete Auth/read error handling prevent a dependable recovery contract. |
| Maintainability | 6 | Few layers and readable models; message-string coupling, stale status documents and error-context loss hurt diagnosis. |
| Test Quality | 5 | Useful behavioral recovery tests, but significant service/Auth boundaries and durable database regressions are missing. |
| Performance | 7 | Bounded Driver reads and no row-by-row client joins; repeated account/data reads and overly broad reconciliation are visible costs. |
| Cost Efficiency | 8 | No paid-API fan-out, polling, location history or unnecessary Edge Functions; avoidable DB round trips remain. |
| Future Extensibility | 6.5 | RPC/action seams are usable; creation recovery and read invalidation need correction before multiplication across apps. |

Overall **FAIR**: a sound small foundation with targeted blockers. Neither a rewrite nor a launch is justified by the current evidence.

## Architecture

| Current design | Why it is a problem / when it hurts | Minimum better design |
|---|---|---|
| Driver Dashboard aggregates account, requests, active order, waiting offers; Bootstrap and Profile consume it. | Optional feed failures gate active-trip recovery/account access today (CR-012). | Minimal active-order bootstrap and independent optional feed sections; Profile uses account/session data only. |
| One generic reconciler plus Driver-specific refresh callback. | Good shared barrier, but any successful read releases it; it cannot correlate a newly created order or prove an old timed-out write finished (CR-004/005). | Preserve the small controller; add bounded transport and an operation-specific creation intent contract. |
| All Driver actions invalidate Dashboard/History/Earnings and order/offer reads. | Unrelated reads block recovery and will amplify event-driven refreshes (CR-017). | Reuse account/terminal data and invalidate only affected resources; no extra repository hierarchy. |
| Shared presentation exports domain types via the app_core barrel. | The legal barrel cycle (`app_core` exports presentation which imports `OrderStatus` from it) couples domain imports to UI/Auth dependencies. | Low urgency: move enums to a leaf file when a real non-UI consumer appears; do not create a domain package now. |
| Lifecycle service returns a fully named DriverOrder from a raw orders RPC. | Metadata defaults conceal a partial result and invite future misuse (CR-029). | Return void where the caller already discards it and awaits authoritative refresh. |

No Supabase business mutation was found directly in Driver widgets. Auth/bootstrap integration is intentionally shared. Earnings sums a **bounded displayed gross dataset**, not a wallet or commission ledger; that small display calculation does not justify a finance architecture now.

Large `driver_screens.dart` is not independently a defect. Its concrete cost is that pagination generation, active recovery, and account visibility rules are hidden among presentation code. Split a screen by its existing boundary when it next receives material work, without creating generic controller hierarchies. This is narrower than old SVG2-012's file-size-only rationale.

## Business Logic

| Contract | Current protection / review outcome |
|---|---|
| Customer/Driver ownership | Identity comes from auth.uid; customer/order and assigned/offer-Driver checks are server-side. CR-001/002/009 concern authorization eligibility, not fabricated client customer IDs. |
| One active job | 008 partial unique Driver index plus Driver-lock/recheck now exist. Old duplicate-job implementation defect is not current; CR-008 is still an evidence gap. |
| Multiple offers | One ACTIVE offer per Driver/Order, multiple orders allowed; current paged collection replaces the old scalar. Paging still has CR-015/016. |
| Withdrawal/replacement | Order→offer locks, ownership, ACTIVE/unselected/open-window checks; replacement inserts a new offer rather than editing it. No future global single-offer restriction is recommended. |
| Manual atomic selection | Sets selected offer, Driver, office snapshot, agreed price; closes affected offers and makes Driver unavailable. Deadline and caller eligibility need CR-003/009. |
| Online meaning | Availability for new work, not permission to progress an assigned trip. 008 correctly removed the online requirement from lifecycle continuation. Documents/motorcycle/helmet rules remain deferred. |
| Lifecycle | Four explicit legal steps; expected-state check and assigned identity; repeated/stale calls reject. No generic client status editor. |
| Cancellation | Customer BIDDING without reason; assigned with reason; on-way/arrived LATE_CANCEL; no direct IN_PROGRESS/terminal cancellation. Driver requires reason before IN_PROGRESS; order remains CANCELLED. |
| Price immutability | Normal client writes are revoked and no edit-price RPC exists. Do not call this a current bypass just because a database owner could update a row. |
| Delivery/Book Again | Create validates recipient/weight/value; private one-to-one details retained. New normal creation is the Book Again path; terminal reopening is not implemented. |
| Trust data | Real completed-trip count is advertised but not maintained (CR-010); a ratings system is correctly not invented. |
| Earnings | Clearly labeled recent/displayed gross; commission/net deferred. Two whole-pound display call sites are inaccurate (CR-019). |

Future Maps, 70% minimum, progressive dispatch, trip OTP, document expiry, commission and cooldown requirements remain **FUTURE FEATURE — NOT A DEFECT**. In particular, manual/event-triggered expiry was explicitly allowed; the absence of cron is not a finding.

## Database

The 16-table implemented schema uses UUID PKs, appropriate relationships, enum statuses, exact numeric money, nonempty addresses and checked coordinates. Required roles/permissions/reference services are seeded in migrations, not a divergent local-only seed.

Useful current indexes cover customer/Driver/office order filters, bidding/expiry, offer order/Driver status, reverse candidate membership, and event order/time. The new composite offer key supports the same-order FK; it is not equivalent to the offer PK for that constraint. The general bidding and bidding-expiry indexes have different access paths and should not be blindly combined. One exact redundant office-members index is CR-031.

Trusted-write hardening is incomplete (CR-020). Null assignment fields can accompany an active state; same-order offer linkage does not verify the entire Driver/price bundle. The legacy orders default remains DRAFT even though normal create_order persists BIDDING. This is a trusted-write/schema-shape concern, not proof that the client creation RPC violates the freeze.

Office/Driver ownership checks enforce Independent→no office and Office Driver→one office. Historical orders preserve office_id on acceptance. A future trusted office-change flow must preserve historical snapshots and explicitly handle outstanding offers; do not join history exclusively through the Driver's current office/type.

### Migration quality

- Treat all nine files as immutable history. Later CREATE OR REPLACE definitions supersede older implementations; the old upsert-offer and online-required lifecycle bodies are not live defects.
- Dependency ordering is coherent: authorization helpers → bidding tables/RPCs → lifecycle → Driver actions/events → User delta/private Delivery details → gate constraints/read surfaces.
- 006 drops/recreates changed-signature create/cancel functions and restores grants. 007 copies complete Delivery payloads into the protected child table before dropping columns. Development had no residual operational fixtures; production replay must still preflight incomplete legacy Delivery rows before any destructive column removal.
- 008's unique index and composite FK can fail cleanly on legacy invalid rows. Do not silently delete conflicting production rows to force migration success; plan a preflight/data decision.
- Repeated replacement is normal for immutable migrations but makes diff-based contract review important (CR-021). Consolidate only in a separately approved future baseline/reset strategy, never by editing applied migrations.
- Hosted migration identifiers differ from local filenames (for example local `202608300008` versus recorded hosted `20260830021017`). Existing progress records their mapping. A future CLI/CI deployment must reconcile that history before treating local versions as unapplied. No new migration tooling was run and no drift was inferred from numbering alone.
- Migration atomicity is supplied by the applying transaction/tool; files do not contain their own BEGIN/COMMIT. This review did not replay the full chain or certify rollback of a production deployment.

## RPC / Transactions

For every public mutation: anon/PUBLIC execution is explicitly revoked in its effective migration; intended client RPCs grant authenticated execution; SECURITY DEFINER has empty search_path and qualified application objects. These are **code-reviewed**, not a rerun of a full grant audit.

| Function | Auth / authorization / validation | Locks and side effects | Repeats, events and failure recovery |
|---|---|---|---|
| create_order (007) | auth.uid, ACTIVE CUSTOMER, enabled service, valid coordinates/price, Delivery-only bounds. | Atomic order plus optional details insertion; no preexisting row to lock. | New ID each call; CR-004. Insert records BIDDING event. Failure rolls back both records. |
| submit_offer (008) | auth.uid Driver, ACTIVE profile/Driver/office, online, candidate, no active job, positive price, open window, no current offer. | Order→Driver lock; insert only; unique ACTIVE offer backstop. | Duplicate rejected; no offer-specific order_event required by current lifecycle design. Deadline gap CR-003; reconcile owned offer. |
| accept_offer (008) | Caller owns order; ACTIVE offer; eligible Driver/profile/office/candidate; no active job. Customer suspension missing CR-009. | Order→Driver→sorted affected ACTIVE offers; reread offer after Driver lock; update order/offer set/availability atomically. | Repeated selection rejects once assigned/closed; one transition event; true race proof pending CR-008 and final clock check CR-003. |
| withdraw_offer (006) | auth.uid; offer belongs to caller's Driver; ACTIVE, unselected and BIDDING/window-valid. | Find order ID, then order→owned offer lock; status becomes WITHDRAWN. | Repeat rejects; subsequent submit creates a new offer. No lifecycle event because order status is unchanged. Deadline CR-003. |
| cancel_order (006) | auth.uid owner; four allowed pre-progress states; reason required after assignment and length bounded. | Order lock; terminal CANCELLED, actor/reason/type; closes ACTIVE offers. | Repeat/terminal rejects; trigger records cancellation metadata. Cancelled order never returns to bidding. |
| driver_cancel_order (006) | auth.uid assigned Driver; reason required; first three assigned states only. | Order lock; actor/reason/DRIVER_CANCEL; closes ACTIVE offers. | Repeat/IN_PROGRESS rejects; one cancellation event; reconcile order. Current availability can remain false deliberately. |
| driver_on_way (003 wrapper → 008 core) | Assigned caller, expected DRIVER_ASSIGNED, valid Driver/profile/office. | Order→Driver lock; changes status and on-way timestamp. | Repeat rejects; event trigger; refresh order. Online is deliberately not required. |
| driver_arrived (003 wrapper → 008 core) | Same identity validation; expected DRIVER_ON_WAY. | Same lock order; arrived timestamp. | Repeat rejects; event trigger. Geofence is future, not missing current guard. |
| start_order (003 wrapper → 008 core) | Same identity validation; expected DRIVER_ARRIVED. | Same locks; started timestamp. | Repeat rejects; event trigger. Trip OTP is deferred, not reintroduced as login OTP. |
| complete_order (003 wrapper → 008 core) | Same identity validation; expected IN_PROGRESS. | Same locks; completed timestamp. | Repeat rejects; event trigger; completed count not updated (CR-010). Finance is deferred. |
| expire_order (003) | Trusted service_role only; no client EXECUTE; BIDDING and elapsed expiry. | Order lock; EXPIRED plus timestamp; closes ACTIVE offers. | Repeat rejects; event trigger; no scheduler required by current scope. now() can delay recognizing expiry in a long trusted transaction; use wall-clock decision when revisited with CR-003. |
| set_driver_online (005) | Caller-derived Driver; nullable input rejected; active account/office checks when enabling; active job conflict for toggles. | Driver lock; updates own availability. | Setting same permitted state is naturally repeatable; no order lifecycle event. Arabic hints are useful; no arbitrary Driver ID. |
| private.advance_order_state (008) | Internal only; explicit four transition pairs, expected state and assigned caller checked. | Shared order→Driver locking and atomic timestamp update. | No direct client entry point. Central seam for later verification, not a generic status editor. |
| Four authorization helpers (001) | auth.uid and database roles/memberships, not client metadata. | Stable SQL, no mutation. | CR-001/002: target permission and suspension semantics are wrong despite safe definer setup. |
| handle_new_auth_user / set_updated_at / record_order_event | Trigger use; CUSTOMER default ignores privileged signup metadata. Definer Auth/event functions are revoked from client execution. set_updated_at is invoker/trigger-only behavior. | Profile mapping; updated timestamps; append event on INSERT/status change within transaction. | No new event on same-status update. Event trigger/grant design is useful; admin before/after correction audit remains future work. |

All client-driven ownership checks run within trusted functions. Several functions lock an order before rejecting an unrelated caller, which can add contention for a known UUID; no practical P0/P1 denial-of-service exploit is claimed from that alone. Preserve consistent lock order; do not extract a helper that secretly acquires locks in a conflicting order.

## Security / RLS

Strong decisions: no normal-client DML on protected tables; private helper schema; auth.uid identity; no trusted role in user_metadata; candidate read projection excludes customer UUID/name/phone; Delivery details separated from candidate rows; customer offer RPC excludes Driver phone/documents/private office fields; order_events has no normal-client SELECT/INSERT/UPDATE/DELETE.

The four helper definitions were read from Development and match the source. The fresh role-switched probes exercised real RLS, not just a mocked helper. CR-001/002 are independent: fixing office correlation does not add suspension checks, and fixing suspension does not correlate permissions. CR-009 is a separate mutation eligibility gap.

Normal clients cannot insert a fake DRIVER/STAFF identity through signup metadata or edit role tables. Existing test coverage previously proved the basic boundary; it missed mixed-role multiple-office memberships and suspension. No whole RLS audit was rerun.

Broad SELECT is restricted by row policies, but future private fields must not be added casually to publicly readable service_types.config or assigned/customer row contracts. Current public service configuration has no identified secret. The code/template secret scan found no embedded service-role/secret/private-key value in the reviewed client source/templates; ignored local secrets were not dumped. This is not a dependency vulnerability audit.

## Flutter State Management

Thin FutureProviders are a good baseline. Network reads are not triggered by every widget rebuild, and Riverpod automatic provider retries are explicitly disabled. That does **not** disable PostgREST's separate GET/HEAD retry layer (three retries by default in the installed SDK).

Session sign-in/out invalidates Dashboard, History, Earnings and both order families, and resets the mutation generation. This is valuable protection against old callbacks affecting a new session. The generation guards also stop old recovery callbacks from clearing a newer session's barrier. Keep them.

Remaining issues: detail-family lifetime/freshness CR-014, aggregate dependency failure CR-012, over-invalidation CR-017, mutable pagination CR-015/016. Do not replace five useful read providers with a giant universal app store.

The global MutationReconciler stores operation/recovery state, not a competing local business database. Its simplicity is good, but its mutable phase fields and anonymous callbacks need narrow invariants and better tests, not more global state.

## Network Reliability

Sensitive Driver mutations all route through runDriverMutation, including availability, submit, withdraw, cancellation, and four lifecycle actions. Successful, deterministic-failure, uncertain and Auth outcomes all attempt authoritative reconciliation; writes are not retained for retry. The installed PostgREST SDK retries only GET/HEAD, not these POST RPC mutations.

CR-004 and CR-005 are different: a deadline makes stalled requests recoverable, but does not solve intent identity or prove an uncertain write cannot commit later. Never equate aborting an HTTP request with rolling back PostgreSQL.

### Catch / stale-state path inventory

| Location | Current behavior | Review |
|---|---|---|
| Shared Auth _submit | Catches error, shows safe Arabic message, resets busy if mounted. | Appropriate Auth form handling; reset completion itself is absent (CR-006). |
| DriverService._friendly | Converts known deterministic DB errors; transport/Auth errors propagate. | Good distinction; retain safe codes/context rather than only English-message matching (CR-023). |
| MutationReconciler.run | Classifies then awaits read; no replay. | Good core behavior; unbounded requests CR-005. |
| MutationReconciler.retryRead | Failure retains barrier; Auth path tries revalidation; retry is read-only. | Safe blocking, but loses failing-read context and can need another manual retry after successful refresh (CR-023). |
| Driver refresh order catch | Swallows **any** DriverAppException as authoritative absence. | Too broad; type absence separately from authorization/business failures (CR-013). |
| Waiting order.when error | Returns SizedBox.shrink while ACTIVE offer UI/actions remain. | Real stale-state presentation gap CR-011. |
| WaitingOffersList loadMore catch | Retains page and shows safe message. | Reasonable read failure fallback; generations/cursors missing CR-015/016. |
| Bootstrap catch | Stores error, offers retry, stays on restore. | No blind write, but optional Dashboard failure blocks core restoration CR-012. |
| Manual refresh / logout | Future error can escape callback. | CR-032; provider errors/local logout still provide partial protection. |
| runDriverMutation snackbar | Shown only after successful authoritative read and released barrier. | **Not** the former catch→snackbar→stale mutation bug. |

No timer polling, speculative reconnect loop, or automatic sensitive mutation retry was found. SDK Auth token maintenance is not business-data polling. No fresh phone-network or OS-resume runtime acceptance is claimed.

## Authentication

Signup/signin share email/password UI and safe Arabic mapping. Signup sends no role/account-type metadata; trusted trigger supplies CUSTOMER. Form controls prevent normal repeat submission while busy. A user can sign into the Driver app with a CUSTOMER account, but sees the explicit no-Driver-account state; backend—not app choice—controls Driver capability.

Router protection checks whether a session exists; it is not authorization. That is acceptable while backend checks remain authoritative. CR-018 concerns the separate Auth-stream error channel. The SDK already invalidates bad refresh sessions and locally signs out before remote revocation; do **not** invent a finding claiming offline logout necessarily retains the session.

Forgot Password is an implemented but incomplete feature (CR-006), not a future User Core screen. [Supabase's reset contract](https://supabase.com/docs/reference/dart/auth-resetpasswordforemail) requires returning to the application and updating the password after the email step.

Auth URLs/password settings in config.toml are **local Development defaults**, not evidence of hosted Production configuration. Do not treat enabled local tooling or disabled local confirmations as a confirmed Production security exposure. Before public launch, owner-approved redirect, confirmation, SMTP, staff MFA and credential policies need their scheduled release review.

## Routing

createAuthRouter has a straightforward signed-out→auth and signed-in→home/restore redirect, with no obvious two-route loop. Driver startup uses /restore; it chooses the active-order route from a fresh aggregate. CR-012 narrows the data needed by that route.

Dynamic order IDs are not locally trusted: Supabase/RPC ownership and UUID validation remain decisive. Invalid/deleted/other-order links currently receive misleading read-error UX (CR-013), not unauthorized data. Terminal Active Trip screens remove actions. Waiting's early SELECTED branch can bypass reading a terminal order (CR-011).

Re-entering a cached active route is not equivalent to fetching fresh state (CR-014). Navigation/back behavior was reviewed from source; no Android/back-stack or browser interaction acceptance was performed.

## app_core

| Classification | Contents / conclusion |
|---|---|
| GOOD SHARED LOGIC | Database enum values, Auth service/router listener, safe error mapping, mutation outcome classification, small recovery controller, price/date/status/route primitives. |
| SHOULD BE APP-SPECIFIC | DriverTripAction/next CTA, Driver availability explanation, Driver shell/navigation and recovery read composition already remain in Driver app. Keep that separation. |
| MISSING SHARED LOGIC | Complete password-recovery mode and safe Auth/read error boundaries (CR-006/013/018); bounded recovery contract. Share only after the actual common behavior is defined. |
| OVER-ABSTRACTED | No material repository/factory/use-case bloat found. Avoid turning AuthenticatedHomeScaffold into a universal app shell; it is currently a simple User placeholder. |
| UNDER-ABSTRACTED | Duplicate price formatting calls (CR-019), theme literals (CR-028), and read-error semantics. Use existing helpers rather than introducing a framework. |

The export/import cycle is legal, not an analyzer failure. A leaf enums file can remove unnecessary coupling when actual new consumers arrive. Exact numeric money belongs in PostgreSQL; the current double display model must not be promoted into a finance ledger calculation engine.

## Driver App

| Screen | Source-review outcome |
|---|---|
| Auth | Shared safe errors/busy state; reset completion and Auth-stream handling need work. |
| Home / requests | Explicit operational projection and bounded feed; active job hides new requests; account toggle ownership stays server-side. Stale cache/aggregate failures remain. |
| Request Details | One primary proposed-price action, secondary counter/ignore; finite-positive client input complements server validation. Existing offer shown after lost-submit recovery. Detail expiry is not modeled. |
| Waiting Offers | Multiple offers now accessible; per-offer ID retained. Mutable offset and delayed-page races remain. |
| Waiting Detail | Refresh/withdraw supported, but offer status alone misrepresents expired/cancelled order state (CR-011). |
| Active Trip | One next lifecycle action and secondary cancellation sheet; terminal action removal is correct. Successful-state manual freshness and broad recovery dependencies need correction. |
| Trips/History | Explicit owner/status query limited to 50; no current pagination. Consider labeling it recent history rather than silently implying all lifetime trips. No full-history milestone is invented here. |
| Earnings | Bounded displayed completed gross is honestly labeled; cancelled/active rows excluded. No invented commission/payroll. Duplicate history reads are CR-017. |
| Profile | Correct Driver type/status and office relation summary; sign-out is wrongly inside Dashboard success dependency (CR-012). |

Impeccable review focused on comprehension and recovery: no-Internet labels for terminal states, misleading waiting instructions, whole-pound fare rounding, and blocking controls are meaningful interaction defects. No subjective color redesign is requested. Keyboard/landscape/text-scale behavior still needs targeted device/layout acceptance: fixed-height skeletons and non-scrollable sheet columns are risk points, but this review does not claim a newly reproduced overflow without a render.

## User App

Implemented scope is Auth, configuration, protected routing, RTL setup, and a placeholder authenticated home. Missing Ride/Delivery Core screens are **not defects**.

Before expanding, reuse corrected shared Auth/recovery semantics; define creation intent handling, a compact customer read model, and session-scoped provider lifetime. Do not copy the Driver Dashboard fan-out or raw offer-status waiting logic. The backend currently supports preselection display and owned order/Delivery prefill; assigned-Driver contact/summary access will need a deliberately scoped contract when the User Core actually consumes it. That planned contract is not a reason to expose raw private profiles now.

## Dashboard

Implemented code is a static Arabic RTL landing/status page, layout metadata, and Tailwind styles. There is no Supabase client, authenticated route, permission-aware operation, or sensitive dynamic data yet. No frontend authorization bypass is claimed merely because the scaffold page is public.

Dependencies are appropriate for the present Next.js shell; no Maps/payments/UI-framework bloat was added. Local Next.js instructions were read; no Dashboard code was written and no build/lint was rerun. Lockfile versions are present; this review did not fetch vulnerability advisories for a dependency audit.

Five create-next-app SVGs in public are unreferenced by current src; iOS testExample bodies are empty scaffold tests. These are low-value cleanup candidates, **not separate inflated findings**. The landing status wording is old placeholder copy; updating it should follow the next actual Dashboard milestone, not drive this review into a redesign.

Future Dashboard authorization must use the repaired database helpers, and sensitive admin operations must be explicit/audited rather than generic table edits.

## Performance

| Path | Current work | Classification / action |
|---|---|---|
| Online Home load | Account then 3 parallel reads: 4 requests. Offline skips candidate request: 3. | Bounded and no N+1; reduce duplicated use through CR-012/017, not micro-optimization. |
| Online submit + reconciliation | 1 mutation + Dashboard 4 + own offer 2 + order detail 1 = 8 requests, excluding SDK retries/other watched tabs. | CURRENT PROBLEM, CR-017. |
| History then Earnings | Each separately loads account + latest 50 terminal orders. | CURRENT PROBLEM: reuse same terminal data. |
| Customer offer list | One server join, no client N+1, but no explicit paging limit. | FUTURE SCALE RISK, CR-025. |
| Waiting pagination | Each page 50, but live OFFSET is unstable. | Correctness before speed, CR-015/016. |
| Current indexes | Existing prefix/partial indexes cover the obvious implemented predicates; prior representative plans used indexes. | NO ACTION YET for new indexes; no fresh EXPLAIN or scale claim. |
| Widget format/sum work | Tiny pure formatting and ≤50-order gross display fold. | NO ACTION YET; do not add caching/isolate machinery. |

Internal SQL SELECT * into a %ROWTYPE variable is not a client N+1 or automatically a privacy leak. However public RPCs returning entire table composites should remain deliberately scoped as schema grows (CR-029). Actual Driver read projections are explicit.

## API / Infrastructure Cost

No Google routing/Places requests, FCM sends, Edge Function deployment, business-data polling, Realtime subscriptions, Redis, or GPS history writes exist. They are correctly deferred; enabling a local service in Supabase config is not runtime application usage.

The current cost lever is round trips (CR-017), followed by bounded customer offer payloads when needed (CR-025). Do not add a paid monitoring/cache service to solve missing operation context (CR-023). Future Maps should add one current-position row per Driver, PostGIS shortlist discovery and limited route calls; these are extension directions from the project rules, not implemented capabilities.

## Tests

### Quality classification

| Asset / pattern | Classification | Value and limit |
|---|---|---|
| Shared reconciler timeout/read-only retry test | GOOD TEST | Counts writes/reads and checks blocked→retry→recovered behavior. Only models commit-before-timeout, not commit-later or indefinite requests. |
| Driver lost-submit/lifecycle widget tests | GOOD TEST | Prove local CTA replacement and no replay for modeled outcomes; fake service bypasses real parsing/transport. |
| Auth safe-message cases | GOOD TEST | Confirms Arabic mapping and no raw secret text. Does not prove real Auth state routing. |
| Bootstrap tests | GOOD TEST with boundary limit | Prove route selection for fake active/null/terminal aggregate; not partial endpoint failure or actual authenticated root. |
| driver_core_test earnings data constructor assertion | LOW-VALUE TEST | It asserts fields just supplied to a passive DTO; it does not test filtering, summation or earnings presentation. |
| iOS RunnerTests.testExample | LOW-VALUE TEST | Empty scaffold body, no behavior; never count as application acceptance. |
| Enum test / foundation script | STRUCTURAL CHECK; partly BRITTLE TEST | Useful cheap presence/name check, not database/schema parity proof. OTP regex contradicts later trip verification (CR-030). |
| Identical setup-state tests in each app | NOT REDUNDANT | Tiny independent app bootstrap checks; no reason to merge them into elaborate shared test infrastructure. |
| Bounded presentation tests using exact strings/widget counts | PARTLY BRITTLE TEST | Valid behavior checks, but avoid equating one FilledButton/string match with complete accessibility/device acceptance. |
| Mixed-office/suspension tests, retained 6.1/7A boundaries | MISSING HIGH-VALUE TEST | CR-021; current RLS tests covered simpler actor sets and missed confirmed cases. |
| Real service HTTP projections/error mapping, actual Auth stream/root router | MISSING HIGH-VALUE TEST | CR-022. |
| True cross-order two-session acceptance | MISSING HIGH-VALUE TEST | CR-008; sequential calls cannot prove overlap. |

No existing full suite was rerun just to report a fresh PASS. A future remediation should add the smallest failing behavior check for each changed boundary. Keep tests at their actual evidence level: source, unit, hosted SQL role simulation, Auth HTTP, widget, and physical device are different.

### Reproducible review probes

Run only on an authorized Development database, as a sufficiently privileged test setup connection. Each script uses reserved review UUIDs and ends in ROLLBACK; the authenticated sections exercise RLS/RPCs. These are documentation evidence, not schema or migration changes. The clock probe deliberately shortens **only its temporary order's** deadline to avoid waiting 90 seconds.

#### Authorization probe

```sql
begin;
do $review$
declare
  staff uuid := '8d310000-0000-0000-0000-000000000001';
  driver_user uuid := '8d310000-0000-0000-0000-000000000002';
  admin_user uuid := '8d310000-0000-0000-0000-000000000003';
  office_a uuid := '8d310000-0000-0000-0000-000000000011';
  office_b uuid := '8d310000-0000-0000-0000-000000000012';
  drv uuid := '8d310000-0000-0000-0000-000000000021';
  doc uuid := '8d310000-0000-0000-0000-000000000031';
  n integer;
  e jsonb := '{}'::jsonb;
begin
  insert into auth.users(id,email,raw_user_meta_data) values
    (staff,'review-staff-8d31@example.invalid','{}'),
    (driver_user,'review-driver-8d31@example.invalid','{}'),
    (admin_user,'review-admin-8d31@example.invalid','{}');
  update public.profiles set profile_type='STAFF' where id in (staff,admin_user);
  update public.profiles set profile_type='DRIVER' where id=driver_user;
  insert into public.offices(id,name) values (office_a,'Review A'),(office_b,'Review B');
  insert into public.office_members(office_id,user_id,role_id)
    select office_a,staff,id from public.roles where code='OFFICE_ACCOUNTANT'
    union all select office_b,staff,id from public.roles where code='OFFICE_DISPATCHER';
  insert into public.user_roles(user_id,role_id)
    select admin_user,id from public.roles where code='SUPER_ADMIN';
  insert into public.drivers(id,user_id,driver_type,office_id,status)
    values(drv,driver_user,'OFFICE_DRIVER',office_a,'ACTIVE');
  insert into public.driver_documents(id,driver_id,document_type,file_path)
    values(doc,drv,'review-only','review-only/private-test-document');

  perform set_config('request.jwt.claim.sub',staff::text,true);
  set local role authenticated;
  select count(*) into n from public.driver_documents where id=doc;
  e := e || jsonb_build_object('accountant_A_dispatcher_B_reads_A_document',n);
  reset role;

  delete from public.office_members where office_id=office_a and user_id=staff;
  insert into public.office_members(office_id,user_id,role_id)
    select office_a,staff,id from public.roles where code='OFFICE_DISPATCHER';
  delete from public.office_members where office_id=office_b and user_id=staff;
  update public.profiles set status='SUSPENDED' where id=staff;
  set local role authenticated;
  select count(*) into n from public.driver_documents where id=doc;
  e := e || jsonb_build_object('suspended_staff_reads_document',n);
  reset role;

  update public.profiles set status='ACTIVE' where id=staff;
  update public.offices set status='SUSPENDED' where id=office_a;
  set local role authenticated;
  select count(*) into n from public.driver_documents where id=doc;
  e := e || jsonb_build_object('suspended_office_staff_reads_document',n);
  reset role;

  update public.profiles set status='SUSPENDED' where id=admin_user;
  perform set_config('request.jwt.claim.sub',admin_user::text,true);
  set local role authenticated;
  e := e || jsonb_build_object('suspended_super_admin_is_super_admin',private.is_super_admin());
  select count(*) into n from public.driver_documents where id=doc;
  e := e || jsonb_build_object('suspended_super_admin_reads_document',n);
  reset role;
  perform set_config('biko.review_security_evidence',e::text,true);
end;
$review$;
select current_setting('biko.review_security_evidence')::jsonb as evidence;
rollback;
```

#### Suspected business-contract probe

```sql
begin;
do $review$
declare
 c uuid := '8d320000-0000-0000-0000-000000000001';
 u uuid := '8d320000-0000-0000-0000-000000000002';
 d uuid := '8d320000-0000-0000-0000-000000000012';
 svc uuid; a uuid; b uuid; f uuid; f2 uuid;
 e jsonb := '{}'::jsonb;
begin
 insert into auth.users(id,email,raw_user_meta_data) values
  (c,'review-customer-8d32@example.invalid','{}'),
  (u,'review-driver-8d32@example.invalid','{}');
 update public.profiles set profile_type='DRIVER',full_name='Review Driver' where id=u;
 insert into public.drivers(id,user_id,driver_type,status,is_online) values(d,u,'INDEPENDENT','ACTIVE',true);
 select id into svc from public.service_types where code='RIDE';
 perform set_config('request.jwt.claim.sub',c::text,true);
 set local role authenticated;
 select id into a from public.create_order(svc,30,31,'Review pickup',30.1,31.1,'Review destination',80);
 select id into b from public.create_order(svc,30,31,'Review pickup',30.1,31.1,'Review destination',80);
 reset role;
 e := e || jsonb_build_object('identical_create_calls_distinct_orders',a<>b);
 insert into public.order_driver_candidates(order_id,driver_id) values(a,d),(b,d);
 perform set_config('request.jwt.claim.sub',u::text,true);
 set local role authenticated;
 select id into f from public.submit_offer(a,90);
 reset role;
 update public.orders set bidding_expires_at=clock_timestamp()+interval '50 milliseconds' where id=a;
 perform pg_sleep(0.1);
 e := e || jsonb_build_object('wall_clock_past_deadline_before_accept',
    (select clock_timestamp()>bidding_expires_at from public.orders where id=a));
 perform set_config('request.jwt.claim.sub',c::text,true);
 set local role authenticated;
 perform public.accept_offer(a,f);
 reset role;
 e := e || jsonb_build_object('past_deadline_accept_status',(select status from public.orders where id=a));
 perform set_config('request.jwt.claim.sub',u::text,true);
 set local role authenticated;
 perform public.driver_on_way(a);
 perform public.driver_arrived(a);
 perform public.start_order(a);
 perform public.complete_order(a);
 reset role;
 e := e || jsonb_build_object('completed_order_count',(select count(*) from public.orders where driver_id=d and status='COMPLETED'),
     'stored_completed_trip_count',(select completed_trip_count from public.drivers where id=d));
 perform set_config('request.jwt.claim.sub',u::text,true);
 set local role authenticated;
 perform public.set_driver_online(true);
 select id into f2 from public.submit_offer(b,95);
 perform public.set_driver_online(false);
 perform set_config('request.jwt.claim.sub',c::text,true);
 e := e || jsonb_build_object('offline_driver_customer_offer_rows',(select count(*) from public.get_customer_order_offers(b)));
 reset role;
 update public.profiles set status='SUSPENDED' where id=c;
 perform set_config('request.jwt.claim.sub',u::text,true);
 set local role authenticated;
 perform public.set_driver_online(true);
 perform set_config('request.jwt.claim.sub',c::text,true);
 perform public.accept_offer(b,f2);
 reset role;
 e := e || jsonb_build_object('suspended_customer_accept_status',(select status from public.orders where id=b));
 perform set_config('biko.review_business_evidence',e::text,true);
end;
$review$;
select current_setting('biko.review_business_evidence')::jsonb as evidence;
rollback;
```

## Maintainability

### Duplication and smallest response

| Duplication | Value of extraction | Recommendation |
|---|---|---|
| Repeated customer/account/Driver eligibility across RPCs | HIGH VALUE for security consistency, but lock behavior differs | Reuse small side-effect-free authorization predicates where exact semantics match; never centralize hidden lock acquisition. Fix CR-001/002/009 first. |
| Account and terminal-order requests | HIGH VALUE | Reuse provider results (CR-017), not a new cache service. |
| Whole-pound formatting at two callers | HIGH VALUE / tiny | Use existing formatAmount (CR-019). |
| Shared blue/slate/semantic literals | MEDIUM VALUE | Theme-native values when next touched (CR-028). |
| Same enum/action/status sets in DB and Flutter | MEDIUM VALUE contract testing, LOW VALUE generic generation now | Keep explicit domain mappings and validate parity; do not generate a universal state machine. |
| Two app bootstrap/setup shells | LOW VALUE | Separate apps need independent lifecycle; no framework extraction until real behavior overlaps. |
| Cancellation reason length 500 in UI/service/SQL | LOW VALUE extraction across languages | Validation at each trust boundary is intentional. A local Dart constant may help later; SQL remains authoritative. |

### Magic values / configuration

| Value | Classification | Decision |
|---|---|---|
| 90 seconds, 8 kg, 3000 EGP | GOOD CONSTANT in trusted frozen backend contract | Keep server-owned; repeated function/constraint limits protect different boundaries. Change together through future migration if product approves. |
| 20 request / 50 waiting/history limits | SHOULD BE CENTRALIZED as named paging contracts | Cursor/caller contracts must agree (CR-015/025). Do not turn every UI list into remote settings. |
| 500 reason characters | GOOD CONSTANT at validation boundaries | No server round trip just to fetch a fixed input limit. |
| Active order/offer enum sets | GOOD CONSTANT | Stable business states; explicit mappings are clearer than arbitrary configurable state graphs. |
| Supabase URL / publishable key | Environment-specific configuration | Compile-time safe client settings; no service secret in clients. Restrict supported schemes/host expectations if bootstrap config validation is hardened. |
| Theme accents/semantic colors | SHOULD BE CENTRALIZED / Theme-owned | CR-028; ordinary padding values do not need configuration services. |
| Commission/promotions/credit thresholds/zones | FUTURE CONFIGURATION / SHOULD BE SERVER CONFIG | Do not introduce guessed client constants now. |
| Map radius/ETA/GPS cadence | FUTURE CONFIGURATION | Implement with actual Maps cost/dispatch requirements, not speculative hooks now. |

Naming is mostly consistent (p_ RPC args, database enums, Driver-specific actions). `isSignedIn` means session-present, not permission-approved; `canGoOnline` is only a UI ACTIVE hint, not the full backend decision; `DriverEarningsData` currently carries displayed gross history, not finance truth. Make those semantics explicit at consumption points. `DriverErrorState.message` is actually unused (CR-013), unlike a merely long file.

## Future Rework Risks

| Upcoming milestone | Readiness | Extension seam / risk |
|---|---|---|
| 7 User App | **HIGH REWORK RISK if copied unchanged** | Creation has no intent recovery key; shared reset/error/recovery flows are incomplete; read composition must not duplicate Driver fan-out. CR-001–006/009–013/018/019/021/022/024/026 plus existing race gate need decisions first. |
| 8 Maps | **MINOR CHANGE** | Database coordinates and candidate boundary are useful. DriverOrder currently omits coordinates/expiry; add a deliberate operational projection when used. Keep PostGIS discovery separate from paid routes and fix freshness before adding map state (CR-014). |
| 9 Realtime | **HIGH REWORK RISK in read invalidation, not backend authority** | Coalesce resource-specific invalidations; fix mutable offsets/generations and broad refresh fan-out (CR-015–017). Events should trigger compact authoritative reads, not client status writes. |
| 10 Safety | **MINOR CHANGE** | DriverTripAction/service and private transition core are usable seams for required OTP/geofence checks. Add verification per transition, not a generic bypass. Scope obsolete OTP regex first (CR-030). |
| 11 Dashboard/Ops | **HIGH REWORK RISK if current helpers are reused** | Repair scoped/suspended authorization and trusted assignment shape (CR-001/002/020). Add explicit audited admin commands later. Static Dashboard shell is otherwise READY for its own implementation. |
| 12 Finance | **MINOR CHANGE if isolated; HIGH REWORK RISK if current display doubles become ledger authority** | Retain exact numeric agreed price and office snapshot; introduce approved ledger/rate snapshots server-side. Current gross-only UI need not be rewritten today. |

Ratings, advanced operations, OTP, geofences, Realtime/FCM and finance are deliberately **FUTURE FEATURE — NOT A DEFECT**. No speculative schema, index or paid infrastructure is recommended just to fill these rows.

## High-Risk Code Map

| # | Area | Why high risk / likely failure | Current protection | Smallest improvement |
|---:|---|---|---|---|
| 1 | Authorization helpers (001) | Central RLS dependency; mixed-office escalation or suspended privileged access. | Trusted role tables, definer hardening, no client role writes. | CR-001/002 correlated/status-aware checks. |
| 2 | accept_offer (008) | Multi-row selection and cross-order closure; late or concurrent commitments. | Order/Driver/sorted-offer locks, recheck, active-job uniqueness, event transaction. | CR-003/008/009 and one real overlapping proof. |
| 3 | create_order (007) | First persisted ID can be lost with response; duplicate intent ambiguous. | Active customer/route/Delivery validation and atomic insert. | CR-004 stable per-customer intent. |
| 4 | MutationReconciler + root barrier | One stalled or misclassified request disables the app. | No write replay, session-generation guard, manual read retry. | CR-005 bounded transport and CR-023 diagnostics. |
| 5 | Driver Dashboard/bootstrap/providers | Optional feed errors gate core recovery; stale caches persist. | Parallel bounded reads and explicit invalidation. | CR-012/014/017 narrow dependencies. |
| 6 | Waiting detail and pagination | Expired/cancelled offers look actionable; live pages skip/reappear. | Owned offer IDs, safe RPC limits, backend write guards. | CR-011/015/016 authoritative summary/cursor/generation. |
| 7 | Shared Auth/router | Reset cannot finish; stream errors bypass form catches. | Shared safe messages, session redirect, SDK local logout. | CR-006/018 real recovery mode/error channel. |
| 8 | orders/offers/events shape | Trusted tooling can make contradictory assignments; public counters drift. | FKs, same-order FK, unique active jobs, atomic status events. | CR-010/020 minimal integrity hardening. |
| 9 | Android release configuration | Debug evidence hides missing network permission/debug signing. | Separate app IDs and explicit Development templates. | CR-007/027 merged manifest/certificate checks. |
| 10 | Regression evidence and current-status docs | Fakes/historical claims can hide regressions or restart completed work. | Useful targeted tests and retained historical ledgers. | CR-021/022/024 durable focused evidence/current status. |

## Findings

Every item below is **OPEN — REVIEW ONLY**, unless explicitly described as an existing evidence gap. Recommendations are not authorization to implement them. ROI-A = high impact/low–medium effort; ROI-B = high impact/high effort; ROI-C = medium impact/low effort; ROI-D = defer. No recommendation needed a new ROI-B architecture project.

P1 evidence is distinguished as hosted reproduction, installed-source/configuration proof, or missing required validation. Static scenarios are not mislabeled device or concurrency tests.

### CR-001 — Permissions from one office authorize another office

**P1 · ROI-A · SECURITY RISK**  
Area: Office authorization. Timing: **FIX NOW BEFORE USER APP**.  
Source: [supabase/migrations/202608300001_authorization_rls.sql](C:/projects/biko/supabase/migrations/202608300001_authorization_rls.sql:66) — `private.can_access_office / private.has_permission`.

- **Evidence / current design:** can_access_office checks target membership, then has_permission searches all memberships (lines 22–80). Hosted probe: Accountant A + Dispatcher B read 1 Driver-document row in A.
- **Scenario:** A staff member is an OFFICE_ACCOUNTANT in office A and an OFFICE_DISPATCHER in B. drivers.view from B satisfies A's policy although Accountant A has no such permission.
- **Impact:** Cross-office permission escalation exposes driver profiles and document metadata within an office where the user lacks that permission.
- **Why existing protection is insufficient:** RLS and membership checks exclude non-members, but do not bind the permission to the same membership. office_members permits one user in multiple offices; the one-office Driver rule does not prohibit this staff scenario.
- **Minimum recommended change:** Resolve office membership, its role permission, and target_office_id in the same EXISTS. Keep explicit platform Super Admin handling separate.
- **Estimated scope / dependency:** Small helper migration + mixed-role regression. None.
- **Targeted acceptance:** Two-office mixed-role test must deny A driver/documents and still allow B's permitted reads.

### CR-002 — Suspension does not revoke privileged reads

**P1 · ROI-A · SECURITY RISK**  
Area: Privilege revocation. Timing: **FIX NOW BEFORE USER APP**.  
Source: [supabase/migrations/202608300001_authorization_rls.sql](C:/projects/biko/supabase/migrations/202608300001_authorization_rls.sql:5) — `private.is_super_admin / has_permission / is_office_member`.

- **Evidence / current design:** Helpers inspect role/membership rows but never profiles.status or offices.status. Hosted probes returned one protected document for suspended staff and suspended-office staff; suspended Super Admin still returned true and read it.
- **Scenario:** An operator suspends a staff profile or office while its existing Auth session remains valid. Subsequent protected SELECTs still succeed.
- **Impact:** Suspended privileged accounts retain access to other people's operational/private data.
- **Why existing protection is insufficient:** om.status='ACTIVE' is checked, but changing profile or office status does not change every membership. Supabase JWT validity is not the application's account-status policy.
- **Minimum recommended change:** Require an ACTIVE caller profile in privilege helpers and an ACTIVE target office for office-scoped access. Make any exceptional suspended-office support access explicit and platform-only.
- **Estimated scope / dependency:** Small helper migration + suspension cases. Coordinate with CR-001.
- **Targeted acceptance:** Existing-session reads fail after staff/office suspension; active authorized access remains intact.

### CR-003 — A request waiting on locks can act after the bidding deadline

**P1 · ROI-A · LOGIC DEFECT**  
Area: Bidding transactions. Timing: **FIX NOW BEFORE USER APP**.  
Source: [supabase/migrations/202608300008_gate_2_remediation.sql](C:/projects/biko/supabase/migrations/202608300008_gate_2_remediation.sql:216) — `accept_offer; submit_offer; withdraw_offer`.

- **Evidence / current design:** Expiry compares bidding_expires_at to transaction-start now(); accept_offer checks before later Driver/offer locks. Rollback probe: wall clock passed expiry, yet accept_offer returned DRIVER_ASSIGNED.
- **Scenario:** Acceptance starts just before expiry and waits on an order/Driver lock until after expiry. now() stays at transaction start; there is no final wall-clock check after all relevant locks.
- **Impact:** The frozen 90-second eligibility boundary is exceeded under contention, even with one valid winner.
- **Why existing protection is insufficient:** Locks and the active-job unique index protect assignment uniqueness, not elapsed wall time. Replacing now() only at the existing early check still misses later lock waits.
- **Minimum recommended change:** Check clock_timestamp() after acquiring the locks needed for the write, immediately before the state mutation. Apply the same deadline discipline to submit/withdraw; leave stable read-time queries alone.
- **Estimated scope / dependency:** Focused RPC migration + boundary test. Preserve current lock order.
- **Targeted acceptance:** A lock-wait crossing expiry must reject; an in-window action must succeed. The review probe proves clock semantics, not an overlapping race.

Related checks: [submit_offer deadline](C:/projects/biko/supabase/migrations/202608300008_gate_2_remediation.sql:116); [withdraw_offer deadline](C:/projects/biko/supabase/migrations/202608300006_user_flow_backend_delta.sql:299). PostgreSQL documents that now() is transaction-start time and clock_timestamp() advances during execution: [official timing reference](https://www.postgresql.org/docs/current/functions-datetime.html#FUNCTIONS-DATETIME-CURRENT).

### CR-004 — create_order has no stable key for recovering an uncertain creation

**P1 · ROI-A · ARCHITECTURE DEBT**  
Area: Create/recovery contract. Timing: **FIX NOW BEFORE USER APP**.  
Source: [supabase/migrations/202608300007_user_flow_privacy_hardening.sql](C:/projects/biko/supabase/migrations/202608300007_user_flow_privacy_hardening.sql:63) — `create_order`.

- **Evidence / current design:** Every call inserts a generated order ID; there is no client intent ID/uniqueness contract. Two identical authenticated calls in the rollback probe produced distinct orders.
- **Scenario:** A new order commits, but the response containing its generated ID is lost. The future User client cannot distinguish that intent from another matching order or safely retry the original creation.
- **Impact:** Duplicate bookings or ambiguous recovery; copying the Driver read-after-write pattern cannot identify a new order whose ID was never received.
- **Why existing protection is insufficient:** Ownership, atomic insertion, positive prices, and BIDDING validation do not deduplicate an intent. A successful read does not prove a timed-out write can no longer commit. Legitimate Book Again must still create a new order.
- **Minimum recommended change:** Add one caller-generated creation intent UUID, unique per customer, and return the existing result for the same intent; reject payload changes for that key. New intentional bookings use new keys.
- **Estimated scope / dependency:** Focused contract migration + lost-response test. Customer creation UI consumes the contract later.
- **Targeted acceptance:** Repeat one intent returns one order; a new intent with identical inputs creates another; conflicting payload is rejected.

### CR-005 — A stalled request can hold the entire Driver app behind a permanent overlay

**P1 · ROI-A · UX/STATE LOGIC ISSUE**  
Area: Network recovery. Timing: **FIX NOW BEFORE USER APP**.  
Source: [packages/app_core/lib/operation_recovery.dart](C:/projects/biko/packages/app_core/lib/operation_recovery.dart:94) — `MutationReconciler.run / retryRead`.

- **Evidence / current design:** await mutate() and await read() are unbounded; ConnectionStateView hides retry while checking/submitting. DriverRecoveryBoundary absorbs all actions. Installed PostgREST 2.9.1 defaults requestTimeout to null; app initialization supplies no override.
- **Scenario:** A connection remains open but stops delivering a response during a mutation or reconciliation read. No exception occurs, so recovery never reaches the unavailable/manual-retry state.
- **Impact:** Active-trip controls, navigation, and Profile sign-out remain inaccessible for an unbounded period.
- **Why existing protection is insufficient:** TimeoutException classification only handles a timeout that somebody actually produces. Riverpod retry:null does not configure transport deadlines; SDK GET retries can also multiply wait time.
- **Minimum recommended change:** Use the installed client's bounded request/abort support, choose a bounded read retry budget, and enter uncertain/read-only recovery on mutation timeout. Never treat abort as proof the database rolled back or replay a sensitive RPC automatically.
- **Estimated scope / dependency:** Small transport/recovery configuration + stalled-Future test. CR-004 for safe creation recovery.
- **Targeted acceptance:** A non-settling request reaches a recoverable state within the configured budget, without a second write.

Related barrier: [DriverRecoveryBoundary](C:/projects/biko/apps/driver_app/lib/features/driver/driver_screens.dart:1346); configuration: [Supabase initialization](C:/projects/biko/apps/driver_app/lib/main.dart:18). Installed dependency evidence: [PostgREST timeout defaults](C:/Users/N/AppData/Local/Pub/Cache/hosted/pub.dev/postgrest-2.9.1/lib/src/postgrest.dart:48).

### CR-006 — Forgot Password sends email but cannot finish resetting the password

**P1 · ROI-A · BUG**  
Area: Shared authentication. Timing: **FIX NOW BEFORE USER APP**.  
Source: [packages/app_core/lib/app_core.dart](C:/projects/biko/packages/app_core/lib/app_core.dart:113) — `AuthService.requestPasswordReset / createAuthRouter / AuthMode`.

- **Evidence / current design:** Only resetPasswordForEmail exists; no passwordRecovery route, new-password form, or auth.updateUser call exists anywhere in app code. Mobile manifests/plists have no recovery callback configuration; local site_url points to 127.0.0.1:3000.
- **Scenario:** A user who forgot their password receives the advertised reset email. There is no implemented application screen/action that saves a replacement password.
- **Impact:** The implemented account-recovery feature cannot complete in either mobile app.
- **Why existing protection is insufficient:** The router only distinguishes session present/absent; a recovery session is not routed to password update. An email delivery success is not a completed reset.
- **Minimum recommended change:** Complete the existing shared Auth flow with a recovery callback, recovery-mode routing, new-password submission, and allowlisted mobile redirect configuration. Do not introduce login OTP.
- **Estimated scope / dependency:** Shared Auth UI/router + Android/iOS callback setup. Approved Development Auth redirect configuration.
- **Targeted acceptance:** Open a recovery link, save a new password, then sign in with it; invalid/expired links fail safely.

Related router: [createAuthRouter](C:/projects/biko/packages/app_core/lib/app_core.dart:138). The required email→callback→password-update sequence is described by [Supabase's Dart reset documentation](https://supabase.com/docs/reference/dart/auth-resetpasswordforemail).

### CR-007 — Release manifests do not declare INTERNET permission

**P1 · ROI-A · BUG**  
Area: Android release configuration. Timing: **FIX BEFORE PUBLIC LAUNCH**.  
Source: [apps/driver_app/android/app/src/main/AndroidManifest.xml](C:/projects/biko/apps/driver_app/android/app/src/main/AndroidManifest.xml:1) — `Main manifests in both Flutter apps`.

- **Evidence / current design:** INTERNET exists only in src/debug and src/profile, not src/main. Both apps' resolved Android plugin manifests (app_links, shared_preferences_android, url_launcher_android) also omit it.
- **Scenario:** Build the current app as an Android release artifact: development-only manifest permissions do not supply release networking.
- **Impact:** Supabase authentication and database calls cannot work in the release app.
- **Why existing protection is insufficient:** Debug/widget checks can pass with debug permission or fake services and do not validate the release manifest. This is source/configuration evidence, not a claimed APK/device test.
- **Minimum recommended change:** Declare INTERNET in each main manifest and verify the merged release manifest once. Do not rely on a dependency to grant an app-required permission.
- **Estimated scope / dependency:** Two manifest lines + merged-manifest check. Android release toolchain for acceptance.
- **Targeted acceptance:** Both merged release manifests contain INTERNET and one release-device Supabase request succeeds.

Same issue: [User main manifest](C:/projects/biko/apps/user_app/android/app/src/main/AndroidManifest.xml:1). [Flutter's Android networking requirement](https://docs.flutter.dev/data-and-backend/networking#android) calls for an explicit manifest permission.

### CR-008 — The changed cross-order acceptance lock protocol lacks a genuine race proof

**P1 · ROI-A · TESTABILITY GAP**  
Area: Concurrency evidence. Timing: **FIX NOW BEFORE USER APP**.  
Source: [supabase/migrations/202608300008_gate_2_remediation.sql](C:/projects/biko/supabase/migrations/202608300008_gate_2_remediation.sql:184) — `accept_offer; supabase/tests/gate_2_remediation.sql`.

- **Evidence / current design:** Current code has Driver locking/recheck, sorted affected-offer locks, and active-job uniqueness. The retained SQL test is sequential. Gate report records session 74036 ending before 74041 began.
- **Scenario:** Two customers select the same Driver on different orders simultaneously, including cross-order closure of the losing offer.
- **Impact:** The required gate remains unproven for waits, rejection outcome, atomic closure, and deadlock behavior after the lock-protocol change.
- **Why existing protection is insufficient:** The partial unique index is a real correctness backstop. It does not demonstrate clean concurrent RPC behavior. Historical same-order races are not this changed cross-order case.
- **Minimum recommended change:** Run one barrier-controlled two-session test through an explicitly authorized concurrency-capable path; retain timestamps, both outcomes, final invariant/event counts, and cleanup. Do not add infrastructure implicitly.
- **Estimated scope / dependency:** One targeted concurrent test/evidence record. Authorization for a concurrency-capable connection path.
- **Targeted acceptance:** Database intervals overlap; exactly one active assignment and one winner event remain, with a safe loser and no residual fixtures.

Existing evidence: [Gate 2 report, appended remediation section](C:/projects/biko/docs/SYSTEM_VALIDATION_GATE_2_REPORT.md); [sequential retained test](C:/projects/biko/supabase/tests/gate_2_remediation.sql:1). This review did not retry the serialized connector path.

### CR-009 — A suspended customer can still select a Driver

**P2 · ROI-A · SECURITY RISK**  
Area: Customer eligibility. Timing: **FIX NOW BEFORE USER APP**.  
Source: [supabase/migrations/202608300008_gate_2_remediation.sql](C:/projects/biko/supabase/migrations/202608300008_gate_2_remediation.sql:201) — `accept_offer customer checks`.

- **Evidence / current design:** The caller is checked for auth.uid and order ownership, but only the Driver's profile status is validated. Hosted suspended-customer acceptance returned DRIVER_ASSIGNED.
- **Scenario:** Customer creates an order while ACTIVE, is suspended, then selects an offer using the still-valid session.
- **Impact:** Suspension blocks creation but not the later new-work assignment commitment.
- **Why existing protection is insufficient:** create_order's ACTIVE customer check happened earlier. Ownership remains correct; this is not cross-customer access.
- **Minimum recommended change:** Require ACTIVE CUSTOMER eligibility when accepting an offer. Preserve any deliberately allowed safe cancellation/history access separately.
- **Estimated scope / dependency:** Small RPC guard + negative test. None.
- **Targeted acceptance:** Suspended customer acceptance rejects without changing order, offers, or events.

### CR-010 — Completed-trip count never changes after completion

**P2 · ROI-A · DATA-INTEGRITY RISK**  
Area: Public Driver statistics. Timing: **FIX NOW BEFORE USER APP**.  
Source: [supabase/migrations/202608300008_gate_2_remediation.sql](C:/projects/biko/supabase/migrations/202608300008_gate_2_remediation.sql:404) — `advance_order_state(COMPLETED); get_customer_order_offers`.

- **Evidence / current design:** No implemented write updates drivers.completed_trip_count. Completion probe produced 1 completed order and stored_completed_trip_count=0; offer RPC returns that stored value (006:477).
- **Scenario:** A Driver completes legitimate orders, then appears in another customer's offer list with the unchanged default count.
- **Impact:** The current privacy-safe read model publishes an inaccurate trust signal.
- **Why existing protection is insufficient:** The nonnegative CHECK prevents invalid negative values, not drift. Ratings are correctly omitted, but completed count is already advertised as real data.
- **Minimum recommended change:** Choose one authority: update the count transactionally once per completion with a reconciliation/backfill rule, or derive the actual count in a measured set-based read. Do not invent ratings.
- **Estimated scope / dependency:** Small DB change + one completion/count regression. Preserve stale-transition/event guards.
- **Targeted acceptance:** One completion increments/derives once; a repeated completion cannot double count.

### CR-011 — Waiting details treat offer status as complete order truth

**P2 · ROI-A · UX/STATE LOGIC ISSUE**  
Area: Driver waiting state. Timing: **FIX NOW BEFORE USER APP**.  
Source: [apps/driver_app/lib/features/driver/driver_screens.dart](C:/projects/biko/apps/driver_app/lib/features/driver/driver_screens.dart:608) — `_OfferWaitingContentState.build / DriverService.loadOffer`.

- **Evidence / current design:** loadOffer reads raw latest offer status with no expiry/order state. ACTIVE renders waiting and withdrawal even when safe order lookup fails (error hidden at 677); SELECTED returns early before any order read.
- **Scenario:** After 90 seconds, persisted BIDDING/ACTIVE rows can remain until trusted expiry. Refresh still says waiting and offers withdrawal, although withdrawal rejects. After customer cancellation, a SELECTED offer still says 'start heading to the customer'.
- **Impact:** The UI can instruct action on an elapsed/cancelled trip despite successful refresh.
- **Why existing protection is insufficient:** Home's active-offer RPC filters elapsed windows and mutation guards reject invalid actions. Neither corrects this detail screen's read model; no cron is required to fix presentation.
- **Minimum recommended change:** Read one owned-offer summary with authoritative order status and expiry; derive waiting/selected/terminal display together. Keep terminal orders terminal and remove stale actions.
- **Estimated scope / dependency:** Small read-model/UI change + expiry/cancellation cases. No Realtime or scheduled expiry dependency.
- **Targeted acceptance:** Manual refresh after expiry/cancellation displays a terminal/unavailable summary with no misleading withdrawal/start direction.

### CR-012 — Active-trip restoration and Profile depend on the whole Dashboard

**P2 · ROI-A · ARCHITECTURE DEBT**  
Area: Driver read dependencies. Timing: **FIX NOW BEFORE USER APP**.  
Source: [apps/driver_app/lib/features/driver/driver_service.dart](C:/projects/biko/apps/driver_app/lib/features/driver/driver_service.dart:17) — `loadDashboard; DriverBootstrapScreen._restore; DriverProfileScreen`.

- **Evidence / current design:** Future.wait combines requests, active order, and waiting offers; any failure rejects all data. Bootstrap awaits that aggregate (screens:1326), and Profile renders/signs out only in dashboard.data (1111–1193).
- **Scenario:** The active-order request succeeds but waiting-offer request fails. Reopening cannot reach the known active trip; Profile also hides sign-out behind a feed failure.
- **Impact:** Optional feed failures disable unrelated core recovery and account controls.
- **Why existing protection is insufficient:** Parallel reads reduce latency, not failure coupling. Fake bootstrap tests override the aggregate and cannot detect partial endpoint failure.
- **Minimum recommended change:** Restore from the minimal account/active-order read; make optional feed failures local to their section. Profile/sign-out must not depend on available requests. Reuse existing services, without adding repository layers.
- **Estimated scope / dependency:** Small provider/service dependency split + partial-failure test. Coordinate with CR-017.
- **Targeted acceptance:** A failed waiting/request read does not prevent active-trip restoration or sign-out access.

### CR-013 — Known absence and session errors are rendered as no Internet

**P2 · ROI-C · UX/STATE LOGIC ISSUE**  
Area: Read-error presentation. Timing: **FIX NOW BEFORE USER APP**.  
Source: [apps/driver_app/lib/features/driver/driver_ui.dart](C:/projects/biko/apps/driver_app/lib/features/driver/driver_ui.dart:196) — `DriverErrorState`.

- **Evidence / current design:** The required message parameter is discarded; build always returns RecoveryPhase.unavailable. loadOrder's explicit 'order no longer available' error and Auth failures take this same UI path.
- **Scenario:** Open an expired, unauthorized, or invalid order link on a healthy network. The screen asks the user to repair connectivity and retry forever.
- **Impact:** Wrong recovery guidance hides terminal/permission/session outcomes.
- **Why existing protection is insufficient:** Raw backend text is safely hidden, but hiding safe classified messages is not necessary for privacy.
- **Minimum recommended change:** Use a small typed read outcome for not-found/forbidden/auth/network; render the already-safe message and appropriate home/sign-in/retry action. Only catch authoritative absence as absence, not every DriverAppException.
- **Estimated scope / dependency:** Shared read-state mapping + Driver callers. Coordinate with CR-011 and CR-018.
- **Targeted acceptance:** Healthy-network not-found and expired-session cases do not claim connectivity loss.

### CR-014 — Order-detail caches can survive indefinitely without a refresh path

**P2 · ROI-A · UX/STATE LOGIC ISSUE**  
Area: Provider freshness. Timing: **FIX BEFORE MAPS**.  
Source: [apps/driver_app/lib/features/driver/driver_providers.dart](C:/projects/biko/apps/driver_app/lib/features/driver/driver_providers.dart:28) — `driverOrderProvider / driverOfferProvider; ActiveOrderScreen`.

- **Evidence / current design:** Non-autoDispose families retain per-order results until explicit invalidation/sign-in/out. Active and Request detail data screens have no successful-state refresh action; no app-level resume invalidation exists.
- **Scenario:** Customer cancels while Driver's active screen is open/backgrounded. Returning to the screen or revisiting a cached route can retain the old next-action CTA until the Driver attempts a now-invalid mutation.
- **Impact:** Stale operational instructions and growing per-order caches in long sessions.
- **Why existing protection is insufficient:** Backend state guards reject the stale write; root reconciliation corrects it only after mutation. SDK session refresh is not order refresh. Missing Realtime itself is not the defect.
- **Minimum recommended change:** Add scoped re-entry/resume/manual refresh for the current operation, and dispose unused detail families or bound their lifetime. Show refresh/stale state without polling.
- **Estimated scope / dependency:** Small provider/lifecycle/UI change. Keep session invalidation already present.
- **Targeted acceptance:** External cancellation followed by resume/re-entry/manual refresh removes the stale CTA; abandoned order providers are released.

### CR-015 — Offset pagination skips live offers after earlier rows disappear

**P2 · ROI-C · LOGIC DEFECT**  
Area: Waiting-offer pagination. Timing: **FIX BEFORE REALTIME**.  
Source: [supabase/migrations/202608300008_gate_2_remediation.sql](C:/projects/biko/supabase/migrations/202608300008_gate_2_remediation.sql:64) — `get_driver_active_offers / WaitingOffersList._loadMore`.

- **Evidence / current design:** RPC uses LIMIT 50 OFFSET; client offset is currently rendered/deduplicated count (screens:1251). The filtered ACTIVE/window-valid set changes between pages.
- **Scenario:** Load offers 1–50, then offer 1 expires or is withdrawn elsewhere. OFFSET 50 now starts at original offer 52, silently skipping still-valid offer 51.
- **Impact:** A valid waiting offer is unreachable in that pagination pass.
- **Why existing protection is insufficient:** ID deduplication only removes repeated rows; it cannot recover skipped rows. A deterministic ORDER BY alone does not stabilize offsets.
- **Minimum recommended change:** Use the existing (created_at,id) order as a keyset cursor, or restart a clearly bounded snapshot when membership changes. No speculative index or paging framework.
- **Estimated scope / dependency:** Small RPC/caller cursor contract + page-boundary test. Coordinate with CR-016.
- **Targeted acceptance:** Removing/inserting a preceding row between pages does not skip an unchanged valid offer.

### CR-016 — An old page response can repopulate a refreshed waiting list

**P2 · ROI-C · UX/STATE LOGIC ISSUE**  
Area: Pagination race. Timing: **FIX BEFORE REALTIME**.  
Source: [apps/driver_app/lib/features/driver/driver_screens.dart](C:/projects/biko/apps/driver_app/lib/features/driver/driver_screens.dart:1234) — `WaitingOffersList.didUpdateWidget / _loadMore`.

- **Evidence / current design:** didUpdateWidget clears _more but does not invalidate an in-flight request; _loadMore checks mounted only and appends against the new widget.offers.
- **Scenario:** Start Load More, then refresh first-page data after an offer is withdrawn. The old response completes later and appends its stale rows into the refreshed list.
- **Impact:** Closed/obsolete offers reappear, and hasMore/error state can describe the previous dataset.
- **Why existing protection is insufficient:** mounted prevents writes to a disposed widget, not writes to a newer dataset in the same widget. Deduplication does not reject stale nonduplicate rows.
- **Minimum recommended change:** Capture a small generation value per request and discard results when first-page identity/session changes; reset paging errors/state with that generation.
- **Estimated scope / dependency:** Small widget-state guard + delayed-page test. None; compatible with CR-015.
- **Targeted acceptance:** A delayed old page is ignored after a first-page refresh.

### CR-017 — Mutation reconciliation repeats account/order reads and unrelated tab invalidations

**P2 · ROI-A · PERFORMANCE/COST ISSUE**  
Area: Read amplification. Timing: **FIX BEFORE REALTIME**.  
Source: [apps/driver_app/lib/features/driver/driver_providers.dart](C:/projects/biko/apps/driver_app/lib/features/driver/driver_providers.dart:57) — `runDriverMutation / DriverService.loadDashboard / loadOffer`.

- **Evidence / current design:** An online submit refresh does 4 Dashboard reads + 2 loadOffer reads + 1 order RPC, after the mutation: 8 HTTP requests total before SDK retries. History and Earnings separately repeat account + terminal-order reads.
- **Scenario:** A single counter-offer or lifecycle operation is followed by several overlapping reads; optional feed failures also delay release of the global recovery boundary.
- **Impact:** CURRENT PROBLEM: unnecessary round trips, tail latency, and database/API usage; future Realtime invalidations would amplify this pattern.
- **Why existing protection is insufficient:** No N+1 per displayed row exists, and Dashboard children already run in parallel. Parallelism does not remove duplicate data or unnecessary calls.
- **Minimum recommended change:** Reuse the account/terminal data already loaded and reconcile only the affected order/offer plus availability/assignment summary. Derive Earnings from the same bounded terminal dataset. Consider one compact summary RPC only if it removes this measured fan-out.
- **Estimated scope / dependency:** Small-to-medium provider/read composition change. Coordinate with CR-012.
- **Targeted acceptance:** Count calls for online submit and History→Earnings; preserve authoritative recovery with fewer distinct reads.

### CR-018 — Application Auth subscriptions do not handle stream errors

**P2 · ROI-A · BUG**  
Area: Auth event handling. Timing: **FIX NOW BEFORE USER APP**.  
Source: [packages/app_core/lib/app_core.dart](C:/projects/biko/packages/app_core/lib/app_core.dart:124) — `AuthRouterRefresh; DriverApp.initState`.

- **Evidence / current design:** AuthRouterRefresh.listen and DriverApp's session listener have no onError. Installed GoTrue 2.27.2 emits addError for retryable token-refresh failures; its own SupabaseAuth listener explicitly handles that channel.
- **Scenario:** An automatic or explicit token refresh encounters a transport failure while application listeners are active.
- **Impact:** Unhandled zone errors occur outside the widget mutation catches; no intentional application recovery state is produced.
- **Why existing protection is insufficient:** Catching the Future from refreshSession does not consume error events delivered independently to every stream subscription. SDK's own onError protects its listener only.
- **Minimum recommended change:** Handle the Auth error channel in each application subscription, retaining the session on retryable network failure and exposing safe recovery. Keep invalid-session sign-out distinct.
- **Estimated scope / dependency:** Small listener guards + stream-error test. Coordinate with CR-013.
- **Targeted acceptance:** Emit a retryable Auth stream error; no uncaught zone error or false sign-out, then recover normally.

Other application listener: [Driver session subscription](C:/projects/biko/apps/driver_app/lib/main.dart:48). Installed emitter: [GoTrue refresh/error channel](C:/Users/N/AppData/Local/Pub/Cache/hosted/pub.dev/gotrue-2.27.2/lib/src/gotrue_client.dart:1590).

### CR-019 — Two screens round real fractional fares to whole pounds

**P2 · ROI-C · BUG**  
Area: Money presentation. Timing: **FIX NOW BEFORE USER APP**.  
Source: [apps/driver_app/lib/features/driver/driver_screens.dart](C:/projects/biko/apps/driver_app/lib/features/driver/driver_screens.dart:510) — `_CounterOfferSheetState.build / _ActiveOrderContentState.build`.

- **Evidence / current design:** Lines 510 and 786 use toStringAsFixed(0), while backend prices have 2 decimal places and shared PriceDisplay/formatAmount preserves them.
- **Scenario:** A 95.50 EGP proposal appears as 96 in the counter-offer sheet; the completed-trip description similarly rounds the agreed fare.
- **Impact:** Customers' proposals and completed agreed amounts are displayed inconsistently.
- **Why existing protection is insufficient:** Database numeric precision and the main price component remain correct; the duplicated formatter is the gap, not financial arithmetic.
- **Minimum recommended change:** Use existing formatAmount/PriceDisplay at these two callers. Do not add another formatter.
- **Estimated scope / dependency:** Two call sites + one fractional-price assertion. None.
- **Targeted acceptance:** 95.50 stays 95.50 in proposal, counter sheet, and completion summary.

Second call site: [completion description](C:/projects/biko/apps/driver_app/lib/features/driver/driver_screens.dart:786); reuse [formatAmount](C:/projects/biko/packages/app_core/lib/order_presentation.dart:137).

### CR-020 — Relational constraints permit incomplete or contradictory assignment bundles

**P2 · ROI-A · DATA-INTEGRITY RISK**  
Area: Assignment shape. Timing: **FIX BEFORE PUBLIC LAUNCH**.  
Source: [supabase/migrations/202608300002_core_bidding_engine.sql](C:/projects/biko/supabase/migrations/202608300002_core_bidding_engine.sql:24) — `orders / offers constraints; 008 composite FK`.

- **Evidence / current design:** Active states do not require driver_id, selected_offer_id, agreed_price or assigned_at. The composite FK verifies same order only; it does not tie assigned driver/price to the selected offer.
- **Scenario:** A trusted import/recovery write sets DRIVER_ASSIGNED with no Driver, or selects a same-order offer while storing a different Driver/price.
- **Impact:** Future trusted tooling can create operational states that the Flutter next-action mapping cannot safely interpret.
- **Why existing protection is insufficient:** Normal client DML is denied and current acceptance fills the bundle correctly. The unique active-driver index cannot constrain null Drivers or inconsistent same-order fields.
- **Minimum recommended change:** Add only state-shape CHECKs/FKs that encode current invariants, plus an explicit trusted assignment consistency check if needed. Preflight existing rows. Do not build a generic transition engine.
- **Estimated scope / dependency:** Focused constraints/trusted-write checks + negative tests. Inventory legacy rows and define legitimate recovery exceptions.
- **Targeted acceptance:** Trusted malformed assignment fails while normal acceptance/cancellation/history snapshots still pass.

### CR-021 — Most completed backend contracts have evidence but no retained runnable regression

**P2 · ROI-A · TESTABILITY GAP**  
Area: Backend regression assets. Timing: **FIX NOW BEFORE USER APP**.  
Source: [supabase/tests/gate_2_remediation.sql](C:/projects/biko/supabase/tests/gate_2_remediation.sql:1) — `Retained SQL test coverage`.

- **Evidence / current design:** The only SQL test file covers A/B/D/E/L remediation. The 6.1/7A delivery bounds, cancellation matrix, withdrawal ownership, customer offer privacy, and deadline tests exist as narrative evidence, not retained test code.
- **Scenario:** A later RPC replacement accidentally removes a prior eligibility/cancellation/privacy check; running the available remediation file does not exercise it.
- **Impact:** Expensive rediscovery and false confidence when effective functions are replaced across milestones.
- **Why existing protection is insufficient:** Historical hosted passes are valid for their original code, not executable regression protection for a changed function.
- **Minimum recommended change:** Retain a compact rollback-based contract test per changed trust boundary, including mixed-role and deadline negatives. Run affected cases, not a full gate every time.
- **Estimated scope / dependency:** Small focused SQL regression assets. Use known hosted contract; no new test infrastructure.
- **Targeted acceptance:** A deliberately wrong fixture/outcome fails the targeted assertion; all fixtures roll back.

### CR-022 — Fakes bypass the real service, router, and failure composition

**P2 · ROI-A · TESTABILITY GAP**  
Area: Flutter contract tests. Timing: **FIX NOW BEFORE USER APP**.  
Source: [apps/driver_app/test/gate_2_remediation_test.dart](C:/projects/biko/apps/driver_app/test/gate_2_remediation_test.dart:27) — `FakeDriverService / router / mount`.

- **Evidence / current design:** Fake loadOrder returns currentOrder regardless of ID; fake mutations directly change memory before throwing; the custom router bypasses createAuthRouter and DriverApp's Auth listeners. No HTTP projection/grant/error mapping is exercised.
- **Scenario:** A wrong RPC parameter, missing field, expired offer, partial Dashboard failure, Auth stream error, or session change can pass the current UI tests.
- **Impact:** Recovery/navigation behavior has useful unit evidence but lacks integration at the exact seams most likely to regress.
- **Why existing protection is insufficient:** Existing tests genuinely prove no blind replay and local CTA updates for their modeled conditions. They are not worthless; their boundary is narrower than the feature claim.
- **Minimum recommended change:** Keep the good tests; add a small mocked-HTTP service contract test and one configured root-router Auth/session test. Include commit-later and never-settling reads, not only commit-before-timeout.
- **Estimated scope / dependency:** Several focused existing-framework tests. CR-004/005/018 contracts.
- **Targeted acceptance:** Real serialization/parser/error mapper and actual Auth redirect/listener paths execute; no live Auth smoke needed for these unit contracts.

### CR-023 — Recovery loses the failing read context and operation correlation

**P2 · ROI-C · MAINTAINABILITY PROBLEM**  
Area: Diagnostics. Timing: **FIX BEFORE PUBLIC LAUNCH**.  
Source: [packages/app_core/lib/operation_recovery.dart](C:/projects/biko/packages/app_core/lib/operation_recovery.dart:132) — `MutationReconciler.retryRead; DriverService._friendly`.

- **Evidence / current design:** The read catch changes phase but never retains its failure/stack; error remains the earlier mutation error or null. The controller receives anonymous callbacks, and _friendly replaces backend errors with text-only BusinessFailure.
- **Scenario:** A successful mutation is followed by a failed offer read. Support sees only generic unavailable state, without which read/RPC failed or its safe error code.
- **Impact:** Hard-to-reproduce recovery incidents require guesswork; business-message wording is also being used as the client's contract.
- **Why existing protection is insufficient:** Database order_events capture committed transitions, not client read failures. SDK logging does not provide the missing application operation/order correlation by itself.
- **Minimum recommended change:** Retain a sanitized last-read error/code and operation name/order ID; add a lightweight diagnostic hook using existing logging. Preserve technical codes separately from safe Arabic messages. Do not log tokens, passwords, phone, or payloads.
- **Estimated scope / dependency:** Small structured error/context fields. Coordinate with CR-013/018.
- **Targeted acceptance:** One failed reconciliation can be identified without exposing sensitive data or replacing the original write outcome.

### CR-024 — Current-state claims remain mixed with obsolete milestone snapshots

**P2 · ROI-A · MAINTAINABILITY PROBLEM**  
Area: Authoritative documentation. Timing: **FIX NOW BEFORE USER APP**.  
Source: [docs/BUSINESS_RULES_FREEZE_V1.md](C:/projects/biko/docs/BUSINESS_RULES_FREEZE_V1.md:161) — `Implementation snapshot; Gate 2 report and issue register`.

- **Evidence / current design:** Freeze section 16 and issue-register Planned Gaps still call 90 seconds, parcel fields and other completed deltas pending. Older issue rows state removed implementation defects in present tense; appended remediation sections correct them.
- **Scenario:** An implementer reads the canonical freeze/current issue table without the later appendix and rebuilds completed 7A work or reintroduces a superseded contract.
- **Impact:** Wrong entry-gate decisions, duplicate migrations/work, and avoidable implementation drift.
- **Why existing protection is insufficient:** IMPLEMENTATION_PROGRESS's current header is accurate and historical evidence is explicitly preserved. Contradictory current-looking snapshots still remain.
- **Minimum recommended change:** After the authorized gate decision, perform the already-planned focused implementation-status sync. Label historical evidence clearly and keep one current status per issue without changing frozen business rules.
- **Estimated scope / dependency:** Documentation-only sync selected by PM. Existing SVG2-010 / final Gate 2 decision.
- **Targeted acceptance:** Current headers/tables agree; historical migration/test evidence remains intact.

### CR-025 — Customer offer RPC has no explicit bounded paging contract

**P2 · ROI-D · PERFORMANCE/COST ISSUE**  
Area: Customer offer list. Timing: **SAFE TO DEFER**.  
Source: [supabase/migrations/202608300006_user_flow_backend_delta.sql](C:/projects/biko/supabase/migrations/202608300006_user_flow_backend_delta.sql:445) — `get_customer_order_offers`.

- **Evidence / current design:** The joined list ends with ORDER BY only, without limit/cursor. An infrastructure row cap, if reached, has no continuation contract in the RPC.
- **Scenario:** A high-candidate order accumulates many eligible offers; the current function materializes/sends an unrestricted application list or is silently truncated by an API cap.
- **Impact:** FUTURE SCALE RISK: payload and sort work grow with offers; no present-volume performance failure is claimed.
- **Why existing protection is insufficient:** 90-second bidding and one active offer per Driver/Order bound time and duplicates, not the number of Drivers. Existing offer indexes cover the query prefix.
- **Minimum recommended change:** Define a modest explicit page limit and stable cursor when candidate volume warrants it; expose enough continuation information. Do not add an index without a measured plan.
- **Estimated scope / dependency:** Small read-contract change when volume requires. Measured candidate/offer volume.
- **Targeted acceptance:** A dataset above one page remains navigable with bounded payloads.

### CR-026 — Customer offer list includes an offline Driver that selection rejects

**P2 · ROI-C · LOGIC DEFECT**  
Area: Offer eligibility reads. Timing: **FIX NOW BEFORE USER APP**.  
Source: [supabase/migrations/202608300006_user_flow_backend_delta.sql](C:/projects/biko/supabase/migrations/202608300006_user_flow_backend_delta.sql:483) — `get_customer_order_offers vs accept_offer`.

- **Evidence / current design:** Listing checks ACTIVE Driver/profile/office but not is_online or candidate membership. Hosted probe returned one offer after its Driver successfully went offline; accept_offer requires is_online and current candidacy.
- **Scenario:** Driver submits an offer then goes offline while the window remains open. A fresh customer list still presents that offer as selectable.
- **Impact:** Avoidable deterministic selection failures even without a timing race.
- **Why existing protection is insufficient:** accept_offer safely refuses the assignment. The error is inconsistent presentation/eligibility, not unauthorized assignment.
- **Minimum recommended change:** Align the preselection filter with current selection eligibility or explicitly expose a nonselectable availability state. Do not silently alter the approved multiple-offer model.
- **Estimated scope / dependency:** Small read predicate + offline-offer test. Keep Driver availability semantics distinct from active-trip permission.
- **Targeted acceptance:** A fresh customer read does not advertise an already-ineligible Driver as selectable.

### CR-027 — Android release builds explicitly use debug signing

**P2 · ROI-A · SECURITY RISK**  
Area: Release signing. Timing: **FIX BEFORE PUBLIC LAUNCH**.  
Source: [apps/driver_app/android/app/build.gradle.kts](C:/projects/biko/apps/driver_app/android/app/build.gradle.kts:33) — `buildTypes.release in both apps`.

- **Evidence / current design:** Both release blocks set signingConfig = signingConfigs.getByName('debug').
- **Scenario:** The scaffold release configuration is used for a distributable build.
- **Impact:** It is not a production signing identity/update chain; publishing readiness can be mistaken for a successful release build.
- **Why existing protection is insufficient:** The TODO documents the shortcut but does not make a build fail safely when production signing is absent. No deployed production artifact is claimed.
- **Minimum recommended change:** Configure protected release signing in the release workflow and fail release publishing if it is missing. Keep debug signing for debug development.
- **Estimated scope / dependency:** Small configuration + secret-management setup. Owner-controlled signing credentials and distribution decision.
- **Targeted acceptance:** Inspect the release certificate fingerprint and confirm it is not the debug certificate.

Same configuration: [User release signing](C:/projects/biko/apps/user_app/android/app/build.gradle.kts:33).

### CR-028 — Extracted components still duplicate Driver-specific palette values

**P3 · ROI-D · CODE QUALITY IMPROVEMENT**  
Area: Shared presentation. Timing: **SAFE TO DEFER**.  
Source: [packages/app_core/lib/order_presentation.dart](C:/projects/biko/packages/app_core/lib/order_presentation.dart:32) — `PriceDisplay / RouteSummary / status colors`.

- **Evidence / current design:** Shared widgets hardcode the same blue/slate/semantic values as DriverColors, while User App seeds teal. Changing the app theme cannot change several shared presentation colors.
- **Scenario:** The next shared design adjustment updates Driver tokens or User theme but leaves embedded colors unchanged.
- **Impact:** MEDIUM-VALUE duplication: visible theme drift and multiple edit sites, not a current security or flow failure.
- **Why existing protection is insufficient:** Shared formatting/components already remove substantial duplication; no universal design-system package is needed.
- **Minimum recommended change:** Use Theme/ColorScheme for app accents and text; centralize only truly shared semantic colors when these components are next touched.
- **Estimated scope / dependency:** Small shared-widget cleanup. User/Driver accent decision.
- **Targeted acceptance:** Existing shared widgets follow the provided theme without changing status meaning.

### CR-029 — advanceOrder returns a partially populated DriverOrder that callers discard

**P3 · ROI-C · CODE QUALITY IMPROVEMENT**  
Area: RPC/model contract. Timing: **SAFE TO DEFER**.  
Source: [apps/driver_app/lib/features/driver/driver_service.dart](C:/projects/biko/apps/driver_app/lib/features/driver/driver_service.dart:175) — `advanceOrder / DriverOrder.fromJson`.

- **Evidence / current design:** Lifecycle RPC returns a raw orders composite without service_types/service_code/name. fromJson silently defaults serviceCode='' and serviceName='خدمة'. Current caller at screens:754–756 discards the returned object.
- **Scenario:** A later caller trusts the advertised DriverOrder return value and renders a generic service after mutation.
- **Impact:** A misleading extension point hides a projection mismatch and performs unnecessary parsing now.
- **Why existing protection is insufficient:** Current authoritative refresh retrieves service metadata, so no present main-screen service-label regression is claimed.
- **Minimum recommended change:** Return Future<void> for the currently discarded mutation result, or explicitly name a minimal mutation result when a real caller needs it. Avoid inventing duplicate domain models.
- **Estimated scope / dependency:** Small signature/caller cleanup. None.
- **Targeted acceptance:** Service contract tests distinguish raw mutation result from enriched order-read projection.

### CR-030 — The OTP text ban will reject approved trip verification and comments

**P3 · ROI-C · TESTABILITY GAP**  
Area: Foundation script. Timing: **FIX BEFORE PUBLIC LAUNCH**.  
Source: [scripts/check-foundation.ps1](C:/projects/biko/scripts/check-foundation.ps1:37) — `Select-String OTP scan`.

- **Evidence / current design:** The script scans all implementation/migration text for any word OTP and fails. Business Freeze explicitly distinguishes banned login SMS OTP from required later trip OTP.
- **Scenario:** A future safety migration or even an explanatory comment mentions Ride Start OTP; the foundation check fails although the code follows the product decision.
- **Impact:** BRITTLE TEST: discourages valid future implementation and confuses a structural check with behavior verification.
- **Why existing protection is insufficient:** It currently catches obvious forbidden login-OTP text, but cannot identify authentication behavior or distinguish trip verification.
- **Minimum recommended change:** Scope the check to forbidden login/SMS APIs/configuration or replace it with a focused Auth contract assertion. Keep the lightweight foundation check labeled structural only.
- **Estimated scope / dependency:** Small script/test adjustment before safety work. No trip OTP implementation in this review.
- **Targeted acceptance:** A trip-OTP/comment fixture is allowed while actual forbidden login/SMS wiring is rejected.

### CR-031 — One office-members index exactly duplicates a unique index

**P3 · ROI-D · PERFORMANCE/COST ISSUE**  
Area: Index maintenance. Timing: **SAFE TO DEFER**.  
Source: [supabase/migrations/202608290001_foundation.sql](C:/projects/biko/supabase/migrations/202608290001_foundation.sql:139) — `office_members_office_user_idx`.

- **Evidence / current design:** office_members UNIQUE(office_id,user_id) at line 63 already creates the same ordered B-tree key as the explicit index at line 139.
- **Scenario:** Every membership change maintains two equivalent indexes.
- **Impact:** CURRENT but small storage/write overhead; not a material hot-path incident at current volume.
- **Why existing protection is insufficient:** The unique constraint is required and must remain. Other status/expiry and composite-FK indexes serve distinct purposes and are not automatically redundant.
- **Minimum recommended change:** If doing an index-maintenance wave, verify catalog equivalence and remove only the duplicate explicit index in a new migration. Do not edit foundation history.
- **Estimated scope / dependency:** One catalog check + focused index migration. None; no new index recommended.
- **Targeted acceptance:** Unique membership enforcement and representative reads remain unchanged.

### CR-032 — Manual refresh and sign-out callbacks allow Future errors to escape

**P3 · ROI-C · CODE QUALITY IMPROVEMENT**  
Area: Async UI boundaries. Timing: **SAFE TO DEFER**.  
Source: [apps/driver_app/lib/features/driver/driver_screens.dart](C:/projects/biko/apps/driver_app/lib/features/driver/driver_screens.dart:43) — `Home/Waiting/History refresh; Profile sign-out; shared Home sign-out`.

- **Evidence / current design:** Refresh callbacks await provider futures without catch (43, 536, 952); sign-out callbacks return an unhandled Future (1180, app_core:407). Installed GoTrue removes the local session first, then remote revocation may throw.
- **Scenario:** A manual refresh or remote logout revocation fails on a network boundary.
- **Impact:** Uncaught async diagnostics and no explicit completion/error handling. This is not a claim that failed remote revocation keeps the local user signed in.
- **Why existing protection is insufficient:** Providers retain read errors and SDK performs local logout first. Mutations already use shared reconciliation, so the old catch/snackbar-only mutation pattern is not present.
- **Minimum recommended change:** Consume these UI Future failures with safe state/diagnostic handling; retain existing provider error rendering and local logout behavior. Add busy guards only where repeated actions cause duplicate reads.
- **Estimated scope / dependency:** Small callback-boundary cleanup. Reuse CR-013/023 behavior.
- **Targeted acceptance:** Refresh/logout transport failures produce no uncaught zone errors or raw backend UI text.

Review stop condition: documentation delivered; no remediation authorized or implemented. **Next: WAIT FOR PROJECT MANAGER TO SELECT REMEDIATION WAVE.**

## Wave B Remediation Evidence — 2026-08-30

Wave B continued from the existing worktree and applied the already-created local migration `202608300010_wave_b_recovery_auth_contracts.sql` to Development as hosted migration `20260830135840_wave_b_recovery_auth_contracts`. Its focused rollback verification had already passed and was not rerun.

- **CR-004 RESOLVED:** `create_order` accepts one caller-stable UUID intent, enforces `(customer_id, creation_intent_id)` uniqueness, returns the same order only when the normalized payload hash matches, rejects changed payload, and permits intentionally identical bookings under a new intent. The retained hosted rollback test covers Ride, Delivery, cross-customer isolation, terminal recovery, event uniqueness, and direct uniqueness enforcement.
- **CR-005 RESOLVED:** PostgREST requests use an eight-second timeout with automatic transport retries disabled. Sensitive mutation waits and recovery reads have independent finite budgets. Timeout remains `UNCERTAIN`, never proves rollback, and never automatically replays the mutation. An unchanged read cannot unlock an uncertain write; exhausted reads expose retry, Profile, navigation, and safe sign-out instead of a permanent full-app barrier.
- **CR-006 IMPLEMENTED — HOSTED REDIRECT CONFIRMATION PENDING:** shared Auth now handles the trusted Supabase `passwordRecovery` event, validates the recovery session, collects and confirms a minimum-six-character password, prevents duplicate submission, calls `updateUser`, and presents safe Arabic invalid-session/success states. Both apps declare distinct Android/iOS callback schemes and local Supabase configuration lists both exact redirects. The available connected Supabase tools cannot inspect or edit Authentication URL Configuration, so no hosted end-to-end redirect acceptance is claimed.
- **CR-011 RESOLVED:** one owned-offer RPC returns compact offer plus order status, server-adjusted bidding expiry, assignment truth, and route/service summary without customer identity/private fields. Flutter checks cover valid waiting, expired, cancelled, selected active assignment, and withdrawn terminal states; stale withdrawal/action UI is removed.
- **CR-012 RESOLVED:** startup awaits only Driver account and active assigned order. Available requests and waiting offers are independent optional sections. Profile reads only Driver account/session data, and sign-out remains available when optional feeds fail.
- **CR-013 RESOLVED:** reads use typed unavailable, forbidden, auth, connection, and unknown safe outcomes. Known absence is the only read error treated as absence during reconciliation; UI now renders the supplied safe message instead of flattening all failures to no Internet.
- **CR-018 RESOLVED:** one shared Auth subscription owns data and error channels. Retryable Auth transport failure preserves a valid session and exposes a safe retry state; definitive invalid-session errors invalidate routing state. No raw SDK/backend text is rendered.

Verification: 13 focused `app_core` recovery/Auth tests and 14 focused Driver recovery/state tests passed. `flutter analyze` passed for `packages/app_core`, `apps/driver_app`, and `apps/user_app`; only App Core's failed style-only first pass was rerun after its six exact brace fixes. Both Android manifests and both iOS plists parse as XML. A final hosted cleanup audit returned zero reserved Wave B Auth users, profiles, Drivers, orders, offers, Delivery details, and order events. No new dependency, OTP, User App Core flow, Maps/Realtime work, or new P0/P1 was introduced.

At the Wave B checkpoint, CR-008 remained **OPEN — EVIDENCE CAPABILITY GAP** because no secure concurrent path had yet been used. Final Evidence Closure later resolved it through the hosted publishable application path. CR-007 remains open before Public Launch: neither main Android manifest currently declares `android.permission.INTERNET`.

## Wave C Remediation

Wave C applied local migration `202608300011_wave_c_read_correctness.sql` to Development as hosted migration `20260830143750_wave_c_read_correctness` and changed only CR-010, CR-019, and CR-026.

- **CR-010 RESOLVED:** the existing locked lifecycle boundary increments `drivers.completed_trip_count` inside the successful `IN_PROGRESS → COMPLETED` transaction. Its expected-state guard rejects repeat/stale completion before the increment. A one-time set-based migration reconciliation sets stored counts to actual completed-order counts; hosted preflight required zero corrective rows.
- **CR-019 RESOLVED:** both direct whole-pound fare strings now call the existing `formatAmount`. One focused widget test proves `105.50` is retained in the counter-offer sheet and completed-trip summary; no new formatter was introduced.
- **CR-026 RESOLVED:** `get_customer_order_offers` retains its compact eight-field projection and customer ownership boundary while filtering for current candidate membership, online/ACTIVE Driver, ACTIVE Driver profile and office, and absence of another active assignment. Filtering never mutates an ACTIVE offer. `accept_offer` remains the authoritative write-time recheck.

The retained hosted rollback test passed exact first/second completion counts, repeat completion denial, cancellation/expiry exclusion, visible/offline/reappearing offers, offline acceptance denial, candidate/Driver/profile/office filters, active-job filtering, Customer B isolation, projection privacy, and changed-function grants/search paths. The first run stopped at a test-only constraint violation because a SUSPENDED Driver fixture was still online; correcting that fixture produced the passing run. Final cleanup found zero Wave C identities or operational records and zero completed-count mismatches.

Driver App's focused CR-019 widget test passed, followed by one clean Driver App `flutter analyze`. App Core was unchanged. No index, dependency, extra RPC, paid service, polling, Maps, Realtime, User App Core work, or new P0/P1 was added.

At the Wave C checkpoint, CR-008 remained an evidence capability gap and CR-024 awaited Evidence Closure. The final section below supersedes that checkpoint.

## Final Evidence Closure

- **Wave A COMPLETE:** hosted `20260830133522_wave_a_security_transaction_integrity`; CR-001/002/003/009 and targeted assignment integrity passed.
- **Wave B COMPLETE WITH EXTERNAL AUTH CONFIGURATION PENDING:** hosted `20260830135840_wave_b_recovery_auth_contracts`; CR-004/005/011/012/013/018 resolved. CR-006 application flow is implemented, but hosted redirect allowlist confirmation remains manual.
- **Wave C COMPLETE:** hosted `20260830143750_wave_c_read_correctness`; CR-010/019/026 resolved with targeted hosted/Flutter evidence.
- **CR-008 RESOLVED:** two independent authenticated HTTPS clients used the hosted publishable application path. B ran `14:46:29.735678–14:46:30.817925 UTC`; A ran `14:46:29.736612–14:46:30.818234 UTC`, proving actual overlap. A returned HTTP 200; B returned HTTP 400 / `P0001`, `Driver already has an active assignment`.
- Final database truth: one active Driver job, one assigned order, one complete assignment bundle, one SELECTED offer, one CLOSED competing offer, one untouched BIDDING losing order, and one assignment event. No deadlock occurred.
- Cleanup returned zero reserved Auth users, profiles, Drivers, orders, offers, candidates, Delivery details, or order events.
- **CR-024 RESOLVED:** current-status sections now distinguish historical findings from implementation reality. Email + Password remains the login contract; Ride/Delivery OTPs remain future operational trip verification.
- CR-021/022 remain partially open for broader retained regression/integration evidence. They were not falsely resolved by targeted Waves.
- Remaining timing: CR-014 before Maps; CR-015/016/017 before Realtime; CR-007, remaining CR-020 recovery/legacy review, CR-023/027/030 before Public Launch; CR-025/028/029/031/032 safe to defer.
- New P0/P1: none.

Current decision: **System Validation Gate 2 = PASS WITH ISSUES**. Milestone 7A remains complete. **User App Core = UNBLOCKED**. Next: **Milestone 7 — User App Core**.
