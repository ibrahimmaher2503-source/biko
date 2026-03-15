# Implementation Plan: Set Pickup Location

**Branch**: `008-set-pickup-location` | **Date**: 2026-03-02 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/008-set-pickup-location/spec.md`

## Summary

Implement a full-screen interactive map screen where customers
select their pickup location via GPS auto-detection, address
search (Google Places Autocomplete), or map dragging. The screen
uses a center-pin pattern with a floating search bar and bottom
sheet for address confirmation. On confirm, the selected location
(PlaceModel) is passed to the Set Dropoff screen via route
arguments.

## Technical Context

**Language/Version**: Dart 3.x (Flutter)
**Primary Dependencies**: GetX (state), google_maps_flutter (map),
  geocoding (reverse-geocode), geolocator (GPS), http (Places API)
**Storage**: SharedPreferences (cached last location), Firestore
  (saved locations — future)
**Testing**: flutter_test (widget tests)
**Target Platform**: Android + iOS
**Project Type**: Mobile app (Flutter)
**Performance Goals**: Map loads in <3s, autocomplete in <2s,
  reverse-geocode in <1s after drag
**Constraints**: Egypt-only addresses, bilingual AR/EN, RTL-first,
  offline fallback for cached location
**Scale/Scope**: 1 screen, ~6 widgets, 1 controller, 1 binding,
  2 core files (model + service)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| # | Principle | Status | Notes |
|---|-----------|--------|-------|
| I | Firebase-Only Architecture | PASS | No backend needed. Google Places API is a third-party REST API called from Flutter client — permitted (it's a Google Cloud service, not a custom backend). |
| II | GetX Exclusive | PASS | PickupController uses GetX. lazyPut in PickupBinding. Obx for reactive UI. Get.toNamed for navigation. |
| III | Feature-First Architecture | PASS | New feature module `lib/features/pickup/` with screens, controllers, bindings, widgets. PlaceModel and MapService in core (shared across features). No cross-feature imports. |
| IV | Bilingual RTL-First | PASS | All strings via .tr keys. EdgeInsetsDirectional for asymmetric padding. Back button flips in RTL. Search field uses TextDirection-aware input. |
| V | Config-Driven Business Logic | PASS | No business parameters in this feature (no pricing, commission). API key from environment config. |
| VI | Server-Side Financial Security | N/A | No financial operations in pickup screen. |
| VII | Theme-Aware Design System | PASS | All colors from AppColorsExtension / AppTheme. Map controls use surfaceElevated bg. Bottom sheet uses semantic tokens. Center pin uses AppTheme.primary. |

**Gate result**: ALL PASS — no violations.

## Project Structure

### Documentation (this feature)

```text
specs/008-set-pickup-location/
├── plan.md              # This file
├── research.md          # Phase 0: 10 research decisions
├── data-model.md        # Phase 1: PlaceModel, controller state, transitions
├── quickstart.md        # Phase 1: setup guide + architecture overview
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── models/
│   │   └── place_model.dart           # PlaceModel + PlaceAutocompleteResult
│   ├── services/
│   │   └── map_service.dart           # Google Places API + reverse geocoding
│   ├── translations/
│   │   └── app_translations.dart      # +20 pickup screen keys (AR + EN)
│   └── routes/
│       └── customer_pages.dart        # Add setPickup GetPage route
│
├── features/
│   └── pickup/
│       ├── bindings/
│       │   └── pickup_binding.dart    # Get.lazyPut<PickupController>
│       ├── controllers/
│       │   └── pickup_controller.dart # State, GPS, search, geocode, nav
│       ├── screens/
│       │   └── set_pickup_screen.dart # Full-screen map + overlays
│       └── widgets/
│           ├── pickup_search_bar.dart # Floating search field
│           ├── pickup_results_list.dart # Autocomplete results overlay
│           ├── pickup_bottom_sheet.dart # Address + confirm button
│           ├── center_pin_widget.dart # Fixed map center marker
│           └── saved_locations_list.dart # Recent/saved locations

pubspec.yaml                           # +google_maps_flutter
android/app/src/main/AndroidManifest.xml # Google Maps API key meta-data
```

**Structure Decision**: Feature-first under `lib/features/pickup/`.
Shared model (PlaceModel) and service (MapService) in `lib/core/`
since they will be used by dropoff, trip, and delivery features.

## Complexity Tracking

> No violations — table empty.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| (none) | — | — |
