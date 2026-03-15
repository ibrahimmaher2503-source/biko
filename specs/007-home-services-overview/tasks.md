# Tasks: Customer Home Services Overview

**Input**: Design documents from `/specs/007-home-services-overview/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md

**Tests**: Not explicitly requested in feature specification. Skipped.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Flutter mobile app**: `lib/` for source, `test/` for tests, `assets/` for resources
- Routes: `lib/core/routes/`
- Theme: `lib/core/theme/`
- Translations: `lib/core/translations/`
- Feature code: `lib/features/home/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Add translation keys, theme updates, and assets required by all user stories

- [X] T001 Add all home screen translation keys (~30 keys for AR + EN) to `lib/core/translations/app_translations.dart`. Keys needed: `home.current_location`, `home.location_unavailable`, `home.balance`, `home.balance_error`, `home.search_placeholder`, `home.take_a_ride`, `home.ride_description`, `home.popular`, `home.book_now`, `home.package_delivery`, `home.delivery_description`, `home.merchant_orders`, `home.merchant_description`, `home.coming_soon`, `home.recent_locations`, `home.see_all`, `nav.home`, `nav.rides`, `nav.wallet`, `nav.profile`
- [X] T002 [P] Add orange accent color constant (`static const Color orange = Color(0xFFF97316)`) and orange background variants to `lib/core/theme/app_theme.dart` for the Package Delivery card icon background
- [X] T003 [P] Create motorcycle placeholder asset directory `assets/images/home/` and add a motorcycle icon fallback note. Register `assets/images/home/` in `pubspec.yaml` under assets section
- [X] T004 [P] Create `RecentLocation` data class in `lib/features/home/models/recent_location.dart` with fields: `name` (String), `address` (String), `lat` (double), `lng` (double), `iconType` (String). Include `const` constructor

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Expand HomeController with all reactive state, update routing to use shell pattern, and create placeholder tab screens. MUST be complete before any user story widget work begins.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T005 Expand `HomeController` in `lib/features/home/controllers/home_controller.dart`: add observable fields `walletBalance` (RxDouble, default 0.0), `walletLoaded` (RxBool, default false), `locationName` (RxString, default ''), `locationLoaded` (RxBool, default false), `recentLocations` (RxList<RecentLocation>, default empty), `currentTabIndex` (RxInt, default 0). Update `_loadUserData()` to also set `walletBalance` from `UserModel.walletBalance` and `walletLoaded`. Add `_loadLocation()` method using `geolocator` to get position + `geocoding` to reverse geocode city name, cache in SharedPreferences, set `locationName` and `locationLoaded`. Add `_loadRecentLocations()` with placeholder demo data (Benha University + Office) behind a `kDebugMode` flag, empty list in release. Add `changeTab(int index)` method for bottom nav. Add navigation methods: `navigateToRideBooking()`, `navigateToDeliveryBooking()`, `navigateToWallet()`, `navigateToSearch()`, `navigateToLocationHistory()`, `onRecentLocationTap(RecentLocation location)`, `onMerchantTap()` (shows AppSnackbar.info coming soon). Call all three load methods in `onInit()`.
- [X] T006 [P] Create four placeholder tab screens as simple `StatelessWidget`s with centered "Coming Soon" text using `.tr` keys: `lib/features/home/screens/placeholder_rides_screen.dart`, `lib/features/home/screens/placeholder_wallet_screen.dart`, `lib/features/home/screens/placeholder_profile_screen.dart`. Each should be a `Scaffold` with an `AppBar` title and centered body text.
- [X] T007 Create `CustomerMainShell` in `lib/features/home/screens/customer_main_shell.dart`: a `GetView<HomeController>` with `Scaffold` body containing a `Stack` — the main area is an `Obx` wrapping `IndexedStack` with `controller.currentTabIndex` selecting between [CustomerHomeScreen (index 0), PlaceholderRidesScreen (index 1), PlaceholderWalletScreen (index 2), PlaceholderProfileScreen (index 3)]. The bottom area is a `Positioned` bottom widget slot for the bottom nav (initially an empty `SizedBox`, replaced in US3). Note: index 2 in the center button is NOT a tab page — it triggers navigation to the booking flow.
- [X] T008 Update `lib/core/routes/customer_pages.dart`: change the `AppRoutes.customerHome` GetPage to point to `CustomerMainShell` instead of `CustomerHomeScreen`. Keep `HomeBinding` as the binding.
- [X] T009 Rewrite `lib/features/home/screens/customer_home_screen.dart` as a skeletal scrollable layout: a `GetView<HomeController>` returning a `Stack` with [map background placeholder (empty Container for now), scrollable content column with `SingleChildScrollView` containing placeholder `SizedBox` slots for: header area, search bar area, service cards area, recent locations area]. Add `pb-24` equivalent bottom padding (96dp) to account for bottom nav overlay. Remove all old widgets (greeting header, service type selector, map placeholder).

**Checkpoint**: App runs with shell navigation skeleton. Home tab shows empty scrollable layout. Other tabs show placeholder screens. No visual content yet.

---

## Phase 3: User Story 1 — Service Cards (Ride, Delivery, Merchant) (Priority: P1) 🎯 MVP

**Goal**: Display three service cards (Take a Ride, Package Delivery, Merchant Orders) with correct styling, icons, and navigation actions matching the reference design.

**Independent Test**: Open the home screen. Verify all three service cards are visible with correct styling. Tap "Book Now" and verify navigation. Tap delivery card and verify navigation. Tap merchant card and verify "Coming Soon" snackbar.

### Implementation for User Story 1

- [X] T010 [P] [US1] Create `RideServiceCard` widget in `lib/features/home/widgets/ride_service_card.dart`: a tappable card with rounded corners (24dp radius), white/surfaceElevated background, subtle border + shadow. Internal layout: `Row` with left column (60% width) containing — "POPULAR" badge (primary/10 bg, primary text, 10px bold, rounded-md), "Take a Ride" title (headlineSmall bold), description text (bodySmall, textMuted color), and "Book Now" button (primary bg, white text, rounded-xl, shadow). Right column: motorcycle illustration `Image.asset('assets/images/home/motorcycle.png')` with fallback to `Icon(Icons.two_wheeler, size: 64)` at 112x112dp with drop shadow. Card has `active:scale-[0.98]` press effect via `GestureDetector` + `AnimatedScale`. Accept `VoidCallback onBookNow` and `VoidCallback? onCardTap` parameters. All text uses `.tr` localization keys.
- [X] T011 [P] [US1] Create `ServiceCardGrid` widget in `lib/features/home/widgets/service_card_grid.dart`: a `Row` with two `Expanded` cards separated by 16dp gap, each 192dp height (h-48). Left card (Package Delivery): white/surfaceElevated bg, rounded-3xl, border + shadow. Contains: 48x48 orange icon container (orange/50 bg, `Icons.inventory_2` orange icon), title "Package Delivery" (titleMedium bold), description (bodySmall, textMuted). Right card (Merchant Orders): `LinearGradient` from `AppTheme.primary` to `AppTheme.primaryDark`, rounded-3xl, shadow with primary/20. Contains: 48x48 white/20 backdrop icon container (`Icons.storefront` white icon), title "Merchant Orders" (titleMedium bold, white), description (bodySmall, white/80). Both have decorative blurred circles. Both cards accept `VoidCallback onTap`. All text uses `.tr` keys.
- [X] T012 [US1] Integrate service cards into `lib/features/home/screens/customer_home_screen.dart`: replace the service cards placeholder slot with `RideServiceCard` and `ServiceCardGrid` widgets. Wire `onBookNow` to `controller.navigateToRideBooking()`, delivery `onTap` to `controller.navigateToDeliveryBooking()`, merchant `onTap` to `controller.onMerchantTap()`. Add 16dp vertical gap between ride card and grid.

**Checkpoint**: Home screen shows all three service cards with correct styling. "Book Now" navigates to ride flow. Delivery card navigates. Merchant card shows "Coming Soon" snackbar.

---

## Phase 4: User Story 2 — Location Header & Wallet Badge (Priority: P1)

**Goal**: Display the user's current city/area in a fixed header with a wallet balance badge showing EGP amount, both matching the reference design.

**Independent Test**: Open the home screen. Verify location name shows (or "Location unavailable"). Verify wallet badge shows EGP balance. Tap wallet badge to navigate to wallet screen.

### Implementation for User Story 2

- [X] T013 [US2] Create `HomeHeader` widget in `lib/features/home/widgets/home_header.dart`: a `GetView<HomeController>` container with surfaceElevated/95% opacity bg, backdrop blur, bottom rounded corners (24dp), horizontal padding 20dp, vertical padding (top safe area + 12dp, bottom 16dp), subtle shadow. Layout: `Row` with `justify-between`. Left side: `Column` with — row containing location_on icon (primary, 20px) + "CURRENT LOCATION" label (labelSmall, textMuted, uppercase, tracking wider), then city name `Obx(() => Text(controller.locationName.value))` as titleLarge bold (show 'home.location_unavailable'.tr if `locationLoaded` is false or name is empty). Right side: tappable wallet badge — `GestureDetector` with `Row` inside pill container (surfaceContainer bg, border, rounded-full, padding). Badge contains: 32x32 circle (primary/10 bg, wallet icon primary 18px), then column with "Balance" label (10px, textMuted) and `Obx(() => Text('EGP ${controller.walletBalance.value.toStringAsFixed(0)}'))` as titleSmall bold (show '---' if `walletLoaded` is false). Accept `VoidCallback onWalletTap`. Active scale-95 press effect.
- [X] T014 [US2] Integrate header into `lib/features/home/screens/customer_home_screen.dart`: add `HomeHeader` as a fixed/pinned element at the top of the `Stack` (above the scrollable content, below the map background, z-index 10). Wire `onWalletTap` to `controller.navigateToWallet()`. Adjust scroll content top padding to account for header height (~100dp).

**Checkpoint**: Header shows location name and wallet balance. Tapping wallet badge navigates to wallet placeholder. Location shows "Location unavailable" if GPS is off.

---

## Phase 5: User Story 3 — Bottom Navigation Bar (Priority: P1)

**Goal**: Persistent bottom navigation bar with 5 items (Home, Rides, center + button, Wallet, Profile) with correct active state and navigation.

**Independent Test**: Verify bottom nav is visible with all 5 items. Tap each tab and verify screen switches. Verify Home tab is active with primary color and dot indicator. Verify center + button navigates to booking flow.

### Implementation for User Story 3

- [X] T015 [US3] Create `CustomerBottomNav` widget in `lib/features/home/widgets/customer_bottom_nav.dart`: a `GetView<HomeController>` container at screen bottom with surfaceElevated bg, top border (borderSubtle), shadow upward, bottom safe area padding + 12dp top + 24dp bottom padding, 24dp horizontal padding. Layout: `Row` with `justify-between` containing 5 items. Items 0,1,3,4 are tab buttons: `GestureDetector` → `Column` with icon (28px Material icon) + label (10px font). Icons: index 0 = `Icons.home` (with red dot indicator positioned -top-1 -right-1 when active), index 1 = `Icons.directions_car`, index 3 = `Icons.wallet`, index 4 = `Icons.person`. Active tab uses primary color, inactive uses textMuted. Labels: use `.tr` keys (`nav.home`, `nav.rides`, `nav.wallet`, `nav.profile`). Center item (index 2): elevated circular button — 56x56dp, primary bg, white `Icons.add` icon (28px), rounded-full, shadow with primary/40, 4dp white/surfaceElevated border, positioned -top-24dp (relative raised). Uses `Obx` with `controller.currentTabIndex` for active state. Accept `Function(int) onTabChanged` and `VoidCallback onCenterTap`.
- [X] T016 [US3] Integrate bottom nav into `lib/features/home/screens/customer_main_shell.dart`: replace the empty `SizedBox` placeholder with `CustomerBottomNav`. Wire `onTabChanged` to `controller.changeTab(index)` (skip index 2, which is the center button). Wire `onCenterTap` to `controller.navigateToRideBooking()`. Ensure the `IndexedStack` maps correctly: tab 0 → home content, tab 1 → rides placeholder, tab 3 → wallet placeholder, tab 4 → profile placeholder (indices adjusted to skip center button).

**Checkpoint**: Bottom nav shows all 5 items. Switching tabs changes the IndexedStack page. Center + button navigates to booking flow. Home tab shows active state with dot indicator.

---

## Phase 6: User Story 4 — Search Bar (Priority: P2)

**Goal**: A floating search bar below the header that navigates to the destination search screen when tapped.

**Independent Test**: Open home screen. Verify search bar is visible below header with search icon and placeholder text. Tap search bar and verify navigation to destination search.

### Implementation for User Story 4

- [X] T017 [US4] Create `HomeSearchBar` widget in `lib/features/home/widgets/home_search_bar.dart`: a tappable container (not an actual input — `GestureDetector` wrapping a styled container). Container: surfaceElevated bg, 16dp rounded corners (rounded-2xl), subtle shadow (0 8 30 rgb(0,0,0,0.04)), border (borderSubtle), 8dp padding. Internal `Row`: left side — 40x40 rounded-xl container with primary/5 bg and search icon (primary color), 12dp gap, then `Text` with placeholder 'home.search_placeholder'.tr in textMuted color, bodyLarge medium weight. Accept `VoidCallback onTap`.
- [X] T018 [US4] Integrate search bar into `lib/features/home/screens/customer_home_screen.dart`: add `HomeSearchBar` below the header spacing and above the service cards in the scrollable content. Wire `onTap` to `controller.navigateToSearch()`. Add 24dp vertical gap below search bar.

**Checkpoint**: Search bar visible below header. Tapping it navigates to destination/pickup screen.

---

## Phase 7: User Story 5 — Recent Locations (Priority: P2)

**Goal**: A "Recent Locations" section showing up to 5 previously used destinations with icons, names, addresses, and tap-to-navigate functionality. Section hidden when no data.

**Independent Test**: In debug mode, verify recent locations section shows with demo data. Tap a location and verify navigation to booking flow. In release mode with no trips, verify section is hidden.

### Implementation for User Story 5

- [X] T019 [US5] Create `RecentLocationsSection` widget in `lib/features/home/widgets/recent_locations_section.dart`: a `Column` wrapped in `Obx` that returns `SizedBox.shrink()` when `controller.recentLocations.isEmpty`. When visible: top row with "Recent Locations" title (titleMedium bold) + "See All" text button (primary color, labelMedium semibold). Below: surfaceElevated container with rounded-2xl, border (borderSubtle), 4dp padding. Inside: `ListView.separated` (shrinkWrap, NeverScrollableScrollPhysics) of location items. Each item: `GestureDetector` → `Row` with 40x40 rounded-full icon container (surfaceContainer bg, icon based on `iconType` — history/work/home/favorite maps to `Icons.history`/`Icons.work`/`Icons.home`/`Icons.favorite`, textMuted color, 20px), 12dp gap, `Expanded` column (name as titleSmall bold, address as bodySmall textMuted truncated), trailing chevron_right icon (textMuted, 20px — flip with `Transform.flip` when RTL using `Directionality.of(context)`). Items separated by 1px divider with 12dp horizontal margin. Accept `Function(RecentLocation) onLocationTap` and `VoidCallback onSeeAllTap`.
- [X] T020 [US5] Integrate recent locations into `lib/features/home/screens/customer_home_screen.dart`: add `RecentLocationsSection` below the service cards grid with 24dp top margin. Wire `onLocationTap` to `controller.onRecentLocationTap(location)` and `onSeeAllTap` to `controller.navigateToLocationHistory()`.

**Checkpoint**: In debug mode, "Recent Locations" section shows demo data. Tapping a location navigates to booking flow. Section hidden when list is empty.

---

## Phase 8: User Story 6 — Map Background & Dark Mode Support (Priority: P3)

**Goal**: Subtle grayscale map background behind all content with gradient overlay. Full dark mode and RTL support across all home screen elements.

**Independent Test**: Verify map background visible behind content with gradient fade. Switch to dark mode — all elements adapt. Switch to Arabic — all elements mirror correctly.

### Implementation for User Story 6

- [X] T021 [US6] Implement map background in `lib/features/home/screens/customer_home_screen.dart`: add as the first child of the root `Stack`, a full-screen `Positioned.fill` container with the static map image `Image.asset('assets/images/backgrounds/cairo_map.png', fit: BoxFit.cover)` wrapped in `ColorFiltered` with grayscale `ColorFilter.matrix` and 80% opacity. Over it, a `Container` with `BoxDecoration` using `LinearGradient` (begin: topCenter, end: bottomCenter) with stops at [0.0, 0.4, 1.0] and colors: scaffoldBackgroundColor/60% → transparent → scaffoldBackgroundColor/90%. Handle missing asset gracefully (use plain scaffold bg color as fallback).
- [X] T022 [P] [US6] Verify dark mode support across all home widgets: review each widget file (`home_header.dart`, `home_search_bar.dart`, `ride_service_card.dart`, `service_card_grid.dart`, `recent_locations_section.dart`, `customer_bottom_nav.dart`) and ensure all colors come from `Theme.of(context)`, `AppColorsExtension`, or `AppTheme` constants — no hardcoded `Colors.white` or `Colors.black` except where explicitly intended (e.g., white text on primary gradient in merchant card). Fix any violations.
- [X] T023 [P] [US6] Verify RTL support across all home widgets: review each widget for directional elements. Ensure chevron icons in recent locations flip in RTL. Ensure `Row` layouts use correct start/end alignment. Ensure text alignment uses `TextAlign.start` not `TextAlign.left`. Ensure the "POPULAR" badge position is direction-aware. Test by temporarily setting `locale: Locale('ar')` in `main_customer.dart` and checking layout mirroring.

**Checkpoint**: Map background visible with subtle grayscale effect. Dark mode: all elements adapt. Arabic: all elements mirror correctly.

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Final integration validation, edge cases, and cleanup

- [X] T024 Verify complete screen assembly in `lib/features/home/screens/customer_home_screen.dart` matches the reference design `stitch/home_services_overview/screen.png`: check spacing between all sections (header → search → ride card → grid → recent locations), ensure scroll behavior is smooth (header stays fixed, content scrolls with bottom padding for nav), verify all shadows and border radii match the stitch HTML code.
- [X] T025 [P] Handle edge cases per spec in `lib/features/home/controllers/home_controller.dart`: verify wallet balance error shows "---" in badge, location unavailable shows fallback text, offline shows cached data from SharedPreferences (last known location name + balance).
- [X] T026 [P] Verify all `.tr` translation keys are used correctly — run the app in English and Arabic, check every visible text element on the home screen uses a translation key and renders correctly in both languages.
- [X] T027 Run app with `flutter run -t lib/main_customer.dart`, navigate through all home screen interactions, and validate against `specs/007-home-services-overview/quickstart.md` acceptance criteria.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 completion — BLOCKS all user stories
- **User Stories (Phase 3-8)**: All depend on Phase 2 completion
  - US1 (Service Cards), US2 (Header), US3 (Bottom Nav): Can proceed in parallel after Phase 2
  - US4 (Search Bar): Can proceed in parallel after Phase 2, no dependencies on other stories
  - US5 (Recent Locations): Can proceed in parallel after Phase 2, no dependencies on other stories
  - US6 (Map Background & Polish): Should run last as it touches all widget files for verification
- **Polish (Phase 9)**: Depends on all user stories being complete

### User Story Dependencies

- **US1 (P1)**: After Phase 2 — independent, no cross-story dependencies
- **US2 (P1)**: After Phase 2 — independent, no cross-story dependencies
- **US3 (P1)**: After Phase 2 — independent (shell created in foundational, this adds styled nav)
- **US4 (P2)**: After Phase 2 — independent
- **US5 (P2)**: After Phase 2 — independent (uses RecentLocation model from Phase 1 T004)
- **US6 (P3)**: After US1-US5 — verifies dark mode/RTL across all widgets

### Within Each User Story

- Widget creation before screen integration
- All widgets within a story marked [P] can be created in parallel
- Screen integration depends on widget completion

### Parallel Opportunities

- T002, T003, T004 can all run in parallel (different files)
- T006 can run in parallel with T005 (different files)
- T010, T011 can run in parallel (different widget files)
- T022, T023 can run in parallel (different concern reviews)
- T025, T026 can run in parallel (different validation areas)
- US1, US2, US3, US4, US5 can all run in parallel after Phase 2 (different widget files)

---

## Parallel Example: User Story 1

```bash
# Launch both US1 widget tasks in parallel (different files):
Task: "Create RideServiceCard widget in lib/features/home/widgets/ride_service_card.dart"
Task: "Create ServiceCardGrid widget in lib/features/home/widgets/service_card_grid.dart"

# Then integrate (depends on both widgets):
Task: "Integrate service cards into customer_home_screen.dart"
```

## Parallel Example: After Phase 2

```bash
# Launch US1, US2, US3, US4, US5 widget creation in parallel:
Task: "T010 [US1] Create RideServiceCard"
Task: "T011 [US1] Create ServiceCardGrid"
Task: "T013 [US2] Create HomeHeader"
Task: "T015 [US3] Create CustomerBottomNav"
Task: "T017 [US4] Create HomeSearchBar"
Task: "T019 [US5] Create RecentLocationsSection"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (translations, theme, assets)
2. Complete Phase 2: Foundational (controller, shell, routing)
3. Complete Phase 3: User Story 1 — Service Cards
4. **STOP and VALIDATE**: Three service cards visible, navigation works
5. App is usable — users can see services and begin booking

### Incremental Delivery

1. Phase 1 + Phase 2 → Foundation ready
2. Add US1 (Service Cards) → Test → MVP with core navigation
3. Add US2 (Header) → Test → Location context + wallet badge
4. Add US3 (Bottom Nav) → Test → Full app navigation structure
5. Add US4 (Search Bar) → Test → Quick destination entry
6. Add US5 (Recent Locations) → Test → Repeat trip convenience
7. Add US6 (Map Background + Polish) → Test → Visual refinement
8. Phase 9 → Final validation against reference design

---

## Summary

- **Total tasks**: 27
- **Phase 1 (Setup)**: 4 tasks
- **Phase 2 (Foundational)**: 5 tasks
- **US1 (Service Cards, P1)**: 3 tasks
- **US2 (Header & Wallet, P1)**: 2 tasks
- **US3 (Bottom Nav, P1)**: 2 tasks
- **US4 (Search Bar, P2)**: 2 tasks
- **US5 (Recent Locations, P2)**: 2 tasks
- **US6 (Map Background, P3)**: 3 tasks
- **Polish**: 4 tasks
- **Parallel opportunities**: 6 identified (Setup, Foundational, US1 widgets, US6 reviews, Polish validations, cross-story widget creation after Phase 2)
- **Suggested MVP scope**: Phase 1 + Phase 2 + US1 (Service Cards) = 12 tasks

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story is independently completable and testable after Phase 2
- No test tasks included (not requested in spec)
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
