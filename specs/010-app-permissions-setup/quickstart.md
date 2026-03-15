# Quickstart: App Permissions Setup

**Feature Branch**: `010-app-permissions-setup`
**Date**: 2026-03-02

## Prerequisites

- Flutter SDK 3.x installed
- Firebase project configured (existing setup)
- Firebase Cloud Messaging enabled in Firebase Console (default)
- Android emulator or physical device for testing
- iOS simulator available (for iOS notification testing)

## Quick Setup

```bash
# 1. Switch to feature branch
git checkout 010-app-permissions-setup

# 2. Install new dependencies (firebase_messaging, flutter_local_notifications)
flutter pub get

# 3. Run the customer app
flutter run -t lib/main_customer.dart --dart-define=GOOGLE_MAPS_API_KEY=<your_key>

# 4. Run the driver app (for background location testing)
flutter run -t lib/main_driver.dart --dart-define=GOOGLE_MAPS_API_KEY=<your_key>
```

## Key Files to Create/Modify

| File | Action | Purpose |
|------|--------|---------|
| `pubspec.yaml` | MODIFY | Add firebase_messaging, flutter_local_notifications |
| `android/app/src/main/AndroidManifest.xml` | MODIFY | Add location, notification, foreground service permissions |
| `lib/core/services/fcm_service.dart` | CREATE | FCM initialization, token management, message handling |
| `lib/core/app_initializer.dart` | MODIFY | Register background message handler |
| `lib/features/auth/controllers/auth_controller.dart` | MODIFY | Call FCM init after login, clear token on logout |
| `lib/core/translations/app_translations.dart` | MODIFY | Add permission-related translation keys |
| `lib/main_customer.dart` | MODIFY | Register background message handler |
| `lib/main_driver.dart` | MODIFY | Register background message handler |

## Architecture Overview

```
App Startup (main_customer.dart / main_driver.dart)
├── Register background message handler (top-level function)
├── AppInitializer.init()
│   ├── Firebase.initializeApp()
│   └── Register AuthController (global)
│
Login Success (AuthController._navigateAfterAuth)
├── FcmService.initialize()
│   ├── Request notification permission (OS prompt)
│   ├── Get FCM token
│   ├── Save token to Firestore (users/{uid}/fcm_token)
│   ├── Set up foreground message listener
│   └── Set up token refresh listener
│
Foreground Message Received
├── FcmService._onForegroundMessage()
│   └── Show local notification via flutter_local_notifications
│
Background/Terminated Message Received
├── firebaseMessagingBackgroundHandler() [top-level]
│   └── (handled by OS notification tray)
│
Logout (AuthController.signOut)
├── FcmService.clearToken()
│   ├── Update Firestore: fcm_token = null
│   └── Delete local FCM instance token
```

## Testing

```bash
# Manual test checklist:

# Push Notifications (US1):
# 1. Install app → login → grant notification permission → check Firestore for fcm_token
# 2. Send test notification from Firebase Console → app in foreground → banner appears
# 3. Send test notification → app in background → system tray notification appears
# 4. Send test notification → app terminated → system tray notification appears
# 5. Deny notification permission → app continues without crash
# 6. Logout → check Firestore fcm_token is null

# Customer Location (US2):
# 7. Fresh install → open home screen → location permission prompt appears
# 8. Grant location → map shows current position
# 9. Deny location → friendly message with settings link
# 10. "Don't ask again" → settings deep-link instead of prompt

# Driver Location (US3):
# 11. Driver app → go online → foreground location permission prompt
# 12. Grant foreground → request background location with explanation
# 13. Grant background → minimize app → GPS updates continue in Realtime DB
# 14. Deny background → warning message, foreground-only tracking works

# Notification Channels (US4):
# 15. Check Android Settings → BikeRide app → 2 notification channels visible
# 16. Mute Promotions channel → promotional notification is silent
```

## Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| No notification permission prompt | Android < 13 (doesn't need runtime permission) | Normal — notifications work without prompt on Android < 13 |
| FCM token not saving | User not logged in when FcmService.initialize() called | Ensure FCM init is called after auth success |
| Foreground notification not showing | Missing flutter_local_notifications setup | Check notification channels are created on init |
| Background location stops after ~10 min | No foreground service | Verify FOREGROUND_SERVICE permission and persistent notification |
| "Exact alarm" crash on Android 14+ | flutter_local_notifications scheduling | Don't use scheduled notifications (we don't need them) |
