# Customer App — Architectural Audit

**Audit date:** 2026-04-17
**Scope:** `lib/main_customer.dart`, `lib/core/routes/customer_pages.dart`, and customer-scoped feature folders (auth, bidding, chat, dropoff, history, home, notifications, onboarding, pickup, profile, promo, referral, settings, splash, tracking, trip, wallet).

---

## 1. Executive Summary

**Phase: Beta (~75–80% production-ready).**

The customer app is the most mature of the three apps. The end-to-end ride flow (pickup → dropoff → bidding → tracking → rating) is functional and cleanly separated into feature modules with GetX bindings, lazy-put controllers, and Firestore/RTDB dual-source updates. Firebase write discipline is correct — no direct writes to `wallets/` or `transactions/`. Localization and theming are solid. The blockers to production are UX gaps (no error-recovery retries, silent trip cancellations, no SOS), not architectural ones.

**Top 5 issues:**
1. **Silent trip cancellation** — `BidsController.onClose` cancels the trip search with no confirmation or feedback. Backing out of `BidsScreen` silently kills the trip.
2. **Settings has no dedicated controller** — `SettingsBinding` re-uses `ProfileController`, conflating profile data with user preferences.
3. **No error-recovery UI** — tracking/bids/wallet/chat screens show an error but offer no retry button. User must re-enter the flow.
4. **Brittle enum parsing** — `TrackingStatus.fromJson` throws on unknown statuses; any server-side status change would crash the tracking screen.
5. **No network-state monitoring / offline strategy** — chat, wallet, history, and trip tracking all assume connectivity. No banner, no queueing.

---

## 2. Implemented Features

| Feature | Status | Completeness | Key files |
|---|---|---|---|
| Phone OTP + Google/Facebook auth | Complete | 95% | `features/auth/controllers/auth_controller.dart` |
| Booking flow (pickup → dropoff → bid → track → rate) | Complete | 90% | `features/bidding/`, `features/tracking/`, `features/pickup/`, `features/dropoff/` |
| Live bidding | Complete | 85% | `features/bidding/controllers/bids_controller.dart` — RTDB stream |
| Live tracking | Complete | 90% | `features/tracking/controllers/tracking_controller.dart` — dual Firestore + RTDB streams |
| In-trip chat | Complete | 80% | `features/chat/controllers/chat_controller.dart` |
| Wallet (read-only + top-up) | Complete | 88% | `features/wallet/controllers/wallet_controller.dart` |
| Trip history (paginated) | Complete | 85% | `features/history/` |
| Ratings (stars, tip, preset chips) | Complete | 90% | `features/trip/` |
| Profile (avatar, name, language, theme) | Complete | 92% | `features/profile/` |
| Notifications (FCM + in-app list) | Complete | 75% | `features/notifications/` |
| Promo codes (Cloud Function validated) | Complete | 80% | `features/promo/` |
| Referral (code + share) | Complete | 85% | `features/referral/` |
| Settings (language / theme toggle) | Partial | 60% | No dedicated controller — reuses `ProfileController` |
| Home dashboard (nearby drivers, recents, balance) | Complete | 88% | `features/home/` |

---

## 3. Screens & Flows

### Auth flow
```
PhoneLoginScreen  → AuthController.sendOtp
OtpVerificationScreen  → AuthController.verifyOtp
ProfileSetupScreen  → ProfileSetupController
CustomerHomeScreen
```
Clean, with explicit AuthState enum (`idle / sendingOtp / error / authenticated`) and OTP timeout. Dev bypass guarded by `kDebugMode && DevConfig.skipOtp` at `auth_controller.dart:64`.

### Full booking flow
```
CustomerHomeScreen → navigateToRideBooking()
  → SetPickupScreen          (pickup_controller.selectPlace)
  → SetDropoffScreen         (dropoff_controller.selectPlace)
  → PriceNegotiationScreen   (bidding_controller.submitTrip)
  → BidsScreen               (bids_controller.acceptBid)
  → TrackingScreen           (tracking_controller.listenToTrip)
  → TripCompletedScreen      (trip_completion_controller.submitRating)
  → HomeScreen (AppSnackbar.success)
```
Recent-location taps shortcut the flow by pre-filling `intended_dropoff` via route arguments (`home_controller.dart:258`).

### Tracking flow
Firestore listener (`listenToActiveTrip`) drives status transitions; RTDB listener (`listenToDriverLocation`) drives the marker. Both subscriptions cleaned up in `onClose` (`tracking_controller.dart:90–95`). Loading fallback timer at `:97–105` — but see Bug #1 in §10.

---

## 4. Controller Logic Maturity

### Production-grade
- **AuthController** — explicit enum state, proper `Timer` disposal in `onClose` (`:38–41`), timeout at `:138`, debug-only bypass.
- **BiddingController** — idempotency guard (`:221`, `isSubmitting` check), parallel pricing + directions with retry fallback (`:94–150`), same-location validation (`:232–235`), min/max offer clamping.
- **HomeController** — parallel init with `Future.wait`, cached-location fallback (`:99–160`), stream cleanup (`:54–58`).
- **WalletController** — opaque pagination cursor that the client never inspects (`:32`), pull-to-refresh, dual-stream (balance + paginated transactions).

### Acceptable, needs hardening
- **TrackingController** — dual streams cleaned up, but `TrackingStatus.fromJson(status)` at `:200` is a string-to-enum conversion with no fallback.
- **ChatController** — `TextEditingController` disposed (`:43`), but raw-map reconstruction at `:51–60` has no validation; silently defaults missing fields.
- **NotificationsController** — optimistic update with rollback (`:56–73`) — good pattern.

### Weak / broken
- **SettingsBinding** registers `ProfileController` only (`settings/bindings/settings_binding.dart:8`). No dedicated `SettingsController` exists.
- **PickupController** — debounce timer OK (`:62`), but uses an integer counter for geocode request IDs (`:65`) — race-prone if requests resolve out-of-order.

---

## 5. Firebase Integration Status

### Firestore collections used
- `users/{uid}` — `getUser`, `listenToUser`, `updateUser`
- `trips/{tripId}` — `listenToActiveTrip`, `createTrip`, `getTripSummary`
- `wallets/{uid}` — `listenToWallet`, `getTransactionsPaginated` (read-only ✓)
- `notifications/{uid}/items` — stream + mark-as-read
- `chats/{tripId}/messages`
- `promo_codes` — read, plus Cloud Function for validation
- `referrals/{uid}`
- `app_config` — pricing + bid limits (read-only)
- `trip_history`

### Realtime DB paths
- `/drivers/{driverId}/location` — position, heading, ETA
- `/trips/{tripId}/bids` — sub-second live bids

### Cloud Functions called
- `validatePromoCode(code, uid)` (`PromoController.applyPromoCode`)
- Implied server hooks for trip accept / rating / tip.

### Write-discipline compliance ✓
All writes route through `FirestoreService` (`lib/core/services/firestore_service.dart`). **No direct `.set() / .update() / .delete()` calls in any customer feature controller.** No writes to `wallets/` or `transactions/`.

---

## 6. Shared Widget & Theme Compliance

Customer features use `AppSnackbar`, `AppLoading`, `AppDialog`, `AppMenuItem`, `AppMapWidget`, `AppColorsExtension`. `main_customer.dart:49–57` wraps the app in a `Directionality` widget keyed off `Get.locale`, so RTL works without per-screen effort. No hardcoded `Colors.*` in customer feature code. The hex-value drift lives in `lib/features/admin/utils/admin_status_colors.dart` — not customer.

---

## 7. Localization & RTL Readiness

`lib/core/translations/app_translations.dart` (3,941 lines, ~800+ keys). Strong coverage for `common.*`, `auth.*`, `error.*`, `validation.*`, onboarding, tracking, trip, wallet, promo, referral, notifications. **Sparse coverage:**
- `settings.*` — language/theme picker labels — partial
- `chat.load_error` only — no send error key
- `bids.*` — exists but inconsistent across screens
- `history.load_error` only — no filter/empty states

RTL: `EdgeInsetsDirectional` used throughout; locale picker toggles `Locale('ar')` / `Locale('en')`. `language_selector.dart` in `profile/widgets/` should be spot-checked for directional Row layouts.

---

## 8. Rule Violations (concrete)

| # | File | Line(s) | Rule / Issue |
|---|------|---------|----|
| 1 | `features/bidding/controllers/bids_controller.dart` | 71–75 | Silent trip cancellation on `onClose` — no confirmation dialog, no UX feedback. |
| 2 | `features/settings/bindings/settings_binding.dart` | 8 | Reuses `ProfileController` — no dedicated `SettingsController`. |
| 3 | `features/tracking/controllers/tracking_controller.dart` | 200 | `TrackingStatus.fromJson(status)` with no fallback — will throw on unknown status. |
| 4 | `features/chat/controllers/chat_controller.dart` | 51–60 | `ChatMessageModel.fromMap` silently defaults missing fields; no schema validation. |
| 5 | `features/wallet/controllers/wallet_controller.dart` | 32, 94–106 | Opaque `Object?` cursor — no type safety; stale cursor reuse is undefined. |
| 6 | `features/referral/controllers/referral_controller.dart` | 45 | Magic string `'---'` for the unavailable-code sentinel. |
| 7 | `features/home/controllers/home_controller.dart` | 271 | "Coming soon" snackbar on merchant card — transient; better to disable the card. |
| 8 | `features/pickup/controllers/pickup_controller.dart` | 65 | Integer counter for geocode request IDs — race-prone. |

---

## 9. Missing Features (NOT IMPLEMENTED)

1. **Scheduled / later booking** — no future-time trip UI.
2. **Saved delivery addresses** — no home/work/custom address book.
3. **Ride sharing / multi-stop** — passenger count stored but unused; only pickup → single dropoff.
4. **Counter-offers** — customer can only accept driver bids; no counter-bid UI.
5. **Trip history filters** — no date-range or status filter; paginated list only.
6. **Payment method management** — top-up exists but no add/remove/switch-card UI.
7. **Offline message queue** — chat messages typed offline are lost.
8. **SOS / emergency contact** — no panic button, no pre-assigned contacts. **Regulatory concern for Egypt ride-hailing.**
9. **Promotion carousel on home** — `home.coming_soon` snackbar only.
10. **Favorite drivers** — not present.
11. **Trip sharing link** — no "share ETA with family" feature.
12. **Dedicated SettingsController** — see Violation #2.

---

## 10. Bugs & Architectural Issues

### High
1. **Tracking loading-timeout race** (`tracking_controller.dart:97–105`): if Firestore data arrives exactly as the 15-second timer fires, both code paths set `isLoading.value = false` and the user sees an error despite data having arrived. Fix: cancel timer immediately on first data emission.
2. **BiddingController nullable directions** (`bidding_controller.dart:120`): `_calculateSuggestedPrice(directions)` reads `distanceKm` without a null check; if the directions API returns a degenerate response it crashes.
3. **HomeController stale balance on locale change** (`home_controller.dart:85–97`): wallet subscription is recreated, but `walletBalance.value` is never reset — brief stale display during locale switch.

### Medium
4. **PickupController geocode race** (`pickup_controller.dart:62–65`): integer counter can be inverted by out-of-order completions.
5. **ChatController empty tripId** (`chat_controller.dart:29–31`): no guard for empty `tripId` / `uid`; listener attaches to a bogus path and the screen shows empty forever.

### Low
6. **No network-state monitoring** anywhere — no `NetworkService`, no banner.
7. **"Coming soon" snackbar** is a transient UX pattern (disable the UI instead).

---

## 11. Current Phase & Next Steps

**Phase: Beta (75–80% production-ready).**

Ordered action items:

1. **[P0, 2h]** Create `lib/features/settings/controllers/settings_controller.dart` — extract language/theme/notification prefs from `ProfileController`. Update `settings_binding.dart`.
2. **[P0, 4h]** Add retry buttons + explicit error states to `TrackingScreen`, `BidsScreen`, `WalletScreen`, `ChatScreen`. Introduce `isError` + `errorMessage` reactive fields, wire a `retry()` controller method.
3. **[P0, 2h]** Trip cancellation UX: confirmation dialog before `BidsController.onClose` cancels; post-cancel snackbar with "Rebook" action.
4. **[P0, 6h]** SOS / emergency contact feature — create `lib/features/emergency/`, store 2–3 contacts on `UserModel`, add a red panic button to `TrackingScreen`.
5. **[P1, 1h]** Safe enum parsing — add `TrackingStatus.tryParse` with a fallback value in `lib/core/models/enums.dart`.
6. **[P1, 4h]** `NetworkService` in `lib/core/services/`, offline banner in app shell, chat message queue on reconnect.
7. **[P1, 3h]** Promotion carousel on home: query active promos from Firestore, new `promo_carousel.dart` widget.
8. **[P2, 3h]** Type-safe pagination cursor — `sealed class PaginationCursor`; update `WalletController` + `TripHistoryController`.
9. **[P2, 3h]** Trip-history filters (date range, status) — extend `getTripHistoryPaginated`.
10. **[Cleanup, 0.5h]** Remove `DevConfig.skipOtp` bypass once production auth is live (`auth_controller.dart:64–71`).

---

## Metrics

| Metric | Value | Notes |
|---|---|---|
| Features implemented | 14 / 24 | 58% — excludes SOS, promo carousel, delivery types, scheduling |
| Controllers with proper stream cleanup | 20/20 observed | ✓ |
| Dedicated controller per screen | 12/13 | Missing for Settings |
| AR localization coverage | ~70% | Gaps in promo, chat, history |
| Firestore collections integrated | 9/9 | ✓ |
| RTL / Directionality | Yes | ✓ |
| Error states with retry UI | ~3/8 screens | Gap |
| Direct `wallets/transactions/` writes | 0 | ✓ |

**Recommendation:** Ship with SOS as a launch gate (regulatory). Settings refactor, error retries, and cancellation UX are the next sprint. Schedule counter-offers, multi-stop, and favorites for Phase 2.
