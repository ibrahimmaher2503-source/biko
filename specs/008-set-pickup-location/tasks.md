# Tasks: Set Pickup Location

**Input**: Design documents from `/specs/008-set-pickup-location/`
**Prerequisites**: plan.md, spec.md, data-model.md, research.md, quickstart.md

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Add dependencies, configure native platform, create shared models and translations

- [X] T001 Add `google_maps_flutter: ^2.10.0` and `http` dependencies to `pubspec.yaml` and run `flutter pub get`
- [X] T002 [P] Configure Google Maps API key in `android/app/src/main/AndroidManifest.xml` — add `<meta-data android:name="com.google.android.geo.API_KEY" android:value="YOUR_KEY_HERE"/>` inside `<application>`
- [X] T003 [P] Add pickup screen translation keys (AR + EN) to `lib/core/translations/app_translations.dart` — keys: pickup_title, confirm_pickup, search_placeholder, no_results, selected_location, gps_unavailable, network_error, recent_locations, saved_locations, back, my_location, loading_address, where_to, search_addresses, poor_gps_accuracy, retry, offline_message, select_pickup_prompt, home_label, work_label, could_not_search
- [X] T004 [P] Create `PlaceModel` and `PlaceAutocompleteResult` classes in `lib/core/models/place_model.dart` — PlaceModel(name, address, lat, lng, placeId?), factory constructors `fromGooglePlaces(Map)`, `fromGeocode(Placemark, lat, lng)`, computed `LatLng get latLng`; PlaceAutocompleteResult(placeId, description, mainText, secondaryText)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core service, controller, binding, routing, and screen skeleton that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T005 Create `MapService` static utility class in `lib/core/services/map_service.dart` — implement `reverseGeocode(double lat, double lng) → Future<PlaceModel?>` using the `geocoding` package; include Egypt-biased address formatting and fallback for no-result
- [X] T006 [P] Create `PickupController` skeleton in `lib/features/pickup/controllers/pickup_controller.dart` — declare all observables from data-model.md: `selectedPlace` (Rxn<PlaceModel>), `searchQuery` (RxString), `searchResults` (RxList<PlaceAutocompleteResult>), `isSearching` (RxBool), `isGeocoding` (RxBool), `isMapReady` (RxBool), `isSearchActive` (RxBool), `mapCenter` (Rx<LatLng> default Cairo 30.0444,31.2357), `currentPosition` (Rxn<LatLng>); add empty `onInit`, `onClose`, GoogleMapController completer
- [X] T007 [P] Create `PickupBinding` in `lib/features/pickup/bindings/pickup_binding.dart` — `Get.lazyPut(() => PickupController())`
- [X] T008 Register `/customer/trip/pickup` GetPage route in `lib/core/routes/customer_pages.dart` — page: `SetPickupScreen`, binding: `PickupBinding`
- [X] T009 Create `SetPickupScreen` scaffold in `lib/features/pickup/screens/set_pickup_screen.dart` — full-screen `Scaffold` (no AppBar), body is a `Stack` with `GoogleMap` widget (full screen, `myLocationEnabled: false`, `zoomControlsEnabled: false`, `mapToolbarEnabled: false`), wire `onMapCreated` to controller's completer, wire `onCameraMove` and `onCameraIdle` to controller stubs

**Checkpoint**: App compiles, navigating to `/customer/trip/pickup` shows a full-screen Google Map centered on Cairo

---

## Phase 3: User Story 2 — Use Current Location as Pickup (Priority: P1) 🎯 MVP

**Goal**: Customer opens pickup screen → GPS auto-detects location → reverse-geocodes to address → one-tap confirm navigates to dropoff

**Independent Test**: Open pickup screen with GPS enabled → map shows pin at current position → address displays in bottom sheet → tap "Confirm Pickup" → navigates to dropoff with location data

### Implementation for User Story 2

- [X] T010 [US2] Implement GPS location detection in `PickupController.onInit()` — use `geolocator` to check permission, request if needed, call `getCurrentPosition()`, set `currentPosition`, animate camera to GPS position; guard with try/catch for permission denied and service disabled
- [X] T011 [US2] Create `CenterPinWidget` in `lib/features/pickup/widgets/center_pin_widget.dart` — fixed-position pin overlay at map center using `Positioned`/`Center` in the Stack, uses `AppTheme.primary` color, includes subtle shadow; pin is a Flutter widget (not a map Marker)
- [X] T012 [US2] Create `PickupBottomSheet` in `lib/features/pickup/widgets/pickup_bottom_sheet.dart` — bottom-anchored container (not DraggableScrollableSheet for now, use simple `Positioned` bottom container) with: location icon, address text (Obx reactive from `selectedPlace`), loading shimmer when `isGeocoding` is true, "Confirm Pickup" `AppButton` (full-width, primary); use `surfaceElevated` background, `borderSubtle` divider, `rounded-t-3xl` (borderRadius top 24)
- [X] T013 [US2] Implement reverse-geocode on init — after GPS position obtained in T010, call `MapService.reverseGeocode(lat, lng)`, set result to `selectedPlace`, update `isGeocoding` states; if reverse-geocode fails, set `selectedPlace` with coordinates-only fallback ("Selected location")
- [X] T014 [US2] Implement confirm pickup navigation — `confirmPickup()` method in controller: if `selectedPlace.value != null`, call `Get.toNamed(AppRoutes.setDropoff, arguments: {'pickup': selectedPlace.value})`; if null, show error snackbar via `AppSnackbar` using translation key
- [X] T015 [US2] Handle GPS unavailable fallback in controller — if permission denied or service disabled: check for cached last location in SharedPreferences, use it if available; otherwise default to Cairo (30.0444, 31.2357); set `selectedPlace` to null, show empty address prompting manual search
- [X] T016 [US2] Add back button and my-location FAB to `SetPickupScreen` — back button: circular 40px white elevated container at top-start (use `PositionedDirectional`), calls `Get.back()`; my-location FAB: right/end side, 40px circular white elevated, taps calls controller method to re-center on GPS position; both use `surfaceElevated` bg with shadow
- [X] T017 [US2] Handle pre-filled route arguments — in `PickupController.onInit()`, check `Get.arguments` for `pickup_name`, `pickup_address`, `pickup_lat`, `pickup_lng`; if present, create `PlaceModel` from arguments, set as `selectedPlace`, animate camera to location, skip GPS detection

**Checkpoint**: Pickup screen opens with GPS location, shows address in bottom sheet, "Confirm Pickup" navigates forward. Back button and my-location button work. GPS-off fallback works.

---

## Phase 4: User Story 1 — Search for Pickup Address (Priority: P1)

**Goal**: Customer types in search field → autocomplete results appear (Egypt-filtered) → tap result → map moves to location → address updates → ready to confirm

**Independent Test**: Open pickup screen → tap search field → type "Benha Uni" → results appear within 2s → tap result → map moves, address updates → confirm works

### Implementation for User Story 1

- [X] T018 [US1] Add `searchPlaces(String query, LatLng? biasLocation)` and `getPlaceDetails(String placeId)` methods to `MapService` — searchPlaces: HTTP GET to Google Places Autocomplete API with `components=country:eg`, `language` from `Get.locale`, optional `location` + `radius=50000` bias; returns `List<PlaceAutocompleteResult>`; getPlaceDetails: HTTP GET to Google Places Details API with `fields=geometry,formatted_address,name`; returns `PlaceModel`; API key from `DevConfig` or constants; handle errors gracefully
- [X] T019 [US1] Create `PickupSearchBar` widget in `lib/features/pickup/widgets/pickup_search_bar.dart` — floating search field at top of Stack (below back button row), white elevated container with rounded corners, search icon prefix, clear button suffix when text present, `TextField` with `TextEditingController` wired to controller's `onSearchChanged`; uses `surfaceElevated` bg; tap expands to full-width; supports RTL text input via `TextDirection` awareness
- [X] T020 [US1] Implement search debounce and autocomplete logic in `PickupController` — `onSearchChanged(String query)`: cancel previous `Timer`, start new 300ms timer, if `query.length >= 2` call `MapService.searchPlaces(query, currentPosition.value)`; set `isSearching` during API call; populate `searchResults` on success; `activateSearch()` and `deactivateSearch()` to toggle `isSearchActive`
- [X] T021 [US1] Create `PickupResultsList` overlay widget in `lib/features/pickup/widgets/pickup_results_list.dart` — shown when `isSearchActive` is true, positioned below search bar, white elevated card with rounded corners; ListView of results with leading location icon, `mainText` bold + `secondaryText` muted; shows "No results found" when `searchResults` empty and `!isSearching`; shows loading indicator when `isSearching`; each row taps calls controller `onResultTap`
- [X] T022 [US1] Implement result selection in controller — `onResultTap(PlaceAutocompleteResult result)`: call `MapService.getPlaceDetails(result.placeId)`, set `selectedPlace`, animate camera to `selectedPlace.latLng`, clear search state (`isSearchActive = false`, clear `searchQuery`, clear `searchResults`), unfocus keyboard
- [X] T023 [US1] Handle search error and no-results states — in `MapService.searchPlaces`: catch HTTP errors, return empty list; in controller: if API call throws, set `searchResults` to empty and show error snackbar "Could not search addresses, please try again" (.tr key); ensure UI shows "No results" vs loading correctly based on `isSearching` state

**Checkpoint**: Full search flow works — type → autocomplete → tap → map moves → address shows → confirm navigates. Error states handled gracefully.

---

## Phase 5: User Story 3 — Adjust Pickup by Dragging Map (Priority: P2)

**Goal**: Customer drags the map to fine-tune pickup → center pin stays fixed → on release, reverse-geocode updates address

**Independent Test**: Open pickup screen → drag map to a different area → release → address field updates to new location → confirm passes new location

### Implementation for User Story 3

- [X] T024 [US3] Implement `onCameraMove(CameraPosition position)` in controller — update `mapCenter` with new `position.target`; set `isGeocoding = true` to show loading in bottom sheet address field; optionally set `selectedPlace` name to loading state
- [X] T025 [US3] Implement `onCameraIdle()` in controller — call `MapService.reverseGeocode(mapCenter.value.latitude, mapCenter.value.longitude)`; on success set `selectedPlace` from result; on failure set fallback PlaceModel with "Selected location" name and coordinates; set `isGeocoding = false`; ensure debounce — if camera is still moving (rapid drags), only process the final idle
- [X] T026 [US3] Add loading indicator in `PickupBottomSheet` during geocoding — when `isGeocoding` is true, show a shimmer or animated dots in the address text area; when false, show the resolved address; ensure the "Confirm Pickup" button remains enabled (user can confirm even during geocoding if `selectedPlace` has a previous value)

**Checkpoint**: Map drag updates address. Rapid drags don't cause race conditions. Loading state shows during geocoding.

---

## Phase 6: User Story 4 — Recent/Saved Locations (Priority: P2)

**Goal**: Customer sees recent and saved locations below the search area and can tap to instantly select one as pickup

**Independent Test**: Open pickup screen with recent locations available → see saved (Home/Work) and recent locations listed → tap one → map moves to that location → address updates → confirm works

### Implementation for User Story 4

- [X] T027 [US4] Create `SavedLocationsList` widget in `lib/features/pickup/widgets/saved_locations_list.dart` — section with "Saved Locations" header showing Home/Work with icons, and "Recent Locations" header showing recent items with clock icon; each row has location icon (in `surfaceContainer` circle), name (bold), address (muted); hidden when list is empty; shown in bottom sheet area when search is NOT active; uses `Obx` reactive from controller lists
- [X] T028 [US4] Integrate saved/recent location data in `PickupController` — add `recentLocations` (RxList) and `savedLocations` (RxList) observables; populate from existing `HomeController` data or SharedPreferences on init; `onSavedLocationTap(location)`: create `PlaceModel` from location data, set as `selectedPlace`, animate camera, collapse search if active

**Checkpoint**: Saved and recent locations appear, tapping one selects it and updates the map. Empty state (no locations) hides the section.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Dark mode, RTL, edge cases, final validation

- [X] T029 [P] Dark mode audit — verify all pickup widgets use semantic theme tokens (`surfaceElevated`, `textMuted`, `borderSubtle`, `surfaceContainer`, `AppTheme.primary`); test in both light and dark mode; fix any hardcoded colors
- [X] T030 [P] RTL audit — verify all pickup widgets use `EdgeInsetsDirectional`, `PositionedDirectional`, `AlignmentDirectional`; back button flips correctly; search field text direction adapts; bottom sheet layout mirrors; test in Arabic locale
- [X] T031 Edge case hardening — implement: poor GPS accuracy indicator (>50m, show hint to adjust manually); network error handling (offline message with retry); API rate-limit/error retry; back button discards selection; keyboard dismissal on map tap
- [X] T032 Final validation — run `flutter analyze` (zero errors/warnings); walk through manual test checklist from quickstart.md (7 test scenarios); verify all translation keys render in AR and EN

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 completion — BLOCKS all user stories
- **US2 (Phase 3)**: Depends on Phase 2 — delivers MVP (GPS + confirm)
- **US1 (Phase 4)**: Depends on Phase 2 — can run in parallel with Phase 3
- **US3 (Phase 5)**: Depends on Phase 3 (needs bottom sheet + center pin from US2)
- **US4 (Phase 6)**: Depends on Phase 3 (needs bottom sheet integration from US2)
- **Polish (Phase 7)**: Depends on all user stories being complete

### Within Each Phase

- Tasks marked [P] can run in parallel (different files)
- Models before services (T004 before T005)
- Services before controller logic (T005 before T010)
- Controller before screen integration (T006 before T009)
- Widgets before screen assembly

### Parallel Opportunities

- T002, T003, T004 can all run in parallel (different files)
- T006, T007 can run in parallel (different files)
- Phase 3 (US2) and Phase 4 (US1) can run in parallel after Phase 2
- T029 and T030 can run in parallel (different concerns)

---

## Implementation Strategy

### MVP First (US2 Only — Phases 1-3)

1. Complete Phase 1: Setup (dependencies, translations, PlaceModel)
2. Complete Phase 2: Foundational (MapService, controller, binding, route, screen)
3. Complete Phase 3: US2 — GPS pickup with confirm
4. **STOP and VALIDATE**: Customer can open pickup → see GPS location → confirm → navigate forward
5. This is a functional pickup screen even without search

### Full Feature (Add US1, US3, US4 — Phases 4-7)

6. Add Phase 4: US1 — Search flow
7. Add Phase 5: US3 — Map drag adjustment
8. Add Phase 6: US4 — Recent/saved locations
9. Complete Phase 7: Polish — dark mode, RTL, edge cases

---

## Summary

| Metric | Count |
|--------|-------|
| Total tasks | 32 |
| Phase 1 (Setup) | 4 |
| Phase 2 (Foundational) | 5 |
| Phase 3 (US2 — GPS, P1) | 8 |
| Phase 4 (US1 — Search, P1) | 6 |
| Phase 5 (US3 — Map Drag, P2) | 3 |
| Phase 6 (US4 — Recent/Saved, P2) | 2 |
| Phase 7 (Polish) | 4 |
| Files to CREATE | ~10 |
| Files to MODIFY | ~3 |
| MVP scope | Phases 1-3 (17 tasks) |
