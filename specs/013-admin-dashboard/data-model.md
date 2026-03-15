# Data Model: Admin Dashboard Web Panel

**Branch**: `013-admin-dashboard` | **Date**: 2026-03-02
**Phase**: 1 — Design & Contracts

## Existing Entities (Reused from `lib/core/models/`)

These models exist and are reused as-is. No modifications needed.

### UserModel (`user_model.dart`)

| Field | Type | Firestore Key | Notes |
|-------|------|---------------|-------|
| uid | String | `uid` | Firebase Auth UID |
| name | String | `name` | Display name |
| phone | String | `phone` | +20 format |
| email | String? | `email` | Optional, from social auth |
| authProviders | List\<String\> | `auth_providers` | google, facebook, phone |
| type | UserType | `type` | customer, driver, merchant |
| status | UserStatus | `status` | active, suspended, pending_approval |
| walletBalance | double | `wallet_balance` | EGP amount |
| referralCode | String? | `referral_code` | |
| referredBy | String? | `referred_by` | |
| lang | String | `lang` | ar, en |
| theme | String | `theme` | light, dark |
| avatarUrl | String? | `avatar_url` | |
| fcmToken | String? | `fcm_token` | |
| createdAt | DateTime? | `created_at` | Firestore Timestamp |

### DriverProfileModel (`driver_profile_model.dart`)

| Field | Type | Firestore Key | Notes |
|-------|------|---------------|-------|
| uid | String | `uid` | |
| nationalId | String | `national_id` | |
| licenseNumber | String | `license_number` | |
| vehicleType | VehicleType | `vehicle_type` | motorcycle, scooter, ebike |
| plateNumber | String | `plate_number` | |
| vehicleModel | String | `vehicle_model` | |
| isOnline | bool | `is_online` | |
| isApproved | bool | `is_approved` | |
| currentLat | double? | `current_lat` | |
| currentLng | double? | `current_lng` | |
| ratingAvg | double | `rating_avg` | 1-5 scale |
| totalTrips | int | `total_trips` | |
| totalEarnings | double | `total_earnings` | EGP |

### TripModel (`trip_model.dart`)

| Field | Type | Firestore Key | Notes |
|-------|------|---------------|-------|
| tripId | String | `trip_id` | |
| customerUid | String | `customer_uid` | |
| driverUid | String? | `driver_uid` | Null during bidding |
| type | TripType | `type` | ride, c2c_delivery, b2b_delivery |
| status | TripStatus | `status` | searching → bidding → accepted → on_the_way → arrived → in_progress → completed → cancelled |
| pickupAddress | String | `pickup_address` | |
| pickupLat | double | `pickup_lat` | |
| pickupLng | double | `pickup_lng` | |
| dropoffAddress | String | `dropoff_address` | |
| dropoffLat | double | `dropoff_lat` | |
| dropoffLng | double | `dropoff_lng` | |
| suggestedPrice | double | `suggested_price` | EGP |
| finalPrice | double? | `final_price` | EGP, set on bid accept |
| commissionAmount | double? | `commission_amount` | EGP |
| paymentMethod | PaymentMethod | `payment_method` | cash, wallet, card, vodafone_cash, fawry |
| distanceKm | double? | `distance_km` | |
| durationMins | int? | `duration_mins` | |
| passengerCount | int | `passenger_count` | Default 1 |
| notes | String? | `notes` | |
| promoCodeUsed | String? | `promo_code_used` | |
| discountAmount | double? | `discount_amount` | |
| createdAt | DateTime? | `created_at` | |
| acceptedAt | DateTime? | `accepted_at` | |
| completedAt | DateTime? | `completed_at` | |

### DocumentModel (`document_model.dart`)

| Field | Type | Firestore Key | Notes |
|-------|------|---------------|-------|
| id | String | `id` | Document ID |
| driverUid | String | `driver_uid` | |
| type | DocumentType | `type` | national_id, license, vehicle_registration, criminal_record |
| fileUrl | String | `file_url` | Firebase Storage URL |
| status | DocumentStatus | `status` | pending, approved, rejected |
| adminNote | String? | `admin_note` | Rejection reason |
| createdAt | DateTime? | `created_at` | |

### Enums (`enums.dart`)

All existing enums with `toJson()` and `fromJson()` serialization:
- `UserType`: customer, driver, merchant
- `UserStatus`: active, suspended, pendingApproval
- `VehicleType`: motorcycle, scooter, ebike
- `DocumentType`: nationalId, license, vehicleRegistration, criminalRecord
- `DocumentStatus`: pending, approved, rejected
- `TripStatus`: searching, bidding, accepted, onTheWay, arrived, inProgress, completed, cancelled
- `TripType`: ride, c2cDelivery, b2bDelivery
- `PaymentMethod`: cash, wallet, card, vodafoneCash, fawry

---

## New Entities (Created in `lib/features/admin/models/`)

### AdminUserModel

Represents the authenticated admin. Extends beyond UserModel with admin-specific fields.

| Field | Type | Firestore Key | Notes |
|-------|------|---------------|-------|
| uid | String | — | From Firebase Auth |
| email | String | — | From Firebase Auth |
| displayName | String? | — | From Firebase Auth |
| role | AdminRole | — | From custom claims: `admin` or `super_admin` |
| lastLoginAt | DateTime? | — | From Firebase Auth metadata |

**Enum `AdminRole`**: `admin`, `superAdmin`

**Source**: Constructed from `FirebaseAuth.instance.currentUser` + `getIdTokenResult().claims['role']`. Not stored in Firestore — derived entirely from Firebase Auth.

**Validation rules**:
- `role` must be present in custom claims; absence = not an admin
- `email` must not be null (admin accounts use email auth)

---

### DashboardStatsModel

Aggregated metrics for the dashboard home screen.

| Field | Type | Default | Notes |
|-------|------|---------|-------|
| tripsToday | int | 0 | Count of trips with createdAt >= startOfDay |
| revenueToday | double | 0.0 | Sum of commissionAmount for completed trips today (EGP) |
| driversOnline | int | 0 | Count from Realtime DB where is_online == true |
| pendingReviews | int | 0 | Count of documents with status == pending |
| totalCustomers | int | 0 | Count of users where type == customer |
| totalDrivers | int | 0 | Count of users where type == driver |
| weeklyTrips | int | 0 | Count of trips in last 7 days |
| weeklyRevenue | double | 0.0 | Commission sum for last 7 days (EGP) |
| cancellationRate | double | 0.0 | Percentage: cancelled / (completed + cancelled) |

**Source**: Client-side aggregation from Firestore queries + Realtime DB listener.

---

### FinancialSummaryModel

Aggregated financial data for a configurable date range.

| Field | Type | Default | Notes |
|-------|------|---------|-------|
| totalRevenue | double | 0.0 | Sum of finalPrice for completed trips (EGP) |
| totalCommission | double | 0.0 | Sum of commissionAmount for completed trips (EGP) |
| totalTopUps | double | 0.0 | Sum of credit transactions with method != cash (EGP) |
| totalRefunds | double | 0.0 | Sum of admin-issued credits (EGP) |
| dateFrom | DateTime | — | Range start |
| dateTo | DateTime | — | Range end |

**Source**: Firestore aggregation queries on `transactions` collection filtered by date range.

---

### CommissionBreakdownModel

Per-service-type financial breakdown for the commission table.

| Field | Type | Notes |
|-------|------|-------|
| serviceType | TripType | ride, c2cDelivery, b2bDelivery |
| tripCount | int | Number of completed trips |
| totalFare | double | Sum of finalPrice (EGP) |
| commissionRate | double | From app_config (0.15, 0.12, or custom) |
| commissionEarned | double | Sum of commissionAmount (EGP) |

---

### NotificationRecordModel

Record of a sent admin notification for the sent history table.

**Firestore collection**: `admin_notifications/{id}`

| Field | Type | Firestore Key | Notes |
|-------|------|---------------|-------|
| id | String | `id` | Auto-generated |
| targetSegment | String | `target_segment` | "all", "customers", "drivers", or specific UID |
| titleAr | String | `title_ar` | Arabic title |
| titleEn | String | `title_en` | English title |
| bodyAr | String | `body_ar` | Arabic body |
| bodyEn | String | `body_en` | English body |
| senderUid | String | `sender_uid` | Admin who sent it |
| senderName | String | `sender_name` | Admin display name |
| sentAt | DateTime | `sent_at` | Firestore Timestamp |

**Methods**: `fromJson()`, `toJson()`

---

### ReferralStatsModel

Aggregated referral program statistics.

| Field | Type | Default | Notes |
|-------|------|---------|-------|
| totalReferrals | int | 0 | Count of all referral records |
| totalRewarded | int | 0 | Count where status == rewarded |
| totalPayout | double | 0.0 | Sum of reward_amount where status == rewarded (EGP) |

**Source**: Firestore aggregation on `referrals` collection.

---

### ChartDataPoint

Generic data point for time-series charts.

| Field | Type | Notes |
|-------|------|-------|
| date | DateTime | Day of the data point |
| value | double | Metric value for that day |
| label | String? | Optional category label (for stacked charts) |

Used by: Revenue chart (30-day line), trip volume (stacked bar), cancellation trend (line).

---

## Entity Relationships

```
AdminUserModel (Firebase Auth)
    └── manages → UserModel (Firestore: users/{uid})
                      ├── type == driver → DriverProfileModel (Firestore: driver_profiles/{uid})
                      │                        └── has → DocumentModel[] (Firestore: documents/{id})
                      └── participates → TripModel (Firestore: trips/{id})
                                             └── has → Bid[] (subcollection: trips/{id}/bids/{bid_id})
                                             └── generates → Transaction (Firestore: transactions/{id})

AppConfig (Firestore: app_config/config) ← read/write by super_admin
PromoCode (Firestore: promo_codes/{code}) ← CRUD by any admin
NotificationRecord (Firestore: admin_notifications/{id}) ← created on send
Referral (Firestore: referrals/{id}) ← read-only by admin
```

---

## State Transitions Relevant to Admin

### Document Review Flow
```
pending → approved (admin approves → driver activated → FCM sent)
pending → rejected (admin rejects with reason → FCM sent with reason)
rejected → pending (driver re-uploads → returns to queue)
```

### User Status (Admin Actions)
```
active → suspended (admin suspends → Firebase Auth disabled)
suspended → active (admin activates → Firebase Auth enabled)
pending_approval → active (via document approval)
```

### Trip Status (Read-Only for Admin)
```
searching → bidding → accepted → on_the_way → arrived → in_progress → completed
                                                                    → cancelled (at any stage)
```
Admin can view all states but only takes action on completed trips (issue credit).

---

## New Firestore Collection

### `admin_notifications/{id}`

```
id, target_segment, title_ar, title_en, body_ar, body_en,
sender_uid, sender_name, sent_at
```

**Security rules**: Read/write by authenticated users with `admin` or `super_admin` custom claim only.
