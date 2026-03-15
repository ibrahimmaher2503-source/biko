# Research: Map Integration

## Google Maps Integration
- **Decision**: Use `google_maps_flutter`.
- **Rationale**: It's the official Google plugin for Flutter, providing the best performance and integration with the Flutter UI tree, and the API key is already configured in the Android manifest.
- **Alternatives considered**: MapBox, Apple Maps (forbidden by constitution).

## Real-time Location Tracking
- **Decision**: Use `geolocator` package.
- **Rationale**: Standard, well-supported package for getting device location. Fits the requirements perfectly and is already in `pubspec.yaml`. Provides streams for real-time tracking.
- **Alternatives considered**: `location` package (less actively maintained than `geolocator`).

## Route Visualization
- **Decision**: Use `flutter_polyline_points`.
- **Rationale**: Required by the spec to decode Google Maps Directions API encoded polylines (which `map_service.dart` already returns as a list of LatLng points).
- **Alternatives considered**: Manual decoding (reinventing the wheel).

## Map Styling
- **Decision**: Load JSON map styles at runtime.
- **Rationale**: Allows seamless switching between light and dark themes using `GoogleMapController.setMapStyle`.
- **Alternatives considered**: Cloud-based styling (requires network config, JSON is fully offline and reliable).

## Marker Clustering
- **Decision**: Use standard marker creation.
- **Rationale**: Given the complexity of custom clusters, if the number of drivers is small (<50), standard markers are fine. The spec calls for "Marker Clustering" which might require the `google_maps_cluster_manager` package or custom implementation if performance degrades.
- **Alternatives considered**: Use `google_maps_cluster_manager` if standard markers get too cluttered.
