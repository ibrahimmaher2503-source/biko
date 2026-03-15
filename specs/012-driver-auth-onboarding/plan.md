# Implementation Plan: Driver Authentication & Onboarding

**Branch**: `012-driver-auth-onboarding` | **Date**: 2026-03-02 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/012-driver-auth-onboarding/spec.md`

## Summary

Implement the full driver authentication and onboarding module for the BikeRide Driver app. The core discovery from research is that **~90% of the implementation already exists** — onboarding, phone auth, OTP, profile setup, driver registration, and pending approval screens are all functional. The remaining work focuses on three gaps: (1) Facebook Sign-In integration, (2) app-type-specific onboarding persistence, and (3) Contact Support button on the pending approval screen. This is an incremental feature completion, not a ground-up build.

## Technical Context

**Language/Version**: Dart 3.x (Flutter 3.x)
**Primary Dependencies**: GetX 4.6.6, Firebase Auth 5.x, Cloud Firestore 5.x, Firebase Storage 12.x, google_sign_in 6.2.1, flutter_facebook_auth (new), image_picker 1.x, shared_preferences 2.x, url_launcher 6.x
**Storage**: Cloud Firestore (users, driver_profiles, documents), Firebase Storage (avatars, documents), SharedPreferences (onboarding flags)
**Testing**: flutter test (widget tests, unit tests)
**Target Platform**: Android + iOS (mobile)
**Project Type**: Mobile app (Flutter, feature-first architecture)
**Performance Goals**: 60fps UI, auth completion <30s excluding user input
**Constraints**: Egypt market (Arabic RTL default, +20 phone prefix, EGP currency)
**Scale/Scope**: ~10 files modified, 3 new functional areas (Facebook auth, onboarding persistence, contact support)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Firebase-Only Architecture | PASS | All auth via Firebase Auth. No external backends. Facebook login uses Firebase Auth provider. |
| II. GetX Exclusive State Management | PASS | AuthController uses `.obs`/`Obx()`. New Facebook method follows same pattern. `Get.lazyPut()` in bindings. |
| III. Feature-First Architecture | PASS | Changes scoped to `features/auth/`, `features/onboarding/`, `features/driver_registration/`, `features/splash/`, and `core/`. No cross-feature imports. |
| IV. Bilingual RTL-First | PASS | All strings use `.tr` translation keys. AR+EN translations exist for all screens. No hardcoded text. |
| V. Config-Driven Business Logic | PASS | No business values hardcoded. Feature is auth/onboarding — no pricing or commission logic involved. |
| VI. Server-Side Financial Security | N/A | No financial operations in this feature. |
| VII. Theme-Aware Design System | PASS | Existing screens use `Theme.of(context)` and `AppColorsExtension`. New code will follow same pattern. |

**Pre-design gate**: PASS — no violations.

**Post-design re-check**: PASS — Facebook auth uses Firebase Auth provider (Principle I), AuthController pattern (Principle II), feature-scoped files (Principle III).

## Project Structure

### Documentation (this feature)

```text
specs/012-driver-auth-onboarding/
├── spec.md              # Feature specification
├── plan.md              # This file
├── research.md          # Phase 0: existing code audit + research
├── data-model.md        # Phase 1: entity reference (all pre-existing)
├── quickstart.md        # Phase 1: dev setup guide
├── checklists/
│   └── requirements.md  # Spec quality checklist
└── tasks.md             # Phase 2 output (created by /speckit.tasks)
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── models/
│   │   └── enums.dart                          # MODIFY: add signingInWithFacebook
│   ├── services/
│   │   └── auth_service.dart                   # MODIFY: add signInWithFacebook()
│   ├── routes/
│   │   └── driver_pages.dart                   # REVIEW: already has all routes
│   └── translations/
│       └── app_translations.dart               # MODIFY: add Facebook error keys
│
├── features/
│   ├── auth/
│   │   ├── controllers/
│   │   │   └── auth_controller.dart            # MODIFY: add signInWithFacebook()
│   │   └── widgets/
│   │       └── social_login_buttons.dart       # MODIFY: wire Facebook button
│   │
│   ├── onboarding/
│   │   └── controllers/
│   │       └── onboarding_controller.dart      # MODIFY: app-type-specific key
│   │
│   ├── splash/
│   │   └── controllers/
│   │       └── splash_controller.dart          # MODIFY: app-type-specific key check
│   │
│   └── driver_registration/
│       └── screens/
│           └── pending_approval_screen.dart    # MODIFY: Contact Support button
│
├── pubspec.yaml                                # MODIFY: add flutter_facebook_auth

android/
└── app/src/main/AndroidManifest.xml            # MODIFY: Facebook SDK config

ios/
└── Runner/Info.plist                           # MODIFY: Facebook SDK config

test/
└── features/
    └── auth/                                   # NEW: auth flow tests
```

**Structure Decision**: Existing feature-first structure. No new directories needed. All changes are modifications to existing files plus platform configuration.

## Implementation Phases

### Phase A: Facebook Sign-In Core (P1)

**Goal**: Add full Facebook authentication as an alternative sign-in method.

**Tasks**:

1. **Add dependency**: Add `flutter_facebook_auth` to `pubspec.yaml`, run `flutter pub get`

2. **Update AuthState enum**: Add `signingInWithFacebook` to `lib/core/models/enums.dart`

3. **Add AuthService method**: Add `signInWithFacebook()` to `lib/core/services/auth_service.dart`
   - Follow existing `signInWithGoogle()` pattern exactly
   - Login with Facebook → get access token → create Firebase credential → sign in
   - Return `UserCredential?` (null if user cancelled)

4. **Add AuthController method**: Add `signInWithFacebook()` to `lib/features/auth/controllers/auth_controller.dart`
   - Follow existing `signInWithGoogle()` pattern exactly
   - Set `_authState` to `signingInWithFacebook` during process
   - Call `_navigateAfterAuth()` on success
   - Show error snackbar on failure

5. **Wire SocialLoginButtons**: Update `lib/features/auth/widgets/social_login_buttons.dart`
   - Replace `_showComingSoon()` with `authController.signInWithFacebook()`
   - Add loading state for Facebook button (matching Google button pattern)

6. **Add translations**: Add Facebook-specific error key to `app_translations.dart`
   - `error.facebook_sign_in_failed` in AR and EN

### Phase B: Platform Configuration (P1)

**Goal**: Configure Android and iOS for Facebook SDK.

**Tasks**:

1. **Android configuration**: Update `AndroidManifest.xml`
   - Add Facebook App ID meta-data
   - Add Facebook activity declarations
   - Add Chrome Custom Tabs activity

2. **iOS configuration**: Update `Info.plist`
   - Add Facebook App ID and display name
   - Add Facebook URL scheme
   - Add `LSApplicationQueriesSchemes` for Facebook

3. **Manual steps** (documented, not automatable):
   - Create Facebook App at developers.facebook.com
   - Configure Android platform (package name, key hash)
   - Configure iOS platform (bundle ID)
   - Enable Facebook provider in Firebase Console
   - Enter App ID and App Secret in Firebase Console

### Phase C: Onboarding Persistence Fix (P2)

**Goal**: Make onboarding "seen" flag app-type-specific.

**Tasks**:

1. **Update OnboardingController**: In `lib/features/onboarding/controllers/onboarding_controller.dart`
   - Change SharedPreferences key from `onboarding_completed` to `onboarding_completed_{appType}`
   - Read `appType` from `Get.arguments` (already passed as 'customer' or 'driver')

2. **Update SplashController**: In `lib/features/splash/controllers/splash_controller.dart`
   - Determine app type from entry point context
   - Check `onboarding_completed_driver` instead of `onboarding_completed`

### Phase D: Contact Support (P2)

**Goal**: Implement functional "Contact Support" button on pending approval screen.

**Tasks**:

1. **Update PendingApprovalScreen**: In `lib/features/driver_registration/screens/pending_approval_screen.dart`
   - Replace TODO with `url_launcher` call
   - Open WhatsApp with pre-filled message containing driver context
   - Add translation keys for support message template
   - Fallback: if WhatsApp not installed, open SMS or email

### Phase E: Testing & Verification (P3)

**Goal**: Verify the complete driver flow end-to-end.

**Tasks**:

1. **Widget tests**: Test Facebook sign-in button states, onboarding persistence, contact support
2. **Integration test**: Full flow: splash → onboarding → auth → profile → registration → pending
3. **RTL verification**: Confirm all screens render correctly in Arabic
4. **Design verification**: Compare screens against stitch designs

## Complexity Tracking

> No constitution violations found. No complexity justifications needed.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| (none) | — | — |
