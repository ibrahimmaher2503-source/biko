# Data Model: Map Integration

Since this feature primarily involves UI and device-level hardware integration (GPS, Maps API), there are no new server-side database entities to define.

However, the client-side integration interacts with the following existing models and structures:

## Key Client-Side Entities

### `DirectionsResult` (already exists in `map_service.dart`)
- `polylinePoints`: `List<LatLng>` - The decoded route points.
- `encodedPolyline`: `String` - Original encoded string.
- `distanceKm`: `double` - Total route distance.
- `durationMins`: `double` - Total route duration.
- `boundsNE`, `boundsSW`: `LatLng` - Map bounds to fit the route on screen.

### Map State (managed via GetX Controller)
- `currentLocation`: `Rx<LatLng?>` - User's current location from Geolocator.
- `markers`: `RxSet<Marker>` - The Set of rendered Google Maps markers (drivers, pickup, dropoff).
- `polylines`: `RxSet<Polyline>` - The Set of rendered route lines.
- `mapStyle`: `Rx<String>` - The dark/light theme JSON configuration.
