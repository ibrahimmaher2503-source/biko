# Implementation Plan: Google Maps Platform Setup

**Branch**: `009-maps-platform-setup` | **Date**: 2026-03-02 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/009-maps-platform-setup/spec.md`

## Summary

Configure the Google Maps SDK on all three platforms (Android, iOS,
Web) so the interactive map renders with tiles on the pickup screen.
The Android manifest placeholder is replaced with a build-time
property, the iOS AppDelegate is updated with SDK initialization
and location permissions, the web entry point loads the Maps
JavaScript API, and the Dart `MapService` reads the API key via
`String.fromEnvironment`. No API keys are committed to version
control.

## Technical Context

**Language/Version**: Dart 3.x (Flutter), Swift 5.0 (iOS), Kotlin DSL (Android Gradle)
**Primary Dependencies**: google_maps_flutter (existing), GoogleMaps iOS SDK (CocoaPod, auto-managed)
**Storage**: N/A
**Testing**: Manual verification on Android emulator, iOS simulator, Chrome browser
**Target Platform**: Android + iOS + Web (Flutter)
**Project Type**: Mobile app platform configuration
**Performance Goals**: Map tiles render within 5 seconds on all platforms
**Constraints**: No API keys in version control (FR-006)
**Scale/Scope**: ~8 files modified, 1 file created, 0 new Dart code

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| # | Principle | Status | Notes |
|---|-----------|--------|-------|
| I | Firebase-Only Architecture | PASS | No backend changes. Google Maps is a permitted Google Cloud service (Technology Constraints table). |
| II | GetX Exclusive | N/A | No state management changes. This is a platform config feature. |
| III | Feature-First Architecture | PASS | No new features or cross-feature imports. Only modifies platform config files and one existing core service. |
| IV | Bilingual RTL-First | PASS | iOS location permission descriptions added in both Arabic (via InfoPlist.strings) and English (Info.plist default). |
| V | Config-Driven Business Logic | PASS | API key is externalized via environment config (local.properties, xcconfig, dart-define). Not hardcoded. |
| VI | Server-Side Financial Security | N/A | No financial operations. |
| VII | Theme-Aware Design System | N/A | No UI changes. |

**Gate result**: ALL PASS — no violations.

## Project Structure

### Documentation (this feature)

```text
specs/009-maps-platform-setup/
├── plan.md              # This file
├── research.md          # Phase 0: 8 research decisions
├── data-model.md        # Phase 1: Config file mapping (no new models)
├── quickstart.md        # Phase 1: Setup guide + verification checklist
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
android/
├── app/
│   ├── build.gradle.kts                    # MODIFY: add manifestPlaceholders
│   └── src/main/AndroidManifest.xml        # MODIFY: use ${GOOGLE_MAPS_API_KEY}
└── local.properties                        # MODIFY: add GOOGLE_MAPS_API_KEY= (gitignored)

ios/
├── Flutter/
│   ├── Debug.xcconfig                      # MODIFY: #include "Maps.xcconfig"
│   ├── Release.xcconfig                    # MODIFY: #include "Maps.xcconfig"
│   └── Maps.xcconfig                       # CREATE: GOOGLE_MAPS_API_KEY= (gitignored)
└── Runner/
    ├── AppDelegate.swift                   # MODIFY: import GoogleMaps + provideAPIKey
    └── Info.plist                          # MODIFY: location permissions + API key entry

web/
└── index.html                              # MODIFY: add Maps JS API script tag

lib/
└── core/
    └── services/
        └── map_service.dart                # MODIFY: String.fromEnvironment for _apiKey

.gitignore                                  # MODIFY: add ios/Flutter/Maps.xcconfig
```

**Structure Decision**: No new directories or feature modules. This
is a pure configuration change touching existing platform files and
one Dart constant. All changes follow the existing project structure.

## Complexity Tracking

> No violations — table empty.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| (none) | — | — |
