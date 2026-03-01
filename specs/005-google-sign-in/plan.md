# Implementation Plan: Google Sign-In

**Branch**: `005-google-sign-in` | **Date**: 2026-03-01 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/005-google-sign-in/spec.md`

## Summary

Replace the non-functional "Coming Soon" Google button on the phone login screen with a working Google Sign-In flow. Uses the `google_sign_in` Flutter package with Firebase Auth's Google provider. Google-authenticated users follow the same post-auth navigation as phone OTP users (new → profile setup, returning → home). Requires adding `email` and `authProviders` fields to UserModel and a new `signingInWithGoogle` auth state.

## Technical Context

**Language/Version**: Dart 3.9.2 / Flutter (latest stable)
**Primary Dependencies**: `get: ^4.6.6`, `firebase_auth: ^5.0.0`, `cloud_firestore: ^5.0.0`, `google_sign_in` (to be added)
**Storage**: Cloud Firestore (users collection — add `email`, `auth_providers` fields)
**Testing**: `flutter_test` (widget tests)
**Target Platform**: Android + iOS (mobile apps only)
**Project Type**: Mobile app (Flutter)
**Performance Goals**: Google sign-in completes within 10 seconds; post-auth navigation within 3 seconds
**Constraints**: Must not break existing phone OTP flow; RTL/LTR support required; localized error messages (AR/EN)
**Scale/Scope**: 2 apps affected (Customer, Driver); ~7 files modified; 0 new files created

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Constitution is not yet defined (blank template). No gates to enforce. Proceeding with standard best practices:
- GetX for state management (per CLAUDE.md)
- Feature-first folder structure (per CLAUDE.md)
- No hardcoded strings — all through translations (per CLAUDE.md)
- Firebase Auth for authentication (per CLAUDE.md)

**Post-Phase 1 re-check**: Design follows all CLAUDE.md constraints. No violations.

## Project Structure

### Documentation (this feature)

```text
specs/005-google-sign-in/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0 — research decisions
├── data-model.md        # Phase 1 — entity changes
├── quickstart.md        # Phase 1 — setup guide
└── checklists/
    └── requirements.md  # Spec quality checklist
```

### Source Code (files to modify)

```text
lib/
├── core/
│   ├── models/
│   │   ├── enums.dart                    # Add signingInWithGoogle to AuthState
│   │   └── user_model.dart               # Add email, authProviders fields
│   ├── services/
│   │   └── auth_service.dart             # Add signInWithGoogle(), signOutGoogle()
│   └── translations/
│       └── app_translations.dart         # Add Google sign-in error strings
├── features/
│   └── auth/
│       ├── controllers/
│       │   └── auth_controller.dart      # Add signInWithGoogle(), update signOut()
│       └── widgets/
│           └── social_login_buttons.dart  # Wire Google button to controller
└── pubspec.yaml                          # Add google_sign_in dependency
```

**Structure Decision**: No new files needed. All changes are additions to existing files, following the established feature-first architecture.

## Implementation Approach

### Step 1: Dependencies & Configuration

Add `google_sign_in` package. Developer must manually:
- Enable Google provider in Firebase Console
- Add SHA-1 fingerprint for Android
- Add reversed client ID URL scheme for iOS

### Step 2: Model Updates

- Add `signingInWithGoogle` to `AuthState` enum
- Add `email` (String?) and `authProviders` (List<String>) to `UserModel`
- Update `fromJson`/`toJson`/`copyWith` accordingly

### Step 3: Service Layer

Add to `AuthService`:
- `signInWithGoogle()`: Handles GoogleSignIn flow → Firebase credential → signInWithCredential
- `signOutGoogle()`: Signs out from both Google and Firebase
- Returns `UserCredential` on success, `null` on cancel, throws on error

### Step 4: Controller Layer

Add to `AuthController`:
- `signInWithGoogle()`: Sets state to `signingInWithGoogle`, calls AuthService, handles cancel/error/success, calls existing `_navigateAfterAuth()`
- Update `signOut()` to also call Google sign-out
- Update `isLoading` getter to include `signingInWithGoogle` state

### Step 5: UI Wiring

Update `SocialLoginButtons`:
- Replace `_showComingSoon()` for Google button with `AuthController.signInWithGoogle()`
- Add loading indicator on Google button when `authState == signingInWithGoogle`
- Facebook button remains unchanged

### Step 6: Translations

Add to `app_translations.dart`:
- `error.google_sign_in_failed` (AR/EN)
- `error.google_sign_in_cancelled` (AR/EN) — optional, may not show to user

## Complexity Tracking

No complexity violations. All changes are minimal additions to existing files.
