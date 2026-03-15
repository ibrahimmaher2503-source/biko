# Data Model: Trip Booking & Bidding — Price Negotiation

**Feature**: 011-trip-bidding
**Date**: 2026-03-02

## Entities

### TripModel (NEW)

**Collection**: `trips/{trip_id}`
**File**: `lib/core/models/trip_model.dart`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| trip_id | String | Yes | Auto-generated Firestore document ID |
| customer_uid | String | Yes | UID of the requesting customer |
| driver_uid | String | No | UID of the assigned driver (null until bid accepted) |
| type | TripType enum | Yes | "ride" (default for this feature) |
| status | TripStatus enum | Yes | "searching" at creation time |
| pickup_address | String | Yes | Human-readable pickup address |
| pickup_lat | double | Yes | Pickup latitude |
| pickup_lng | double | Yes | Pickup longitude |
| dropoff_address | String | Yes | Human-readable dropoff address |
| dropoff_lat | double | Yes | Dropoff latitude |
| dropoff_lng | double | Yes | Dropoff longitude |
| suggested_price | double | Yes | System-calculated fare from app_config formula |
| final_price | double | Yes | Customer's offer amount |
| commission_amount | double | No | Calculated at trip completion (Cloud Functions) |
| payment_method | PaymentMethod enum | Yes | Cash (default), Wallet, Card, Vodafone Cash, Fawry |
| passenger_count | int | Yes | 1–3 (default 1) |
| notes | String | No | Optional customer note (max 200 chars) |
| distance_km | double | Yes | Route distance from Directions API |
| duration_mins | double | Yes | Estimated trip duration from Directions API |
| promo_code_used | String | No | Applied promo code (future feature) |
| discount_amount | double | No | Discount from promo code (future feature) |
| created_at | Timestamp | Yes | Server timestamp at creation |
| accepted_at | Timestamp | No | Set when driver bid is accepted |
| completed_at | Timestamp | No | Set at trip completion |

**Serialization pattern**: Follows `UserModel` pattern — const constructor, `fromJson()` factory, `toJson()` method, Timestamp handling.

---

### TripStatus (NEW enum)

**File**: `lib/core/models/enums.dart` (append to existing file)

| Value | Firestore String | Description |
|-------|-----------------|-------------|
| searching | "searching" | Trip created, waiting for driver bids |
| bidding | "bidding" | Drivers are submitting bids |
| accepted | "accepted" | Customer accepted a driver bid |
| onTheWay | "on_the_way" | Driver en route to pickup |
| arrived | "arrived" | Driver arrived at pickup |
| inProgress | "in_progress" | Trip active (customer on board) |
| completed | "completed" | Trip finished |
| cancelled | "cancelled" | Trip cancelled by customer or system |

---

### TripType (NEW enum)

**File**: `lib/core/models/enums.dart` (append to existing file)

| Value | Firestore String | Description |
|-------|-----------------|-------------|
| ride | "ride" | Passenger ride (this feature) |
| c2cDelivery | "c2c_delivery" | Customer-to-customer delivery |
| b2bDelivery | "b2b_delivery" | Business delivery |

---

### PaymentMethod (NEW enum)

**File**: `lib/core/models/enums.dart` (append to existing file)

| Value | Firestore String | Description |
|-------|-----------------|-------------|
| cash | "cash" | Cash payment to driver |
| wallet | "wallet" | In-app wallet balance |
| card | "card" | Credit/debit card via Paymob |
| vodafoneCash | "vodafone_cash" | Vodafone Cash mobile wallet |
| fawry | "fawry" | Fawry payment network |

---

### DirectionsResult (NEW — not persisted)

**File**: `lib/core/models/directions_result.dart`

| Field | Type | Description |
|-------|------|-------------|
| polylinePoints | List<LatLng> | Decoded route points for map polyline |
| encodedPolyline | String | Raw encoded polyline from API |
| distanceKm | double | Route distance in kilometers |
| durationMins | double | Estimated duration in minutes |
| boundsNE | LatLng | Northeast corner of route bounds |
| boundsSW | LatLng | Southwest corner of route bounds |

---

## Translation Keys

**File**: `lib/core/translations/app_translations.dart`

| Key | Arabic | English |
|-----|--------|---------|
| trip.recommended_fare | الأجرة الموصى بها | Recommended Fare |
| trip.fair_price | السعر العادل: {price} ج.م | Fair Price: EGP {price} |
| trip.your_offer | عرضك | YOUR OFFER |
| trip.egp | ج.م | EGP |
| trip.bid_hint | السائقون يفضلون العروض الأعلى | Drivers are more likely to accept higher bids |
| trip.request_ride | اطلب رحلة | Request Ride |
| trip.cash | نقدي | Cash |
| trip.wallet | المحفظة | Wallet |
| trip.card | بطاقة | Card |
| trip.vodafone_cash | فودافون كاش | Vodafone Cash |
| trip.fawry | فوري | Fawry |
| trip.passenger | راكب | Passenger |
| trip.passengers | ركاب | Passengers |
| trip.add_note | أضف ملاحظة | Add Note |
| trip.note_added | تم إضافة الملاحظة | Note Added |
| trip.note_hint | ملاحظات للسائق (اختياري) | Note for driver (optional) |
| trip.note_save | حفظ الملاحظة | Save Note |
| trip.same_location_error | نقطة الانطلاق والوصول لا يمكن أن تكونا نفس المكان | Pickup and dropoff cannot be the same location |
| trip.create_failed | فشل إنشاء الطلب. حاول مرة أخرى | Failed to create request. Try again |
| trip.loading_route | جاري تحميل المسار... | Loading route... |
| trip.payment_method | طريقة الدفع | Payment Method |
| trip.passenger_count | عدد الركاب | Passenger Count |

---

## Firestore Operations

### Create Trip

**Collection**: `trips/`
**Method**: `FirestoreService.createTrip(TripModel) → Future<String>` (returns trip_id)
**Operation**: Auto-generate doc ID, write document, return ID
**Security**: Write allowed for authenticated customers (matches `customer_uid`)

### Read app_config

**Collection**: `app_config` (single document)
**Method**: `FirestoreService.getAppConfig() → Future<Map<String, dynamic>?>`
**Fields used**: base_fare, price_per_km, price_per_min
**Security**: Read allowed for any authenticated user
