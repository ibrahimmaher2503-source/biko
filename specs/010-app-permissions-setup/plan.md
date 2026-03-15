# Implementation Plan: App Permissions Setup

**Branch**: `010-app-permissions-setup` | **Date**: 2026-03-02 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/010-app-permissions-setup/spec.md`

## Summary

Set up push notification infrastructure (Firebase Cloud Messaging +
local notifications) and declare Android platform permissions for
location and notifications. Create an `FcmService` that requests
notification permission after login, saves the device token to
Firestore, handles foreground/background message delivery, and
cleans up on logout. Declare Android manifest permissions for GPS
(foreground + background) and notification runtime permission
(Android 13+). Create notification channels for trip updates and
promotions.

## Technical Context

**Language/Version**: Dart 3.x (Flutter), Android SDK (manifest XML)
**Primary Dependencies**: GetX (state), firebase_messaging (FCM),
  flutter_local_notifications (foreground display + channels),
  firebase_auth (current user), cloud_firestore (token storage)
**Storage**: Cloud Firestore (`users/{uid}/fcm_token` field)
**Testing**: Manual testing on Android device/emulator + iOS simulator
**Target Platform**: Android + iOS
**Project Type**: Mobile app (Flutter)
**Performance Goals**: Notification delivery <5s, token save <3s
**Constraints**: Bilingual AR/EN, permission prompt after login only,
  no API keys in source, background GPS for driver only
**Scale/Scope**: 1 new service file, ~5 files modified, ~8 translation
  keys, 6 Android permission declarations

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| # | Principle | Status | Notes |
|---|-----------|--------|-------|
| I | Firebase-Only Architecture | PASS | Uses Firebase Cloud Messaging (approved Push service). Token stored in Firestore (approved Database). No custom backend. |
| II | GetX Exclusive | PASS | AuthController (GetX) handles FCM init/cleanup. FcmService is a static utility (like MapService, FirebaseService) — not a state management class. No Provider/Bloc/Riverpod. |
| III | Feature-First Architecture | PASS | FcmService in `lib/core/services/` (shared infrastructure). No new feature module created — this is platform plumbing used across all features. AuthController modifications stay in its existing location. |
| IV | Bilingual RTL-First | PASS | All permission-related user-facing strings via `.tr` keys in both Arabic and English. ~8 new translation keys. |
| V | Config-Driven Business Logic | N/A | No business parameters. Notification channel names are UX constants, not tunable business values. |
| VI | Server-Side Financial Security | N/A | No financial operations. |
| VII | Theme-Aware Design System | N/A | No new UI widgets. Permission prompts are OS-native dialogs. |

**Gate result**: ALL PASS — no violations.

## Project Structure

### Documentation (this feature)

```text
specs/010-app-permissions-setup/
├── plan.md              # This file
├── research.md          # Phase 0: 10 research decisions
├── data-model.md        # Phase 1: FCM service methods, manifest permissions, translations
├── quickstart.md        # Phase 1: setup guide + test scenarios
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── services/
│   │   └── fcm_service.dart              # CREATE: FCM init, token management, message handling
│   ├── translations/
│   │   └── app_translations.dart         # MODIFY: +8 permission translation keys (AR + EN)
│   └── app_initializer.dart              # MODIFY: Register background handler setup
│
├── features/
│   └── auth/
│       └── controllers/
│           └── auth_controller.dart      # MODIFY: Call FcmService after login, clear on logout
│
├── main_customer.dart                    # MODIFY: Register background message handler
└── main_driver.dart                      # MODIFY: Register background message handler

android/
└── app/
    └── src/
        └── main/
            └── AndroidManifest.xml       # MODIFY: Add 6 permission declarations

pubspec.yaml                              # MODIFY: Add firebase_messaging, flutter_local_notifications
```

**Structure Decision**: No new directories or feature modules. This
is core infrastructure (FCM service) plus platform configuration
(Android manifest). FcmService is a core service because it's used
by both customer and driver apps across all features that send
notifications.

## Complexity Tracking

> No violations — table empty.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| (none) | — | — |
