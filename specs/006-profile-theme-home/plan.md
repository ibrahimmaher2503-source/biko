# Implementation Plan: Profile Auto-Fill, Theme Chooser, Debug Logging & Home Page

**Branch**: `006-profile-theme-home` | **Date**: 2026-03-01 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/006-profile-theme-home/spec.md`

## Summary

Four enhancements across the profile setup and home experience: (1) auto-fill user name and avatar from Google Auth on the profile setup screen, (2) add a Light/Dark theme selector on the profile setup screen with persistence via SharedPreferences and Firestore, (3) create a centralized snackbar helper that prints messages to the debug console in development mode, and (4) build the foundational customer home page with greeting header, map placeholder, and Ride/Delivery service type selector.

## Technical Context

**Language/Version**: Dart 3.9.2 / Flutter
**Primary Dependencies**: GetX 4.6.6, Firebase Auth 5.x, Cloud Firestore 5.x, google_sign_in 6.2.1, shared_preferences 2.2.0, cached_network_image 3.3.1
**Storage**: Cloud Firestore (user documents) + SharedPreferences (local theme cache)
**Testing**: Manual testing (no test tasks per spec)
**Target Platform**: Android + iOS
**Project Type**: Mobile app (Flutter)
**Performance Goals**: Theme switch with zero visible delay, home page load under 2 seconds
**Constraints**: Arabic RTL default, bilingual UI
**Scale/Scope**: 4 user stories, ~10 files modified/created

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Constitution is blank (template only) — no gates to check. Proceeding with standard project conventions from CLAUDE.md:

- [x] Uses GetX for state management (no Provider/Bloc)
- [x] No hardcoded strings — all through translations
- [x] Feature-first folder structure
- [x] `Get.lazyPut()` in bindings (not `Get.put()` for feature controllers)
- [x] No direct wallet/transaction writes from Flutter
- [x] All screens tested in Arabic RTL

## Project Structure

### Documentation (this feature)

```text
specs/006-profile-theme-home/
├── plan.md              # This file
├── research.md          # Phase 0: 8 research decisions
├── data-model.md        # Phase 1: UserModel + SharedPreferences schema
├── quickstart.md        # Phase 1: Prerequisites and testing checklist
└── tasks.md             # Phase 2 output (via /speckit.tasks)
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── app_initializer.dart          # MODIFY: Load theme from SharedPreferences
│   ├── models/
│   │   └── user_model.dart           # MODIFY: Add theme field
│   ├── services/
│   │   └── auth_service.dart         # READ ONLY: currentUser for Google data
│   ├── translations/
│   │   └── app_translations.dart     # MODIFY: Add theme + home strings
│   ├── widgets/
│   │   └── app_snackbar.dart         # CREATE: Debug-logging snackbar wrapper
│   └── routes/
│       └── customer_pages.dart       # MODIFY: Add home route
│
├── features/
│   ├── auth/
│   │   ├── controllers/
│   │   │   └── profile_setup_controller.dart  # MODIFY: Google auto-fill + theme
│   │   └── screens/
│   │       └── profile_setup_screen.dart      # MODIFY: Theme selector UI
│   └── home/
│       ├── screens/
│       │   └── customer_home_screen.dart       # CREATE: Home page UI
│       ├── controllers/
│       │   └── home_controller.dart            # CREATE: Home state management
│       └── bindings/
│           └── home_binding.dart               # CREATE: Home DI binding
│
└── main_customer.dart                # MODIFY: Use restored ThemeMode
```

**Structure Decision**: Follows existing feature-first pattern. Home page gets its own feature module (`lib/features/home/`) consistent with auth, onboarding, splash features.

## Implementation Approach

### Step 1: Data model update
Add `theme` field to `UserModel` — constructor, `fromJson`, `toJson`, `copyWith`.

### Step 2: Translation strings
Add all new strings for theme chooser, home page, and debug snackbar in both Arabic and English.

### Step 3: Centralized snackbar helper
Create `AppSnackbar.show()` that wraps `Get.snackbar()` with `debugPrint()` when `kDebugMode` is true. Replace existing `Get.snackbar()` calls across the codebase.

### Step 4: Google auto-fill + theme on profile setup
In `ProfileSetupController.onInit()`, read `AuthService.currentUser?.displayName` and `photoURL` to pre-fill name and avatar. Add `selectedTheme` observable and `selectTheme()` method. Persist theme to SharedPreferences immediately, and to Firestore on profile complete.

### Step 5: Theme selector UI
Add theme toggle (Light/Dark) to `ProfileSetupScreen` below the language selector. Reuse the pill-style toggle pattern.

### Step 6: Theme restoration on app start
In `AppInitializer.init()`, read `theme_mode` from SharedPreferences before `runApp()`. Pass restored `ThemeMode` to the app widget. Update `main_customer.dart` to accept and use the restored theme mode.

### Step 7: Customer home page
Create `HomeController` (loads user data, manages service type selection), `HomeBinding`, and `CustomerHomeScreen`. Register route in `CustomerPages`. Layout: greeting header with avatar, map placeholder, Ride/Delivery selector.

## Complexity Tracking

No violations to justify — all implementations follow existing patterns with minimal new concepts.
