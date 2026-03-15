# Data Model: Driver Authentication & Onboarding

**Branch**: `012-driver-auth-onboarding` | **Date**: 2026-03-02

## Entities

All entities below already exist in the codebase. No new models are required. This document serves as a reference for the implementation tasks.

### User (existing: `lib/core/models/user_model.dart`)

| Field | Type | Description |
|-------|------|-------------|
| uid | String | Firebase UID (primary key) |
| name | String | Display name |
| phone | String | Phone number (10 digits, no prefix) |
| email | String? | Optional email (from social auth) |
| authProviders | List\<String\> | Auth methods used: 'phone', 'google', 'facebook' |
| type | UserType | customer, driver, merchant |
| status | UserStatus | active, suspended, pendingApproval |
| walletBalance | double | Balance in EGP |
| referralCode | String? | User's referral code |
| referredBy | String? | Referrer UID |
| lang | String | 'ar' or 'en' (default: 'ar') |
| theme | String | 'light' or 'dark' (default: 'light') |
| avatarUrl | String? | Profile photo URL |
| fcmToken | String? | FCM token |
| createdAt | DateTime | Account creation timestamp |

**Profile completeness**: `name.trim().isNotEmpty`

**State transitions relevant to this feature**:
```
[new user] → (auth) → status: active, type: TBD
           → (profile setup) → name set, isProfileComplete = true
           → (driver registration) → type: driver, status: pendingApproval
           → (admin approval) → status: active
```

### Driver Profile (existing: `lib/core/models/driver_profile_model.dart`)

| Field | Type | Description |
|-------|------|-------------|
| uid | String | Driver UID (matches user uid) |
| nationalId | String? | National ID number |
| licenseNumber | String? | Driving license number |
| vehicleType | VehicleType | motorcycle, scooter, ebike |
| plateNumber | String | Vehicle plate number |
| vehicleModel | String | e.g., "Honda Wing 2022" |
| isOnline | bool | Availability status |
| isApproved | bool | Admin approval status |
| currentLat | double? | Current latitude |
| currentLng | double? | Current longitude |
| ratingAvg | double | Average rating (default: 0.0) |
| totalTrips | int | Lifetime trip count |
| totalEarnings | double | Total earnings in EGP |

### Driver Document (existing: `lib/core/models/document_model.dart`)

| Field | Type | Description |
|-------|------|-------------|
| id | String | Auto-generated document ID |
| driverUid | String | Driver UID |
| type | DocumentType | nationalId, license, vehicleRegistration, criminalRecord |
| fileUrl | String | Firebase Storage download URL |
| status | DocumentStatus | pending, approved, rejected |
| adminNote | String? | Admin rejection reason |
| createdAt | DateTime | Upload timestamp |

### Onboarding State (local persistence)

| Key | Type | Storage | Description |
|-----|------|---------|-------------|
| onboarding_completed_driver | bool | SharedPreferences | Driver onboarding seen flag |
| onboarding_completed_customer | bool | SharedPreferences | Customer onboarding seen flag |

**Change from current**: Single `onboarding_completed` key → app-type-specific keys.

## Enums (existing: `lib/core/models/enums.dart`)

### AuthState — requires update

```
idle
sendingOtp
codeSent
verifying
signingInWithGoogle
signingInWithFacebook   ← NEW
authenticated
error
```

### Existing enums (no changes needed)
- **UserType**: customer, driver, merchant
- **UserStatus**: active, suspended, pendingApproval
- **VehicleType**: motorcycle, scooter, ebike
- **DocumentType**: nationalId, license, vehicleRegistration, criminalRecord
- **DocumentStatus**: pending, approved, rejected

## Firestore Collections Used

| Collection | Operation | Who Writes |
|-----------|-----------|------------|
| users/{uid} | Read + Update | Flutter (profile setup, status update) |
| driver_profiles/{uid} | Create | Flutter (registration submission) |
| documents/{doc_id} | Create | Flutter (document upload) |

## Firebase Storage Paths

| Path Pattern | Usage |
|-------------|-------|
| users/{uid}/avatar.jpg | Profile photo |
| documents/{uid}/{docType}_{timestamp}.jpg | Verification documents |
