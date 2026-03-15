# Implementation Plan: User App Testing Suite

**Branch**: `016-user-app-tests` | **Date**: 2026-03-11 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/016-user-app-tests/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

Establish comprehensive testing infrastructure for the BikeRide customer app, including widget tests for all shared UI components, unit tests for controllers and services, integration tests for critical user journeys, and performance/accessibility tests. The test suite will enforce minimum 70% code coverage, run in under 10 minutes, and integrate with CI/CD to block merges on failures. All tests must verify RTL layout correctness, theme consistency, and proper GetX lifecycle management.

## Technical Context

**Language/Version**: Dart ^3.9.2 with Flutter SDK (Material 3)
**Primary Dependencies**: GetX (state management), firebase_core, cloud_firestore, firebase_auth, google_maps_flutter, flutter_test, mockito, fake_cloud_firestore
**Storage**: Cloud Firestore (source of truth), Firebase Realtime Database (temporary data), local caching via GetStorage
**Testing**: Flutter test framework, mockito for mocking, fake_cloud_firestore for Firebase mocks, golden_toolkit for visual regression, integration_test package for E2E flows
**Target Platform**: Android 8.0+ (API 26+), iOS 13+, Web (Chrome for admin panel)
**Project Type**: Multi-platform mobile app with web admin panel
**Performance Goals**: Test suite completes in <10 minutes, 60 FPS rendering for map/list widgets, <2s screen load times
**Constraints**: 70% minimum code coverage, 80%+ for core services, RTL layout verification mandatory, tests must run offline with mocked Firebase
**Scale/Scope**: ~50 screens across customer/driver/admin apps, 10+ core shared widgets, 20+ controllers, 5+ core services, 15+ models

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Principle I: Firebase-Only Architecture
**Status**: ✅ PASS
**Evaluation**: All tests will mock Firebase services (Auth, Firestore, Realtime DB, Storage, Cloud Messaging) using `fake_cloud_firestore`, `mockito`, and test doubles. No traditional backend services are introduced. Tests verify correct Firebase SDK usage patterns.

### Principle II: GetX Exclusive State Management
**Status**: ✅ PASS
**Evaluation**: Tests explicitly verify GetX patterns: `Get.lazyPut()` in bindings, `.obs` reactive state, `Get.toNamed()` navigation, controller lifecycle (`onInit`, `onReady`, `onClose`), and stream cleanup. No alternative state management libraries are tested or introduced.

### Principle III: Feature-First Architecture
**Status**: ✅ PASS
**Evaluation**: Test structure mirrors feature-first organization under `test/features/*/` and `test/core/`. Tests verify feature isolation by ensuring features don't import from other features' internal files. Cross-feature communication through `core/` services is validated.

### Principle IV: Bilingual RTL-First
**Status**: ✅ PASS
**Evaluation**: Widget tests explicitly verify RTL layout correctness in Arabic, directional icon flipping, `EdgeInsetsDirectional` usage, and `.tr` translation key presence. Golden tests capture both LTR and RTL rendering. Tests enforce that no hardcoded text exists in widgets.

### Principle V: Config-Driven Business Logic
**Status**: ✅ PASS
**Evaluation**: Unit tests for controllers verify that business parameters (prices, commissions, bid timeouts) are read from mocked `app_config` documents, never hardcoded. Tests will fail if hardcoded business values are detected in controller logic.

### Principle VI: Server-Side Financial Security
**Status**: ✅ PASS
**Evaluation**: Tests verify that Flutter code never writes to `wallets/` or `transactions/` collections. Unit tests mock financial operations to ensure they call Cloud Functions (simulated) rather than direct Firestore writes. Security rule violations trigger test failures.

### Principle VII: Theme-Aware Design System
**Status**: ✅ PASS
**Evaluation**: Widget tests verify all colors come from `Theme.of(context)`, `AppColorsExtension`, or `AppTheme` constants. Tests detect hardcoded `Colors.*` usage (except allowed shadows and text-on-primary). Golden tests validate light/dark theme rendering.

**Overall Gate Status**: ✅ **PASS** — No constitutional violations. This feature enforces adherence to all 7 principles through automated testing.

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
lib/
├── main_customer.dart          # Customer app entry point
├── main_driver.dart            # Driver app entry point
├── main_admin.dart             # Admin panel entry point
├── core/
│   ├── widgets/                # Shared UI components (AppButton, AppTextField, etc.)
│   ├── models/                 # Data models (User, Trip, Bid, Place, etc.)
│   ├── services/               # Business services (AuthService, FirestoreService, LocationService)
│   ├── routes/                 # Route constants and page registries
│   ├── theme/                  # AppTheme, AppColorsExtension, typography
│   ├── translations/           # GetX translations (inline in Dart)
│   └── constants/              # App-wide constants
└── features/
    ├── auth/                   # Authentication flow
    │   ├── controllers/
    │   ├── screens/
    │   ├── bindings/
    │   └── widgets/
    ├── home/                   # Customer home screen
    ├── profile/                # User profile management
    ├── trip/                   # Trip creation and management
    ├── bidding/                # Bid submission and selection
    ├── tracking/               # Live trip tracking
    ├── wallet/                 # Wallet viewing (read-only)
    └── [other features]/

test/
├── core/
│   ├── widgets/                # Widget tests for shared components
│   │   ├── app_button_test.dart
│   │   ├── app_text_field_test.dart
│   │   ├── app_card_test.dart
│   │   ├── app_loading_test.dart
│   │   └── [other widget tests]
│   ├── services/               # Unit tests for core services
│   │   ├── auth_service_test.dart
│   │   ├── firestore_service_test.dart
│   │   └── location_service_test.dart
│   └── models/                 # Unit tests for data models
├── features/
│   ├── auth/
│   │   ├── controllers/        # Unit tests for controllers
│   │   └── screens/            # Widget tests for screens
│   ├── home/
│   ├── trip/
│   └── [other features]/
├── integration/
│   ├── auth_flow_test.dart
│   ├── trip_creation_flow_test.dart
│   └── bidding_flow_test.dart
├── helpers/
│   ├── test_factories.dart     # Test data factories (UserFactory, TripFactory, etc.)
│   ├── mock_services.dart      # Mock Firebase services
│   ├── test_helpers.dart       # Common test utilities
│   └── pump_app.dart           # Widget testing helpers
└── goldens/                    # Golden test reference images
    ├── app_button/
    ├── app_text_field/
    └── [other widgets]/
```

**Structure Decision**: This is a Flutter multi-app monorepo with three entry points sharing a single codebase. Tests mirror the `lib/` structure under `test/`, following Flutter's standard test organization. Widget tests verify UI components, unit tests validate business logic in isolation, integration tests cover complete user journeys, and golden tests catch visual regressions. All test artifacts are version-controlled except for coverage reports (generated in `coverage/` directory).

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

**No violations detected.** This testing feature reinforces constitutional compliance rather than introducing exceptions.
