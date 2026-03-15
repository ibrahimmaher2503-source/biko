# Research: Trip Booking & Bidding — Price Negotiation

**Feature**: 011-trip-bidding
**Date**: 2026-03-02

## R1: Google Maps Directions API for Route Polyline

**Decision**: Use the Google Maps Directions API via HTTP (through existing `MapService` pattern) to fetch route polyline, distance, and duration between pickup and dropoff.

**Rationale**: The project already uses the Google Maps HTTP API pattern in `MapService` for Places Autocomplete and Place Details. Extending this same pattern for Directions keeps the architecture consistent. The `flutter_polyline_points` package (listed in CLAUDE.md) can decode the encoded polyline string returned by the API.

**Alternatives considered**:
- **Google Maps Routes API (v2)**: Newer API but requires additional setup and API key configuration. The legacy Directions API is simpler and sufficient for this use case.
- **Client-side distance calculation only**: Would not provide a polyline for map display or accurate road-based distance/duration. Rejected — the design shows a route polyline on the map.

**Implementation notes**:
- Add `getDirections(LatLng origin, LatLng destination)` static method to `MapService`
- Returns a result object with: encoded polyline, distance in km, duration in minutes
- Decode polyline using `flutter_polyline_points` package
- Fallback: If API fails, use Haversine straight-line distance × 1.3 road factor

---

## R2: Polyline Decoding Package

**Decision**: Add `flutter_polyline_points` ^2.1.0 to pubspec.yaml for decoding Google Maps encoded polyline strings.

**Rationale**: The package is already listed in CLAUDE.md dependencies but not yet installed. It provides `PolylinePoints().decodePolyline()` which converts the encoded string from Directions API into a list of `LatLng` points for map display.

**Alternatives considered**:
- **Manual polyline decoding**: The Google polyline encoding algorithm is well-documented, but using a maintained package is more reliable and follows the project's dependency conventions.
- **google_maps_flutter built-in**: The package does not include polyline decoding — only rendering `Polyline` objects from existing points.

---

## R3: Trip Model Structure

**Decision**: Create `TripModel` in `lib/core/models/trip_model.dart` following the existing model pattern (fromJson/toJson, const constructor, Firestore Timestamp handling).

**Rationale**: The Firestore `trips/{trip_id}` collection structure is already defined in CLAUDE.md. No TripModel exists yet. The model needs to handle the fields defined in the spec: customer_uid, type, status, pickup/dropoff (address + coordinates), suggested_price, final_price, payment_method, passenger_count, notes, distance_km, duration_mins, created_at.

**Alternatives considered**:
- **Map<String, dynamic> without a model**: Rejected — the project consistently uses typed models (UserModel, DriverProfileModel, DocumentModel) for Firestore documents.

---

## R4: Trip-Related Enums

**Decision**: Add `TripStatus`, `TripType`, and `PaymentMethod` enums to `lib/core/models/enums.dart` following the existing enum pattern with `toJson()`/`fromJson()` serialization.

**Rationale**: The project uses enums with Firestore snake_case serialization for all typed fields. Trip status values (searching, bidding, accepted, etc.) and payment methods (cash, wallet, card, vodafone_cash, fawry) need the same treatment.

**Alternatives considered**:
- **String constants**: Rejected — enums provide type safety and are the established pattern in the codebase.

---

## R5: Fare Calculation from app_config

**Decision**: Read pricing parameters (base_fare, price_per_km, price_per_min) from Firestore `app_config` document at screen load. Use hardcoded development fallbacks if unavailable.

**Rationale**: Constitution Principle V (Config-Driven Business Logic) requires all pricing to come from `app_config`. The price screen fetches these values once when initialized. No `app_config` reader exists yet in the codebase, so a method is needed in `FirestoreService`.

**Implementation notes**:
- Add `getAppConfig()` to `FirestoreService` that returns a Map or typed model
- Fallback values for development: base_fare=10, price_per_km=5, price_per_min=1
- Formula: `suggested_price = base_fare + (price_per_km × distance_km) + (price_per_min × duration_min)`
- Round result to nearest integer

---

## R6: Navigation Flow (Dropoff → Price Screen)

**Decision**: The price negotiation screen uses the existing route `AppRoutes.createTrip` (/customer/trip/create). It receives both pickup and dropoff `PlaceModel` objects as route arguments.

**Rationale**: The `createTrip` route already exists in `AppRoutes`. The pickup flow currently navigates to `setDropoff` with the pickup data. The dropoff screen (not yet implemented, outside this feature scope) will navigate to `createTrip` passing both locations.

**Navigation chain**: `setPickup` → `setDropoff` → `createTrip` (price screen) → `viewBids`

**For this feature**: The price screen assumes it receives `{'pickup': PlaceModel, 'dropoff': PlaceModel}` as arguments. The dropoff screen implementation is a prerequisite but outside scope — for testing, arguments can be passed directly.

---

## R7: Firestore Trip Creation

**Decision**: Add a `createTrip(TripModel)` method to `FirestoreService` that writes to `trips/` collection with an auto-generated document ID.

**Rationale**: Follows the existing `FirestoreService` pattern for document creation (see `createDocument()` and `createDriverProfile()`). The trip document must include the auto-generated ID as `trip_id` field.

**Implementation notes**:
- Auto-generate doc ID, include as `trip_id` field in document
- Use `FieldValue.serverTimestamp()` for `created_at`
- Return the generated trip ID for navigation to bids screen
