# Implementation Plan: Splash, Onboarding, and Authentication Flow

**Branch**: `003-splash-onboarding` | **Date**: 2026-03-01 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/003-splash-onboarding/spec.md`

## Summary

Build the complete first-launch experience for both Customer and Driver apps: branded splash screen with smart routing, 3-slide onboarding carousel (shared widget, app-specific content), Firebase Phone Auth (OTP flow), profile setup with avatar/language, driver document registration, and application pending status screen. All screens support Arabic RTL / English LTR, light/dark themes, and use GetX for state management and navigation.

## Technical Context

**Language/Version**: Dart 3.9.2+ / Flutter 3.x
**Primary Dependencies**: GetX 4.6.6, Firebase Auth 5.x, Cloud Firestore 5.x, Firebase Storage 12.x, image_picker 1.x, shared_preferences 2.2.x, google_fonts 6.1.x
**Storage**: Cloud Firestore (users, driver_profiles, documents), Firebase Storage (avatars, documents), SharedPreferences (onboarding flag)
**Testing**: flutter_test (unit + widget tests)
**Target Platform**: Android + iOS (mobile)
**Project Type**: Multi-app mobile (Customer App + Driver App + Admin Panel, shared codebase)
**Performance Goals**: Splash → navigation in <3 seconds (SC-010), smooth 60fps carousel transitions (SC-002)
**Constraints**: Full RTL/LTR support, light/dark theme, no hardcoded strings, GetX-only state management
**Scale/Scope**: 7 screens, 4 controllers, 3 models, 3 services, ~40 localization keys per language

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

The project constitution is not yet ratified (template placeholders only). No gates to enforce. Proceeding with project conventions established in CLAUDE.md:

| Convention | Status | Notes |
|-----------|--------|-------|
| GetX for all state management | PASS | All controllers use GetX. AuthController is permanent, others use lazyPut in bindings |
| Feature-first folder structure | PASS | Features organized under `lib/features/{feature}/` |
| No hardcoded strings | PASS | All text uses GetX `.tr` localization |
| No hardcoded prices/config | N/A | No pricing in this feature |
| Firebase-only backend | PASS | Auth, Firestore, Storage — no REST APIs |
| RTL/LTR support | PASS | All screens designed for both directions |
| Wallets/transactions Cloud Functions only | N/A | No wallet operations in this feature |

**Post-Phase 1 re-check**: All design decisions remain compliant. No violations.

## Project Structure

### Documentation (this feature)

```text
specs/003-splash-onboarding/
├── plan.md              # This file
├── research.md          # Phase 0 output — 12 research decisions
├── data-model.md        # Phase 1 output — 4 entities, 6 enums
├── quickstart.md        # Phase 1 output — setup & file structure guide
├── contracts/
│   └── navigation.md    # Phase 1 output — route definitions & flow
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── models/
│   │   ├── user_model.dart               # UserModel (Firestore serialization)
│   │   ├── driver_profile_model.dart     # DriverProfileModel
│   │   └── document_model.dart           # DocumentModel
│   ├── services/
│   │   ├── auth_service.dart             # Firebase Phone Auth wrapper
│   │   ├── firestore_service.dart        # Firestore CRUD for users/drivers/docs
│   │   ├── storage_service.dart          # Firebase Storage upload helper
│   │   └── firebase_service.dart         # (existing) Firebase Core init
│   ├── routes/
│   │   ├── app_routes.dart               # (existing) Route constants
│   │   ├── customer_pages.dart           # GetPage list for customer app
│   │   └── driver_pages.dart             # GetPage list for driver app
│   ├── theme/
│   │   └── app_theme.dart                # (existing) Theme system
│   ├── translations/
│   │   └── app_translations.dart         # (existing, extended) +onboarding/auth keys
│   ├── widgets/
│   │   ├── app_button.dart               # (existing)
│   │   ├── app_text_field.dart           # (existing)
│   │   └── ...                           # (existing widgets)
│   └── app_initializer.dart              # (existing, minor updates)
│
├── features/
│   ├── splash/
│   │   ├── screens/
│   │   │   └── splash_screen.dart
│   │   ├── controllers/
│   │   │   └── splash_controller.dart
│   │   └── bindings/
│   │       └── splash_binding.dart
│   │
│   ├── onboarding/
│   │   ├── screens/
│   │   │   └── onboarding_screen.dart
│   │   ├── widgets/
│   │   │   ├── onboarding_page.dart       # Shared slide widget (FR-010)
│   │   │   └── page_indicator.dart        # Pagination dots (FR-009)
│   │   ├── controllers/
│   │   │   └── onboarding_controller.dart
│   │   ├── bindings/
│   │   │   └── onboarding_binding.dart
│   │   └── data/
│   │       └── onboarding_data.dart       # OnboardingSlide definitions
│   │
│   ├── auth/
│   │   ├── screens/
│   │   │   ├── phone_login_screen.dart
│   │   │   ├── otp_verification_screen.dart
│   │   │   └── profile_setup_screen.dart
│   │   ├── widgets/
│   │   │   ├── otp_input_field.dart        # 4-digit OTP input (FR-016)
│   │   │   ├── phone_input_field.dart      # +20 Egypt phone input (FR-011)
│   │   │   └── social_login_buttons.dart   # Google/Facebook (deferred, FR-014)
│   │   ├── controllers/
│   │   │   ├── auth_controller.dart        # (expand from stub)
│   │   │   └── profile_setup_controller.dart
│   │   └── bindings/
│   │       └── profile_setup_binding.dart
│   │
│   └── driver_registration/
│       ├── screens/
│       │   ├── driver_registration_screen.dart
│       │   └── pending_approval_screen.dart
│       ├── widgets/
│       │   ├── document_upload_item.dart    # Single document row (FR-027)
│       │   └── step_progress_indicator.dart # 4-step progress bar (FR-025)
│       ├── controllers/
│       │   └── driver_registration_controller.dart
│       └── bindings/
│           └── driver_registration_binding.dart
│
├── main_customer.dart                      # (update with GetPages)
├── main_driver.dart                        # (update with GetPages)
└── main_admin.dart                         # (no changes for this spec)

test/
├── core/
│   └── models/
│       ├── user_model_test.dart
│       ├── driver_profile_model_test.dart
│       └── document_model_test.dart
├── features/
│   ├── splash/
│   │   └── splash_controller_test.dart
│   ├── onboarding/
│   │   ├── onboarding_controller_test.dart
│   │   └── onboarding_page_test.dart
│   ├── auth/
│   │   ├── auth_controller_test.dart
│   │   ├── otp_input_field_test.dart
│   │   └── profile_setup_controller_test.dart
│   └── driver_registration/
│       └── driver_registration_controller_test.dart
└── helpers/
    └── getx_test_helpers.dart              # (existing)

assets/
├── images/
│   ├── logo/
│   │   └── bikeride_logo.png
│   ├── onboarding/
│   │   ├── customer_speed.png
│   │   ├── customer_bidding.png
│   │   ├── customer_delivery.png
│   │   ├── driver_freedom.png
│   │   ├── driver_trust.png
│   │   └── driver_earnings.png
│   └── backgrounds/
│       └── cairo_map.png
└── lang/
    ├── ar.json                             # (existing)
    └── en.json                             # (existing)
```

**Structure Decision**: Feature-first Flutter structure following CLAUDE.md conventions. Shared models and services live in `lib/core/`. Feature-specific screens, controllers, bindings, and widgets live under `lib/features/{feature}/`. Both Customer and Driver apps share the same codebase with different entry points (`main_customer.dart`, `main_driver.dart`) and route configurations.

## Complexity Tracking

No constitution violations to justify. Design follows established project patterns.

## Design Decisions Summary

| # | Decision | Rationale | See |
|---|----------|-----------|-----|
| R-001 | Firebase Phone Auth direct integration in AuthController | GetX reactive state maps to multi-step auth flow | research.md |
| R-002 | Built-in PageView for onboarding carousel | No third-party package needed for 3-page swipe | research.md |
| R-003 | SharedPreferences for first-launch flag | Lightweight, already a dependency | research.md |
| R-004 | Custom OTP input widget (4 TextFields) | Exact design match, full control over styling | research.md |
| R-005 | Firebase Storage for image uploads, 1024px max resize | Standard approach, image_picker handles resize | research.md |
| R-006 | Add firebase_auth, cloud_firestore, firebase_storage, image_picker | Required packages not yet in pubspec | research.md |
| R-007 | Egypt phone validation: 11 digits, 010/011/012/015 prefixes | Catches invalid numbers before Firebase API call | research.md |
| R-008 | 30-second client-side OTP timer with Timer.periodic | Visual UX pattern, actual expiry is server-side | research.md |
| R-009 | 2-second minimum splash with parallel init checks | Brand visibility + SC-010 compliance (<3s total) | research.md |
| R-010 | Third slide: "Fast Delivery" (customer), "Earn More" (driver) | Completes value proposition trilogy | research.md |
| R-011 | Social login shows "Coming Soon" snackbar | Spec explicitly defers implementation | research.md |
| R-012 | Static Cairo map image with red gradient overlay | Avoids Maps SDK for decorative background | research.md |

## Stitch Design Reference

| Screen | Stitch File | Key Design Elements |
|--------|-------------|-------------------|
| Customer Onboarding Slide 1 | `stitch/onboarding_speed_and_agility/screen.png` | "Beat the Traffic", motorcycle rider illustration, Skip top-right, pagination dots, Next button |
| Customer Onboarding Slide 2 | `stitch/onboarding_fair_bidding/code.html` | "Your Price, Your Choice" with "Choice" in primary, handshake illustration, Get Started button |
| Driver Onboarding Slide 1 | `stitch/driver_onboarding_freedom/code.html` | "Be Your Own Boss" with "Boss" in primary, delivery driver illustration |
| Driver Onboarding Slide 2 | `stitch/driver_onboarding_trust/code.html` | "Safe & Reliable", motorcycle+shield illustration |
| Phone Login | `stitch/authentication_phone_login/screen.png` | Cairo map BG with red overlay, "Yalla! Let's get moving", +20 phone input, Google/Facebook buttons |
| OTP Verification | `stitch/authentication_otp_verification/code.html` | 4 digit inputs (h-16 w-14), 30s timer, Verify button |
| Profile Setup | `stitch/authentication_profile_setup/code.html` | Avatar upload (h-32 w-32), name input, language radio grid |
| Driver Registration | `stitch/driver_registration_documents/code.html` | 4-step progress, vehicle form, 4 document items with status |
| Pending Status | `stitch/driver_application_pending_status/code.html` | Status timeline, Contact Support + Back to Home buttons |

## Artifacts Generated

| Artifact | Path | Description |
|----------|------|-------------|
| Research | `specs/003-splash-onboarding/research.md` | 12 technical decisions with rationale |
| Data Model | `specs/003-splash-onboarding/data-model.md` | 4 entities, 6 enums, relationships, validation rules |
| Navigation Contract | `specs/003-splash-onboarding/contracts/navigation.md` | Route table, navigation flows, bindings, arguments |
| Quickstart | `specs/003-splash-onboarding/quickstart.md` | Setup guide, dependencies, file structure |
| Plan | `specs/003-splash-onboarding/plan.md` | This file — implementation plan |
