# Feature Specification: User App Testing Suite

**Feature Branch**: `016-user-app-tests`
**Created**: 2026-03-10
**Status**: Draft
**Input**: User description: "create test scenarios or unit tests or widget tests for user app"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Core Shared Widgets Testing (Priority: P1)

Developers need comprehensive widget tests for all shared UI components (`AppButton`, `AppTextField`, `AppCard`, `AppLoading`, `AppSnackbar`, `AppDialog`, `AppBottomSheet`, `AppErrorWidget`, `AppEmptyState`) to ensure consistent behavior and appearance across the customer app. These widgets are the foundation of the entire UI and are reused throughout all features.

**Why this priority**: These shared widgets are used in every screen of the app. A bug in `AppButton` or `AppTextField` could break dozens of screens simultaneously. Testing these first ensures the UI foundation is solid before testing higher-level features.

**Independent Test**: Can be fully tested by running widget tests that verify each component's rendering, interaction, theming, RTL support, and accessibility without requiring any feature-specific context. Delivers immediate value by catching widget bugs before they propagate to features.

**Acceptance Scenarios**:

1. **Given** a developer runs widget tests for `AppButton`, **When** the test suite executes, **Then** it verifies primary/secondary variants, loading states, disabled states, theme color application, RTL layout, and tap interactions
2. **Given** a developer runs widget tests for `AppTextField`, **When** tests execute, **Then** they verify text input, validation, error states, prefix/suffix icons, RTL text direction, and keyboard interactions
3. **Given** shared widgets are tested in both light and dark themes, **When** theme changes, **Then** all widgets render correctly with appropriate theme colors from `AppTheme` and `AppColorsExtension`
4. **Given** shared widgets are tested in Arabic (RTL) mode, **When** directionality changes, **Then** layouts flip correctly and directional icons mirror appropriately
5. **Given** a developer runs accessibility tests, **When** testing shared widgets, **Then** all widgets have proper semantic labels and support screen readers

---

### User Story 2 - Feature Unit Testing (Controllers & Services) (Priority: P2)

Developers need unit tests for customer app controllers (auth, home, profile, trip, bidding, wallet, etc.) and services (`AuthService`, `LocationService`, `FirestoreService`) to validate business logic, state management, and data transformations in isolation without UI dependencies.

**Why this priority**: Controllers contain critical business logic (bid calculations, trip state machines, wallet operations). Testing these in isolation catches logic errors before integration testing and ensures GetX reactive state works correctly.

**Independent Test**: Can be tested independently by mocking Firebase services and running unit tests that verify controller methods, state transitions, stream subscriptions, error handling, and cleanup logic. Delivers value by validating business rules without needing a UI or real Firebase instance.

**Acceptance Scenarios**:

1. **Given** a developer writes unit tests for `AuthController`, **When** tests run, **Then** they verify phone number validation, OTP flow state management, social login handling, and proper cleanup in `onClose()`
2. **Given** unit tests for trip-related controllers, **When** testing bid submission logic, **Then** tests verify bid amount validation against `app_config`, bid state management, and timer handling
3. **Given** service unit tests with mocked Firebase, **When** testing `FirestoreService` methods, **Then** tests verify data serialization/deserialization, error handling, and batch write operations
4. **Given** controller tests with stream subscriptions, **When** testing reactive state updates, **Then** tests verify `.obs` properties update correctly and all subscriptions are canceled in `onClose()`
5. **Given** unit tests for location-based features, **When** mocking `LocationService`, **Then** tests verify coordinate handling, distance calculations, and permission state management

---

### User Story 3 - Integration Testing (Feature Flows) (Priority: P3)

Developers need integration tests that validate complete user journeys in the customer app (authentication → home → trip creation → bidding → tracking → completion) to ensure all components work together correctly and data flows properly between screens.

**Why this priority**: While unit and widget tests validate individual pieces, integration tests catch issues in feature interactions, navigation flows, and data passing between screens. These are higher priority than performance tests but lower than unit/widget tests since they build on that foundation.

**Independent Test**: Can be tested by running integration test suites that simulate user journeys through multiple screens, verify navigation state, check data persistence, and validate end-to-end flows without requiring manual testing. Delivers value by automating regression testing of critical user paths.

**Acceptance Scenarios**:

1. **Given** an integration test for the authentication flow, **When** simulating phone number entry → OTP verification → profile setup, **Then** the test verifies navigation through all screens, data persistence, and final authentication state
2. **Given** an integration test for trip creation, **When** simulating pickup location → destination → service selection → bid submission, **Then** the test verifies map interactions, location data flow, and trip document creation
3. **Given** an integration test for the bidding flow, **When** simulating receiving bids → selecting a driver → trip start, **Then** the test verifies real-time updates, state transitions, and navigation to tracking screen
4. **Given** integration tests running with mock Firebase backends, **When** testing data flows, **Then** tests verify Firestore writes, Realtime Database subscriptions, and state synchronization across screens
5. **Given** integration tests for error scenarios, **When** simulating network failures or invalid data, **Then** tests verify error handling, user feedback, and graceful degradation

---

### User Story 4 - Performance & Accessibility Testing (Priority: P4)

Developers need performance tests (widget build times, frame rates, memory usage) and accessibility tests (screen reader support, semantic labels, contrast ratios) to ensure the customer app meets quality standards and is usable by all customers including those with disabilities.

**Why this priority**: These tests are important for quality but can be implemented after functional correctness is established. They catch performance regressions and accessibility issues that affect user experience but don't block core functionality.

**Independent Test**: Can be tested using Flutter's performance profiling tools and accessibility checkers without requiring complete feature implementation. Delivers value by ensuring the app is performant and inclusive.

**Acceptance Scenarios**:

1. **Given** performance tests for heavy widgets (maps, lists), **When** running frame rate analysis, **Then** tests verify 60 FPS rendering and memory usage under load
2. **Given** accessibility tests for all screens, **When** running semantic analysis, **Then** tests verify all interactive elements have labels, sufficient contrast ratios, and proper focus order
3. **Given** performance benchmarks for critical paths (home screen load, trip creation), **When** running tests, **Then** they measure and enforce maximum load time thresholds
4. **Given** RTL layout tests, **When** switching to Arabic, **Then** automated tests verify all layouts render correctly without overflow or clipping
5. **Given** golden image tests for shared widgets, **When** running screenshot comparisons, **Then** tests catch unintended visual regressions across theme changes

---

### Edge Cases

- What happens when tests run in CI/CD with different Flutter versions or dependencies?
- How does the test suite handle flaky tests (timing-dependent, network-dependent)?
- What happens when Firebase mock services return unexpected data structures?
- How do tests handle platform-specific behaviors (Android vs iOS vs Web)?
- What happens when running tests on different screen sizes and orientations?
- How do integration tests handle navigation guards and middleware (e.g., authentication checks)?
- What happens when testing controllers that depend on global services (`AuthController`, `LocationService`)?
- How do tests verify proper cleanup of streams, timers, and subscriptions to prevent memory leaks?
- What happens when testing widgets that require platform-specific permissions (location, camera)?
- How do tests handle translation keys that might be missing or incorrectly formatted?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Test suite MUST include widget tests for all shared components in `lib/core/widgets/` (AppButton, AppTextField, AppCard, AppLoading, AppSnackbar, AppDialog, AppBottomSheet, AppErrorWidget, AppEmptyState, AppMapWidget)
- **FR-002**: Test suite MUST include unit tests for all customer app controllers in `lib/features/*/controllers/` covering state management, business logic, and lifecycle methods
- **FR-003**: Test suite MUST include unit tests for all core services (`AuthService`, `LocationService`, `FirestoreService`) with mocked Firebase dependencies
- **FR-004**: Test suite MUST provide test data factories and builders for all core models (User, Trip, Bid, Place, etc.) to simplify test setup
- **FR-005**: Test suite MUST mock all Firebase services (Auth, Firestore, Realtime Database, Storage) to enable offline testing without real backend dependencies
- **FR-006**: All widget tests MUST verify correct rendering in both light and dark themes using `AppTheme.lightTheme` and `AppTheme.darkTheme`
- **FR-007**: All widget tests MUST verify correct RTL (Arabic) layout rendering and directional icon flipping
- **FR-008**: Test suite MUST verify all user-visible strings use `.tr` translation keys and never hardcoded text
- **FR-009**: Test suite MUST verify all colors come from `AppTheme` or `AppColorsExtension` tokens, never hardcoded `Colors.*` values
- **FR-010**: Test suite MUST include integration tests for critical user journeys (authentication, trip creation, bidding, tracking)
- **FR-011**: Test suite MUST verify all controllers properly cancel stream subscriptions and clean up resources in `onClose()`
- **FR-012**: Test suite MUST include accessibility tests verifying semantic labels, screen reader support, and contrast ratios
- **FR-013**: Test suite MUST include performance tests measuring widget build times and memory usage for heavy components (maps, lists)
- **FR-014**: Test suite MUST enforce minimum code coverage thresholds (80% for core services, 70% for controllers, 60% for widgets)
- **FR-015**: Test suite MUST run in CI/CD pipeline and block merges on test failures or coverage drops
- **FR-016**: Test suite MUST complete full test run in under 10 minutes to enable rapid feedback
- **FR-017**: Test suite MUST verify GetX dependency injection works correctly with `Get.lazyPut()` in bindings
- **FR-018**: Test suite MUST verify navigation using `Get.toNamed()` with route constants from `AppRoutes`
- **FR-019**: Test suite MUST include golden tests (screenshot comparisons) for all shared widgets to catch visual regressions
- **FR-020**: Test suite MUST verify all Firebase batch writes and transactions follow atomic operation patterns

### Key Entities

- **Test Suite**: Collection of all tests organized by type (unit, widget, integration, performance, accessibility)
- **Test Factory**: Utility classes that generate test data for models (UserFactory, TripFactory, BidFactory, etc.)
- **Mock Service**: Test doubles for Firebase services (MockAuthService, MockFirestoreService, MockLocationService)
- **Test Fixture**: Predefined test data and configuration used across multiple tests
- **Coverage Report**: Generated artifact showing code coverage percentages per file and overall
- **Golden File**: Reference screenshot images for visual regression testing of widgets
- **Test Helper**: Utility functions for common test setup (pumping widgets, creating test environments, mocking GetX)

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Overall code coverage reaches minimum 70% across the customer app codebase
- **SC-002**: Core services (`AuthService`, `FirestoreService`, `LocationService`) achieve 80%+ coverage
- **SC-003**: All 10 shared widgets in `lib/core/widgets/` have comprehensive widget tests with 100% coverage
- **SC-004**: All customer app controllers have unit tests covering initialization, state updates, and cleanup
- **SC-005**: Test suite executes completely in under 10 minutes on CI/CD pipeline
- **SC-006**: Zero test failures in the main branch at all times
- **SC-007**: All critical user journeys (authentication, trip booking, bidding, tracking) have integration test coverage
- **SC-008**: 100% of shared widgets pass RTL layout tests without visual regressions
- **SC-009**: All accessibility tests pass with zero critical issues (missing labels, insufficient contrast)
- **SC-010**: Developers can run the full test suite locally with a single command (`flutter test`)
- **SC-011**: New features cannot be merged without accompanying tests that maintain or improve coverage
- **SC-012**: Performance tests verify map widgets and list views maintain 60 FPS under normal load
- **SC-013**: Test documentation exists showing developers how to write and run tests for each test type
- **SC-014**: Flaky test rate remains below 2% (tests pass consistently across multiple runs)
- **SC-015**: All tests run successfully on Windows, macOS, and Linux development environments

## Assumptions

- Developers have basic familiarity with Flutter testing framework and GetX state management
- CI/CD pipeline (GitHub Actions or similar) is available for automated test execution
- Firebase emulators or mocking libraries (mockito, fake_cloud_firestore) can be used for test isolation
- Test coverage reporting tools (lcov, codecov) are integrated into the development workflow
- Golden test image storage and comparison is handled by version control (git)
- Performance testing requirements assume standard mid-range mobile devices (not high-end flagships)
- Accessibility standards follow WCAG 2.1 Level AA guidelines
- Test data factories will use realistic Egyptian phone numbers (+20 format) and Arabic text
- Integration tests will use mock data rather than connecting to real Firebase instances
- Test execution time budget of 10 minutes is based on standard CI/CD runner performance
