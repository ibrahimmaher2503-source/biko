# Research: App Permissions Setup

**Branch**: `010-app-permissions-setup` | **Date**: 2026-03-02

## Research Decisions

### R1: Firebase Cloud Messaging Package Version

**Decision**: Add `firebase_messaging: ^15.1.0` to pubspec.yaml.

**Rationale**: The constitution mandates Firebase Cloud Messaging
(FCM) as the push notification service (Principle I, Push boundary).
The project uses `firebase_core: ^3.0.0` and `firebase_auth: ^5.0.0`
which are FlutterFire 3.x compatible. The `firebase_messaging`
package ^15.x is the compatible version for this generation.

**Alternatives considered**:
- `onesignal_flutter` — rejected per constitution (Firebase-only).
- `flutter_pusher` — rejected per constitution.

### R2: Local Notification Package for Foreground Display

**Decision**: Add `flutter_local_notifications: ^18.0.0` to
pubspec.yaml.

**Rationale**: Firebase Messaging does not display notifications
when the app is in the foreground on Android or iOS by default.
`flutter_local_notifications` is the standard companion package
for showing banner-style notifications while the app is active.
It also provides the notification channel API needed for US4
(Android notification channels).

**Alternatives considered**:
- `awesome_notifications` — rejected; heavier dependency with more
  features than needed. `flutter_local_notifications` is the
  de facto standard and is officially referenced in FlutterFire docs.
- Manual platform channel — rejected; unnecessary complexity when
  a well-maintained package exists.

### R3: FCM Service Architecture

**Decision**: Create `FcmService` as a static utility class in
`lib/core/services/fcm_service.dart`.

**Rationale**: Follows the same pattern as `FirebaseService` and
`MapService` — static utility classes in `lib/core/services/`. The
service handles:
- `initialize()` — request permission, get token, set up listeners
- `_saveToken(String token)` — write to Firestore
- `_onTokenRefresh(String token)` — update on refresh
- `_onForegroundMessage(RemoteMessage)` — show local notification
- `_onBackgroundMessage(RemoteMessage)` — top-level handler

Per constitution Principle III (Feature-First), this is a core
service because FCM is used by both customer and driver apps across
multiple features.

### R4: FCM Token Storage Approach

**Decision**: Save the FCM token to the existing `fcm_token` field
in the `users/{uid}` Firestore document using
`FirestoreService.updateUser()`.

**Rationale**: The `UserModel` already has an `fcmToken` field
(nullable String) and `toJson()` serializes it as `fcm_token`.
`FirestoreService.updateUser()` uses `SetOptions(merge: true)`,
which is correct for updating a single field without overwriting
the entire document.

The token save happens in two places:
1. After initial permission grant (in `FcmService.initialize()`).
2. On token refresh event (in `_onTokenRefresh()`).

Both require the user's UID from `FirebaseAuth.instance.currentUser`.

### R5: FCM Initialization Timing

**Decision**: Initialize FCM in `AppInitializer.init()` after
Firebase Core is initialized but call `requestPermission()` only
after login completes.

**Rationale**: Firebase Messaging must be initialized after
`Firebase.initializeApp()`. However, permission should NOT be
requested on the splash screen — the spec assumes it happens after
login so the user has context. The flow is:

1. `AppInitializer.init()` → `FirebaseService.initialize()` →
   set up `FirebaseMessaging.onBackgroundMessage()` handler
   (must be top-level).
2. `AuthController._navigateAfterAuth()` (after successful login) →
   `FcmService.initialize()` → requests permission, gets token,
   saves to Firestore, sets up foreground listener.

This ensures the background message handler is registered early
(required by Firebase), while the permission prompt is delayed
until after login.

### R6: Android Manifest Permission Declarations

**Decision**: Add the following permissions to
`android/app/src/main/AndroidManifest.xml`:

- `ACCESS_FINE_LOCATION` — required for GPS (geolocator)
- `ACCESS_COARSE_LOCATION` — fallback for GPS
- `POST_NOTIFICATIONS` — required for Android 13+ notification
  permission at runtime
- `ACCESS_BACKGROUND_LOCATION` — required for driver background GPS
- `FOREGROUND_SERVICE` — required for driver background GPS service
- `FOREGROUND_SERVICE_LOCATION` — required for Android 14+ to
  specify foreground service type

**Rationale**: These permissions are required by the Android OS.
Without `ACCESS_FINE_LOCATION`, the geolocator package cannot
request location permission at runtime. Without `POST_NOTIFICATIONS`,
Firebase Messaging cannot request notification permission on
Android 13+.

Note: Both customer and driver apps share the same manifest. The
runtime code determines which permissions are actually requested
(customer skips background location, driver requests it).

**Alternative considered**: Separate manifests for customer vs
driver build flavors — rejected for now; adds build complexity.
The extra permissions declared but not requested at runtime have
no effect on the user.

### R7: Android Notification Channels

**Decision**: Create two notification channels at app startup using
`flutter_local_notifications`:

1. **trip_updates** — High importance, sound enabled, vibration
   enabled. For: new bids, bid accepted, driver arriving, trip
   completed.
2. **promotions** — Default importance, no vibration. For: promo
   codes, referral rewards, general announcements.

**Rationale**: Android 8.0+ requires at least one notification
channel for notifications to display. Separating trip-critical
notifications from promotions lets users mute promotions without
losing trip alerts. Two channels is sufficient for launch — more
can be added later.

### R8: FCM Token Cleanup on Logout

**Decision**: Clear the `fcm_token` field in Firestore when the
user logs out, and delete the local FCM token instance.

**Implementation location**: `AuthController.signOut()` — before
clearing auth state, call
`FirestoreService.updateUser(uid, {'fcm_token': null})` and
`FirebaseMessaging.instance.deleteToken()`.

**Rationale**: If the token is not cleared, push notifications
will continue to be sent to the device after the user logs out.
This is both a privacy concern and a UX issue (the user would
receive notifications for a session they've ended).

### R9: Background Message Handler

**Decision**: Register a top-level function as the background
message handler via
`FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler)`.

**Rationale**: Firebase Messaging requires the background handler
to be a top-level function (not a class method or closure). This
function runs in a separate isolate. It should be registered in
the main entry points (`main_customer.dart`, `main_driver.dart`)
before `runApp()`.

The handler itself is minimal — it logs the message. The actual
display is handled by the OS for data+notification messages.

### R10: Translation Keys for Permission Prompts

**Decision**: Add permission-related translation keys to
`app_translations.dart` for:
- Notification permission explanation
- Location permission denied message
- Background location explanation for driver
- Settings deep-link prompt
- Foreground service notification text

**Rationale**: Constitution Principle IV (Bilingual RTL-First)
requires all user-facing strings to use `.tr` keys in both
Arabic and English.

## Summary

| Decision | Choice | Risk |
|----------|--------|------|
| FCM package | firebase_messaging ^15.1.0 | None — official FlutterFire |
| Local notifications | flutter_local_notifications ^18.0.0 | None — standard companion |
| Service architecture | FcmService static class in core/services/ | None — follows existing pattern |
| Token storage | Existing fcmToken field in UserModel | None — field already exists |
| Init timing | Background handler early, permission after login | None — best practice |
| Android permissions | 6 permission declarations in manifest | None — required by OS |
| Notification channels | 2 channels (trip_updates, promotions) | None — extensible |
| Logout cleanup | Clear token in Firestore + delete local | None — privacy requirement |
| Background handler | Top-level function in main files | None — Firebase requirement |
| Translations | ~8 new keys in AR + EN | None — follows existing pattern |
