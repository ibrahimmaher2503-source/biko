# Customer (User) App Analysis

> Generated: 2026-03-09 | Branch: `015-admin-dashboard-fixes`

---

## Summary

| Category | Count |
|----------|-------|
| Specs covering customer app | 10 |
| Total spec tasks | 329 |
| Completed tasks | 286 |
| Pending tasks | 43 |
| Completion rate | 87% |
| Screens implemented | 14 |
| Controllers implemented | 9 |
| Core services | 7 |
| Core models | 6 |
| Core widgets | 6 |

---

## Spec-by-Spec Status

| Spec | Feature | Tasks | Done | Pending | Status |
|------|---------|-------|------|---------|--------|
| 002 | GetX Ecosystem Validation | 116 | 76 | 40 | Partial (tests) |
| 003 | Splash, Onboarding & Auth | 49 | 49 | 0 | COMPLETE |
| 004 | Theme Redesign & Skip OTP | 24 | 24 | 0 | COMPLETE |
| 006 | Profile, Theme Chooser & Home | 15 | 15 | 0 | COMPLETE |
| 007 | Home Services Overview | 27 | 27 | 0 | COMPLETE |
| 008 | Set Pickup Location | 32 | 32 | 0 | COMPLETE |
| 009 | Google Maps Platform Setup | 15 | 15 | 0 | COMPLETE |
| 010 | App Permissions (FCM + Location) | 11 | 11 | 0 | COMPLETE |
| 011 | Trip Bidding & Price Negotiation | 21 | 21 | 0 | COMPLETE |
| 014 | Map Integration | 19 | 16 | 3 | Partial |

---

## What's DONE

### Spec 002: GetX Ecosystem Validation
- [x] Test infrastructure and helpers
- [x] US1: State management tests (Rx variables, observers, GetBuilder, lifecycle) — 19 tasks
- [x] US2: Navigation tests (toNamed, back, parameters, bindings) — 19 tasks
- [x] US3: Dependency injection tests (put, lazyPut, delete, singleton) — 22 tasks

### Spec 003: Splash, Onboarding & Auth (ALL 49 TASKS DONE)
- [x] Dependencies (firebase_auth, firebase_storage, image_picker)
- [x] Core models: UserModel, DriverProfileModel, DocumentModel
- [x] Core services: AuthService, FirestoreService, StorageService
- [x] US1: SplashScreen with auto-routing decision tree (onboarding → auth → profile → home)
- [x] US2: Customer onboarding carousel with PageIndicator
- [x] US3: Driver onboarding slides + translation keys
- [x] US4: Phone login with Egyptian format (+20, 11-digit, prefixes 10/11/12/15)
- [x] US5: OTP verification with 30s resend timer + auto-verify
- [x] US6: Profile setup (name, avatar, language/theme selection)
- [x] US7: Driver registration (vehicle info + document uploads: national ID, license, vehicle reg, criminal record)
- [x] US8: Pending approval screen for drivers
- [x] Error handling, RTL/dark mode verification, linting

### Spec 004: Theme Redesign & Skip OTP (ALL 24 TASKS DONE)
- [x] DevConfig with skipOtp flag for development
- [x] AppColorsExtension with 12 semantic color tokens
- [x] All 6 shared widgets migrated to theme tokens
- [x] All 7 auth/onboarding screens migrated to theme tokens
- [x] OTP bypass in AuthController for dev mode
- [x] Firebase-safe splash check
- [x] Dark mode and RTL verification

### Spec 006: Profile, Theme & Home (ALL 15 TASKS DONE)
- [x] Google Sign-In auto-fill (name + photo pre-populated in profile setup)
- [x] Theme chooser in profile setup (light/dark/system)
- [x] Theme persistence via SharedPreferences
- [x] Debug snackbar logging
- [x] CustomerHomeScreen with HomeController + HomeBinding + route registration

### Spec 007: Home Services Overview (ALL 27 TASKS DONE)
- [x] ~30 translation keys for home screen
- [x] Orange accent color addition
- [x] HomeController (user data, location, wallet, recent locations, navigation)
- [x] CustomerMainShell with bottom navigation
- [x] RideServiceCard + ServiceCardGrid widgets (bike ride, delivery, etc.)
- [x] HomeHeader (welcome, wallet balance)
- [x] CustomerBottomNav (4 tabs: Home, Rides, center FAB, Wallet, Profile)
- [x] HomeSearchBar (tap to navigate to pickup)
- [x] RecentLocationsSection (debug demo data)
- [x] Map background with grayscale overlay
- [x] Dark mode + RTL verified

### Spec 008: Set Pickup Location (ALL 32 TASKS DONE)
- [x] google_maps_flutter dependency, Android config
- [x] PlaceModel for geocoding results
- [x] MapService (directions, reverse-geocode, places autocomplete, place details)
- [x] PickupController with full map + search logic
- [x] GPS detection with high accuracy, permission handling, service check
- [x] CenterPinWidget (draggable map marker)
- [x] PickupBottomSheet (selected location display + confirm)
- [x] Reverse-geocode on camera idle with stale-request skipping
- [x] PickupSearchBar + PickupResultsList (debounced 300ms, Egypt-biased, locale-aware)
- [x] SavedLocationsList widget
- [x] Location caching (SharedPreferences)
- [x] Dark mode + RTL audit

### Spec 009: Maps Platform Setup (ALL 15 TASKS DONE)
- [x] Android: manifestPlaceholders in build.gradle.kts, AndroidManifest.xml placeholder
- [x] iOS: Maps.xcconfig, Debug/Release xcconfig includes, Info.plist, AppDelegate.swift init
- [x] Web: Google Maps JS script in index.html
- [x] API key via String.fromEnvironment (not hardcoded)
- [x] Setup guide in quickstart

### Spec 010: App Permissions (ALL 11 TASKS DONE)
- [x] firebase_messaging + flutter_local_notifications dependencies
- [x] FcmService: permission request, token save, token refresh, foreground listener
- [x] Notification channels: trip_updates (high priority), promotions (default)
- [x] FCM integrated with AuthController (init on login, clear on logout)
- [x] Background notification handler

### Spec 011: Trip Bidding (ALL 21 TASKS DONE)
- [x] flutter_polyline_points dependency
- [x] TripStatus, TripType, PaymentMethod enums
- [x] DirectionsResult model
- [x] TripModel with full lifecycle fields
- [x] BiddingController with:
  - App config fetch from Firestore (base fare, per-km, per-min rates)
  - Google Directions API call + Haversine fallback (1.3x road factor)
  - Fare = base + (per_km × distance) + (per_min × duration), rounded to nearest 5 EGP
  - Offer adjustment ±5 EGP (min = suggested, max = 999)
  - Same-location validation (50m threshold)
  - Trip creation in Firestore (status: searching)
- [x] PriceNegotiationScreen with RouteAddressBar, FareBadge, OfferAdjuster, TripOptionsChips
- [x] Payment method selection (cash, wallet, card, Vodafone Cash, Fawry)
- [x] Passenger count selection
- [x] Trip note dialog

### Spec 014: Map Integration (16/19 TASKS DONE)
- [x] Map style assets (light + dark JSON)
- [x] LocationService: reactive location stream, permission handling
- [x] Real-time location on GoogleMap with blue dot
- [x] Camera animation on location updates
- [x] Trip route polylines on map
- [x] DirectionsResult parsing + bounds
- [x] Theme-aware map styling (light/dark JSON auto-applied)

---

## What's MISSING / PENDING

### Spec 002: GetX Tests (40 tasks remaining)

| Phase | Tasks | Description |
|-------|-------|-------------|
| US4: Localization | T064-T084 (21 tasks) | Translation key tests, locale switching, RTL/LTR verification |
| US5: Snackbar | T085-T101 (17 tasks) | Snackbar types, colors, integration tests |
| Multi-App Integration | T102-T105 (4 tasks) | Test all 3 entry points initialize correctly |
| Polish | T106-T116 (11 tasks) | Coverage reports, analysis, documentation |

### Spec 014: Map Integration (3 tasks remaining)

| Task | Description |
|------|-------------|
| **T010** | Load driver marker bitmap assets |
| **T011** | Accept `markers` parameter in AppMapWidget |
| **T012** | Convert nearby driver locations from Realtime DB to map markers |

These 3 tasks implement **US2: Available Drivers on Map** — showing nearby driver icons on the home/pickup map.

---

## Screens NOT Yet Implemented

These routes are defined in `app_routes.dart` but have **no corresponding screens or controllers**:

| Route | Feature | Priority |
|-------|---------|----------|
| `/customer/trip/dropoff` | Set dropoff location | **HIGH** — next step after pickup |
| `/customer/trip/bids` | View incoming driver bids, accept one | **HIGH** — core bidding flow |
| `/customer/trip/track` | Real-time trip tracking with driver on map | **HIGH** — active trip experience |
| `/customer/trip/completed` | Trip completion summary + fare breakdown | **MEDIUM** |
| `/customer/trip/rate` | Rate driver (stars + comment) | **MEDIUM** |
| `/customer/wallet` | Wallet balance + transaction history | **MEDIUM** |
| `/customer/wallet/top-up` | Add funds to wallet | **MEDIUM** |
| `/customer/promo` | Apply promo codes | **LOW** |
| `/customer/referral` | Referral program | **LOW** |
| `/customer/history` | Past trips list | **LOW** |
| `/customer/notifications` | Notification center | **LOW** |
| `/customer/profile` | User profile view/edit | **LOW** (placeholder exists) |
| `/customer/settings` | App settings | **LOW** |
| `/customer/chat` | In-trip chat with driver | **LOW** |

### Placeholder Screens (exist but non-functional)
- `placeholder_rides_screen.dart` — Rides tab in bottom nav
- `placeholder_wallet_screen.dart` — Wallet tab in bottom nav
- `placeholder_profile_screen.dart` — Profile tab in bottom nav

---

## File Inventory

### Screens (14 files)
```
lib/features/splash/screens/
  splash_screen.dart

lib/features/onboarding/screens/
  onboarding_screen.dart

lib/features/auth/screens/
  phone_login_screen.dart
  otp_verification_screen.dart
  profile_setup_screen.dart

lib/features/home/screens/
  customer_home_screen.dart
  customer_main_shell.dart
  placeholder_rides_screen.dart
  placeholder_wallet_screen.dart
  placeholder_profile_screen.dart

lib/features/pickup/screens/
  set_pickup_screen.dart

lib/features/bidding/screens/
  price_negotiation_screen.dart

lib/features/driver_registration/screens/
  driver_registration_screen.dart
  pending_approval_screen.dart
```

### Controllers (9 files)
```
lib/features/splash/controllers/splash_controller.dart
lib/features/onboarding/controllers/onboarding_controller.dart
lib/features/auth/controllers/auth_controller.dart          (global, permanent)
lib/features/auth/controllers/profile_setup_controller.dart
lib/features/home/controllers/home_controller.dart
lib/features/pickup/controllers/pickup_controller.dart
lib/features/bidding/controllers/bidding_controller.dart
lib/features/driver_registration/controllers/driver_registration_controller.dart
lib/core/services/location_service.dart                     (global, permanent)
```

### Bindings (7 files)
```
lib/features/splash/bindings/splash_binding.dart
lib/features/onboarding/bindings/onboarding_binding.dart
lib/features/auth/bindings/profile_setup_binding.dart
lib/features/home/bindings/home_binding.dart
lib/features/pickup/bindings/pickup_binding.dart
lib/features/bidding/bindings/bidding_binding.dart
lib/features/driver_registration/bindings/driver_registration_binding.dart
```

### Feature Widgets (18 files)
```
lib/features/auth/widgets/
  phone_input_field.dart
  otp_input_field.dart
  social_login_buttons.dart

lib/features/onboarding/widgets/
  onboarding_page.dart
  page_indicator.dart

lib/features/home/widgets/
  customer_bottom_nav.dart
  home_header.dart
  home_search_bar.dart
  service_card_grid.dart
  ride_service_card.dart
  recent_locations_section.dart

lib/features/pickup/widgets/
  pickup_search_bar.dart
  pickup_bottom_sheet.dart
  pickup_results_list.dart
  center_pin_widget.dart
  saved_locations_list.dart

lib/features/bidding/widgets/
  fare_badge.dart
  offer_adjuster.dart
  route_address_bar.dart
  trip_options_chips.dart

lib/features/driver_registration/widgets/
  document_upload_item.dart
  step_progress_indicator.dart
```

### Core Services (7 files)
```
lib/core/services/
  auth_service.dart         — Phone OTP, Google, Facebook auth
  firebase_service.dart     — Firebase initialization
  firestore_service.dart    — Users, drivers, documents, trips, config CRUD
  location_service.dart     — GPS position stream (GetxService)
  map_service.dart          — Directions, geocode, places autocomplete
  storage_service.dart      — Image pick + Firebase Storage upload
  fcm_service.dart          — Push notifications, channels, token mgmt
```

### Core Models (6 files + enums)
```
lib/core/models/
  user_model.dart           — User profile (customer/driver)
  driver_profile_model.dart — Vehicle, approval, online status, stats
  document_model.dart       — Uploaded document metadata
  trip_model.dart           — Full trip lifecycle
  place_model.dart          — Geographic location + autocomplete result
  directions_result.dart    — Route polyline, distance, duration, bounds
  enums.dart                — UserType, UserStatus, VehicleType, DocumentType,
                              DocumentStatus, AuthState, TripStatus, TripType,
                              PaymentMethod, AdminRole
```

### Core Widgets (6 files)
```
lib/core/widgets/
  app_button.dart           — Primary/outlined/text button with loading
  app_card.dart             — Styled card with border
  app_loading.dart          — Loading spinner/skeleton
  app_snackbar.dart         — Toast (success/error/info/warning)
  app_text_field.dart       — Validated text input
  app_map_widget.dart       — GoogleMap with polylines + styling
```

---

## Current User Journey (What Works End-to-End)

```
1. App Launch → Splash (2s min)
2. First time? → Onboarding carousel → Phone login
3. Enter phone (+20) → OTP (or skip in dev) → Verify
4. OR: Google Sign-In / Facebook Sign-In
5. New user? → Profile setup (name, avatar, theme)
6. → Customer Home (services grid, wallet badge, search bar)
7. Tap "Where to?" or service card → Set Pickup (GPS + map + search)
8. Confirm pickup → [DROPOFF SCREEN MISSING]
9. → Price Negotiation (route, fare calc, ±5 EGP, payment, passengers)
10. Submit → Trip created in Firestore (status: searching)
11. → [BID VIEWING MISSING] → [TRIP TRACKING MISSING] → [COMPLETION MISSING]
```

**The flow breaks after step 8** — dropoff selection is not implemented, and steps 9-11 (bid acceptance, tracking, completion) have no screens.

---

## Verdict

The customer app has **strong foundations** with 87% of spec tasks completed. Authentication, home screen, pickup location, and price negotiation are all production-ready. However, the **post-bidding trip lifecycle** is entirely unbuilt — this is the critical gap blocking a usable end-to-end customer experience.

### Recommended Next Steps (Priority Order)

1. **Set Dropoff Location** — Reuse pickup screen pattern for dropoff
2. **View & Accept Driver Bids** — Real-time bid listening from Realtime DB
3. **Trip Tracking Screen** — Driver location on map, ETA, status updates
4. **Trip Completion & Rating** — Summary, fare breakdown, driver rating
5. **Available Drivers on Map** (Spec 014 T010-T012) — Show nearby drivers
6. **Wallet Screen** — Balance, transaction history, top-up
7. **Profile & Settings Screens** — Replace placeholders
8. **Trip History** — Past trips list
9. **Remaining GetX tests** (Spec 002) — Localization, snackbar, integration
