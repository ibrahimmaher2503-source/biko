# Implementation Plan: Redesign Screen UIs with Theme Compliance & Skip OTP

**Branch**: `004-redesign-ui-skip-otp` | **Date**: 2026-03-01 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/004-redesign-ui-skip-otp/spec.md`

## Summary

Redesign all 7 screens (Splash, Onboarding, PhoneLogin, OtpVerification, ProfileSetup, DriverRegistration, PendingApproval) to use the AppTheme system exclusively, eliminating ~50+ hardcoded color values, ~21 hardcoded BorderRadius calls, ~16 bare button widgets, and ~5 bare TextField widgets. Extend AppTheme with semantic surface/border/status colors via ThemeExtension. Add AppButton `filled` variant with trailing icon support. Add a single-flag OTP bypass for development that skips Firebase Phone Auth entirely.

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.x
**Primary Dependencies**: GetX (state/navigation/DI), Firebase Auth (OTP flow), Google Fonts
**Storage**: SharedPreferences (onboarding flag), Cloud Firestore (user profiles)
**Testing**: `flutter test` (unit + widget tests), `flutter analyze` (static analysis)
**Target Platform**: Android + iOS (mobile), Flutter Web (admin)
**Project Type**: Multi-app mobile platform (Customer + Driver + Admin)
**Performance Goals**: 60 fps, no jank during theme switching
**Constraints**: Must support RTL (Arabic/Cairo font), light + dark modes
**Scale/Scope**: 7 screens, 7 custom widgets, 1 theme file, 1 constants file, 2 controllers

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Constitution is template only (not ratified). Using CLAUDE.md conventions as governance reference:

- **GetX only**: All state management uses GetX — no change needed. Pass.
- **No hardcoded strings**: All user-facing text uses `.tr` localization — no new strings needed (no new screens). Pass.
- **Feature-first structure**: All changes are within existing feature folders and `core/`. Pass.
- **No hardcoded prices/config**: Not applicable to UI redesign. Pass.
- **RTL support**: All screens already support RTL — redesign preserves this. Pass.

No violations. Proceeding to Phase 0.

## Project Structure

### Documentation (this feature)

```text
specs/004-redesign-ui-skip-otp/
├── plan.md              # This file
├── research.md          # Phase 0 output — 8 research decisions
├── data-model.md        # Phase 1 output — theme extension model
├── quickstart.md        # Phase 1 output — verification steps
├── contracts/
│   └── navigation.md    # Phase 1 output — OTP bypass navigation flow
└── tasks.md             # Phase 2 output (created by /speckit.tasks)
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── constants/
│   │   ├── app_constants.dart    # MODIFY: add radiusSm, remove duplicate radius values
│   │   └── dev_config.dart       # CREATE: OTP bypass flag
│   ├── theme/
│   │   └── app_theme.dart        # MODIFY: add AppColorsExtension ThemeExtension
│   └── widgets/
│       ├── app_button.dart       # MODIFY: add filled variant, enhance trailing icon
│       └── app_text_field.dart   # NO CHANGE (already theme-compliant)
│
├── features/
│   ├── splash/
│   │   ├── controllers/
│   │   │   └── splash_controller.dart    # MODIFY: dev bypass in auth check
│   │   └── screens/
│   │       └── splash_screen.dart        # MODIFY: replace bare FilledButton
│   ├── onboarding/
│   │   ├── widgets/
│   │   │   ├── page_indicator.dart       # MODIFY: replace hardcoded colors
│   │   │   └── onboarding_page.dart      # MINOR: already mostly compliant
│   │   └── screens/
│   │       └── onboarding_screen.dart    # MODIFY: replace bare buttons, hardcoded styles
│   ├── auth/
│   │   ├── controllers/
│   │   │   └── auth_controller.dart      # MODIFY: add OTP bypass branch
│   │   ├── widgets/
│   │   │   ├── phone_input_field.dart    # MODIFY: replace all hardcoded colors
│   │   │   ├── otp_input_field.dart      # MODIFY: replace all hardcoded colors
│   │   │   └── social_login_buttons.dart # MODIFY: replace border colors (keep brand colors)
│   │   └── screens/
│   │       ├── phone_login_screen.dart       # MODIFY: replace bare buttons, colors
│   │       ├── otp_verification_screen.dart  # MODIFY: replace bare buttons, colors
│   │       └── profile_setup_screen.dart     # MODIFY: replace bare TextField, colors
│   └── driver_registration/
│       ├── widgets/
│       │   ├── step_progress_indicator.dart  # MODIFY: replace hardcoded radius
│       │   └── document_upload_item.dart     # MODIFY: replace all hardcoded colors
│       └── screens/
│           ├── driver_registration_screen.dart  # MODIFY: replace bare TextFields, colors
│           └── pending_approval_screen.dart     # MODIFY: replace bare buttons, colors
```

**Structure Decision**: All changes are modifications to existing files within the established feature-first structure. One new file (`dev_config.dart`) is created in `lib/core/constants/`.

## Complexity Tracking

No constitution violations to justify.
