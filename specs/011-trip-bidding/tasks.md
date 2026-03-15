# Tasks: Trip Booking & Bidding — Price Negotiation

**Input**: Design documents from `/specs/011-trip-bidding/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Tests**: Not requested — no test tasks included.

**Organization**: Tasks are grouped by user story. US1 includes the BiddingController with all observable state (offer, payment, passengers, note, submit) since it is a single GetX controller file — each subsequent story's widget tasks exercise that state.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Add required package dependency for polyline decoding

- [X] T001 Add flutter_polyline_points ^2.1.0 dependency to pubspec.yaml and run flutter pub get

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core models, enums, services, and translations that MUST be complete before user story implementation begins

**CRITICAL**: No user story work can begin until this phase is complete

- [X] T002 [P] Add TripStatus enum (searching, bidding, accepted, onTheWay, arrived, inProgress, completed, cancelled), TripType enum (ride, c2cDelivery, b2bDelivery), and PaymentMethod enum (cash, wallet, card, vodafoneCash, fawry) with toJson()/fromJson() snake_case serialization to lib/core/models/enums.dart
- [X] T003 [P] Create DirectionsResult model (polylinePoints: List<LatLng>, encodedPolyline: String, distanceKm: double, durationMins: double, boundsNE: LatLng, boundsSW: LatLng) in lib/core/models/directions_result.dart
- [X] T004 [P] Add ~20 trip.* translation keys (AR + EN) to lib/core/translations/app_translations.dart per data-model.md Translation Keys table (trip.recommended_fare, trip.fair_price, trip.your_offer, trip.egp, trip.bid_hint, trip.request_ride, trip.cash, trip.wallet, trip.card, trip.vodafone_cash, trip.fawry, trip.passenger, trip.passengers, trip.add_note, trip.note_added, trip.note_hint, trip.note_save, trip.same_location_error, trip.create_failed, trip.loading_route, trip.payment_method, trip.passenger_count)
- [X] T005 Create TripModel with all fields from data-model.md (trip_id, customer_uid, driver_uid, type, status, pickup_address/lat/lng, dropoff_address/lat/lng, suggested_price, final_price, commission_amount, payment_method, passenger_count, notes, distance_km, duration_mins, promo_code_used, discount_amount, created_at, accepted_at, completed_at) with fromJson()/toJson() and Timestamp handling following UserModel pattern in lib/core/models/trip_model.dart
- [X] T006 [P] Add getDirections(LatLng origin, LatLng destination) static method to MapService that calls Google Maps Directions API, decodes polyline via flutter_polyline_points, and returns DirectionsResult (with Haversine fallback on API failure using 1.3x road factor) in lib/core/services/map_service.dart
- [X] T007 [P] Add createTrip(TripModel) → Future<String> (auto-generate doc ID, write to trips/ collection, return trip_id) and getAppConfig() → Future<Map<String, dynamic>?> (read app_config document) static methods to lib/core/services/firestore_service.dart

**Checkpoint**: Dependencies installed, models defined, services ready, translation keys available. All user story implementation can begin.

---

## Phase 3: User Story 1 — View Route and Suggested Fare (Priority: P1) MVP

**Goal**: Display the Google Map with route polyline between pickup and dropoff, show addresses in bottom sheet, and display the system-calculated "Fair Price" badge. Also creates the BiddingController with full observable state for all stories.

**Independent Test**: Navigate to price screen with pickup/dropoff arguments. Verify map shows polyline route, camera fits both markers, bottom sheet shows pickup (red circle) and dropoff (pin icon) addresses, "Fair Price: EGP XX" badge is displayed with system-calculated amount.

### Implementation for User Story 1

- [X] T008 [US1] Create BiddingController (GetxController) in lib/features/bidding/controllers/bidding_controller.dart with: onInit() to extract pickup/dropoff PlaceModel from Get.arguments, fetch app_config pricing via FirestoreService.getAppConfig(), fetch route via MapService.getDirections(), calculate suggestedPrice using formula (base_fare + price_per_km × distance_km + price_per_min × duration_mins) with fallback values, set default offer (suggested fare rounded up to nearest 5). Observable state: pickup/dropoff (Rxn<PlaceModel>), directionsResult (Rxn<DirectionsResult>), suggestedPrice (0.obs), offerAmount (0.obs), minOffer (0.obs), paymentMethod (PaymentMethod.cash.obs), passengerCount (1.obs), tripNote (''.obs), isLoadingRoute (true.obs), isSubmitting (false.obs). Methods: incrementOffer(), decrementOffer(), setPaymentMethod(), setPassengerCount(), setNote(), submitTrip() (creates TripModel, calls FirestoreService.createTrip, navigates to AppRoutes.viewBids on success, shows error snackbar on failure)
- [X] T009 [P] [US1] Create BiddingBinding (Bindings) with Get.lazyPut(() => BiddingController()) in lib/features/bidding/bindings/bidding_binding.dart
- [X] T010 [P] [US1] Create RouteAddressBar widget showing pickup address (red circle icon, "58 El-Thawra St." style) and dropoff address (location pin icon) separated by a subtle divider, matching stitch design in lib/features/bidding/widgets/route_address_bar.dart
- [X] T011 [P] [US1] Create FareBadge widget showing "Recommended Fare" label on the left and a red-outlined "Fair Price: EGP XX" badge on the right, matching stitch design in lib/features/bidding/widgets/fare_badge.dart
- [X] T012 [US1] Create PriceNegotiationScreen (StatelessWidget with GetView<BiddingController>) with: full-screen Google Map (top portion) showing polyline route + pickup/dropoff markers with camera fitted to route bounds, and a DraggableScrollableSheet (bottom) containing RouteAddressBar + FareBadge, matching stitch/set_route_and_place_bid_1 layout in lib/features/bidding/screens/price_negotiation_screen.dart
- [X] T013 [US1] Register AppRoutes.createTrip GetPage with page: PriceNegotiationScreen and binding: BiddingBinding in lib/core/routes/customer_pages.dart

**Checkpoint**: Price screen shows map with route polyline, pickup/dropoff addresses, and fair price badge. The core screen scaffold is complete.

---

## Phase 4: User Story 2 — Adjust Offer Amount (Priority: P1)

**Goal**: Add the +/- offer adjuster to the bottom sheet so the customer can modify their bid amount in 5 EGP increments.

**Independent Test**: On the price screen, verify default offer equals suggested fare rounded up to nearest 5. Tap "+" and verify +5 EGP. Tap "-" and verify -5 EGP with minimum floor. Verify "-" disabled at minimum, "+" disabled at 999 EGP.

### Implementation for User Story 2

- [X] T014 [US2] Create OfferAdjuster widget with: circular "-" button (disabled at min), large bold offer amount, "EGP"/"ج.م" label, circular "+" button (disabled at 999), and hint text "Drivers are more likely to accept higher bids". Uses Obx to read/write BiddingController.offerAmount via incrementOffer()/decrementOffer(). Matching stitch design in lib/features/bidding/widgets/offer_adjuster.dart
- [X] T015 [US2] Integrate OfferAdjuster into PriceNegotiationScreen bottom sheet — add "YOUR OFFER" label and OfferAdjuster widget below the FareBadge in lib/features/bidding/screens/price_negotiation_screen.dart

**Checkpoint**: Customer can see and adjust their offer with +/- buttons. Minimum enforced at suggested fare, maximum at 999.

---

## Phase 5: User Story 5 — Submit Ride Request (Priority: P1)

**Goal**: Add the "Request Ride" button that creates a trip document in Firestore and navigates to the bids screen.

**Independent Test**: Set offer to 50 EGP, tap "Request Ride", verify loading spinner, verify trip document in Firestore (status=searching, final_price=50, payment_method=cash, etc.), verify navigation to bids screen. Test network error shows snackbar.

### Implementation for User Story 5

- [X] T016 [US5] Add full-width red "Request Ride" ElevatedButton to the bottom of PriceNegotiationScreen bottom sheet with: loading state (CircularProgressIndicator when isSubmitting), disabled during submission, same-location guard (snackbar if pickup ≈ dropoff), calls BiddingController.submitTrip() on tap. Matching stitch design in lib/features/bidding/screens/price_negotiation_screen.dart

**Checkpoint**: All P1 stories complete — customer can view route + fare, adjust offer, and submit ride request. This is the MVP.

---

## Phase 6: User Story 3 — Select Payment Method and Passenger Count (Priority: P2)

**Goal**: Add payment method and passenger count selection chips to the bottom sheet so drivers know what to expect.

**Independent Test**: Verify "Cash" and "1 Passenger" chips shown by default. Tap Cash chip → picker shows 5 options → select Wallet → chip updates. Tap passenger chip → picker shows 1/2/3 → select 2 → chip updates.

### Implementation for User Story 3

- [X] T017 [US3] Create TripOptionsChips widget with: payment method chip (icon + label, taps to show bottom sheet picker with Cash/Wallet/Card/Vodafone Cash/Fawry options) and passenger count chip (person icon + "X Passenger(s)" label, taps to show picker with 1/2/3 options). Uses Obx to read/write BiddingController.paymentMethod and passengerCount. In lib/features/bidding/widgets/trip_options_chips.dart
- [X] T018 [US3] Integrate TripOptionsChips into PriceNegotiationScreen bottom sheet — add chip row between the offer adjuster hint text and the Request Ride button in lib/features/bidding/screens/price_negotiation_screen.dart

**Checkpoint**: Payment method and passenger count chips work with picker bottom sheets. Trip document includes selected values.

---

## Phase 7: User Story 4 — Add Trip Note (Priority: P3)

**Goal**: Add an "Add Note" chip that opens a dialog for the customer to type a message for the driver.

**Independent Test**: Tap "Add Note" chip → dialog appears with text field → type "Meet at Gate 3" → save → chip changes to "Note Added" with checkmark. Re-tap → dialog pre-filled with existing note.

### Implementation for User Story 4

- [X] T019 [US4] Add "Add Note" chip to TripOptionsChips widget that opens a Get.dialog with text field (max 200 chars), save/cancel buttons. On save, writes to BiddingController.tripNote. Chip label changes to "Note Added" with checkmark icon when note is non-empty. In lib/features/bidding/widgets/trip_options_chips.dart
- [X] T020 [US4] Verify note is included in trip document when submitting — ensure BiddingController.submitTrip() passes tripNote.value to TripModel.notes field (should already be wired from T008, verify only)

**Checkpoint**: All 5 user stories complete — full price negotiation screen with route, fare, offer, payment, passengers, notes, and submit.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Validate all stories work together, verify design match and RTL

- [X] T021 Run all 14 manual test scenarios from quickstart.md to validate US1 (route + fare display, Directions API fallback), US2 (offer adjustment, min/max caps), US3 (payment + passenger selection), US4 (note add/edit), US5 (submit success/error, same-location guard), and cross-cutting concerns (Arabic RTL, English LTR, design match to stitch)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Setup (pubspec.yaml must have dependencies first)
- **US1 (Phase 3)**: Depends on Foundational (needs models, services, translations)
- **US2 (Phase 4)**: Depends on US1 (screen + controller must exist)
- **US5 (Phase 5)**: Depends on US2 (button goes below the offer adjuster in bottom sheet layout)
- **US3 (Phase 6)**: Depends on US5 (chips go between offer hint and Request Ride button)
- **US4 (Phase 7)**: Depends on US3 (note chip added to existing TripOptionsChips widget)
- **Polish (Phase 8)**: Depends on all phases complete

### User Story Dependencies

- **US1 (P1)**: Core screen — all other stories build on this
- **US2 (P1)**: Adds offer adjuster to US1 screen — depends only on US1
- **US5 (P1)**: Adds submit button below offer — depends on US2 for layout order
- **US3 (P2)**: Adds chips between offer hint and submit button — depends on US5 for layout order
- **US4 (P3)**: Extends US3's TripOptionsChips widget — depends on US3

### Within Foundational Phase

1. T002 + T003 + T004 — parallel (different files: enums.dart, directions_result.dart, app_translations.dart)
2. T005 — depends on T002 (TripModel uses enums)
3. T006 + T007 — parallel after T003 and T005 respectively (different files: map_service.dart, firestore_service.dart)

### Within User Story 1

1. T008 (create controller) — FIRST, all other US1 tasks depend on this
2. T009 + T010 + T011 — parallel (binding, route_address_bar, fare_badge — different files)
3. T012 (create screen) — depends on T008, T010, T011
4. T013 (register route) — depends on T009, T012

### Parallel Opportunities

```text
# Phase 2 — Foundational (parallel, different files):
T002: Add enums to enums.dart
T003: Create DirectionsResult model
T004: Add translation keys to app_translations.dart

# Phase 3 — US1 (parallel after T008 completes):
T009: Create BiddingBinding
T010: Create RouteAddressBar widget
T011: Create FareBadge widget
```

---

## Implementation Strategy

### MVP First (Setup + Foundational + US1 + US2 + US5)

1. Complete Phase 1: Setup (add dependency)
2. Complete Phase 2: Foundational (models + enums + services + translations)
3. Complete Phase 3: US1 (controller + screen + route + fare display)
4. Complete Phase 4: US2 (offer adjuster)
5. Complete Phase 5: US5 (submit ride request)
6. **STOP and VALIDATE**: Test price negotiation end-to-end — route display, offer adjustment, trip creation
7. At this point, the 3 P1 stories are functional — screen is usable for ride requests with default cash/1 passenger

### Full Delivery

1. Setup → Foundational → US1 → US2 → US5 → Validate MVP (delivers 3 P1 stories)
2. US3 (payment + passenger chips) → Validate selections saved to trip document
3. US4 (trip note) → Validate note saved to trip document
4. Polish → Run full quickstart.md test suite (14 scenarios)

### Key Insight

The MVP (Setup + Foundational + US1 + US2 + US5) delivers a fully functional price negotiation screen with route display, fare calculation, offer adjustment, and trip creation. US3 and US4 add convenience features (payment selection, notes) that enhance but don't block the core bidding flow. The screen defaults to Cash/1 Passenger which are sensible defaults.

---

## Notes

- [P] tasks = different files, no dependencies — safe to execute in parallel
- [Story] label maps task to specific user story for traceability
- No automated test tasks — spec does not request them (manual testing via quickstart.md)
- The BiddingController (T008) contains ALL observable state for all 5 stories because it is a single GetX controller file. This avoids fragmented edits to the same file across phases.
- All 15 files from plan.md are covered: pubspec.yaml (T001), enums.dart (T002), directions_result.dart (T003), app_translations.dart (T004), trip_model.dart (T005), map_service.dart (T006), firestore_service.dart (T007), bidding_controller.dart (T008), bidding_binding.dart (T009), route_address_bar.dart (T010), fare_badge.dart (T011), price_negotiation_screen.dart (T012+T015+T016+T018), offer_adjuster.dart (T014), customer_pages.dart (T013), trip_options_chips.dart (T017+T019)
- Commit after each task or logical group
- Stop at any checkpoint to validate independently
