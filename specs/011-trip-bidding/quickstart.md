# Quickstart: Trip Booking & Bidding — Price Negotiation

**Feature**: 011-trip-bidding
**Date**: 2026-03-02

## Prerequisites

1. Flutter SDK ^3.9.2 installed
2. Firebase project configured (firebase_core initialized)
3. Google Maps API key with Directions API enabled (set via `--dart-define=GOOGLE_MAPS_API_KEY=...`)
4. Firestore `app_config` document exists with pricing fields: `base_fare`, `price_per_km`, `price_per_min`
5. Features 008 (pickup) and 009 (maps) completed

## Quick Validation

### Test 1: Screen Loads with Route (US1)

1. Run customer app: `flutter run -t lib/main_customer.dart --dart-define=GOOGLE_MAPS_API_KEY=YOUR_KEY`
2. Login and navigate to home
3. Set a pickup location (e.g., search "Tahrir Square")
4. Set a dropoff location (e.g., search "City Stars Mall")
5. **Verify**: Price negotiation screen appears with:
   - Google Map showing polyline route between pickup and dropoff
   - Camera fitted to show both markers
   - Bottom sheet with pickup address (red circle) and dropoff address (pin icon)
   - "Recommended Fare" label with "Fair Price: EGP XX" badge

### Test 2: Directions API Fallback (US1 Edge Case)

1. Disable network temporarily
2. Navigate to price screen
3. **Verify**: Map shows pickup and dropoff markers without polyline
4. **Verify**: Suggested fare uses straight-line distance estimate (Haversine × 1.3)

### Test 3: Offer Adjustment (US2)

1. On price screen, note the default offer amount
2. **Verify**: Default offer = suggested fare rounded up to nearest 5 EGP
3. Tap "+" button 3 times
4. **Verify**: Amount increases by 5 EGP per tap
5. Tap "-" button until reaching minimum
6. **Verify**: Amount does not go below minimum (suggested fare rounded up to 5)
7. **Verify**: "-" button appears disabled at minimum

### Test 4: Payment Method Selection (US3)

1. On price screen, verify "Cash" chip is shown by default
2. Tap the Cash chip
3. **Verify**: Bottom sheet appears with 5 options: Cash, Wallet, Card, Vodafone Cash, Fawry
4. Select "Wallet"
5. **Verify**: Chip updates to show "Wallet" with wallet icon

### Test 5: Passenger Count (US3)

1. On price screen, verify "1 Passenger" chip is shown by default
2. Tap the passenger chip
3. **Verify**: Picker shows options 1, 2, 3
4. Select 2
5. **Verify**: Chip updates to "2 Passengers"

### Test 6: Add Note (US4)

1. On price screen, tap "Add Note" chip
2. **Verify**: Dialog appears with text input
3. Type "Meet at the back gate" and tap save
4. **Verify**: Chip changes to "Note Added" with checkmark icon
5. Tap the chip again
6. **Verify**: Dialog opens pre-filled with "Meet at the back gate"

### Test 7: Submit Ride Request — Success (US5)

1. On price screen with offer set to 50 EGP
2. Tap "Request Ride"
3. **Verify**: Button shows loading spinner, becomes non-tappable
4. **Verify**: Navigation to bids screen occurs
5. Open Firebase Console → Firestore → `trips/` collection
6. **Verify**: New document exists with:
   - `status` = "searching"
   - `suggested_price` = system-calculated value
   - `final_price` = 50
   - `payment_method` = "cash"
   - `passenger_count` = 1
   - `customer_uid` = current user's UID
   - `pickup_address`, `pickup_lat`, `pickup_lng` populated
   - `dropoff_address`, `dropoff_lat`, `dropoff_lng` populated
   - `distance_km` and `duration_mins` populated
   - `created_at` = server timestamp

### Test 8: Submit Ride Request — Network Error (US5 Edge Case)

1. On price screen, enable airplane mode
2. Tap "Request Ride"
3. **Verify**: Error snackbar appears
4. **Verify**: Button returns to normal state (not stuck in loading)
5. Disable airplane mode and retry
6. **Verify**: Trip is created successfully on retry

### Test 9: Same Location Guard (Edge Case)

1. Navigate to price screen with pickup and dropoff at the same coordinates
2. Tap "Request Ride"
3. **Verify**: Snackbar shows "Pickup and dropoff cannot be the same location"
4. **Verify**: No trip document is created

### Test 10: Maximum Offer Cap (US2 Edge Case)

1. On price screen, tap "+" repeatedly until offer reaches 999 EGP
2. **Verify**: Amount stops at 999, "+" button becomes disabled
3. Tap "-" once
4. **Verify**: Amount decreases to 994

### Test 11: Back Navigation (Edge Case)

1. On price screen, tap the back button
2. **Verify**: Returns to previous screen (dropoff selection)
3. Open Firestore → `trips/` collection
4. **Verify**: No new trip document was created

### Test 12: Arabic RTL Layout (SC-004)

1. Switch app language to Arabic
2. Navigate to price screen
3. **Verify**: All text is in Arabic
4. **Verify**: Layout is RTL — back arrow points right, "EGP" label shows as "ج.م"
5. **Verify**: Bottom sheet content is right-aligned
6. **Verify**: +/- buttons are correctly positioned

### Test 13: English LTR Layout (SC-004)

1. Switch app language to English
2. Navigate to price screen
3. **Verify**: All text is in English
4. **Verify**: Layout is LTR — standard Western layout
5. **Verify**: All elements match stitch/set_route_and_place_bid_1 design

### Test 14: Design Match (SC-005)

1. Open `stitch/set_route_and_place_bid_1/screen.png` for reference
2. Navigate to price screen
3. **Verify** visual match:
   - Map fills top portion of screen with route polyline
   - White bottom sheet with drag handle
   - Pickup address with red circle icon
   - Dropoff address with location pin icon
   - "Recommended Fare" text with "Fair Price: EGP XX" badge (red outlined)
   - "YOUR OFFER" label centered
   - Large bold offer number with "EGP" suffix
   - Circular -/+ buttons flanking the number
   - Hint text below offer
   - Chip row: Cash, Passenger count, Add Note
   - Full-width red "Request Ride" button at bottom
