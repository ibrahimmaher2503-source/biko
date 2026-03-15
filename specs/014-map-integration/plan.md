# Implementation Plan: Map Integration

**Branch**: `014-map-integration` | **Date**: 2026-03-03 | **Spec**: [spec.md](c:/Users/berog/StudioProjects/biko/specs/014-map-integration/spec.md)
**Input**: Feature specification from `/specs/014-map-integration/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

This feature replaces the placeholder map widget in `AppMapWidget` with a fully functional `GoogleMap` from `google_maps_flutter`. It implements real-time location tracking using `geolocator`, polyline route visualization with `flutter_polyline_points`, standard markers (clusters if necessary), and dynamic light/dark map styling to match the app theme. 

## Technical Context

**Language/Version**: Dart 3.x, Flutter 3.x
**Primary Dependencies**: `google_maps_flutter`, `geolocator`, `flutter_polyline_points`, `get`
**Storage**: N/A
**Testing**: Flutter Widget Tests, Manual UI Testing
**Target Platform**: Android, iOS
**Project Type**: Mobile App (Flutter)
**Performance Goals**: Sub-second map rendering, smooth 60fps panning
**Constraints**: Must strictly follow iOS/Android location permission guidelines
**Scale/Scope**: Impacts all screens containing the map (Customer Home, Driver Home, Trip active screens, Admin tracking)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Firebase-Only Architecture**: N/A for this client-side widget.
- **GetX Exclusive State Management**: `Obx` and `GetxController` will manage map state (markers, polylines, camera position).
- **Feature-First Architecture**: `AppMapWidget` remains in `lib/core/widgets/` as it's shared across multiple features (Admin, Driver, Customer). A new `lib/core/services/location_service.dart` will be added.
- **Bilingual RTL-First**: Map camera bounding box calculations must be robust regardless of layout direction.
- **Config-Driven Business Logic**: N/A.
- **Server-Side Financial Security**: N/A.
- **Theme-Aware Design System**: Map JSON styles are explicitly required to adapt to `AppTheme` light/dark states.

*Result*: **PASS**.

## Project Structure

### Documentation (this feature)

```text
specs/014-map-integration/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # N/A
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── widgets/
│   │   └── app_map_widget.dart      # The core UI map component
│   └── services/
│       └── location_service.dart    # New service for GPS wrapper
assets/
└── map_styles/                      # Contains light.json and dark.json
    ├── map_style_light.json
    └── map_style_dark.json
```

**Structure Decision**: A core shared widget (`AppMapWidget`) combined with a core shared service (`LocationService`). Map JSON styles are added as runtime assets.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| (None)    | N/A | N/A |
