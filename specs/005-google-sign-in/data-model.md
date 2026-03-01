# Data Model: Google Sign-In

**Feature**: 005-google-sign-in
**Date**: 2026-03-01

## Entity Changes

### UserModel (Modified)

**Location**: `lib/core/models/user_model.dart`

| Field | Type | Required | Default | Change |
|-------|------|----------|---------|--------|
| uid | String | Yes | - | Existing |
| name | String | Yes | - | Existing |
| phone | String | Yes | - | Existing (empty for Google-only users) |
| email | String? | No | null | **NEW** — Google email address |
| authProviders | List<String> | No | [] | **NEW** — e.g. ['phone'], ['google'], ['phone', 'google'] |
| type | UserType | Yes | customer | Existing |
| status | UserStatus | No | active | Existing |
| walletBalance | double | No | 0.0 | Existing |
| referralCode | String | No | '' | Existing |
| referredBy | String? | No | null | Existing |
| lang | String | No | 'ar' | Existing |
| avatarUrl | String? | No | null | Existing (pre-filled from Google photo) |
| fcmToken | String? | No | null | Existing |
| createdAt | DateTime | Yes | - | Existing |

**Validation rules**:
- `phone` may be empty for Google-only users (phone is no longer strictly required for auth)
- `email` is populated from Google account on first Google sign-in
- `authProviders` is updated on each sign-in to track all used methods
- `name` can be pre-filled from Google display name if user is new

**Firestore mapping** (new fields):
- `email` → `email` (String, nullable)
- `authProviders` → `auth_providers` (List<String>)

### AuthState Enum (Modified)

**Location**: `lib/core/models/enums.dart`

| Value | Change |
|-------|--------|
| idle | Existing |
| sendingOtp | Existing |
| codeSent | Existing |
| verifying | Existing |
| signingInWithGoogle | **NEW** — Google sign-in in progress |
| authenticated | Existing |
| error | Existing |

## Firestore Document Changes

### `users/{uid}` — Updated schema

```
uid, name, phone, email (NEW), auth_providers (NEW), type,
status, wallet_balance, referral_code, referred_by,
lang, avatar_url, fcm_token, created_at
```

No new collections. No new subcollections. Only field additions to existing `users` documents.

## State Transitions

### Google Sign-In Flow

```
idle → signingInWithGoogle → authenticated → [navigation]
idle → signingInWithGoogle → error → idle (retry)
idle → signingInWithGoogle → idle (user cancelled)
```

### Comparison with Phone OTP Flow

```
idle → sendingOtp → codeSent → verifying → authenticated → [navigation]
idle → sendingOtp → error → idle
```

Both flows converge at `authenticated` and share the same `_navigateAfterAuth()` logic.
