# Tasks: Map Integration

**Input**: Design documents from `/specs/014-map-integration/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [x] T001 Create `assets/map_styles/` directory
- [x] T002 In `pubspec.yaml`, register `assets/map_styles/` under the `flutter: assets:` section

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T003 Implement `LocationService` in `lib/core/services/location_service.dart` wrapper for `geolocator` requests and permission handling
- [x] T004 [P] Create `map_style_light.json` in `assets/map_styles/` based on `AppTheme` colors
- [x] T005 [P] Create `map_style_dark.json` in `assets/map_styles/` based on `AppTheme` colors

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - View Real-Time Location (Priority: P1) 🎯 MVP

**Goal**: Users (Customers and Drivers) need to see their real-time location on a map.

**Independent Test**: Can be fully tested by opening the app and observing the blue dot (user location) accurately reflecting the device's physical location.

### Implementation for User Story 1

- [x] T006 [US1] Inject `LocationService` dependency where `AppMapWidget` is initialized or in its controller
- [x] T007 [US1] Update `AppMapWidget` in `lib/core/widgets/app_map_widget.dart` to replace the placeholder `Container` with `GoogleMap` widget
- [x] T008 [US1] Implement `myLocationEnabled: true` and `myLocationButtonEnabled: false` inside the `GoogleMap` widget
- [x] T009 [US1] Implement controller logic to observe `currentLocation` stream from `LocationService` and call `animateCamera` on the `GoogleMapController` when the user's location changes

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently

---

## Phase 4: User Story 2 - View Available Drivers (Priority: P2)

**Goal**: Customers need to see available drivers clustered on the map.

**Independent Test**: Can be fully tested by mocking driver locations and verifying that custom markers appear.

### Implementation for User Story 2

- [x] T010 [US2] Create or load custom image assets for driver markers
- [x] T011 [US2] Update `AppMapWidget` to accept an `RxSet<Marker>` or `Set<Marker>` parameter for displaying dynamic markers
- [ ] T012 [US2] Implement logic to convert incoming driver locations into standard `Marker` objects and bind to the `GoogleMap` widget

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently

---

## Phase 5: User Story 3 - Trip Route Visualization (Priority: P2)

**Goal**: Users need to see the polyline route between the pickup and dropoff locations when a trip is active.

**Independent Test**: Can be fully tested by providing mock pickup and dropoff coordinates and verifying that a route polyline is correctly drawn on the map.

### Implementation for User Story 3

- [x] T013 [US3] Update `AppMapWidget` to accept an `RxSet<Polyline>` or `Set<Polyline>` parameter
- [ ] T014 [US3] Ensure `MapService.getDirections` parses `DirectionsResult.encodedPolyline` and correctly converts them to `Polyline` objects
- [x] T015 [US3] Bind the constructed `Polyline` objects to the `GoogleMap` widget
- [x] T016 [US3] Implement dynamic camera bounds adjustment (`LatLngBounds`) based on the route to ensure the entire polyline is visible

**Checkpoint**: All core interactive functionality should now be working

---

## Phase 6: User Story 4 - Themed Map Styling (Priority: P3)

**Goal**: Users need the map to seamlessly blend with the app's overall design system (light/dark mode).

**Independent Test**: Can be fully tested by toggling the device or app theme and observing the map tile colors updating accordingly.

### Implementation for User Story 4

- [x] T017 [US4] Implement logic in `AppMapWidget` to read the current `ThemeMode`
- [x] T018 [US4] Load the corresponding JSON style string from `assets/map_styles/map_style_light.json` or `assets/map_styles/map_style_dark.json` using `rootBundle`
- [x] T019 [US4] Apply the loaded string via `GoogleMapController.setMapStyle` within the `onMapCreated` callback or upon theme changes

**Checkpoint**: All user stories should now be independently functional

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-6)**: All depend on Foundational phase completion
  - User Story 1 (P1) is required to initialize the `GoogleMap` widget correctly before markers and polylines can be added. 
  - US2, US3, and US4 can then proceed in parallel or sequentially.

### Within Each User Story

- Ensure the correct parameters are exposed in `AppMapWidget` before implementing the caller-side logic in the controllers.
- Core implementation before integration.
- Story complete before moving to the next priority.
