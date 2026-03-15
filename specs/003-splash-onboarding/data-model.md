# Data Model: Splash, Onboarding, and Authentication Flow

**Feature Branch**: `003-splash-onboarding`
**Date**: 2026-03-01

## Entity Overview

```
┌─────────────┐     ┌──────────────────┐     ┌────────────┐
│  UserModel   │────→│ DriverProfileModel│────→│ DocumentModel│
│  (Firestore) │     │   (Firestore)    │     │  (Firestore) │
└─────────────┘     └──────────────────┘     └────────────┘
      ↑
      │ auth
┌─────────────┐     ┌──────────────────┐
│ FirebaseAuth │     │ OnboardingSlide  │
│   (SDK)      │     │   (local data)   │
└─────────────┘     └──────────────────┘
```

---

## Entity: UserModel

**Firestore collection**: `users/{uid}`
**Created by**: Cloud Function `onUserCreated` (initial doc) + Profile Setup screen (completes fields)
**Used in**: Splash routing, Profile Setup, all app features

### Fields

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `uid` | `String` | Yes | Firebase Auth UID | Unique user identifier |
| `name` | `String` | Yes | `''` | Full display name |
| `phone` | `String` | Yes | — | Phone number in E.164 format (`+20XXXXXXXXXX`) |
| `type` | `UserType` enum | Yes | — | `customer` \| `driver` \| `merchant` |
| `status` | `UserStatus` enum | Yes | `active` | `active` \| `suspended` \| `pending_approval` |
| `walletBalance` | `double` | No | `0.0` | Current wallet balance in EGP |
| `referralCode` | `String` | No | Auto-generated | Unique referral code |
| `referredBy` | `String?` | No | `null` | UID of referring user |
| `lang` | `String` | Yes | `'ar'` | Language preference: `ar` \| `en` |
| `avatarUrl` | `String?` | No | `null` | Firebase Storage URL for profile photo |
| `fcmToken` | `String?` | No | `null` | Firebase Cloud Messaging token |
| `createdAt` | `DateTime` | Yes | Server timestamp | Account creation timestamp |

### Validation Rules

- `name`: Non-empty, max 100 characters, trimmed
- `phone`: Must match pattern `^\+20(10|11|12|15)\d{8}$`
- `type`: Must be valid enum value
- `lang`: Must be `'ar'` or `'en'`
- `avatarUrl`: Must be valid URL if provided (Firebase Storage URL)

### Serialization

```dart
class UserModel {
  // fromJson: Maps Firestore document to model
  factory UserModel.fromJson(Map<String, dynamic> json);

  // toJson: Maps model to Firestore document
  Map<String, dynamic> toJson();

  // copyWith: Immutable update pattern
  UserModel copyWith({String? name, String? lang, ...});
}
```

### State Transitions

```
[new user] → active (default on creation)
active → suspended (admin action — out of scope)
suspended → active (admin action — out of scope)
```

For drivers:
```
[new driver] → pending_approval (after document submission)
pending_approval → active (admin approval — out of scope)
```

---

## Entity: DriverProfileModel

**Firestore collection**: `driver_profiles/{uid}`
**Created by**: Driver Registration screen
**Used in**: Driver registration, splash routing (approval check)

### Fields

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `uid` | `String` | Yes | Firebase Auth UID | Must match `users/{uid}` |
| `nationalId` | `String` | No | `''` | National ID number |
| `licenseNumber` | `String` | No | `''` | Driving license number |
| `vehicleType` | `VehicleType` enum | No | `motorcycle` | `motorcycle` \| `scooter` \| `ebike` |
| `plateNumber` | `String` | No | `''` | Vehicle plate number |
| `vehicleModel` | `String` | No | `''` | Vehicle make/model (e.g., "Honda Wing 2022") |
| `isOnline` | `bool` | No | `false` | Whether driver is accepting rides |
| `isApproved` | `bool` | No | `false` | Admin approval status |
| `currentLat` | `double?` | No | `null` | Current latitude |
| `currentLng` | `double?` | No | `null` | Current longitude |
| `ratingAvg` | `double` | No | `0.0` | Average rating (1-5) |
| `totalTrips` | `int` | No | `0` | Completed trip count |
| `totalEarnings` | `double` | No | `0.0` | Lifetime earnings in EGP |

### Validation Rules

- `vehicleModel`: Non-empty when submitting application
- `plateNumber`: Non-empty when submitting application, uppercase
- `vehicleType`: Valid enum value
- `ratingAvg`: Range 0.0–5.0
- `totalTrips`: Non-negative integer
- `totalEarnings`: Non-negative

### Serialization

```dart
class DriverProfileModel {
  factory DriverProfileModel.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
  DriverProfileModel copyWith({...});
}
```

---

## Entity: DocumentModel

**Firestore collection**: `documents/{doc_id}`
**Created by**: Driver Registration screen (document upload)
**Used in**: Driver registration, admin document review (out of scope)

### Fields

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `id` | `String` | Yes | Auto-generated | Firestore document ID |
| `driverUid` | `String` | Yes | — | Reference to driver's UID |
| `type` | `DocumentType` enum | Yes | — | `national_id` \| `license` \| `vehicle_registration` \| `criminal_record` |
| `fileUrl` | `String` | Yes | — | Firebase Storage download URL |
| `status` | `DocumentStatus` enum | Yes | `pending` | `pending` \| `approved` \| `rejected` |
| `adminNote` | `String?` | No | `null` | Admin review note |
| `createdAt` | `DateTime` | Yes | Server timestamp | Upload timestamp |

### Validation Rules

- `driverUid`: Non-empty, must be valid Firebase UID
- `type`: Valid enum value
- `fileUrl`: Must be valid Firebase Storage URL
- `status`: Valid enum value

### State Transitions

```
[uploaded] → pending (default on creation)
pending → approved (admin action — out of scope)
pending → rejected (admin action — out of scope)
rejected → pending (driver re-uploads)
```

### Serialization

```dart
class DocumentModel {
  factory DocumentModel.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
}
```

---

## Data Class: OnboardingSlide

**Storage**: In-memory only — not persisted to any database
**Used in**: Customer and Driver onboarding screens

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `title` | `String` | Yes | Headline text (localization key) |
| `highlightWord` | `String` | Yes | Word within title to color with primary (localization key) |
| `description` | `String` | Yes | Body text (localization key) |
| `illustration` | `String` | Yes | Asset path for illustration image |
| `index` | `int` | Yes | Slide position (0-based) |

### Predefined Content

**Customer slides**:
```dart
static final customerSlides = [
  OnboardingSlide(
    title: 'onboarding.customer.slide1.title',      // "Beat the Traffic"
    highlightWord: 'onboarding.customer.slide1.highlight', // "Traffic"
    description: 'onboarding.customer.slide1.desc',
    illustration: 'assets/images/onboarding/customer_speed.png',
    index: 0,
  ),
  OnboardingSlide(
    title: 'onboarding.customer.slide2.title',      // "Your Price, Your Choice"
    highlightWord: 'onboarding.customer.slide2.highlight', // "Choice"
    description: 'onboarding.customer.slide2.desc',
    illustration: 'assets/images/onboarding/customer_bidding.png',
    index: 1,
  ),
  OnboardingSlide(
    title: 'onboarding.customer.slide3.title',      // "Fast Delivery"
    highlightWord: 'onboarding.customer.slide3.highlight', // "Delivery"
    description: 'onboarding.customer.slide3.desc',
    illustration: 'assets/images/onboarding/customer_delivery.png',
    index: 2,
  ),
];
```

**Driver slides**:
```dart
static final driverSlides = [
  OnboardingSlide(
    title: 'onboarding.driver.slide1.title',      // "Be Your Own Boss"
    highlightWord: 'onboarding.driver.slide1.highlight', // "Boss"
    description: 'onboarding.driver.slide1.desc',
    illustration: 'assets/images/onboarding/driver_freedom.png',
    index: 0,
  ),
  OnboardingSlide(
    title: 'onboarding.driver.slide2.title',      // "Safe & Reliable"
    highlightWord: 'onboarding.driver.slide2.highlight', // "Reliable"
    description: 'onboarding.driver.slide2.desc',
    illustration: 'assets/images/onboarding/driver_trust.png',
    index: 1,
  ),
  OnboardingSlide(
    title: 'onboarding.driver.slide3.title',      // "Earn More"
    highlightWord: 'onboarding.driver.slide3.highlight', // "More"
    description: 'onboarding.driver.slide3.desc',
    illustration: 'assets/images/onboarding/driver_earnings.png',
    index: 2,
  ),
];
```

---

## Enums

### UserType
```dart
enum UserType { customer, driver, merchant }
```

### UserStatus
```dart
enum UserStatus { active, suspended, pendingApproval }
```
Firestore serialization: `pending_approval` ↔ `pendingApproval`

### VehicleType
```dart
enum VehicleType { motorcycle, scooter, ebike }
```

### DocumentType
```dart
enum DocumentType { nationalId, license, vehicleRegistration, criminalRecord }
```
Firestore serialization: `national_id`, `license`, `vehicle_registration`, `criminal_record`

### DocumentStatus
```dart
enum DocumentStatus { pending, approved, rejected }
```

### AuthState (controller state, not persisted)
```dart
enum AuthState { idle, sendingOtp, codeSent, verifying, authenticated, error }
```

---

## Relationships

```
UserModel (1) ←──→ (0..1) DriverProfileModel
  └── via: uid == uid

DriverProfileModel (1) ←──→ (0..N) DocumentModel
  └── via: uid == driverUid

UserModel.type determines:
  - customer → no DriverProfileModel
  - driver → has DriverProfileModel + DocumentModel(s)
```

---

## Firestore Indexes Required

No composite indexes needed for this spec. All queries are single-field:
- `users/{uid}` — direct document read by UID
- `driver_profiles/{uid}` — direct document read by UID
- `documents` where `driverUid == uid` — single field query (auto-indexed)
