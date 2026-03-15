# Feature Specification: Trip Booking & Bidding — Price Negotiation

**Feature Branch**: `011-trip-bidding`
**Created**: 2026-03-02
**Status**: Draft
**Input**: User description: "Story 5.1 — Price Negotiation: As a customer on the price screen, I want to see the suggested price and adjust my offer, so that I can request a trip at my preferred price."
**Design Reference**: `stitch/set_route_and_place_bid_1/screen.png`

## User Scenarios & Testing *(mandatory)*

### User Story 1 - View Route and Suggested Fare (Priority: P1)

As a customer who has selected pickup and dropoff locations, I want to see my route on the map with a system-calculated fair price, so that I know the recommended cost before making my offer.

After confirming the dropoff location, the customer navigates to the price negotiation screen. The screen shows:
- A Google Map filling the top portion with a polyline route drawn between pickup and dropoff markers
- A draggable bottom sheet displaying the pickup address (red circle icon) and dropoff address (location pin icon)
- A "Recommended Fare" label with a "Fair Price: EGP XX" badge showing the system-calculated price
- The suggested price is calculated using the formula from `app_config`: `base_fare + (price_per_km × distance_km) + (price_per_min × estimated_duration_min)`

**Why this priority**: Without a visible route and fare suggestion, the customer has no reference point for their offer. This is the foundational UI that all other interactions depend on.

**Independent Test**: Navigate from dropoff confirmation to the price screen. Verify the map shows a polyline between pickup and dropoff. Verify the "Fair Price" badge displays a calculated amount in EGP. Verify the pickup and dropoff addresses are shown correctly in the bottom sheet.

**Acceptance Scenarios**:

1. **Given** a customer has confirmed pickup (e.g., "58 El-Thawra St.") and dropoff (e.g., "City Stars Mall, Gate 3"), **When** they arrive at the price negotiation screen, **Then** the map shows a polyline route between the two points, and the bottom sheet displays both addresses with a "Fair Price: EGP XX" badge where XX is calculated from `app_config` pricing parameters.
2. **Given** the price screen is displayed, **When** the customer views the map, **Then** the camera is zoomed to fit both pickup and dropoff markers with appropriate padding.
3. **Given** the Google Maps Directions API fails to return a route, **When** the screen loads, **Then** the map shows pickup and dropoff markers without a polyline, and the suggested fare falls back to a straight-line distance estimate.

---

### User Story 2 - Adjust Offer Amount (Priority: P1)

As a customer viewing the suggested fare, I want to adjust my offer up or down using +/- buttons, so that I can bid a price I am comfortable with.

The screen shows a "YOUR OFFER" section centered below the recommended fare:
- A large bold number showing the current offer amount (e.g., "50") with "EGP" label
- A circular "-" button on the left to decrease the offer
- A circular "+" button on the right to increase the offer
- Each tap adjusts the amount by a fixed step (5 EGP)
- The offer defaults to the suggested fare rounded up to the nearest 5
- A hint text below: "Drivers are more likely to accept higher bids"
- The offer has a minimum floor (equal to the suggested fare rounded up to nearest 5) — the customer cannot bid below the system price

**Why this priority**: The offer amount is the core interaction of the bidding system. Without it, the customer cannot submit a meaningful ride request.

**Independent Test**: On the price screen, verify the default offer equals the suggested fare (rounded up to nearest 5). Tap "+" and verify the amount increases by 5 EGP. Tap "-" and verify the amount decreases by 5 EGP but does not go below the minimum. Verify the hint text is displayed.

**Acceptance Scenarios**:

1. **Given** the suggested fare is EGP 43, **When** the price screen loads, **Then** the default offer is EGP 45 (rounded up to nearest 5) and the "-" button is disabled because 45 equals the minimum floor.
2. **Given** the current offer is EGP 50, **When** the customer taps "+", **Then** the offer becomes EGP 55.
3. **Given** the current offer is EGP 50 and the minimum is EGP 45, **When** the customer taps "-", **Then** the offer becomes EGP 45.
4. **Given** the current offer equals the minimum floor, **When** the customer taps "-", **Then** nothing happens and the "-" button appears disabled (reduced opacity).

---

### User Story 3 - Select Payment Method and Passenger Count (Priority: P2)

As a customer, I want to select my payment method and number of passengers before requesting the ride, so that drivers know what to expect.

Below the offer adjustment section, a row of tappable chips is displayed:
- **Cash** chip (default selected) — with a cash/money icon. Tapping opens a payment method picker (Cash, Wallet, Card, Vodafone Cash, Fawry).
- **1 Passenger** chip — with a person icon. Tapping opens a picker to select 1-3 passengers.

**Why this priority**: Payment method and passenger count are important metadata but not blocking for the core bidding flow. The trip can default to cash/1 passenger.

**Independent Test**: On the price screen, verify the Cash chip and 1 Passenger chip are visible. Tap the Cash chip and verify a bottom sheet picker appears with payment options. Select "Wallet" and verify the chip updates to show "Wallet". Tap the passenger chip and change to 2, verify it updates to "2 Passengers".

**Acceptance Scenarios**:

1. **Given** the price screen is displayed, **When** the customer views the chip row, **Then** "Cash" and "1 Passenger" chips are shown as defaults.
2. **Given** the customer taps the payment chip, **When** the picker sheet appears, **Then** it shows options: Cash, Wallet, Card, Vodafone Cash, Fawry.
3. **Given** the customer selects "Wallet" in the picker, **When** the picker closes, **Then** the chip updates its icon and label to "Wallet".
4. **Given** the customer taps the passenger chip, **When** the picker appears, **Then** they can choose 1, 2, or 3 passengers, and the chip label updates accordingly.

---

### User Story 4 - Add Trip Note (Priority: P3)

As a customer, I want to add an optional text note for the driver, so that I can communicate special instructions (e.g., "I have luggage", "Meet at the back gate").

An "Add Note" chip with a chat/note icon is shown in the chip row. Tapping opens a small text input dialog where the customer types a note (max 200 characters). After saving, the chip label changes to "Note Added" with a checkmark.

**Why this priority**: Notes are a convenience feature. The trip can proceed without one.

**Independent Test**: Tap the "Add Note" chip, type a message, save it, verify the chip changes to "Note Added". Submit the ride request and verify the note appears in the Firestore trip document.

**Acceptance Scenarios**:

1. **Given** the price screen is displayed, **When** the customer taps "Add Note", **Then** a dialog with a text field appears.
2. **Given** the note dialog is open, **When** the customer types "Meet at Gate 3" and taps save, **Then** the dialog closes and the chip shows "Note Added" with a checkmark icon.
3. **Given** a note has been added, **When** the customer taps the chip again, **Then** the dialog opens pre-filled with the existing note for editing.

---

### User Story 5 - Submit Ride Request (Priority: P1)

As a customer who has set their offer, I want to tap "Request Ride" to create a trip and start receiving driver bids, so that I can get matched with a driver.

A full-width red "Request Ride" button sits at the bottom of the sheet. Tapping it:
1. Shows a loading state on the button (disabled + spinner)
2. Creates a trip document in Firestore `trips/{trip_id}` with status `searching`, the system-calculated fare as `suggested_price`, the customer's offer as `final_price`, pickup/dropoff coordinates, payment method, passenger count, and optional note
3. On success, navigates to the waiting-for-bids screen (`AppRoutes.viewBids`)
4. On failure, shows an error snackbar and re-enables the button

**Why this priority**: This is the terminal action of the screen — without it, no trip is created and the bidding flow cannot begin.

**Independent Test**: Set an offer amount, tap "Request Ride", verify a trip document is created in Firestore with the correct fields. Verify navigation to the bids screen. Turn off network, tap "Request Ride", verify an error snackbar appears.

**Acceptance Scenarios**:

1. **Given** the customer has set offer to EGP 50, payment method Cash, 1 passenger, **When** they tap "Request Ride", **Then** a trip document is created in `trips/` with `suggested_price` = system fare, `final_price` = 50, `payment_method` = "cash", `status` = "searching", and the customer is navigated to the bids screen.
2. **Given** the customer taps "Request Ride", **When** the request is in flight, **Then** the button shows a loading spinner and is not tappable.
3. **Given** a network error occurs during trip creation, **When** the write fails, **Then** an error snackbar is shown and the button returns to its normal state.
4. **Given** a trip is successfully created, **When** navigation completes, **Then** the trip ID is passed as an argument to the bids screen.

---

### Edge Cases

- What happens when the customer navigates back from the price screen? The trip is NOT created — only "Request Ride" creates it. Back navigation returns to the previous screen.
- What happens if `app_config` pricing parameters are not available? Use hardcoded fallback values (base_fare=10, price_per_km=5, price_per_min=1) and log a warning. These are ONLY fallbacks for development — production always reads from Firestore.
- What happens if the Google Maps Directions API rate-limits or times out? Show the map without a polyline, calculate distance using straight-line (Haversine) formula with a 1.3x road-factor multiplier for the fare estimate.
- What happens if the customer's wallet balance is insufficient when "Wallet" payment is selected? Allow selection — balance validation happens at trip completion, not at request time (per the project architecture).
- What happens if the offer amount + step exceeds 999 EGP? Cap the maximum offer at 999 EGP.
- What happens if pickup and dropoff are the same location? Prevent submission — show a snackbar explaining that pickup and dropoff must be different.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST display a Google Map with a polyline route between pickup and dropoff locations on the price negotiation screen.
- **FR-002**: System MUST calculate and display a recommended fare using `app_config` pricing parameters (base_fare, price_per_km, price_per_min).
- **FR-003**: System MUST provide +/- buttons that adjust the customer offer by 5 EGP per tap.
- **FR-004**: System MUST enforce a minimum offer equal to the suggested fare (rounded up to nearest 5 EGP).
- **FR-005**: System MUST enforce a maximum offer of 999 EGP.
- **FR-006**: System MUST default the offer to the suggested fare rounded up to the nearest 5 EGP.
- **FR-007**: System MUST display "Recommended Fare" with a "Fair Price: EGP XX" badge.
- **FR-008**: System MUST provide a "Request Ride" button that creates a trip document in Firestore `trips/{trip_id}`.
- **FR-009**: Trip document MUST include: customer_uid, pickup (address + lat/lng), dropoff (address + lat/lng), suggested_price, final_price, payment_method, passenger_count, notes, status ("searching"), type ("ride"), distance_km, duration_mins, created_at.
- **FR-010**: System MUST navigate to the bids screen (`AppRoutes.viewBids`) after successful trip creation.
- **FR-011**: System MUST show a loading state during trip creation and an error snackbar on failure.
- **FR-012**: System MUST provide payment method selection with options: Cash (default), Wallet, Card, Vodafone Cash, Fawry.
- **FR-013**: System MUST provide passenger count selection (1-3, default 1).
- **FR-014**: System MUST provide an optional note field (max 200 characters).
- **FR-015**: All user-facing strings MUST use `.tr` translation keys (Arabic + English).
- **FR-016**: System MUST fetch route distance and duration from Google Maps Directions API for fare calculation.
- **FR-017**: The back button MUST return to the previous screen without creating a trip.

### Key Entities *(include if feature involves data)*

- **Trip**: Represents a ride request created by the customer. Key attributes: trip_id, customer_uid, type, status, pickup (address + coordinates), dropoff (address + coordinates), suggested_price, final_price, payment_method, passenger_count, notes, distance_km, duration_mins, created_at. Stored in Firestore `trips/{trip_id}`.
- **PlaceModel**: Existing entity representing a geographic location with name, address, lat, lng. Used for pickup and dropoff data passed as route arguments.
- **AppConfig**: Existing Firestore document containing pricing parameters (base_fare, price_per_km, price_per_min, surge_multiplier). Read at screen load to calculate the suggested fare.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Customer can view the route and suggested fare within 3 seconds of screen load (including Directions API call).
- **SC-002**: Customer can adjust their offer and submit a ride request in under 10 seconds (from screen load to tap "Request Ride").
- **SC-003**: Trip document is written to Firestore within 2 seconds of tapping "Request Ride".
- **SC-004**: All UI elements render correctly in both Arabic (RTL) and English (LTR) layouts.
- **SC-005**: The price negotiation screen matches the design in `stitch/set_route_and_place_bid_1/screen.png` — map with route on top, bottom sheet with addresses, fare badge, offer adjuster, chips, and red CTA button.
