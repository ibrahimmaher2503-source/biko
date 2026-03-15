# Quickstart: Map Integration

This feature handles the integration of `google_maps_flutter` into the app.

## Prerequisites
- Android API Key is configured in `android/app/src/main/AndroidManifest.xml` (already done).
- iOS API Key must be configured via `AppDelegate.swift` (ensure this exists).
- `geolocator` requires location permissions in `AndroidManifest.xml` and `Info.plist`.

## Key Components
- `AppMapWidget` (`lib/core/widgets/app_map_widget.dart`): The central reusable map widget for the application.
- `MapService` (`lib/core/services/map_service.dart`): Handles Directions and Places API calls.
- `LocationService` (To be created): Abstracts `geolocator` calls, permissions, and location streams to prevent memory leaks and standardise permission handling across the app.

## Steps for Developers
1. Provide the `AppMapWidget` with an `initialPosition` stream or static coordinate.
2. Provide `Set<Marker>` and `Set<Polyline>` variables to the widget, reacting to GetX observables (`.obs`).
3. Handle map controller initialization callback to set custom JSON styles (`mapStyle`).
