# Data Model: App Permissions Setup

**Branch**: `010-app-permissions-setup` | **Date**: 2026-03-02

## Existing Entities (Modified)

### UserModel (existing — no schema change)

**Location**: `lib/core/models/user_model.dart`
**Status**: Already has `fcmToken` field. No model changes needed.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| fcmToken | String? | No | Device messaging token for push notifications |

**Serialization**: `toJson()` serializes as `'fcm_token'`.
`fromJson()` reads `'fcm_token'`. `copyWith()` supports
`fcmToken` override. All already implemented.

**Firestore path**: `users/{uid}` → `fcm_token` field.

## New Service: FcmService

**Location**: `lib/core/services/fcm_service.dart`
**Purpose**: Manages push notification setup, permissions, token
lifecycle, and message handling.

### Methods

| Method | Return | Description |
|--------|--------|-------------|
| `initialize()` | `Future<void>` | Request permission, get token, save to Firestore, set up foreground listener |
| `_saveToken(String token)` | `Future<void>` | Write token to `users/{uid}/fcm_token` via FirestoreService |
| `_setupTokenRefreshListener()` | `void` | Listen for token changes and auto-save |
| `_setupForegroundListener()` | `void` | Listen for foreground messages and show local notification |
| `clearToken()` | `Future<void>` | Clear token from Firestore and delete local token (called on logout) |
| `setupNotificationChannels()` | `Future<void>` | Create Android notification channels via flutter_local_notifications |

### Top-Level Function

| Function | Location | Description |
|----------|----------|-------------|
| `firebaseMessagingBackgroundHandler(RemoteMessage)` | `lib/core/services/fcm_service.dart` | Top-level background message handler (required by Firebase) |

## Notification Channels

| Channel ID | Name (EN) | Name (AR) | Importance | Sound | Vibrate |
|------------|-----------|-----------|------------|-------|---------|
| trip_updates | Trip Updates | تحديثات الرحلة | High | Yes | Yes |
| promotions | Promotions | العروض | Default | No | No |

## State Changes in AuthController

**Location**: `lib/features/auth/controllers/auth_controller.dart`

### After Login (in `_navigateAfterAuth`)

```
AUTH SUCCESS
  → FcmService.initialize()
    → Request notification permission
    → Get FCM token
    → Save token to Firestore
    → Set up foreground message listener
    → Set up token refresh listener
  → Navigate to appropriate screen
```

### On Logout (in `signOut`)

```
SIGN OUT
  → FcmService.clearToken()
    → Update Firestore: fcm_token = null
    → Delete local FCM token
  → Clear auth state
  → Navigate to phone login
```

## Android Manifest Changes

**Location**: `android/app/src/main/AndroidManifest.xml`

| Permission | Purpose | Required By |
|------------|---------|-------------|
| `ACCESS_FINE_LOCATION` | GPS for map and pickup | geolocator (customer + driver) |
| `ACCESS_COARSE_LOCATION` | Fallback location | geolocator (customer + driver) |
| `POST_NOTIFICATIONS` | Runtime notification prompt (Android 13+) | firebase_messaging |
| `ACCESS_BACKGROUND_LOCATION` | Driver GPS while app in background | geolocator (driver only) |
| `FOREGROUND_SERVICE` | Persistent service for background GPS | Android OS (driver only) |
| `FOREGROUND_SERVICE_LOCATION` | Foreground service type (Android 14+) | Android OS (driver only) |

## Translation Keys

| Key | English | Arabic |
|-----|---------|--------|
| `permission.notification_title` | Enable Notifications | تفعيل الإشعارات |
| `permission.notification_body` | Get real-time updates about your trips and offers | احصل على تحديثات فورية عن رحلاتك وعروضك |
| `permission.location_denied` | Location access is required to use this feature | الوصول إلى الموقع مطلوب لاستخدام هذه الميزة |
| `permission.location_settings` | Please enable location in Settings | يرجى تفعيل الموقع من الإعدادات |
| `permission.open_settings` | Open Settings | فتح الإعدادات |
| `permission.background_location` | Allow background location for continuous tracking while driving | السماح بالموقع في الخلفية للتتبع المستمر أثناء القيادة |
| `permission.background_denied` | Your location may not update when the app is minimized | قد لا يتم تحديث موقعك عند تصغير التطبيق |
| `notification.tracking_active` | BikeRide is tracking your location | بيكو يتتبع موقعك |
