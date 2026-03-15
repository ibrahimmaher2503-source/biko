# Data Model: Profile Auto-Fill, Theme Chooser, Debug Logging & Home Page

**Feature**: `006-profile-theme-home`
**Date**: 2026-03-01

## Entity Changes

### UserModel — Updated

**File**: `lib/core/models/user_model.dart`

**New field**:
- `theme` (String, default: `'light'`) — User's preferred theme mode (`'light'` or `'dark'`)

**Updates required**:
- Constructor: add `this.theme = 'light'`
- `fromJson`: add `theme: json['theme'] as String? ?? 'light'`
- `toJson`: add `'theme': theme`
- `copyWith`: add `String? theme` parameter

### Firestore Document — `users/{uid}`

**New field added to collection**:
```
theme: 'light' | 'dark'    // User's preferred theme
```

No new collections created. Existing `users/{uid}` collection extended.

---

## Local Storage

### SharedPreferences Keys

| Key | Type | Default | Purpose |
|-----|------|---------|---------|
| `theme_mode` | String | `'light'` | Fast theme restoration on app start (before Firestore loads) |

---

## Service Type (In-Memory Only)

The home page service type selector (Ride / Delivery) is purely UI state — not persisted. It will be used when trip creation is implemented in a future feature.

| Value | Display (EN) | Display (AR) |
|-------|-------------|-------------|
| `ride` | Ride | توصيلة |
| `delivery` | Delivery | توصيل طلب |

---

## Data Flow

### Google Profile Auto-Fill Flow
```
FirebaseAuth.currentUser
  → displayName → ProfileSetupController.nameController.text
  → photoURL → ProfileSetupController.avatarUrl.value
```

### Theme Persistence Flow
```
User selects theme
  → Get.changeThemeMode() [immediate visual switch]
  → SharedPreferences.setString('theme_mode', value) [local persistence]

User completes profile
  → FirestoreService.updateUser(uid, {'theme': value}) [remote persistence]

App starts
  → SharedPreferences.getString('theme_mode') [read in AppInitializer]
  → Get.changeThemeMode(restored) [apply before first frame]
```
