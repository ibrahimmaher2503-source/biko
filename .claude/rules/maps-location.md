---
paths:
  - "lib/core/services/location_service.dart"
  - "lib/core/services/map_service.dart"
  - "lib/features/**/map*"
  - "lib/features/**/location*"
---

# Maps & Location Rules

## Driver Location Publishing
- Publish driver location to Realtime Database every 3 seconds ONLY when driver is online.
- Stop publishing immediately when driver goes offline.
- Use `LocationService` from `lib/core/services/location_service.dart`.

## GPS Filtering
- Ignore GPS events where accuracy > 50 meters.
- Ignore GPS events where distance > 100 meters within < 2 seconds (jump detection).
- These filters prevent erratic location updates on the map.

## Map Widget
- Use `AppMapWidget` from `lib/core/widgets/` for all map views.
- Map styles are in `assets/map_styles/`.
