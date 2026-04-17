# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

> **Audit date:** 2026-04-17. This document reflects the REAL current state of the codebase, not theoretical intent. See `customer_app_analysis.md`, `driver_app_analysis.md`, `admin_panel_analysis.md` for per-app deep dives.

---

## Project Overview

BikeRide (package name: `biko`) is an inDrive-style bike ride and delivery platform for Egypt with price-bidding. Three apps share one codebase: Customer, Driver, and Admin Web Panel. Server-side logic is intended to live in Firebase Cloud Functions — those functions are **called** from the client (`cloud_functions` SDK) but are NOT in this repo (no `functions/` directory here).

**Current architectural maturity: C+ / Beta.** Feature-complete for a pilot; not hardened for scale. Zero automated tests (no `test/` directory). No Firestore/RTDB security rules in the repo. Several admin write paths violate the "Cloud Functions only" rule.

---

## Build & Run Commands

```bash
# Run each app (separate entry points)
flutter run -t lib/main_customer.dart          # Customer app
flutter run -t lib/main_driver.dart            # Driver app
flutter run -d chrome -t lib/main_admin.dart   # Admin web panel

# Default entry point (main.dart) currently launches Admin app
flutter run

# Build admin panel for cPanel deployment — base-href MUST be set
flutter build web --release --base-href /admin/

# Analyze & lint
flutter analyze          # As of 2026-04-17: 1 warning (missing assets/images/markers/)

# Run all tests — currently no test/ directory exists
flutter test

# Get dependencies
flutter pub get

# Deploy Firestore indexes after adding new queries
firebase deploy --only firestore:indexes
```

**SDK**: Dart ^3.9.2, Flutter, Material 3.

---

## Architecture

### Multi-App Entry Points

Each app has its own entry point, page registry, and initial route:
- `lib/main_customer.dart` → `CustomerPages.pages` → starts at `/splash` (27 routes)
- `lib/main_driver.dart` → `DriverPages.pages` → starts at `/splash` (23 routes)
- `lib/main_admin.dart` → `AdminPages.pages` → starts at `/admin/login` (30 routes)

Shared: `AppInitializer.init()` → Flutter bindings → Firebase init (graceful offline fallback) → local notifications + FCM channels → theme restoration from SharedPreferences → global controllers (`AuthController`, `LocationService`, `BackgroundLocationService` for driver only) → `runApp()`.

### State Management: GetX Only

- GetX is used consistently across all features. No Provider/Bloc/Riverpod present.
- Feature controllers use `Get.lazyPut()` inside bindings. Only `AuthController`, `LocationService`, and the driver's `BackgroundLocationService` are permanent globals.
- Reactive state: `.obs` + `Obx()`. `GetBuilder` is effectively unused.
- Navigation via `Get.toNamed()` / `Get.offAllNamed()` with constants from `lib/core/routes/app_routes.dart` (74 total route constants).

### Feature-First Folder Structure

```
lib/core/          — Shared: theme, routes, services, widgets, models, translations, constants
lib/features/      — 28 feature folders, each with screens/, controllers/, bindings/, widgets/
```

Customer-scoped features: auth, bidding, chat, dropoff, history, home, notifications, onboarding, pickup, profile, promo, referral, settings, splash, tracking, trip, wallet.
Driver-scoped features: driver_home, driver_trips, driver_wallet, driver_earnings, driver_profile, driver_ratings, driver_registration, driver_chat, driver_settings (reuses bidding, tracking, auth).
Admin: single `features/admin/` folder with 30 screens, 22 bindings, 10 admin-specific services.

### Route Registration Pattern

- `lib/core/routes/app_routes.dart` — route name constants only
- `lib/core/routes/customer_pages.dart`, `driver_pages.dart`, `admin_pages.dart` — GetPage lists
- Admin pages use `AdminAuthGuard` middleware (verifies `role` custom claim via `AuthService.getIdTokenResult()`) and wrap content in `AdminLayoutShell` (responsive: mobile <768px, tablet 768–1200px, desktop >1200px). Login and 404 are the only admin routes not wrapped.

### Theme System

- `AppTheme.lightTheme` / `AppTheme.darkTheme` — Material 3, primary `#E0062E`.
- `AppColorsExtension` — 13 semantic tokens: `surfaceElevated`, `surfaceContainer`, `border`, `borderSubtle`, `textMuted`, `info`/`infoBg`/`infoBorder`, `success`/`successBg`, `warning`/`warningBg`, `accent`.
- Fonts: Plus Jakarta Sans (English) / Cairo (Arabic) via `AppTheme.getThemeWithLocale(locale)`.
- Theme restored from SharedPreferences in `AppInitializer`.

### Localization

- Translations are inline in `lib/core/translations/app_translations.dart` — **3,941 lines, ~800+ keys**, strong AR/EN parity.
- Customer/Driver default to Arabic (RTL); Admin defaults to English.
- Known gaps: `settings.*`, chat send-error keys, and feature-specific admin labels have sparse AR coverage.

### Shared Widgets (all present in `lib/core/widgets/`)

`AppButton`, `AppTextField`, `AppCard`, `AppLoading`, `AppSnackbar`, `AppMapWidget`, `AppErrorWidget`, `AppEmptyState`, `AppDialog`, `AppBottomSheet`, `AppMenuItem`, `LanguageSelector`. The design system is complete; the main compliance gap is scattered hardcoded hex values inside `lib/features/admin/utils/admin_status_colors.dart`.

---

## Firebase Data Architecture (Real Usage)

### Firestore — source of truth
Collections actually read/written by the client:
- `users/{uid}` — customer/driver/admin profiles
- `trips/{tripId}` — trip lifecycle, bids subcollection
- `wallets/{uid}` — read-only from client; **customer + driver correctly do not write here**
- `transactions/` — read-only from client
- `notifications/{uid}/items` — read + mark-as-read writes
- `chats/{tripId}/messages` — read/write (both sides)
- `app_config` — read-only from client; write is via Cloud Function `updateAppConfig` (super-admin gated)
- `promo_codes`, `referrals`, `documents`, `driver_profiles`, `payment_requests`

### Realtime Database — temporary only
- `/driver_locations/{uid}` — driver publishes every 3s while online; `onDisconnect` auto-marks offline
- `/trip_requests/` — customer requests streamed to drivers
- `/live_bids/{tripId}/{bidId}` — driver bids; cleaned up in the Firestore `acceptBid` transaction
- `/active_trips/{tripId}` — driver location during active trip (every GPS update, not throttled)
- `/chats/{tripId}/messages` — live chat

### Cloud Functions called from client
- `validatePromoCode(code, uid)` — customer
- `processCommission(tripId)` — driver, on cash confirmation
- `adjustWallet(userUid, amount, reason)` — admin wallet screen ✓ correct
- `updateAppConfig(configData)` — admin config screen ✓ correct
- Implied (not verified in this repo): trip acceptance/rating server hooks, FCM push.

### Missing / out-of-repo
- No `firestore.rules`, no `database.rules.json`, no `functions/` in this repo. Security therefore depends on rules deployed elsewhere. **Do not assume the backend is locked down.**

---

## Implemented vs Missing Features (High-Level)

### Customer App — ~75–80% ready (Beta)
**Implemented:** phone OTP + Google/Facebook auth, pickup→dropoff→bidding→live tracking→rating flow, chat, wallet balance + top-up, trip history (paginated), promo codes, referral codes, profile, notifications, home with nearby drivers and recent locations.
**NOT IMPLEMENTED:** scheduled/later bookings, saved delivery addresses, ride sharing / multi-stop, counter-offers, trip history filters (date/status), payment method management UI, offline message queue, SOS/emergency contact, promotion carousel on home, favorite drivers, trip sharing link, dedicated `SettingsController` (currently reuses `ProfileController`).

### Driver App — Beta (ready for Egypt pilot with caveats)
**Implemented:** registration with 4-document upload, online/offline toggle with debt check, 3-second RTDB location publishing with `onDisconnect`, request stream with per-request countdown timers, bid submission, `acceptBid` Firestore transaction, active-trip screen with in-trip location publishing, trip completion with commission Cloud Function + rating, wallet read-only, earnings aggregations (day/week/date-range).
**NOT IMPLEMENTED:** vehicle type selection (hardcoded `motorcycle`), multi-vehicle, scheduled trips, surge pricing visibility, driver performance metrics screen, acceptance timeout for bids, language override, stale-bid cleanup in RTDB, GPS-staleness detection, document-expiry tracking, re-upload flow after rejection.
**Known bugs:** `ActiveTripController` never clears `markers`/`polylines` on close (leak on re-open); `TripRequestsController` countdown timers have a minor removal race; debt check is soft (no mid-trip re-check).

### Admin Panel — Beta / Phase 1.5
**Implemented:** login with `role` custom-claim verification, dashboard with 9 metrics + 30-day revenue chart + recent trips + manual refresh, paginated lists + search for customers/drivers/trips, driver approval queue, document review, wallet monitoring + balance adjustments via Cloud Function, app_config editor (super-admin, Cloud Function), promo list/create/update, notifications list, referral views, financial sub-module (summary/dashboard/revenue/commission/driver-earnings/wallet), responsive 3-breakpoint layout via `AdminLayoutShell`.
**NOT IMPLEMENTED:** admin audit log, dispute/appeals workflow, send-notification composer, bulk operations, 2FA, scheduled reports, CSV/PDF export, fine-grained permissions, auto-refresh on dashboard, breadcrumbs, base-href automation in build pipeline, `robots.txt`, CSP/X-Frame-Options headers.

---

## Critical Rules (Still in Force)

1. **No Laravel/PHP/REST API.** Everything is Firebase + Cloud Functions (called from client via `cloud_functions`).
2. **GetX only** for state, navigation, DI.
3. **Never hardcode prices/commissions.** Read from `app_config`.
4. **Never write `wallets/` or `transactions/` from Flutter.** Customer and driver apps comply. **Admin partially violates** — see below.
5. **Realtime DB is temporary.** Firestore is source of truth.
6. **All strings via `.tr` translations.** No hardcoded text in widgets.
7. **Test every screen in Arabic RTL.**
8. **Firestore batch writes** for multi-document atomic operations.
9. **Route names from `AppRoutes` constants only** — no hardcoded strings.

---

## Rule Violations Present in the Codebase (2026-04-17)

These are concrete, should-be-fixed violations — not theoretical:

| # | File | Line(s) | Violation |
|---|------|---------|-----------|
| 1 | `lib/features/admin/services/admin_firestore_service.dart` | 443–461 | `batchRejectDocumentsByIds` writes directly to `documents/`. Should be a Cloud Function for audit + driver FCM. |
| 2 | `lib/features/admin/services/admin_firestore_service.dart` | 558–587 | `rejectDriverCompletely` batch-writes `users` + `documents` directly. No audit trail, no driver notification. |
| 3 | `lib/features/admin/services/admin_firestore_service.dart` | 463–468 | `updateUserStatus` direct Firestore write — no centralized approval/suspension logic. |
| 4 | `lib/features/admin/services/admin_firestore_service.dart` | 815–845 | `createPromoCode` / `updatePromoCode` direct writes — no validation of expiry, discount range, or usage caps. |
| 5 | `lib/features/bidding/controllers/bids_controller.dart` | 71–75 | Silent trip cancellation on `onClose` without user confirmation. |
| 6 | `lib/features/settings/bindings/settings_binding.dart` | 8 | Settings screen reuses `ProfileController` — SRP violation; no dedicated `SettingsController`. |
| 7 | `lib/features/driver_trips/controllers/active_trip_controller.dart` | ~152 | `markers`/`polylines` never cleared in `onClose` — memory leak on re-open. |
| 8 | `lib/features/driver_trips/controllers/trip_requests_controller.dart` | 142–165 | Countdown timer removal race on auto-dismiss. |
| 9 | `web/index.html` | 15 | `<base href="$FLUTTER_BASE_HREF">` — placeholder not replaced; build script must pass `--base-href=/admin/`. |
| 10 | `pubspec.yaml` assets | — | `assets/images/markers/` referenced but directory doesn't exist (`flutter analyze` warning). |

---

## Technical Debt & Risks

1. **Zero tests.** No `test/` directory. `mockito`, `fake_cloud_firestore`, `golden_toolkit` are in `dev_dependencies` but unused. `golden_toolkit` itself is discontinued.
2. **No Firestore/RTDB security rules in repo.** They must be deployed out-of-band; do not assume they exist in production.
3. **`FirestoreService` is a 1,131-line monolith** spanning every domain. Split by feature (`TripService`, `WalletService`, `NotificationService`) before it grows further.
4. **No retry/backoff strategy in services.** Network flakes surface as errors immediately; no graceful degradation.
5. **Outdated dependencies.** `geolocator`, `google_maps_flutter`, `google_sign_in`, `share_plus` are 1+ major versions behind. `golden_toolkit` is abandoned.
6. **Admin has no audit log.** Moderation actions (rejections, suspensions, promo edits) are invisible after the fact.
7. **Driver location writes are unthrottled during active trips** — at 1,000+ concurrent drivers this becomes expensive.
8. **No offline-first strategy** anywhere — chat, wallet, trips all require network on every screen.
9. **Driver debt check is soft** — no backend lock; commission during online session can push balance negative mid-trip.
10. **Admin `isCheckingAuth` never re-verifies** — revoked admin claims persist until page refresh.

---

## Lint Configuration

Uses `flutter_lints ^5.0.0` with strict rules: `prefer_single_quotes`, `require_trailing_commas`, `prefer_const_constructors`, `prefer_final_locals`, `avoid_print`, `sort_child_properties_last`, `sort_constructors_first`, + error rules (`cancel_subscriptions`, `close_sinks`, `valid_regexps`, etc.). See `analysis_options.yaml` (139 rules total). Current status: **1 warning** (missing asset directory).

---

## SpecKit Workflow

`.specify/memory/constitution.md` exists (7 non-negotiable principles), but there is **no `specs/` directory with per-feature artifacts in this repo**. SpecKit slash commands (`/speckit.specify`, `/speckit.plan`, `/speckit.tasks`, `/speckit.implement`) are available via the installed plugin but have not produced feature folders here yet.

---

## Target Market

Egypt only. Currency: EGP. Phone format: +20 prefix, 11 digits. Arabic RTL is the primary UX for customer + driver; Admin is English-default (with RTL wrapper ready if locale switches).

---

## See Also

- `customer_app_analysis.md` — per-feature completeness, flows, controller maturity, rule violations.
- `driver_app_analysis.md` — location engine deep dive, ride flow, race conditions, performance risks.
- `admin_panel_analysis.md` — auth guard, Firestore vs Cloud Function, layout shell, missing tools.
