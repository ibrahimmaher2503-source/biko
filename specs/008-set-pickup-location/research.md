# Research: Set Pickup Location

**Branch**: `008-set-pickup-location` | **Date**: 2026-03-02

## Research Decisions

### R1: Google Maps Flutter Integration

**Decision**: Add `google_maps_flutter: ^2.10.0` to pubspec.yaml.

**Rationale**: The constitution mandates Google Maps SDK for
Flutter (Technology Constraints table). The existing
`AppMapWidget` in `lib/core/widgets/app_map_widget.dart` is a
placeholder with TODOs for google_maps_flutter integration. The
pickup screen requires an interactive map with panning, marker
placement, and camera movement.

**Alternatives considered**:
- `flutter_map` (uses OpenStreetMap) — rejected per constitution
  (Google Maps only).
- Static map image — rejected; user needs to drag/pan to adjust
  pickup.

**Setup requirements**:
- Android: Add API key to `android/app/src/main/AndroidManifest.xml`
  as `<meta-data android:name="com.google.android.geo.API_KEY"
  android:value="${GOOGLE_MAPS_API_KEY}"/>`.
- iOS: Add API key to `ios/Runner/AppDelegate.swift` via
  `GMSServices.provideAPIKey()`.
- Enable Maps SDK for Android + iOS in Google Cloud Console.

### R2: Google Places Autocomplete Approach

**Decision**: Use Google Places API via direct HTTP calls (the
`http` package or `dio`). No dedicated Flutter Places package.

**Rationale**: There is no official Google-maintained Flutter
package for Places API. The REST API is straightforward:
- Autocomplete: `GET /maps/api/place/autocomplete/json?input=X&components=country:eg&key=KEY`
- Place Details: `GET /maps/api/place/details/json?place_id=X&fields=geometry,formatted_address,name&key=KEY`

This keeps dependencies minimal and avoids unmaintained third-party
wrappers. The `http` package is already a transitive dependency
(via other packages) so no new dependency needed.

**Alternatives considered**:
- `google_place: ^0.4.7` (third-party) — rejected; low maintenance
  and API changes risk.
- `flutter_google_places_sdk` — rejected; adds native SDK overhead
  and is overkill for simple autocomplete.

**Egypt bias**: Pass `components=country:eg` to limit results to
Egypt. Also pass `location` bias using customer's current GPS
coordinates + `radius=50000` (50km) for relevance ranking.

### R3: Map Interaction Pattern — Center Pin

**Decision**: Fixed center pin overlay (Flutter widget) with map
dragging underneath. NOT a draggable marker.

**Rationale**: This is the standard pattern used by inDrive, Uber,
Careem, and most ride-hailing apps. The pin is a Flutter widget
overlaid on the map center (using a Stack), so it stays fixed
while the map pans. On `onCameraIdle` callback, reverse-geocode
the new map center.

**Implementation**:
- `Stack`: Google Map (full screen) + center pin widget (positioned
  at center).
- `GoogleMap.onCameraMove` → update loading state.
- `GoogleMap.onCameraIdle` → reverse-geocode `target` LatLng.
- Pin animates slightly on drag start/end (subtle bounce).

**Alternatives considered**:
- Draggable `Marker` — rejected; markers are map-rendered and
  don't support custom Flutter widget rendering or animation.
- Fixed marker at map center via Marker API — rejected; less
  control over visual state and animation.

### R4: Search Debounce Strategy

**Decision**: 300ms debounce using Dart `Timer` in the controller.

**Rationale**: Google Places API charges per request. Without
debounce, every keystroke fires a request. 300ms is the industry
standard balance between responsiveness and cost. GetX's
`debounce()` worker on an RxString is a clean alternative, but a
simple Timer gives more control over cancellation.

**Implementation**:
```
Timer? _debounce;
void onSearchChanged(String query) {
  _debounce?.cancel();
  _debounce = Timer(Duration(milliseconds: 300), () {
    if (query.length >= 2) _searchPlaces(query);
  });
}
```

### R5: PlaceModel Location in Project Structure

**Decision**: Create `PlaceModel` in `lib/core/models/place_model.dart`
(core, not feature-specific).

**Rationale**: Per the user's input, the PlaceModel represents a
geographic location used across features (pickup, dropoff, trip
creation, saved locations, recent locations). It belongs in core
since it will be referenced by trip, delivery, and home features.

The existing `RecentLocation` model in
`lib/features/home/models/recent_location.dart` has overlapping
fields (name, address, lat, lng). PlaceModel will be the canonical
location type. RecentLocation can remain as-is for now (it adds
`iconType` specific to the home screen display) or be refactored
later to extend/wrap PlaceModel.

**Fields** (from user input):
- `name` (String) — display name
- `address` (String) — full formatted address
- `lat` (double) — latitude
- `lng` (double) — longitude
- `placeId` (String?) — Google Places ID (optional, for detail
  fetching)

### R6: Map Service Architecture

**Decision**: Create `MapService` as a static utility class in
`lib/core/services/map_service.dart` for all Google Maps/Places
API interactions.

**Rationale**: The user explicitly requested a MapService with
methods for searchPlaces, getPlaceDetails, calculateDistanceKm,
estimateDurationMins, getRoutePolyline. This service wraps all
Google API calls and returns typed models. As a core service,
it's reusable across trip, delivery, and tracking features.

**Methods** (from user input + research):
- `searchPlaces(String query, LatLng biasLocation)` → `List<PlaceModel>`
- `getPlaceDetails(String placeId)` → `PlaceModel`
- `reverseGeocode(double lat, double lng)` → `PlaceModel`
  (wraps existing `geocoding` package)
- `calculateDistanceKm(LatLng from, LatLng to)` → `double`
  (deferred — not needed for this feature)
- `estimateDurationMins(LatLng from, LatLng to)` → `int`
  (deferred — not needed for this feature)
- `getRoutePolyline(LatLng from, LatLng to)` → `List<LatLng>`
  (deferred — not needed for this feature)

Only `searchPlaces`, `getPlaceDetails`, and `reverseGeocode` are
needed for the pickup screen. Distance/duration/polyline will be
implemented when the bid/route confirmation feature is built.

### R7: Screen Layout Architecture

**Decision**: Full-screen map with floating elements overlaid via
Stack. Address display + confirm button in a bottom sheet.

**Layout** (derived from stitch design #1 and ride-hailing
patterns):
```
Stack:
├── GoogleMap (full screen, interactive)
├── Center pin widget (fixed, centered vertically with offset)
├── Top bar: back button + search field (floating)
├── Map controls: my-location button (right side)
└── Bottom sheet (DraggableScrollableSheet):
    ├── Address display (reverse-geocoded)
    ├── Recent/saved locations list (when search inactive)
    └── "Confirm Pickup" button (primary, full-width)
```

When the user taps the search field, it expands to show
autocomplete results, covering the bottom sheet.

### R8: Controller Architecture — PickupController

**Decision**: Create a dedicated `PickupController` in
`lib/features/pickup/controllers/pickup_controller.dart` with
a `PickupBinding` in `lib/features/pickup/bindings/`.

**Rationale**: Per constitution principle III (Feature-First),
the pickup screen is its own feature module. The controller
manages:
- Map camera position (observable)
- Selected place (PlaceModel, observable)
- Search query (observable with debounce)
- Search results (observable list)
- Loading states (isSearching, isGeocodingRx, isLoadingMap)
- GPS current location on init
- Navigation to dropoff screen on confirm

**GetX registration**: `Get.lazyPut(() => PickupController())`
in PickupBinding, registered via GetPage in customer_pages.dart.

### R9: Navigation Data Flow

**Decision**: Use GetX route arguments to pass PlaceModel data
between screens.

**Flow**:
1. Home → Pickup: optional arguments (pre-fill from recent
   location tap).
2. Pickup → Dropoff: required arguments containing the confirmed
   pickup PlaceModel (`Get.toNamed(AppRoutes.setDropoff,
   arguments: {'pickup': selectedPlace})`).

**Pre-fill handling**: PickupController reads arguments in
`onInit()`. If a location is passed, set it as selectedPlace and
move the map camera there. Otherwise, use GPS.

### R10: API Key Management

**Decision**: Store Google Maps API key in the project's existing
environment configuration. Access via `DevConfig` or environment
variable.

**Rationale**: The constitution requires API keys in `.env` (never
committed). For Google Maps Flutter, the key must also be in
native config files (AndroidManifest.xml, AppDelegate.swift). For
Places API HTTP calls, the key is passed as a query parameter.

**Current state**: `dev_config.dart` exists with `skipOtp` flag.
The Google Maps API key needs to be available at both build time
(native manifests) and runtime (HTTP calls). Use a constants file
or `--dart-define` build flag for the runtime key.

## Summary

| Decision | Choice | Risk |
|----------|--------|------|
| Maps package | google_maps_flutter ^2.10.0 | Low — official Google package |
| Places API | Direct HTTP calls | Low — REST API is stable |
| Map pattern | Center pin overlay | None — industry standard |
| Debounce | 300ms Timer | None |
| PlaceModel | core/models/ | None — reusable |
| MapService | core/services/ (static) | None — aligns with existing services |
| Screen layout | Full-screen map + overlays | None |
| Controller | features/pickup/ | None — follows feature-first |
| Navigation | GetX route arguments | None — existing pattern |
| API key | env + native config | Low — standard setup |
