# Milestone 9 — Realtime + Push Notifications

Status: **COMPLETE WITH EXTERNAL CONFIGURATION PENDING**  
Date: 2026-08-30  
Target: hosted Development (`biko-development`), User App, Driver App, App Core

## Delivered contract

- Hosted migration: `20260830174205_realtime_push_notifications` from local `202608300014_realtime_push_notifications.sql`.
- Stable waiting-offer paging: descending `(created_at,id)` keyset, bounded to 50, without mutable-set OFFSET.
- Stale-page protection: one generation value invalidates old results after first-page/session/assignment refresh and resets page UI state.
- Narrow Driver refreshes: Availability refreshes account/request discovery; Offer refreshes active/owned-offer state; Lifecycle refreshes active/affected order; Terminal refreshes active/order/history and lets Earnings derive from the same bounded History dataset.
- Realtime: one session-scoped app channel. User receives only own outbox rows. Driver receives own outbox rows and RLS-filtered work signals. A work signal invokes one authoritative PostGIS request refresh and is never rendered as a request row.
- Recovery: initial subscribe, reconnect, and foreground resume perform one scoped authoritative refresh. Manual refresh remains available.
- Push tokens: `auth.uid()` ownership, multiple devices, rotation/upsert, owner-only revoke, no client table reads/writes, anon denial, bounded best-effort cleanup on sign-out.
- Durable Push: business triggers write notification intent only. FCM is outside the order transaction and failures remain retryable/observable without rolling back business truth.
- Routing: stable UUID/event/target validation, Auth resolution, authoritative owned/geographic fetch, safe Home fallback, and separate state/route dedupe sets.

## Event matrix

| Audience | Event | Authoritative reaction |
|---|---|---|
| Customer | New offer | Refresh active order, then existing privacy-safe offer RPC |
| Customer | Driver assigned/on-way/arrived/in-progress | Refresh owned active order |
| Customer | Completed/cancelled/expired | Refresh active state and invalidate bounded history |
| Driver | Potential new work | One `get_driver_requests` geographic refresh |
| Driver | Offer selected/closed | Refresh active order, owned offer, and waiting list |
| Driver | Active order changed | Refresh active order and affected order only |
| Driver | Completed/cancelled/expired | Refresh active order/affected order and bounded history |

Realtime and FCM carry the same outbox ID. Duplicate or out-of-order delivery cannot regress business state because the client renders only the subsequent authoritative read. Foreground OS-style presentation is suppressed on the already-relevant Home/order screen; elsewhere a restrained local notification is allowed.

## Security evidence

- `register_push_token` and `revoke_push_token` derive identity from `auth.uid()` and have no trusted `user_id` input.
- Anon has no execution; clients cannot execute enqueue/claim/complete/disable functions or directly mutate token/outbox/work-signal tables.
- `notification_outbox` select is limited to the targeted authenticated user. Eligible-driver broadcast intent is not client-readable; the RLS work signal uses an auth-derived SECURITY DEFINER predicate.
- Dispatcher functions are service-role-only. All Milestone 9 SECURITY DEFINER functions use `search_path=''`.
- `order_events` remains append-only and direct client insert/update/delete stays denied.
- FCM service-account JSON is read only from hosted Edge secrets and is not committed or returned to clients.

## Verification

- Hosted rollback harness: PASS on the corrected run and two explicit reruns; the final expanded proof includes actual cross-user outbox and Customer/eligible-Driver work-signal RLS visibility. Coverage also includes token ownership/upsert/revoke/multi-device behavior, anon/direct-write denial, outbox stable identity, invalid-token disablement, Push failure isolation, shared Realtime/Push work identity, append-only events, and 60-row keyset paging across mutable membership.
- Hosted cleanup: zero reserved Auth users, profiles, orders, outbox intents, and Push tokens; both intended Realtime tables are published.
- App Core: 11 tests PASS, including parser/target validation, bounded identity dedupe, session-generation cleanup, and the affected Auth/recovery seam.
- User App: 2 focused event-resource tests PASS.
- Driver App: 23 affected event/pagination/recovery tests PASS; corrected delayed-page seam separately PASS 5/5 with a real visible tap/loading assertion.
- Flutter analysis: App Core, User App, Driver App — no issues.
- Focused performance/cost review: no polling, no location fanout, no history/profile/earnings subscriptions, bounded pages/channels/claims/fanout, no FCM call in a database transaction, and no account read per operational event.

## External configuration pending

- Create/configure the two Firebase mobile apps and supply `FIREBASE_PROJECT_ID`, `FIREBASE_API_KEY`, `FIREBASE_APP_ID`, `FIREBASE_MESSAGING_SENDER_ID`, and the iOS bundle ID through Dart defines.
- Upload/configure the APNs authentication key in Firebase for iOS.
- Set hosted Edge secret `FIREBASE_SERVICE_ACCOUNT_JSON`.
- Deploy `supabase/functions/push-dispatch` and configure a trusted service-role scheduled invocation. The available connected Supabase path exposed database migration/SQL tools but no Edge deployment or secret-management call, so this was not bypassed with CLI or direct HTTP.
- Run physical-device foreground/background/terminated delivery and token-rotation acceptance. Until then, live Push delivery is not claimed.

Milestone 8 external Maps/Pricing configuration remains unchanged and was not retested.
