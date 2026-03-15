# Tasks: App Permissions Setup

**Input**: Design documents from `/specs/010-app-permissions-setup/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Tests**: Not requested — no test tasks included.

**Organization**: Tasks are grouped by user story. US2 and US3 are manifest-only stories whose implementation is covered by foundational tasks (see Dependencies section).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Add required package dependencies for push notifications and local notification display

- [X] T001 Add firebase_messaging ^15.1.0 and flutter_local_notifications ^18.0.0 dependencies to pubspec.yaml

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Platform configuration and translations that MUST be complete before user story implementation begins

**CRITICAL**: No user story work can begin until this phase is complete

- [X] T002 [P] Add 8 permission-related translation keys (AR + EN) to lib/core/translations/app_translations.dart per data-model.md Translation Keys table (permission.notification_title, permission.notification_body, permission.location_denied, permission.location_settings, permission.open_settings, permission.background_location, permission.background_denied, notification.tracking_active)
- [X] T003 [P] Add 6 Android permission declarations (ACCESS_FINE_LOCATION, ACCESS_COARSE_LOCATION, POST_NOTIFICATIONS, ACCESS_BACKGROUND_LOCATION, FOREGROUND_SERVICE, FOREGROUND_SERVICE_LOCATION) to android/app/src/main/AndroidManifest.xml

**Checkpoint**: Dependencies installed, Android permissions declared, translation keys available. US2 (customer location) and US3 (driver location) are fully delivered by T002 + T003 — see Dependencies section.

---

## Phase 3: User Story 1 — Request Push Notification Permission (Priority: P1) MVP

**Goal**: Set up Firebase Cloud Messaging so users receive push notifications in foreground, background, and terminated states. Device token is saved to Firestore after login and cleared on logout.

**Independent Test**: Install app, login, grant notification permission when prompted, verify fcm_token is saved to users/{uid} in Firestore, send a test notification from Firebase Console, verify delivery in foreground (local banner), background (system tray), and terminated (system tray) states, logout, verify fcm_token is null in Firestore.

### Implementation for User Story 1

- [X] T004 [US1] Create FcmService static class with initialize() (request permission + get token + save + set up listeners), _saveToken(String token) (write to users/{uid}/fcm_token via FirestoreService), _setupTokenRefreshListener() (auto-save on refresh), _setupForegroundListener() (show local notification via FlutterLocalNotificationsPlugin), clearToken() (null Firestore field + delete local token), and top-level firebaseMessagingBackgroundHandler(RemoteMessage) function in lib/core/services/fcm_service.dart
- [X] T005 [P] [US1] Import fcm_service.dart and register firebaseMessagingBackgroundHandler via FirebaseMessaging.onBackgroundMessage() before runApp() in lib/main_customer.dart
- [X] T006 [P] [US1] Import fcm_service.dart and register firebaseMessagingBackgroundHandler via FirebaseMessaging.onBackgroundMessage() before runApp() in lib/main_driver.dart
- [X] T007 [US1] Initialize FlutterLocalNotificationsPlugin with default Android initialization settings for foreground notification display in lib/core/app_initializer.dart
- [X] T008 [US1] Call FcmService.initialize() after successful login in _navigateAfterAuth() and call FcmService.clearToken() before auth state cleanup in signOut() in lib/features/auth/controllers/auth_controller.dart

**Checkpoint**: Push notifications work end-to-end — permission requested after login, token saved to Firestore, foreground shows local banner, background/terminated shows in system tray, token refreshes auto-save, token cleared on logout.

---

## Phase 4: User Story 2 — Request Location Permission for Customer App (Priority: P1)

**Goal**: Android manifest declares foreground location permissions so existing runtime permission requests work correctly for customer GPS features (home map, pickup location).

**Independent Test**: Install customer app on Android, open home screen, verify location permission prompt appears, grant it, confirm map shows current device position. Deny permission, verify a friendly message appears with a link to device settings.

**Implementation Note**: This story is fully delivered by foundational tasks:
- **T003** declares ACCESS_FINE_LOCATION and ACCESS_COARSE_LOCATION in the Android manifest
- **T002** adds location-related translation keys (permission.location_denied, permission.location_settings, permission.open_settings)
- Runtime permission handling exists from earlier features (008-set-pickup-location, 009-maps-platform-setup)

No additional implementation tasks required.

**Checkpoint**: Customer app location permission prompt works correctly on Android devices.

---

## Phase 5: User Story 3 — Request Location Permission for Driver App (Priority: P1)

**Goal**: Android manifest declares background location and foreground service permissions so the driver app can track GPS position when minimized.

**Independent Test**: Install driver app on Android, login as driver, go online, grant foreground and background location permissions, minimize app, verify GPS position updates continue in Realtime Database every 3 seconds for at least 30 minutes.

**Implementation Note**: This story is fully delivered by foundational tasks:
- **T003** declares ACCESS_BACKGROUND_LOCATION, FOREGROUND_SERVICE, and FOREGROUND_SERVICE_LOCATION in the Android manifest
- **T002** adds driver-specific translation keys (permission.background_location, permission.background_denied, notification.tracking_active)
- Background location and foreground service implementation depends on existing geolocator infrastructure from earlier features

No additional implementation tasks required.

**Checkpoint**: Driver app background location tracking works with proper Android permissions declared.

---

## Phase 6: User Story 4 — Handle Notification Channels on Android (Priority: P2)

**Goal**: Create two Android notification channels (Trip Updates with high importance and sound, Promotions with default importance) so users can control notification types independently in device settings.

**Independent Test**: Install app, open Android Settings > Apps > BikeRide > Notifications, verify two channels are visible (Trip Updates, Promotions), send a trip notification and confirm it plays a sound, mute the Promotions channel in settings, send a promotional notification and confirm it arrives silently.

### Implementation for User Story 4

- [X] T009 [US4] Add setupNotificationChannels() method to FcmService that creates trip_updates channel (id: trip_updates, name: Trip Updates / AR: تحديثات الرحلة, importance: high, sound: yes, vibration: yes) and promotions channel (id: promotions, name: Promotions / AR: العروض, importance: default, sound: no, vibration: no) via FlutterLocalNotificationsPlugin in lib/core/services/fcm_service.dart
- [X] T010 [US4] Call FcmService.setupNotificationChannels() during app initialization (after FlutterLocalNotificationsPlugin is initialized) in lib/core/app_initializer.dart

**Checkpoint**: Two notification channels created at app startup, trip notifications use high-importance channel with sound, promotional notifications use default-importance channel without sound.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Validate all stories work together across both app variants

- [X] T011 Run all 16 manual test scenarios from quickstart.md to validate US1 (push notifications: foreground/background/terminated delivery, token save/refresh/cleanup), US2 (customer location prompt and denial handling), US3 (driver background location continuity), and US4 (notification channel separation and independent muting)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Setup (pubspec.yaml must have dependencies first)
- **US1 (Phase 3)**: Depends on Foundational (needs firebase_messaging package and translation keys)
- **US2 (Phase 4)**: Fully delivered by Foundational phase (T002 + T003) — no additional work
- **US3 (Phase 5)**: Fully delivered by Foundational phase (T002 + T003) — no additional work
- **US4 (Phase 6)**: Depends on US1 (extends FcmService created in T004)
- **Polish (Phase 7)**: Depends on all phases complete

### User Story Dependencies

- **US1 (P1)**: Depends only on Foundational phase — can start immediately after Phase 2
- **US2 (P1)**: No code tasks — delivered by Phase 2 foundational tasks (T002 translations + T003 manifest)
- **US3 (P1)**: No code tasks — delivered by Phase 2 foundational tasks (T002 translations + T003 manifest)
- **US4 (P2)**: Depends on US1 (extends FcmService with notification channels)

### Within User Story 1

1. T004 (create FcmService) — FIRST, all other US1 tasks depend on this
2. T005 + T006 + T007 (main files + app_initializer) — parallel, different files, all depend on T004
3. T008 (auth_controller integration) — LAST, depends on T004

### Within User Story 4

1. T009 (add setupNotificationChannels method) — depends on T004 (FcmService exists)
2. T010 (integrate into app startup) — depends on T009

### Foundational Task → Story Mapping

| Task | Permission / Key | Serves Story |
|------|-----------------|-------------|
| T002 | permission.notification_title, permission.notification_body | US1 |
| T002 | permission.location_denied, permission.location_settings, permission.open_settings | US2 |
| T002 | permission.background_location, permission.background_denied, notification.tracking_active | US3 |
| T003 | POST_NOTIFICATIONS | US1 |
| T003 | ACCESS_FINE_LOCATION, ACCESS_COARSE_LOCATION | US2 |
| T003 | ACCESS_BACKGROUND_LOCATION, FOREGROUND_SERVICE, FOREGROUND_SERVICE_LOCATION | US3 |

### Parallel Opportunities

```text
# Phase 2 — Foundational (parallel, different files):
T002: Add translation keys to app_translations.dart
T003: Add permissions to AndroidManifest.xml

# Phase 3 — US1 (parallel after T004 completes):
T005: Register handler in main_customer.dart
T006: Register handler in main_driver.dart
T007: Initialize plugin in app_initializer.dart
```

---

## Implementation Strategy

### MVP First (Setup + Foundational + US1)

1. Complete Phase 1: Setup (add dependencies)
2. Complete Phase 2: Foundational (translations + manifest — also delivers US2 + US3)
3. Complete Phase 3: US1 (FcmService + integration)
4. **STOP and VALIDATE**: Test push notifications end-to-end + verify location permissions work
5. At this point, US1 + US2 + US3 are all functional (3 of 4 stories)

### Full Delivery

1. Setup → Foundational → US1 → Validate MVP (delivers US1 + US2 + US3)
2. US4 (notification channels) → Validate channels
3. Polish → Run full quickstart.md test suite

### Key Insight

Because US2 and US3 are manifest-only stories (no runtime code changes in this feature's scope), the MVP phase (Setup + Foundational + US1) delivers 3 out of 4 user stories. US4 is the only story requiring additional implementation beyond the foundational phase.

---

## Notes

- [P] tasks = different files, no dependencies — safe to execute in parallel
- [Story] label maps task to specific user story for traceability
- No automated test tasks — spec does not request them (manual testing via quickstart.md)
- US2 and US3 are "manifest-only" stories — their deliverables are Android permission declarations + translation keys, both handled in the Foundational phase
- All 8 files from plan.md are covered: pubspec.yaml (T001), app_translations.dart (T002), AndroidManifest.xml (T003), fcm_service.dart (T004 + T009), main_customer.dart (T005), main_driver.dart (T006), app_initializer.dart (T007 + T010), auth_controller.dart (T008)
- Commit after each task or logical group
- Stop at any checkpoint to validate independently
