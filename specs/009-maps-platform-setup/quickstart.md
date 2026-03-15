# Quickstart: Google Maps Platform Setup

**Feature Branch**: `009-maps-platform-setup`
**Date**: 2026-03-02

## Prerequisites

- Flutter SDK 3.x installed
- Google Cloud Console project with these APIs enabled:
  - Maps SDK for Android
  - Maps SDK for iOS
  - Maps JavaScript API
  - Places API
- An API key created with appropriate restrictions:
  - Android: Application restriction with your app's SHA-1
  - iOS: Application restriction with your bundle ID
  - Web: HTTP referrer restriction with your domain
- Xcode installed (for iOS builds)

## Quick Setup

```bash
# 1. Switch to feature branch
git checkout 009-maps-platform-setup

# 2. Set your Android API key
# Edit android/local.properties and add:
# GOOGLE_MAPS_API_KEY=AIzaSy...your_key_here

# 3. Set your iOS API key
# Create ios/Flutter/Maps.xcconfig with:
# GOOGLE_MAPS_API_KEY=AIzaSy...your_key_here

# 4. Set your Web API key
# Edit web/index.html — replace YOUR_GOOGLE_MAPS_API_KEY_HERE
# in the Maps JavaScript API script tag

# 5. Run the customer app (Android)
flutter run -t lib/main_customer.dart \
  --dart-define=GOOGLE_MAPS_API_KEY=AIzaSy...your_key_here

# 6. Run the customer app (iOS)
flutter run -t lib/main_customer.dart \
  --dart-define=GOOGLE_MAPS_API_KEY=AIzaSy...your_key_here

# 7. Run the customer app (Web)
flutter run -t lib/main_customer.dart -d chrome \
  --dart-define=GOOGLE_MAPS_API_KEY=AIzaSy...your_key_here
```

## Key Files Modified

| File | Action | Purpose |
|------|--------|---------|
| `android/app/build.gradle.kts` | MODIFY | Add manifest placeholder from local.properties |
| `android/app/src/main/AndroidManifest.xml` | MODIFY | Use `${GOOGLE_MAPS_API_KEY}` placeholder |
| `ios/Runner/AppDelegate.swift` | MODIFY | Add Google Maps SDK initialization |
| `ios/Runner/Info.plist` | MODIFY | Add location permissions + API key entry |
| `ios/Flutter/Maps.xcconfig` | CREATE | Gitignored file for iOS API key |
| `ios/Flutter/Debug.xcconfig` | MODIFY | Include Maps.xcconfig |
| `ios/Flutter/Release.xcconfig` | MODIFY | Include Maps.xcconfig |
| `web/index.html` | MODIFY | Add Maps JavaScript API script tag |
| `lib/core/services/map_service.dart` | MODIFY | Use String.fromEnvironment for API key |
| `.gitignore` | MODIFY | Add Maps.xcconfig pattern |

## Verification Checklist

```bash
# Manual test checklist:
# 1. Android: Open pickup screen → Google Map renders with tiles
# 2. Android: Pan/zoom map → tiles load smoothly
# 3. iOS: Open pickup screen → Google Map renders with tiles
# 4. iOS: Location permission prompt shows with description
# 5. iOS: Search for address → autocomplete results appear
# 6. Web: Open pickup screen in browser → Google Map renders
# 7. Web: Mouse scroll/drag → map responds to gestures
# 8. Verify: No API keys in git history (git log --all -p | grep AIza)
```

## Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| Grey/blank map on Android | Missing/invalid API key in local.properties | Verify key and ensure Maps SDK for Android is enabled |
| Grey/blank map on iOS | Missing GMSServices.provideAPIKey() call | Check AppDelegate.swift has the import and init call |
| "For development purposes only" watermark | API key restrictions don't include your app | Add SHA-1 (Android) or bundle ID (iOS) to key restrictions |
| App crashes on iOS location request | Missing NSLocationWhenInUseUsageDescription | Verify Info.plist has location permission keys |
| Web shows "can't load Google Maps" | Missing or invalid script tag in index.html | Check script tag URL and ensure Maps JavaScript API is enabled |
| Places search returns empty | API key doesn't have Places API enabled | Enable Places API in Google Cloud Console |
