# Tasks: Google Maps Platform Setup

**Input**: Design documents from `/specs/009-maps-platform-setup/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Gitignore updates and API key template files that all platforms share

- [X] T001 Add `ios/Flutter/Maps.xcconfig` pattern to `.gitignore` so iOS API keys are never committed
- [X] T002 [P] Create template file `ios/Flutter/Maps.xcconfig` with `GOOGLE_MAPS_API_KEY=YOUR_KEY_HERE` placeholder — this file is gitignored and each developer fills in their key

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Centralize the Dart-side API key so all platforms share the same runtime approach

**⚠️ CRITICAL**: The MapService change is needed before validating any platform — Places API calls depend on it

- [X] T003 Replace hardcoded `_apiKey` constant in `lib/core/services/map_service.dart` line 19 with `static const String _apiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY', defaultValue: '');` — removes the `YOUR_GOOGLE_MAPS_API_KEY_HERE` placeholder and reads the key from `--dart-define` at build time

**Checkpoint**: MapService reads API key from build-time environment. All platforms will use `--dart-define=GOOGLE_MAPS_API_KEY=AIza...` for Places API HTTP calls.

---

## Phase 3: User Story 1 — Display Interactive Map on Android (Priority: P1) 🎯 MVP

**Goal**: Customer opens the Android app, navigates to the pickup screen, and sees a fully interactive Google Map with tiles, pan/zoom, and center pin.

**Independent Test**: Run `flutter run -t lib/main_customer.dart --dart-define=GOOGLE_MAPS_API_KEY=<real_key>` on an Android emulator → navigate to pickup screen → verify map tiles render within 5 seconds, pan/zoom works.

### Implementation for User Story 1

- [X] T004 [US1] Add `manifestPlaceholders` to `android/app/build.gradle.kts` inside `defaultConfig {}` block — read the key from `local.properties` via `val localProperties = java.util.Properties(); val localPropsFile = rootProject.file("local.properties"); if (localPropsFile.exists()) { localPropsFile.inputStream().use { localProperties.load(it) } }` then set `manifestPlaceholders["GOOGLE_MAPS_API_KEY"] = localProperties.getProperty("GOOGLE_MAPS_API_KEY", "")` inside `defaultConfig`
- [X] T005 [US1] Update `android/app/src/main/AndroidManifest.xml` line 31 — change `android:value="YOUR_GOOGLE_MAPS_API_KEY_HERE"` to `android:value="${GOOGLE_MAPS_API_KEY}"` so the value is injected from build.gradle.kts manifest placeholders
- [X] T006 [US1] Add `GOOGLE_MAPS_API_KEY=` entry comment to `android/local.properties` as a setup reminder — add line `# Google Maps API Key (get from Google Cloud Console)\nGOOGLE_MAPS_API_KEY=` (this file is already gitignored by default Flutter setup)

**Checkpoint**: Android map renders with tiles when the developer sets their API key in `local.properties` and runs with `--dart-define`.

---

## Phase 4: User Story 2 — Display Interactive Map on iOS (Priority: P1)

**Goal**: Customer opens the iOS app, navigates to the pickup screen, and sees the same interactive Google Map. Location permission prompt shows a clear description.

**Independent Test**: Run `flutter run -t lib/main_customer.dart --dart-define=GOOGLE_MAPS_API_KEY=<real_key>` on an iOS simulator → navigate to pickup screen → verify map tiles render, location permission prompt shows English description.

### Implementation for User Story 2

- [X] T007 [US2] Add `#include "Maps.xcconfig"` line to `ios/Flutter/Debug.xcconfig` before the existing `#include "Generated.xcconfig"` line — this pulls in the developer's API key for debug builds
- [X] T008 [P] [US2] Add `#include "Maps.xcconfig"` line to `ios/Flutter/Release.xcconfig` before the existing `#include "Generated.xcconfig"` line — this pulls in the developer's API key for release builds
- [X] T009 [US2] Add `GOOGLE_MAPS_API_KEY` entry to `ios/Runner/Info.plist` — add key `GOOGLE_MAPS_API_KEY` with string value `$(GOOGLE_MAPS_API_KEY)` so the xcconfig value is accessible from the app bundle at runtime
- [X] T010 [US2] Add location permission descriptions to `ios/Runner/Info.plist` — add `NSLocationWhenInUseUsageDescription` with value "BikeRide needs your location to find nearby drivers and set your pickup point", `NSLocationAlwaysAndWhenInUseUsageDescription` with value "BikeRide needs your location for real-time trip tracking and navigation"
- [X] T011 [US2] Update `ios/Runner/AppDelegate.swift` — add `import GoogleMaps` at the top, then before `GeneratedPluginRegistrant.register(with: self)` add: `let mapsKey = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_MAPS_API_KEY") as? String ?? ""; GMSServices.provideAPIKey(mapsKey)`

**Checkpoint**: iOS map renders with tiles when the developer sets their API key in `Maps.xcconfig`. Location permission prompt shows description text.

---

## Phase 5: User Story 3 — Display Interactive Map on Web (Priority: P2)

**Goal**: Admin or developer previews the app in a web browser and sees Google Maps rendering with tiles and basic gestures.

**Independent Test**: Run `flutter run -t lib/main_customer.dart -d chrome --dart-define=GOOGLE_MAPS_API_KEY=<real_key>` → navigate to pickup screen → verify map renders in browser with mouse scroll/drag.

### Implementation for User Story 3

- [X] T012 [US3] Add Google Maps JavaScript API script tag to `web/index.html` — add `<script src="https://maps.googleapis.com/maps/api/js?key=YOUR_GOOGLE_MAPS_API_KEY_HERE"></script>` in the `<head>` section before the closing `</head>` tag; include an HTML comment instructing developers to replace the placeholder with their key

**Checkpoint**: Web map renders in browser when the developer replaces the key in index.html and passes `--dart-define` for Places API.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Documentation, validation, and security audit

- [X] T013 [P] Create developer setup guide section in `specs/009-maps-platform-setup/quickstart.md` — ensure the existing quickstart covers: how to get a Google Cloud API key, how to enable Maps SDK for Android/iOS/Web + Places API, how to set the key in each platform file, how to run with `--dart-define`
- [X] T014 Verify no API keys are committed — run `git diff` on all modified files to confirm no real API key values are present, only placeholders and environment references; verify `.gitignore` includes the `Maps.xcconfig` pattern
- [X] T015 Final validation — verify the build compiles on Android (`flutter build apk --dart-define=GOOGLE_MAPS_API_KEY=test`), verify iOS project structure is valid (`flutter build ios --no-codesign --dart-define=GOOGLE_MAPS_API_KEY=test` if on macOS), verify web build works (`flutter build web --dart-define=GOOGLE_MAPS_API_KEY=test`)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: No dependency on Phase 1 (different files) — can start in parallel
- **US1 Android (Phase 3)**: Depends on Phase 2 (MapService key needed for full validation)
- **US2 iOS (Phase 4)**: Depends on Phase 1 (Maps.xcconfig template) + Phase 2
- **US3 Web (Phase 5)**: Depends on Phase 2 only (no iOS/Android dependency)
- **Polish (Phase 6)**: Depends on all user stories being complete

### Within Each Phase

- T001, T002 can run in parallel (different files)
- T003 is independent (Dart file, no platform dependency)
- T004 → T005 must be sequential (build.gradle before manifest)
- T007, T008 can run in parallel (different xcconfig files)
- T009, T010 are in the same file (Info.plist) — sequential
- T011 depends on T009 (needs the Info.plist key entry to read)
- T012 is independent (only web/index.html)

### Parallel Opportunities

- T001 and T002 can run in parallel (gitignore vs xcconfig)
- T003 can run in parallel with Phase 1 (different file)
- Phase 3 (Android) and Phase 5 (Web) can run in parallel after Phase 2
- T007 and T008 can run in parallel (Debug.xcconfig vs Release.xcconfig)
- T013 and T014 can run in parallel

---

## Implementation Strategy

### MVP First (US1 Only — Phases 1-3)

1. Complete Phase 1: Setup (gitignore + xcconfig template)
2. Complete Phase 2: Foundational (MapService `String.fromEnvironment`)
3. Complete Phase 3: US1 — Android map rendering
4. **STOP and VALIDATE**: Map tiles render on Android emulator with real API key
5. This is the minimum needed to unblock feature 008 testing

### Full Feature (Add US2, US3 — Phases 4-6)

6. Add Phase 4: US2 — iOS map rendering + location permissions
7. Add Phase 5: US3 — Web map rendering
8. Complete Phase 6: Polish — documentation, security audit, build validation

---

## Summary

| Metric | Count |
|--------|-------|
| Total tasks | 15 |
| Phase 1 (Setup) | 2 |
| Phase 2 (Foundational) | 1 |
| Phase 3 (US1 — Android, P1) | 3 |
| Phase 4 (US2 — iOS, P1) | 5 |
| Phase 5 (US3 — Web, P2) | 1 |
| Phase 6 (Polish) | 3 |
| Files to CREATE | 1 (Maps.xcconfig) |
| Files to MODIFY | 8 |
| New Dart code | 0 lines (1 constant change) |
| MVP scope | Phases 1-3 (6 tasks) |
