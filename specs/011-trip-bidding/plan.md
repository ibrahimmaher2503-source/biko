# Implementation Plan: Trip Booking & Bidding — Price Negotiation

**Branch**: `011-trip-bidding` | **Date**: 2026-03-02 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/011-trip-bidding/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

Implement the price negotiation screen for the customer app. After selecting pickup and dropoff locations, the customer sees a map with the route polyline, a system-calculated "fair price" badge, and a +/- offer adjuster. They can set payment method, passenger count, and an optional note, then tap "Request Ride" to create a trip document in Firestore and navigate to the waiting-for-bids screen. This feature requires a new TripModel, trip-related enums, Directions API integration in MapService, app_config reading in FirestoreService, and the full price negotiation UI matching the stitch design.

## Technical Context

**Language/Version**: Dart 3.9.2 (Flutter)
**Primary Dependencies**: GetX 4.6.6, google_maps_flutter 2.10.0, cloud_firestore 5.0.0, flutter_polyline_points (NEW — ^2.1.0), http 1.2.0
**Storage**: Cloud Firestore (trips/, app_config)
**Testing**: Manual (quickstart.md — 14 test scenarios)
**Target Platform**: Android + iOS (Customer App)
**Project Type**: Mobile app (Flutter)
**Performance Goals**: Route + fare displayed within 3s of screen load, trip creation within 2s
**Constraints**: Must work in Arabic RTL (primary) and English LTR, all strings via `.tr` keys
**Scale/Scope**: 1 new screen, 1 new model, 3 new enums, ~10 files modified/created

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| # | Principle | Status | Notes |
|---|-----------|--------|-------|
| I | Firebase-Only Architecture | PASS | All data in Firestore (trips/, app_config). No external backends. |
| II | GetX Exclusive State Management | PASS | New BiddingController uses GetX (.obs, Obx, Get.lazyPut in binding). Navigation via Get.toNamed/Get.offAllNamed. |
| III | Feature-First Architecture | PASS | New feature at `lib/features/bidding/`. Shared models/services in `lib/core/`. No cross-feature imports. |
| IV | Bilingual RTL-First | PASS | All strings in app_translations.dart (AR + EN). UI uses EdgeInsetsDirectional where padding differs. |
| V | Config-Driven Business Logic | PASS | Pricing formula reads base_fare, price_per_km, price_per_min from Firestore app_config at runtime. Development fallbacks only for when document is unavailable. |
| VI | Server-Side Financial Security | PASS | This feature only creates the trip document. No wallet/transaction writes from client. commission_amount is null at creation — calculated by Cloud Functions on trip completion. |
| VII | Theme-Aware Design System | PASS | All colors from Theme.of(context), AppColorsExtension, or AppTheme constants. No hardcoded colors except shadows and white-on-primary (per constitution allowances). |

**Post-Phase 1 re-check**: All 7 gates PASS. No violations.

## Project Structure

### Documentation (this feature)

```text
specs/011-trip-bidding/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0: Research decisions
├── data-model.md        # Phase 1: Entity definitions
├── quickstart.md        # Phase 1: Manual test scenarios
└── checklists/
    └── requirements.md  # Spec quality checklist
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── models/
│   │   ├── enums.dart                    # MODIFY: Add TripStatus, TripType, PaymentMethod
│   │   ├── trip_model.dart               # NEW: Trip Firestore model
│   │   ├── directions_result.dart        # NEW: Directions API response model
│   │   └── place_model.dart              # EXISTING: Used for pickup/dropoff
│   ├── services/
│   │   ├── map_service.dart              # MODIFY: Add getDirections() method
│   │   └── firestore_service.dart        # MODIFY: Add createTrip(), getAppConfig()
│   ├── translations/
│   │   └── app_translations.dart         # MODIFY: Add ~20 trip.* translation keys
│   └── routes/
│       ├── app_routes.dart               # EXISTING: createTrip route already defined
│       └── customer_pages.dart           # MODIFY: Register createTrip GetPage
├── features/
│   └── bidding/                          # NEW feature module
│       ├── controllers/
│       │   └── bidding_controller.dart   # NEW: Price negotiation state management
│       ├── bindings/
│       │   └── bidding_binding.dart      # NEW: GetX dependency injection
│       ├── screens/
│       │   └── price_negotiation_screen.dart  # NEW: Main screen widget
│       └── widgets/
│           ├── route_address_bar.dart    # NEW: Pickup/dropoff address display
│           ├── fare_badge.dart           # NEW: "Fair Price: EGP XX" badge
│           ├── offer_adjuster.dart       # NEW: +/- buttons with amount display
│           ├── trip_options_chips.dart    # NEW: Cash, Passenger, Note chip row
│           └── note_dialog.dart          # NEW: Add/edit note dialog
└── pubspec.yaml                          # MODIFY: Add flutter_polyline_points
```

**Structure Decision**: Feature-first architecture under `lib/features/bidding/` with shared core models and services. The bidding feature is isolated — it receives data via route arguments (pickup/dropoff PlaceModel) and outputs a trip document to Firestore. All new UI widgets are scoped to the feature's `widgets/` directory.

## Files Summary

### New Files (9)

| File | Purpose |
|------|---------|
| `lib/core/models/trip_model.dart` | Trip Firestore document model |
| `lib/core/models/directions_result.dart` | Google Maps Directions API result model |
| `lib/features/bidding/controllers/bidding_controller.dart` | Price negotiation state (GetX) |
| `lib/features/bidding/bindings/bidding_binding.dart` | GetX binding for controller |
| `lib/features/bidding/screens/price_negotiation_screen.dart` | Main screen widget |
| `lib/features/bidding/widgets/route_address_bar.dart` | Pickup/dropoff display |
| `lib/features/bidding/widgets/fare_badge.dart` | Recommended fare badge |
| `lib/features/bidding/widgets/offer_adjuster.dart` | +/- offer controls |
| `lib/features/bidding/widgets/trip_options_chips.dart` | Payment, passengers, note chips |

### Modified Files (6)

| File | Changes |
|------|---------|
| `pubspec.yaml` | Add flutter_polyline_points ^2.1.0 |
| `lib/core/models/enums.dart` | Add TripStatus, TripType, PaymentMethod enums |
| `lib/core/services/map_service.dart` | Add getDirections() method |
| `lib/core/services/firestore_service.dart` | Add createTrip(), getAppConfig() methods |
| `lib/core/translations/app_translations.dart` | Add ~20 trip.* translation keys (AR + EN) |
| `lib/core/routes/customer_pages.dart` | Register createTrip GetPage with BiddingBinding |

## Complexity Tracking

> No constitution violations — table left empty.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| — | — | — |
