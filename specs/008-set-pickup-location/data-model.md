# Data Model: Set Pickup Location

**Branch**: `008-set-pickup-location` | **Date**: 2026-03-02

## Entities

### PlaceModel

**Location**: `lib/core/models/place_model.dart`
**Purpose**: Canonical geographic location used across features.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| name | String | Yes | Display name (e.g., "Benha University") |
| address | String | Yes | Full formatted address |
| lat | double | Yes | Latitude |
| lng | double | Yes | Longitude |
| placeId | String? | No | Google Places ID for fetching details |

**Construction sources**:
- `PlaceModel.fromGooglePlaces(Map)` — from Places API response
- `PlaceModel.fromGeocode(Placemark, double lat, double lng)` —
  from reverse-geocoding result
- `PlaceModel(name:, address:, lat:, lng:)` — direct construction
  from saved/recent location data

**Computed property**:
- `LatLng get latLng` — returns `LatLng(lat, lng)` for map use

**Relationship to RecentLocation**: The existing `RecentLocation`
model has the same core fields. PlaceModel is the general-purpose
location type. RecentLocation adds `iconType` for home screen
display. No refactoring needed now — they coexist.

### PlaceAutocompleteResult

**Location**: `lib/core/models/place_model.dart` (same file)
**Purpose**: Intermediate type for autocomplete search results
before full details are fetched.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| placeId | String | Yes | Google Places ID |
| description | String | Yes | Display text for autocomplete row |
| mainText | String | Yes | Primary text (place name) |
| secondaryText | String | Yes | Secondary text (area/city) |

**Note**: When the user taps an autocomplete result, `MapService.
getPlaceDetails(placeId)` is called to get the full PlaceModel
with lat/lng.

## PickupController State

**Location**: `lib/features/pickup/controllers/pickup_controller.dart`

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| selectedPlace | Rxn\<PlaceModel\> | null | Currently selected pickup |
| searchQuery | RxString | '' | Current search input text |
| searchResults | RxList\<PlaceAutocompleteResult\> | [] | Autocomplete results |
| isSearching | RxBool | false | Autocomplete API in flight |
| isGeocoding | RxBool | false | Reverse-geocode in progress |
| isMapReady | RxBool | false | GoogleMap controller ready |
| isSearchActive | RxBool | false | Search field has focus |
| mapCenter | Rx\<LatLng\> | Cairo default | Current map camera center |
| currentPosition | Rxn\<LatLng\> | null | GPS position |

**Default map center** (when GPS unavailable):
Cairo: `LatLng(30.0444, 31.2357)`

## State Transitions

### Screen Load
```
INIT
  ├─ GPS available → getCurrentPosition → reverseGeocode
  │   → set selectedPlace + move camera
  ├─ GPS unavailable, cached location → set mapCenter from cache
  │   → show empty address, prompt search
  └─ GPS unavailable, no cache → show Cairo default
      → show empty address, prompt search

Check route arguments:
  ├─ Arguments contain location → override GPS
  │   → set selectedPlace from arguments + move camera
  └─ No arguments → use GPS flow above
```

### Search Flow
```
User types → onSearchChanged(query)
  ├─ query.length < 2 → clear results
  └─ query.length >= 2 → debounce 300ms → searchPlaces(query)
      ├─ results found → show autocomplete list
      └─ no results → show "No results found"

User taps result → onResultTap(result)
  → getPlaceDetails(result.placeId)
  → set selectedPlace
  → move camera to place
  → close search, show address in bottom sheet
```

### Map Drag Flow
```
User drags map → onCameraMove(position)
  → update mapCenter (for tracking)
  → show "loading" in address field

User stops dragging → onCameraIdle()
  → reverseGeocode(mapCenter)
  → set selectedPlace from geocode result
  → show address in bottom sheet
```

### Confirm Flow
```
User taps "Confirm Pickup"
  ├─ selectedPlace != null
  │   → Get.toNamed(setDropoff, arguments: {pickup: selectedPlace})
  └─ selectedPlace == null
      → show error "Please select a pickup location"
```

## Navigation Arguments

### Incoming (from Home)
```dart
// Optional — from recent location tap
{
  'pickup_name': String,
  'pickup_address': String,
  'pickup_lat': double,
  'pickup_lng': double,
}
```

### Outgoing (to Dropoff)
```dart
// Required — confirmed pickup
{
  'pickup': PlaceModel,  // or serialized map
}
```
