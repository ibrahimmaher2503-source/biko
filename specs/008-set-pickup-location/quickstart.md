# Quickstart: Set Pickup Location

**Feature Branch**: `008-set-pickup-location`
**Date**: 2026-03-02

## Prerequisites

- Flutter SDK 3.x installed
- Project dependencies installed (`flutter pub get`)
- Firebase configured (existing setup)
- Google Maps API key with Maps SDK + Places API enabled
- Android emulator or iOS simulator available

## Quick Setup

```bash
# 1. Switch to feature branch
git checkout 008-set-pickup-location

# 2. Install dependencies (google_maps_flutter will be added)
flutter pub get

# 3. Ensure Google Maps API key is in AndroidManifest.xml
# android/app/src/main/AndroidManifest.xml
# <meta-data android:name="com.google.android.geo.API_KEY"
#   android:value="YOUR_KEY_HERE"/>

# 4. Run the customer app
flutter run -t lib/main_customer.dart
```

## Key Files to Create/Modify

| File | Action | Purpose |
|------|--------|---------|
| `lib/core/models/place_model.dart` | CREATE | PlaceModel + PlaceAutocompleteResult |
| `lib/core/services/map_service.dart` | CREATE | Google Places API + reverse geocoding wrapper |
| `lib/features/pickup/controllers/pickup_controller.dart` | CREATE | Pickup screen state + logic |
| `lib/features/pickup/bindings/pickup_binding.dart` | CREATE | GetX binding for PickupController |
| `lib/features/pickup/screens/set_pickup_screen.dart` | CREATE | Full-screen map + search + confirm UI |
| `lib/features/pickup/widgets/*.dart` | CREATE | Extracted widgets (search bar, results list, bottom sheet, center pin) |
| `lib/core/routes/customer_pages.dart` | MODIFY | Register setPickup route with PickupBinding |
| `lib/core/translations/app_translations.dart` | MODIFY | Add pickup screen translation keys |
| `pubspec.yaml` | MODIFY | Add google_maps_flutter dependency |

## Architecture Overview

```
SetPickupScreen (full-screen Scaffold, no AppBar)
├── Stack
│   ├── GoogleMap (interactive, full screen)
│   ├── CenterPinWidget (fixed overlay at map center)
│   ├── FloatingTopBar
│   │   ├── Back button (circular, elevated)
│   │   └── Search field (expandable)
│   ├── MyLocationButton (right side, floating)
│   └── PickupBottomSheet (DraggableScrollableSheet)
│       ├── Address display (reverse-geocoded name)
│       ├── Recent/Saved locations (when search inactive)
│       └── "Confirm Pickup" button (primary, full-width)
└── SearchOverlay (when search active)
    └── AutocompleteResultsList
```

## Controller State

| Observable | Type | Purpose |
|------------|------|---------|
| selectedPlace | Rxn\<PlaceModel\> | Currently picked location |
| searchQuery | RxString | Search text input |
| searchResults | RxList | Autocomplete results |
| isSearchActive | RxBool | Search overlay visible |
| isGeocoding | RxBool | Reverse-geocode loading |
| isMapReady | RxBool | Map controller initialized |

## Navigation Flow

```
Home (search bar tap)
  → /customer/trip/pickup (this screen)
    → /customer/trip/dropoff (next feature, receives pickup data)
```

## Entry Points

The pickup screen can be reached from:
1. **Home search bar** tap → `HomeController.navigateToSearch()`
2. **Recent location** tap (with pre-filled data) →
   `HomeController.onRecentLocationTap(location)`

## Theme Colors Used

| Token | Usage |
|-------|-------|
| `surfaceElevated` | Bottom sheet, search bar, buttons |
| `surfaceContainer` | Location icon backgrounds |
| `borderSubtle` | Dividers, input borders |
| `textMuted` | Secondary text, placeholder |
| `AppTheme.primary` | Confirm button, center pin, active states |

## Testing

```bash
# Run all tests
flutter test

# Run only pickup feature tests
flutter test test/features/pickup/

# Manual test checklist:
# 1. Tap home search bar → pickup screen opens with GPS location
# 2. Type "Benha" → autocomplete results appear
# 3. Tap a result → map moves, address updates
# 4. Drag map → address updates on release
# 5. Tap "Confirm Pickup" → navigates forward
# 6. Test in Arabic (RTL) → layout mirrors correctly
# 7. Test with GPS off → fallback behavior works
```
