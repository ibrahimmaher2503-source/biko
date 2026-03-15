# Tasks: Profile Auto-Fill, Theme Chooser, Debug Logging & Home Page

**Input**: Design documents from `/specs/006-profile-theme-home/`
**Prerequisites**: plan.md (required), spec.md (required), data-model.md, research.md, quickstart.md

**Tests**: Not requested in feature specification. Test tasks omitted.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Phase 1: Foundational (Blocking Prerequisites)

**Purpose**: Data model and translation updates that multiple user stories depend on

- [x] T001 [P] Add `theme` field (String, default `'light'`) to `UserModel` in `lib/core/models/user_model.dart` — update constructor, `fromJson`, `toJson`, and `copyWith`
- [x] T002 [P] Add translation strings to `lib/core/translations/app_translations.dart` — add theme chooser strings (`profile.select_theme`, `profile.light`, `profile.dark`), home page strings (`home.welcome`, `home.ride`, `home.delivery`, `home.map_placeholder`), in both Arabic and English sections

**Checkpoint**: Foundation ready — model and translations in place for user story implementation

---

## Phase 2: User Story 1 — Auto-Fill Profile from Google Auth (Priority: P1) MVP

**Goal**: When a user signs in with Google, pre-fill their name and avatar on the profile setup screen from their Google account data.

**Independent Test**: Sign in with Google, land on profile setup, verify name field is pre-filled with Google display name and avatar shows Google profile photo. Sign in with phone OTP, verify name field is empty (no regression).

### Implementation

- [x] T003 [US1] Add Google auto-fill logic to `onInit()` in `lib/features/auth/controllers/profile_setup_controller.dart` — check `AuthService.currentUser?.displayName`, if not null/empty set `nameController.text`; check `AuthService.currentUser?.photoURL`, if not null set `avatarUrl.value`

**Checkpoint**: Google-signed-in users see their name and photo pre-filled. Phone OTP users see empty fields (existing behavior).

---

## Phase 3: User Story 2 — Theme Chooser on Profile Setup (Priority: P2)

**Goal**: Add a Light/Dark theme selector on the profile setup screen. Theme applies immediately and persists across app restarts via SharedPreferences + Firestore.

**Independent Test**: Open profile setup, toggle to Dark theme, verify immediate visual switch. Complete profile, restart app, verify Dark theme persists.

### Implementation

- [x] T004 [US2] Add `selectedTheme` observable (`'light'`.obs) and `selectTheme(String)` method to `lib/features/auth/controllers/profile_setup_controller.dart` — `selectTheme()` updates observable, calls `Get.changeThemeMode()`, and saves to SharedPreferences key `'theme_mode'`; update `completeProfile()` to persist `selectedTheme.value` to Firestore `theme` field
- [x] T005 [US2] Add theme selector UI to `lib/features/auth/screens/profile_setup_screen.dart` — add `_buildThemeSelector(context)` method below the language selector, reuse the pill-style toggle pattern with Light (sun icon) and Dark (moon icon) options, wire to `controller.selectTheme()`
- [x] T006 [US2] Add theme restoration on app start in `lib/core/app_initializer.dart` — read `'theme_mode'` from SharedPreferences in `init()` before `runApp()`, store the restored `ThemeMode` value, pass it to the app builder
- [x] T007 [US2] Update `lib/main_customer.dart` to accept and apply the restored `ThemeMode` — change `themeMode: ThemeMode.system` to use the restored value from `AppInitializer`, also update `lib/main_driver.dart` with the same change

**Checkpoint**: Theme toggle works with instant preview. Theme persists across restarts. Default is Light.

---

## Phase 4: User Story 3 — Debug Snackbar Logging (Priority: P2)

**Goal**: All snackbar messages print to the debug console in development mode. No output in release mode.

**Independent Test**: Trigger any snackbar (e.g., name required validation), verify title and message appear in debug console. Build release mode and verify no debug prints.

### Implementation

- [x] T008 [US3] Add `debugPrint()` logging to the `show()` method in `lib/core/widgets/app_snackbar.dart` — when `kDebugMode` is true (from `flutter/foundation.dart`), print `[Snackbar] {title}: {message}` before calling `Get.snackbar()`; skip message part if empty
- [x] T009 [US3] Replace all raw `Get.snackbar()` calls with `AppSnackbar` methods across the codebase — update `lib/features/auth/controllers/auth_controller.dart` (Google sign-in error snackbar), `lib/features/auth/widgets/social_login_buttons.dart` (Coming Soon snackbar), `lib/features/auth/controllers/profile_setup_controller.dart` (name required + upload failed + error snackbars), `lib/features/driver_registration/controllers/driver_registration_controller.dart` (error snackbars)

**Checkpoint**: All snackbar messages appear in debug console. No raw `Get.snackbar()` calls remain outside `AppSnackbar`.

---

## Phase 5: User Story 4 — Customer Home Page (Priority: P3)

**Goal**: Build the foundational customer home page with greeting header, map placeholder, and Ride/Delivery service type selector.

**Independent Test**: Complete profile as customer, verify navigation to home page, verify user name displayed, map placeholder visible, Ride/Delivery selector works.

### Implementation

- [x] T010 [P] [US4] Create `HomeController` in `lib/features/home/controllers/home_controller.dart` — load user data from Firestore via `FirestoreService.getUser()` in `onInit()`, expose `userName` and `avatarUrl` observables, add `selectedServiceType` (`'ride'`.obs) with `selectServiceType(String)` method
- [x] T011 [P] [US4] Create `HomeBinding` in `lib/features/home/bindings/home_binding.dart` — register `HomeController` with `Get.lazyPut()`
- [x] T012 [US4] Create `CustomerHomeScreen` in `lib/features/home/screens/customer_home_screen.dart` — build greeting header (avatar + "Welcome, {name}"), map placeholder (rounded gray container with map icon and placeholder text), service type selector (Ride / Delivery pill-style toggle matching theme selector pattern), use `GetView<HomeController>`
- [x] T013 [US4] Register customer home route in `lib/core/routes/customer_pages.dart` — add `GetPage` for `AppRoutes.customerHome` with `CustomerHomeScreen` and `HomeBinding`

**Checkpoint**: Complete app flow works: Login → Profile Setup → Home Page with greeting, map placeholder, and service selector.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final verification and cleanup

- [x] T014 Verify phone OTP flow is unaffected — test full phone OTP login flow to ensure Google auto-fill does not break existing behavior in `lib/features/auth/controllers/profile_setup_controller.dart`
- [x] T015 Verify RTL layout — test theme selector, home page greeting, map placeholder, and service selector render correctly in Arabic RTL mode

---

## Dependencies & Execution Order

### Phase Dependencies

- **Foundational (Phase 1)**: No dependencies — start immediately
- **US1 (Phase 2)**: Depends on Phase 1 (translations must exist)
- **US2 (Phase 3)**: Depends on Phase 1 (UserModel `theme` field and translations must exist)
- **US3 (Phase 4)**: No dependency on Phase 1 — can start in parallel with US1/US2
- **US4 (Phase 5)**: Depends on Phase 1 (translations must exist)
- **Polish (Phase 6)**: Depends on all phases complete

### Within Phase Task Dependencies

- **Phase 1**: T001, T002 are [P] — can run in parallel (different files)
- **Phase 2**: T003 — single task, no internal dependencies
- **Phase 3**: T004 must complete before T005. T006 and T007 depend on each other (T006 before T007). T004-T005 and T006-T007 can run in parallel.
- **Phase 4**: T008 must complete before T009 (helper must exist before replacing call sites)
- **Phase 5**: T010 and T011 are [P] — can run in parallel. T012 depends on T010. T013 depends on T012.
- **Phase 6**: T014 and T015 can run in parallel

### Parallel Opportunities

```text
# Phase 1 — both in parallel (different files):
T001: user_model.dart
T002: app_translations.dart

# Phase 3 — two parallel tracks:
Track A: T004 → T005 (controller → screen)
Track B: T006 → T007 (app_initializer → main_customer)

# Phase 4 — sequential (same dependency chain):
T008 → T009

# Phase 5 — T010 and T011 in parallel, then T012, then T013:
T010: home_controller.dart  |  T011: home_binding.dart
T012: customer_home_screen.dart (depends on T010)
T013: customer_pages.dart (depends on T012)
```

---

## Implementation Strategy

### MVP First (User Story 1)

1. Complete Phase 1: Foundational (2 tasks, parallelizable)
2. Complete Phase 2: US1 — Google auto-fill (1 task)
3. **STOP and VALIDATE**: Test Google sign-in → profile pre-fill
4. Deploy/demo if ready — Google auto-fill is functional

### Full Delivery

1. Complete MVP (Phases 1-2)
2. Complete Phase 3: US2 — Theme chooser (4 tasks)
3. Complete Phase 4: US3 — Debug snackbar logging (2 tasks)
4. Complete Phase 5: US4 — Customer home page (4 tasks)
5. Complete Phase 6: Polish (2 tasks)
6. All 15 tasks complete — feature is production-ready

---

## Notes

- Total: **15 tasks** across 6 phases
- US1 (P1): 1 implementation task — minimal change, high impact
- US2 (P2): 4 implementation tasks — controller, UI, app init, main files
- US3 (P2): 2 implementation tasks — centralized helper + migration
- US4 (P3): 4 implementation tasks — controller, binding, screen, route
- Foundational: 2 tasks
- Polish: 2 tasks
- New files created: 3 (`home_controller.dart`, `home_binding.dart`, `customer_home_screen.dart`)
- Key file touch count: `profile_setup_controller.dart` (2 tasks), `profile_setup_screen.dart` (1 task), `app_snackbar.dart` (1 task), `customer_pages.dart` (1 task), `app_initializer.dart` (1 task)
- Existing `AppSnackbar` class already exists — US3 extends it with debug logging rather than creating new file
