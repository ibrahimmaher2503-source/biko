# Data Model: Customer Home Services Overview

**Feature Branch**: `007-home-services-overview`
**Date**: 2026-03-02

## Entities

### 1. HomeController State (GetX Observable State)

The `HomeController` manages all reactive state for the home screen. No new Firestore collections are needed — all data comes from existing sources.

| Field | Type | Source | Description |
|-------|------|--------|-------------|
| `userName` | `RxString` | `UserModel.name` via FirestoreService | User's display name |
| `avatarUrl` | `Rxn<String>` | `UserModel.avatarUrl` via FirestoreService | User's avatar image URL |
| `walletBalance` | `RxDouble` | `UserModel.walletBalance` via FirestoreService | Wallet balance in EGP |
| `walletLoaded` | `RxBool` | Internal | Whether wallet data loaded successfully |
| `locationName` | `RxString` | Geolocator + Geocoding | Human-readable city/area name |
| `locationLoaded` | `RxBool` | Internal | Whether location reverse-geocoded successfully |
| `recentLocations` | `RxList<RecentLocation>` | Trip history (placeholder initially) | Up to 5 recent destinations |
| `currentTabIndex` | `RxInt` | Internal (bottom nav) | Active bottom nav tab (0-4) |
| `isLoading` | `RxBool` | Internal | Initial data loading state |

### 2. RecentLocation (Local Data Class)

A simple data class for displaying recent location items. Not persisted to Firestore in this feature.

```dart
class RecentLocation {
  final String name;        // Display name (e.g., "Benha University")
  final String address;     // Full address (e.g., "Kafr Saad, Banha, Al Qalyubia")
  final double lat;         // Latitude
  final double lng;         // Longitude
  final String iconType;    // Icon type: "history", "work", "home", "favorite"
}
```

| Field | Type | Validation | Description |
|-------|------|------------|-------------|
| `name` | `String` | Required, non-empty | Location display name |
| `address` | `String` | Required, non-empty | Full address text |
| `lat` | `double` | Valid latitude (-90 to 90) | Latitude coordinate |
| `lng` | `double` | Valid longitude (-180 to 180) | Longitude coordinate |
| `iconType` | `String` | One of: history, work, home, favorite | Determines icon shown |

### 3. ServiceType (Enum — for navigation)

Used to pass service context when navigating from cards/buttons to the booking flow.

```dart
enum HomeServiceType {
  ride,
  delivery,
  merchant,
}
```

## Existing Entities Used (No Modifications)

### UserModel (read-only)

Already defined in `lib/core/models/user_model.dart`. Fields used:
- `name` → displayed in greeting (future use) and loaded for context
- `avatarUrl` → not shown in new design header but available
- `walletBalance` → displayed in wallet badge

### AppRoutes (read-only)

Already defined in `lib/core/routes/app_routes.dart`. Routes used:
- `customerHome` → main shell route
- `customerTripCreate` → ride/delivery booking
- `customerTripPickup` → search bar destination
- `customerWallet` → wallet badge tap
- `customerHistory` → rides tab
- `customerProfile` → profile tab

## State Transitions

### Home Screen Load Sequence

```
onInit()
  ├─→ _loadUserData()
  │     ├─→ Fetch UserModel from Firestore
  │     ├─→ Set userName, avatarUrl, walletBalance
  │     └─→ Set walletLoaded = true (or false on error)
  │
  ├─→ _loadLocation()
  │     ├─→ Check location permission
  │     ├─→ Get GPS coordinates via Geolocator
  │     ├─→ Reverse geocode to city name via Geocoding
  │     ├─→ Set locationName
  │     ├─→ Cache in SharedPreferences
  │     └─→ Set locationLoaded = true
  │
  └─→ _loadRecentLocations()
        ├─→ Query trip history (placeholder: hardcoded demo data)
        └─→ Set recentLocations list (empty = section hidden)
```

### Bottom Navigation Tab Switching

```
currentTabIndex changes (0-4)
  ├─→ 0: Home screen content (this feature)
  ├─→ 1: Rides/History placeholder
  ├─→ 2: Quick action (navigates to booking flow, not a tab)
  ├─→ 3: Wallet placeholder
  └─→ 4: Profile placeholder
```

## Relationships

```
UserModel (Firestore)
  └─→ walletBalance ──→ HomeController.walletBalance ──→ Wallet Badge UI

Geolocator (Device GPS)
  └─→ coordinates ──→ Geocoding ──→ HomeController.locationName ──→ Header UI

Trip History (Firestore, future)
  └─→ recent destinations ──→ HomeController.recentLocations ──→ Recent Locations UI

HomeController.currentTabIndex
  └─→ IndexedStack ──→ Active tab page in CustomerMainShell
```
