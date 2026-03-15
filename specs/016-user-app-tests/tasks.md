# Tasks: User App Testing Suite

**Input**: Design documents from `/specs/016-user-app-tests/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/, quickstart.md

**Tests**: This feature IS about creating tests, so all tasks involve writing test code.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each test suite component.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4)
- Include exact file paths in descriptions

## Path Conventions

This is a Flutter project at repository root with:
- Source code: `lib/`
- Tests: `test/`
- Test helpers: `test/helpers/`
- Test fixtures: `test/goldens/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and test tooling setup

- [X] T001 Add testing dependencies to pubspec.yaml (mockito ^5.4.4, build_runner ^2.4.8, fake_cloud_firestore ^2.5.1, golden_toolkit ^0.15.0)
- [X] T002 [P] Create test directory structure matching lib/ organization (test/core/, test/features/, test/integration/, test/helpers/, test/goldens/)
- [X] T003 [P] Configure analysis_options.yaml to exclude test files from production lints
- [X] T004 [P] Setup .gitignore to exclude coverage/ directory but include test/goldens/ golden images

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core test infrastructure that MUST be complete before ANY user story tests can be implemented

**⚠️ CRITICAL**: No user story test work can begin until this phase is complete

### Test Helpers

- [X] T005 [P] Create GetXTestHelper in test/helpers/getx_test_helpers.dart (setup(), cleanup(), pumpApp(), registerMockServices())
- [X] T006 [P] Create GoldenTestHelper in test/helpers/golden_test_helpers.dart (testLightTheme(), testDarkTheme(), testRTL(), testResponsive())
- [X] T007 [P] Create FirebaseTestHelper in test/helpers/firebase_test_helpers.dart (createFakeFirestore(), createMockAuth(), seedFirestore(), clearFirestore())

### Test Factories

- [X] T008 [P] Create UserFactory in test/helpers/test_factories.dart (create(), createCustomer(), createDriver(), createList())
- [X] T009 [P] Create TripFactory in test/helpers/test_factories.dart (create(), createPending(), createAccepted(), createCompleted())
- [X] T010 [P] Create BidFactory in test/helpers/test_factories.dart (create(), createMultipleBids())
- [X] T011 [P] Create PlaceFactory in test/helpers/test_factories.dart (createCairoLocation(), createGizaLocation(), create())

### Mock Services

- [X] T012 [P] Create MockAuthService in test/helpers/mock_services.dart (implements AuthService interface with fake auth state)
- [X] T013 [P] Create MockFirestoreService in test/helpers/mock_services.dart (implements FirestoreService with FakeFirebaseFirestore)
- [X] T014 [P] Create MockLocationService in test/helpers/mock_services.dart (implements LocationService with fake GPS positions)

### Test Fixtures

- [X] T015 Create TestFixtures class in test/helpers/test_fixtures.dart (tripWithMultipleBids(), completedTripWithRating(), userWithWallet())

**Checkpoint**: Foundation ready - user story test implementation can now begin in parallel

---

## Phase 3: User Story 1 - Core Shared Widgets Testing (Priority: P1) 🎯 MVP

**Goal**: Comprehensive widget tests for all 9 shared UI components to ensure consistent behavior, theming, RTL support, and accessibility across the customer app.

**Independent Test**: Run `flutter test test/core/widgets/` to verify all shared widgets render correctly in light/dark themes, RTL layouts, and pass accessibility checks.

### Widget Tests - AppButton

- [X] T016 [P] [US1] Create app_button_test.dart in test/core/widgets/ with primary button variant test (light theme)
- [X] T017 [P] [US1] Add secondary button variant test to test/core/widgets/app_button_test.dart
- [X] T018 [P] [US1] Add loading state test to test/core/widgets/app_button_test.dart (verify spinner shows when isLoading=true)
- [X] T019 [P] [US1] Add disabled state test to test/core/widgets/app_button_test.dart (verify onPressed=null disables button)
- [X] T020 [P] [US1] Add dark theme test to test/core/widgets/app_button_test.dart (verify AppTheme.darkTheme colors)
- [X] T021 [P] [US1] Add RTL layout test to test/core/widgets/app_button_test.dart (verify icon flips with leading icon in Arabic)
- [X] T022 [P] [US1] Add tap interaction test to test/core/widgets/app_button_test.dart (verify onPressed callback fires)
- [X] T023 [P] [US1] Add accessibility test to test/core/widgets/app_button_test.dart (verify semantic label exists)

### Widget Tests - AppTextField

- [X] T024 [P] [US1] Create app_text_field_test.dart in test/core/widgets/ with text input test
- [X] T025 [P] [US1] Add validation test to test/core/widgets/app_text_field_test.dart (verify error message shows on invalid input)
- [X] T026 [P] [US1] Add error state test to test/core/widgets/app_text_field_test.dart (verify error styling applied)
- [X] T027 [P] [US1] Add prefix/suffix icon test to test/core/widgets/app_text_field_test.dart
- [X] T028 [P] [US1] Add RTL text direction test to test/core/widgets/app_text_field_test.dart (verify text aligns right in Arabic)
- [X] T029 [P] [US1] Add keyboard interaction test to test/core/widgets/app_text_field_test.dart (verify focus and text entry)
- [X] T030 [P] [US1] Add dark theme test to test/core/widgets/app_text_field_test.dart
- [X] T031 [P] [US1] Add accessibility test to test/core/widgets/app_text_field_test.dart (verify semantic label and hint)

### Widget Tests - AppCard

- [X] T032 [P] [US1] Create app_card_test.dart in test/core/widgets/ with default card rendering test
- [X] T033 [P] [US1] Add elevated card test to test/core/widgets/app_card_test.dart (verify elevation styling)
- [X] T034 [P] [US1] Add outlined card test to test/core/widgets/app_card_test.dart (verify border styling)
- [X] T035 [P] [US1] Add dark theme test to test/core/widgets/app_card_test.dart
- [X] T036 [P] [US1] Add RTL layout test to test/core/widgets/app_card_test.dart
- [X] T037 [P] [US1] Add child widget rendering test to test/core/widgets/app_card_test.dart

### Widget Tests - AppLoading

- [X] T038 [P] [US1] Create app_loading_test.dart in test/core/widgets/ with circular progress indicator test
- [X] T039 [P] [US1] Add custom message test to test/core/widgets/app_loading_test.dart (verify loading message displays)
- [X] T040 [P] [US1] Add dark theme test to test/core/widgets/app_loading_test.dart
- [X] T041 [P] [US1] Add accessibility test to test/core/widgets/app_loading_test.dart (verify semantic label for screen readers)

### Widget Tests - AppSnackbar

- [X] T042 [P] [US1] Create app_snackbar_test.dart in test/core/widgets/ with success snackbar test
- [X] T043 [P] [US1] Add error snackbar test to test/core/widgets/app_snackbar_test.dart (verify error styling and icon)
- [X] T044 [P] [US1] Add warning snackbar test to test/core/widgets/app_snackbar_test.dart
- [X] T045 [P] [US1] Add info snackbar test to test/core/widgets/app_snackbar_test.dart
- [X] T046 [P] [US1] Add action button test to test/core/widgets/app_snackbar_test.dart (verify action callback fires)
- [X] T047 [P] [US1] Add dark theme test to test/core/widgets/app_snackbar_test.dart

### Widget Tests - AppDialog

- [X] T048 [P] [US1] Create app_dialog_test.dart in test/core/widgets/ with confirmation dialog test
- [X] T049 [P] [US1] Add title and content test to test/core/widgets/app_dialog_test.dart
- [X] T050 [P] [US1] Add primary/secondary action buttons test to test/core/widgets/app_dialog_test.dart
- [X] T051 [P] [US1] Add dismiss on tap outside test to test/core/widgets/app_dialog_test.dart
- [X] T052 [P] [US1] Add dark theme test to test/core/widgets/app_dialog_test.dart
- [X] T053 [P] [US1] Add RTL layout test to test/core/widgets/app_dialog_test.dart

### Widget Tests - AppBottomSheet

- [X] T054 [P] [US1] Create app_bottom_sheet_test.dart in test/core/widgets/ with bottom sheet rendering test
- [X] T055 [P] [US1] Add drag handle test to test/core/widgets/app_bottom_sheet_test.dart
- [X] T056 [P] [US1] Add dismiss on swipe down test to test/core/widgets/app_bottom_sheet_test.dart
- [X] T057 [P] [US1] Add dark theme test to test/core/widgets/app_bottom_sheet_test.dart
- [X] T058 [P] [US1] Add RTL layout test to test/core/widgets/app_bottom_sheet_test.dart

### Widget Tests - AppErrorWidget

- [X] T059 [P] [US1] Create app_error_widget_test.dart in test/core/widgets/ with error message display test
- [X] T060 [P] [US1] Add retry button test to test/core/widgets/app_error_widget_test.dart (verify onRetry callback fires)
- [X] T061 [P] [US1] Add error icon test to test/core/widgets/app_error_widget_test.dart
- [X] T062 [P] [US1] Add dark theme test to test/core/widgets/app_error_widget_test.dart
- [X] T063 [P] [US1] Add RTL layout test to test/core/widgets/app_error_widget_test.dart

### Widget Tests - AppEmptyState

- [X] T064 [P] [US1] Create app_empty_state_test.dart in test/core/widgets/ with empty state rendering test
- [X] T065 [P] [US1] Add custom icon test to test/core/widgets/app_empty_state_test.dart
- [X] T066 [P] [US1] Add custom message test to test/core/widgets/app_empty_state_test.dart
- [X] T067 [P] [US1] Add action button test to test/core/widgets/app_empty_state_test.dart (verify onAction callback fires)
- [X] T068 [P] [US1] Add dark theme test to test/core/widgets/app_empty_state_test.dart
- [X] T069 [P] [US1] Add RTL layout test to test/core/widgets/app_empty_state_test.dart

### Golden Tests (Visual Regression)

- [ ] T070 [P] [US1] Create golden test for AppButton in test/core/widgets/app_button_test.dart (capture light/dark/RTL variants)
- [ ] T071 [P] [US1] Create golden test for AppTextField in test/core/widgets/app_text_field_test.dart (capture light/dark/RTL variants)
- [ ] T072 [P] [US1] Create golden test for AppCard in test/core/widgets/app_card_test.dart (capture light/dark variants)
- [ ] T073 [P] [US1] Create golden test for AppLoading in test/core/widgets/app_loading_test.dart (capture light/dark variants)
- [ ] T074 [P] [US1] Create golden test for AppDialog in test/core/widgets/app_dialog_test.dart (capture light/dark/RTL variants)
- [ ] T075 [P] [US1] Create golden test for AppBottomSheet in test/core/widgets/app_bottom_sheet_test.dart (capture light/dark variants)
- [ ] T076 [P] [US1] Create golden test for AppErrorWidget in test/core/widgets/app_error_widget_test.dart (capture light/dark variants)
- [ ] T077 [P] [US1] Create golden test for AppEmptyState in test/core/widgets/app_empty_state_test.dart (capture light/dark variants)
- [ ] T078 [US1] Generate golden reference images by running `flutter test --update-goldens test/core/widgets/`
- [ ] T079 [US1] Commit golden reference images to Git in test/core/widgets/goldens/ directory

**Checkpoint**: Run `flutter test test/core/widgets/` - All shared widget tests should pass with 100% coverage

---

## Phase 4: User Story 2 - Feature Unit Testing (Controllers & Services) (Priority: P2)

**Goal**: Unit tests for customer app controllers and core services to validate business logic, state management, and data transformations in isolation.

**Independent Test**: Run `flutter test test/core/services/ test/features/*/controllers/` to verify controllers and services work correctly with mocked dependencies.

### Service Unit Tests - AuthService

- [X] T080 [P] [US2] Create auth_service_test.dart in test/core/services/ with signInWithPhoneNumber test
- [X] T081 [P] [US2] Add signOut test to test/core/services/auth_service_test.dart
- [X] T082 [P] [US2] Add currentUser getter test to test/core/services/auth_service_test.dart
- [X] T083 [P] [US2] Add authStateChanges stream test to test/core/services/auth_service_test.dart
- [X] T084 [P] [US2] Add error handling test to test/core/services/auth_service_test.dart (verify exception thrown on auth failure)

### Service Unit Tests - FirestoreService

- [X] T085 [P] [US2] Create firestore_service_test.dart in test/core/services/ with createUser test
- [X] T086 [P] [US2] Add getUser test to test/core/services/firestore_service_test.dart
- [X] T087 [P] [US2] Add updateUser test to test/core/services/firestore_service_test.dart
- [X] T088 [P] [US2] Add watchUserTrips stream test to test/core/services/firestore_service_test.dart
- [X] T089 [P] [US2] Add batch write test to test/core/services/firestore_service_test.dart (verify atomic operations)
- [X] T090 [P] [US2] Add error handling test to test/core/services/firestore_service_test.dart
- [X] T091 [P] [US2] Add data serialization test to test/core/services/firestore_service_test.dart (verify toMap()/fromMap() work correctly)

### Service Unit Tests - LocationService

- [X] T092 [P] [US2] Create location_service_test.dart in test/core/services/ with getCurrentLocation test
- [X] T093 [P] [US2] Add getAddressFromCoordinates test to test/core/services/location_service_test.dart
- [X] T094 [P] [US2] Add requestLocationPermission test to test/core/services/location_service_test.dart
- [X] T095 [P] [US2] Add permission denied handling test to test/core/services/location_service_test.dart
- [X] T096 [P] [US2] Add accuracy filtering test to test/core/services/location_service_test.dart (verify accuracy > 50m is ignored)

### Controller Unit Tests - AuthController

- [X] T097 [P] [US2] Create auth_controller_test.dart in test/features/auth/controllers/ with phone number validation test
- [X] T098 [P] [US2] Add OTP flow state management test to test/features/auth/controllers/auth_controller_test.dart
- [X] T099 [P] [US2] Add social login handling test to test/features/auth/controllers/auth_controller_test.dart
- [X] T100 [P] [US2] Add onClose cleanup test to test/features/auth/controllers/auth_controller_test.dart (verify stream subscriptions canceled)
- [X] T101 [P] [US2] Add reactive state update test to test/features/auth/controllers/auth_controller_test.dart (verify .obs properties update)

### Controller Unit Tests - HomeController

- [X] T102 [P] [US2] Create home_controller_test.dart in test/features/home/controllers/ with initialization test
- [X] T103 [P] [US2] Add location fetch test to test/features/home/controllers/home_controller_test.dart
- [X] T104 [P] [US2] Add recent trips loading test to test/features/home/controllers/home_controller_test.dart
- [X] T105 [P] [US2] Add error handling test to test/features/home/controllers/home_controller_test.dart

### Controller Unit Tests - ProfileController

- [X] T106 [P] [US2] Create profile_controller_test.dart in test/features/profile/controllers/ with user profile loading test
- [X] T107 [P] [US2] Add profile update test to test/features/profile/controllers/profile_controller_test.dart
- [X] T108 [P] [US2] Add photo upload test to test/features/profile/controllers/profile_controller_test.dart
- [X] T109 [P] [US2] Add validation test to test/features/profile/controllers/profile_controller_test.dart

### Controller Unit Tests - TripController

- [X] T110 [P] [US2] Create trip_controller_test.dart in test/features/trip/controllers/ with trip creation test
- [X] T111 [P] [US2] Add pickup location selection test to test/features/trip/controllers/trip_controller_test.dart
- [X] T112 [P] [US2] Add destination selection test to test/features/trip/controllers/trip_controller_test.dart
- [X] T113 [P] [US2] Add service type selection test to test/features/trip/controllers/trip_controller_test.dart
- [X] T114 [P] [US2] Add price estimation test to test/features/trip/controllers/trip_controller_test.dart (verify reads from app_config)

### Controller Unit Tests - BiddingController

- [X] T115 [P] [US2] Create bidding_controller_test.dart in test/features/bidding/controllers/ with bid submission test
- [X] T116 [P] [US2] Add bid amount validation test to test/features/bidding/controllers/bidding_controller_test.dart (verify validates against app_config)
- [X] T117 [P] [US2] Add bid state management test to test/features/bidding/controllers/bidding_controller_test.dart
- [X] T118 [P] [US2] Add bid timer handling test to test/features/bidding/controllers/bidding_controller_test.dart
- [X] T119 [P] [US2] Add bid selection test to test/features/bidding/controllers/bidding_controller_test.dart

### Controller Unit Tests - WalletController

- [X] T120 [P] [US2] Create wallet_controller_test.dart in test/features/wallet/controllers/ with wallet balance loading test
- [X] T121 [P] [US2] Add transaction history loading test to test/features/wallet/controllers/wallet_controller_test.dart
- [X] T122 [P] [US2] Add read-only enforcement test to test/features/wallet/controllers/wallet_controller_test.dart (verify no direct wallet writes from Flutter)

### Model Unit Tests

- [X] T123 [P] [US2] Create user_model_test.dart in test/core/models/ with toMap()/fromMap() test
- [X] T124 [P] [US2] Create trip_model_test.dart in test/core/models/ with toMap()/fromMap() test
- [X] T125 [P] [US2] Create bid_model_test.dart in test/core/models/ with toMap()/fromMap() test
- [X] T126 [P] [US2] Create place_model_test.dart in test/core/models/ with toMap()/fromMap() test
- [X] T127 [P] [US2] Add copyWith() test to test/core/models/user_model_test.dart
- [X] T128 [P] [US2] Add validation test to test/core/models/user_model_test.dart (verify phone format validation)

**Checkpoint**: Run `flutter test test/core/services/ test/features/*/controllers/ test/core/models/` - All service, controller, and model tests should pass with 80%+ coverage

---

## Phase 5: User Story 3 - Integration Testing (Feature Flows) (Priority: P3)

**Goal**: Integration tests for complete user journeys to ensure all components work together correctly and data flows properly between screens.

**Independent Test**: Run `flutter test integration/` to verify critical user paths work end-to-end with navigation, data persistence, and state synchronization.

### Integration Tests - Authentication Flow

- [X] T129 [US3] Create auth_flow_test.dart in test/integration/ with phone number entry → OTP verification → profile setup flow
- [X] T130 [US3] Add navigation verification test to test/integration/auth_flow_test.dart (verify all screens navigated correctly)
- [X] T131 [US3] Add data persistence test to test/integration/auth_flow_test.dart (verify user data saved to Firestore)
- [X] T132 [US3] Add final authentication state test to test/integration/auth_flow_test.dart (verify user is logged in)

### Integration Tests - Trip Creation Flow

- [X] T133 [US3] Create trip_creation_flow_test.dart in test/integration/ with pickup → destination → service selection → bid submission flow
- [X] T134 [US3] Add map interactions test to test/integration/trip_creation_flow_test.dart
- [X] T135 [US3] Add location data flow test to test/integration/trip_creation_flow_test.dart
- [X] T136 [US3] Add trip document creation test to test/integration/trip_creation_flow_test.dart (verify trip saved to Firestore)
- [X] T137 [US3] Add navigation to bidding screen test to test/integration/trip_creation_flow_test.dart

### Integration Tests - Bidding Flow

- [X] T138 [US3] Create bidding_flow_test.dart in test/integration/ with receiving bids → selecting driver → trip start flow
- [X] T139 [US3] Add real-time bid updates test to test/integration/bidding_flow_test.dart (verify RTDB subscriptions work)
- [X] T140 [US3] Add driver selection test to test/integration/bidding_flow_test.dart
- [X] T141 [US3] Add trip state transition test to test/integration/bidding_flow_test.dart (pending → accepted)
- [X] T142 [US3] Add navigation to tracking screen test to test/integration/bidding_flow_test.dart

### Integration Tests - Error Scenarios

- [X] T143 [P] [US3] Create error_scenarios_test.dart in test/integration/ with network failure simulation test
- [X] T144 [P] [US3] Add invalid data handling test to test/integration/error_scenarios_test.dart
- [X] T145 [P] [US3] Add error feedback test to test/integration/error_scenarios_test.dart (verify user sees error messages)
- [X] T146 [P] [US3] Add graceful degradation test to test/integration/error_scenarios_test.dart

### Integration Tests - Navigation Guards

- [X] T147 [P] [US3] Create navigation_guards_test.dart in test/integration/ with authentication guard test
- [X] T148 [P] [US3] Add unauthorized access prevention test to test/integration/navigation_guards_test.dart
- [X] T149 [P] [US3] Add redirect to login test to test/integration/navigation_guards_test.dart

**Checkpoint**: Run `flutter test integration/` - All integration tests should pass and critical user journeys work end-to-end

---

## Phase 6: User Story 4 - Performance & Accessibility Testing (Priority: P4)

**Goal**: Performance tests for heavy widgets and accessibility tests to ensure the app is performant and usable by all customers.

**Independent Test**: Run performance and accessibility tests separately to verify 60 FPS rendering, memory usage limits, and WCAG 2.1 Level AA compliance.

### Performance Tests

- [X] T150 [P] [US4] Create performance_test.dart in test/performance/ with AppMapWidget frame rate test (verify 60 FPS)
- [X] T151 [P] [US4] Add AppMapWidget memory usage test to test/performance/performance_test.dart (verify <100MB under load)
- [X] T152 [P] [US4] Add trip list scroll performance test to test/performance/performance_test.dart
- [X] T153 [P] [US4] Add home screen load time test to test/performance/performance_test.dart (verify <2s)
- [X] T154 [P] [US4] Add trip creation performance test to test/performance/performance_test.dart

### Accessibility Tests

- [X] T155 [P] [US4] Create accessibility_test.dart in test/accessibility/ with semantic labels test for all interactive elements
- [X] T156 [P] [US4] Add screen reader support test to test/accessibility/accessibility_test.dart
- [X] T157 [P] [US4] Add contrast ratio test to test/accessibility/accessibility_test.dart (verify WCAG 2.1 Level AA compliance)
- [X] T158 [P] [US4] Add focus order test to test/accessibility/accessibility_test.dart
- [X] T159 [P] [US4] Add tap target size test to test/accessibility/accessibility_test.dart (verify minimum 48x48 dp)

### RTL Layout Tests

- [X] T160 [P] [US4] Create rtl_layout_test.dart in test/accessibility/ with Arabic layout rendering test for all screens
- [X] T161 [P] [US4] Add layout overflow test to test/accessibility/rtl_layout_test.dart (verify no clipping or overflow in RTL)
- [X] T162 [P] [US4] Add directional icon flipping test to test/accessibility/rtl_layout_test.dart
- [X] T163 [P] [US4] Add EdgeInsetsDirectional usage test to test/accessibility/rtl_layout_test.dart

### Translation Key Tests

- [X] T164 [P] [US4] Create translation_test.dart in test/l10n/ with hardcoded text detection test (verify all text uses .tr)
- [X] T165 [P] [US4] Add missing translation key test to test/l10n/translation_test.dart
- [X] T166 [P] [US4] Add translation key format test to test/l10n/translation_test.dart

**Checkpoint**: Run `flutter test test/performance/ test/accessibility/ test/l10n/` - All performance, accessibility, and translation tests should pass

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Final improvements, documentation, and CI/CD setup that affect all test suites

### CI/CD Integration

- [X] T167 [P] Create GitHub Actions workflow file .github/workflows/test.yml with flutter test --coverage step
- [X] T168 [P] Add coverage enforcement step to .github/workflows/test.yml (fail if coverage < 70%)
- [X] T169 [P] Add golden test verification step to .github/workflows/test.yml
- [X] T170 [P] Setup Codecov integration in .github/workflows/test.yml for coverage reports
- [X] T171 [P] Add matrix testing for Flutter stable and beta channels to .github/workflows/test.yml

### Documentation

- [X] T172 [P] Create test/README.md with quickstart guide for running tests
- [X] T173 [P] Add test writing guide to test/README.md (how to write unit, widget, integration tests)
- [X] T174 [P] Add coverage report generation instructions to test/README.md
- [X] T175 [P] Add troubleshooting section to test/README.md

### Coverage Analysis

- [X] T176 Run `flutter test --coverage` to generate coverage/lcov.info
- [X] T177 Analyze coverage by directory (core/services should be 80%+, core/widgets should be 80%+, controllers should be 70%+)
- [X] T178 Identify low-coverage files and add missing tests
- [X] T179 Generate HTML coverage report with `genhtml coverage/lcov.info -o coverage/html`

### Code Quality

- [X] T180 [P] Add test lint rules to analysis_options.yaml (prefer_const_constructors, avoid_print in tests)
- [X] T181 [P] Setup pre-commit hook to run tests locally (optional but recommended)
- [X] T182 Run `flutter analyze` on test/ directory and fix all warnings

### Validation

- [ ] T183 Run quickstart.md validation: Execute all commands from quickstart.md to verify they work
- [ ] T184 Test full test suite execution time (verify <10 minutes)
- [ ] T185 Test flakiness: Run full test suite 5 times and verify <2% failure rate
- [ ] T186 Test on different platforms: Run tests on Windows, macOS, Linux (if available)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-6)**: All depend on Foundational phase completion
  - US1 (Core Widgets): Can start after Foundational
  - US2 (Controllers & Services): Can start after Foundational (parallel with US1)
  - US3 (Integration): Can start after Foundational (parallel with US1, US2)
  - US4 (Performance & Accessibility): Can start after Foundational (parallel with US1, US2, US3)
- **Polish (Phase 7)**: Depends on all desired user stories being complete

### User Story Dependencies

- **US1 (P1)**: No dependencies on other stories - Can run in parallel with US2, US3, US4
- **US2 (P2)**: No dependencies on other stories - Can run in parallel with US1, US3, US4
- **US3 (P3)**: No dependencies on other stories - Can run in parallel with US1, US2, US4
- **US4 (P4)**: No dependencies on other stories - Can run in parallel with US1, US2, US3

### Within Each User Story

- **US1**: All widget tests can run in parallel, golden tests run last
- **US2**: Service tests, controller tests, and model tests can all run in parallel
- **US3**: Integration tests can run in parallel (different flow files)
- **US4**: Performance tests, accessibility tests, and RTL tests can all run in parallel

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel
- All Foundational tasks marked [P] can run in parallel (within Phase 2)
- Once Foundational phase completes, ALL user stories (US1, US2, US3, US4) can start in parallel
- Within each user story, all tasks marked [P] can run in parallel
- All Polish tasks marked [P] can run in parallel

---

## Parallel Example: User Story 1 (Core Shared Widgets)

```bash
# Launch all widget test files in parallel (9 widgets):
Task: "Create app_button_test.dart in test/core/widgets/"
Task: "Create app_text_field_test.dart in test/core/widgets/"
Task: "Create app_card_test.dart in test/core/widgets/"
Task: "Create app_loading_test.dart in test/core/widgets/"
Task: "Create app_snackbar_test.dart in test/core/widgets/"
Task: "Create app_dialog_test.dart in test/core/widgets/"
Task: "Create app_bottom_sheet_test.dart in test/core/widgets/"
Task: "Create app_error_widget_test.dart in test/core/widgets/"
Task: "Create app_empty_state_test.dart in test/core/widgets/"

# Launch all golden tests in parallel (8 widgets):
Task: "Create golden test for AppButton"
Task: "Create golden test for AppTextField"
Task: "Create golden test for AppCard"
Task: "Create golden test for AppLoading"
Task: "Create golden test for AppDialog"
Task: "Create golden test for AppBottomSheet"
Task: "Create golden test for AppErrorWidget"
Task: "Create golden test for AppEmptyState"
```

## Parallel Example: User Story 2 (Controllers & Services)

```bash
# Launch all service test files in parallel (3 services):
Task: "Create auth_service_test.dart in test/core/services/"
Task: "Create firestore_service_test.dart in test/core/services/"
Task: "Create location_service_test.dart in test/core/services/"

# Launch all controller test files in parallel (6 controllers):
Task: "Create auth_controller_test.dart in test/features/auth/controllers/"
Task: "Create home_controller_test.dart in test/features/home/controllers/"
Task: "Create profile_controller_test.dart in test/features/profile/controllers/"
Task: "Create trip_controller_test.dart in test/features/trip/controllers/"
Task: "Create bidding_controller_test.dart in test/features/bidding/controllers/"
Task: "Create wallet_controller_test.dart in test/features/wallet/controllers/"

# Launch all model test files in parallel (4 models):
Task: "Create user_model_test.dart in test/core/models/"
Task: "Create trip_model_test.dart in test/core/models/"
Task: "Create bid_model_test.dart in test/core/models/"
Task: "Create place_model_test.dart in test/core/models/"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T004)
2. Complete Phase 2: Foundational (T005-T015) - CRITICAL
3. Complete Phase 3: User Story 1 (T016-T079)
4. **STOP and VALIDATE**: Run `flutter test test/core/widgets/` - All widget tests should pass
5. Generate coverage report - Verify core/widgets has 100% coverage
6. Demo: Show all shared widgets have comprehensive tests with visual regression

### Incremental Delivery

1. **Foundation** (Setup + Foundational) → Test infrastructure ready
2. **US1** (Core Widgets) → Run `flutter test test/core/widgets/` → 100% widget coverage → Deploy/Demo (MVP!)
3. **US2** (Controllers & Services) → Run `flutter test test/core/services/ test/features/*/controllers/` → 80%+ service/controller coverage → Deploy/Demo
4. **US3** (Integration) → Run `flutter test integration/` → All critical flows covered → Deploy/Demo
5. **US4** (Performance & Accessibility) → Run all perf/a11y tests → Quality standards met → Deploy/Demo
6. Each story adds test coverage without breaking previous tests

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together (T001-T015)
2. Once Foundational is done:
   - **Developer A**: User Story 1 (Widget Tests) - T016-T079
   - **Developer B**: User Story 2 (Controller & Service Tests) - T080-T128
   - **Developer C**: User Story 3 (Integration Tests) - T129-T149
   - **Developer D**: User Story 4 (Performance & Accessibility) - T150-T166
3. Stories complete and integrate independently
4. Team completes Polish phase together (T167-T186)

---

## Notes

- [P] tasks = different files, no dependencies - can run in parallel
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- This feature IS about writing tests, so all tasks involve creating test files
- Run `flutter test` frequently to catch issues early
- Run `flutter test --update-goldens` when golden images need updating
- Commit golden images to Git for version control
- Coverage target: 70% overall, 80% for services/widgets, 70% for controllers
- Test execution time target: <10 minutes for full suite
- Flaky test rate target: <2%

---

## Task Summary

**Total Tasks**: 186
- Phase 1 (Setup): 4 tasks
- Phase 2 (Foundational): 11 tasks (BLOCKS all user stories)
- Phase 3 (US1 - Core Widgets): 64 tasks
- Phase 4 (US2 - Controllers & Services): 49 tasks
- Phase 5 (US3 - Integration): 21 tasks
- Phase 6 (US4 - Performance & Accessibility): 17 tasks
- Phase 7 (Polish): 20 tasks

**Parallel Opportunities**:
- Phase 1: 3 tasks can run in parallel
- Phase 2: 11 tasks can run in parallel (test helpers, factories, mocks)
- All 4 user stories (US1, US2, US3, US4) can run in parallel after Foundational phase
- Within US1: 64 tasks can run in parallel (different widget files)
- Within US2: 49 tasks can run in parallel (different service/controller/model files)
- Within US3: Most integration tests can run in parallel (different flow files)
- Within US4: 17 tasks can run in parallel (different test types)
- Phase 7: Most polish tasks can run in parallel

**MVP Scope** (Recommended): Setup + Foundational + US1 only = 79 tasks
- Delivers comprehensive widget testing for all shared components
- Establishes test infrastructure for future test development
- Achieves 100% coverage for core shared widgets
- Provides immediate value by catching widget bugs early
