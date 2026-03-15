# Data Model: Google Maps Platform Setup

**Branch**: `009-maps-platform-setup` | **Date**: 2026-03-02

## Overview

This feature is a platform configuration feature — it does not
introduce new Dart models, services, or controllers. It modifies
native platform files and one existing Dart constant. No new
entities are created.

## Configuration Files Modified

### Android Configuration

| File | Change | Purpose |
|------|--------|---------|
| `android/app/build.gradle.kts` | Add manifest placeholder for API key | Inject key from local.properties into manifest |
| `android/app/src/main/AndroidManifest.xml` | Change hardcoded value to `${GOOGLE_MAPS_API_KEY}` | Reference build-time property |
| `android/local.properties` | Add `GOOGLE_MAPS_API_KEY=` entry | Developer sets their key here (gitignored) |

### iOS Configuration

| File | Change | Purpose |
|------|--------|---------|
| `ios/Runner/AppDelegate.swift` | Add `import GoogleMaps` + `GMSServices.provideAPIKey()` | Initialize Google Maps iOS SDK |
| `ios/Runner/Info.plist` | Add location permission keys + `GOOGLE_MAPS_API_KEY` entry | iOS permissions + key injection |
| `ios/Flutter/Maps.xcconfig` | New file with `GOOGLE_MAPS_API_KEY=` | Developer sets their key here (gitignored) |
| `ios/Flutter/Debug.xcconfig` | Add `#include "Maps.xcconfig"` | Include key in debug builds |
| `ios/Flutter/Release.xcconfig` | Add `#include "Maps.xcconfig"` | Include key in release builds |

### Web Configuration

| File | Change | Purpose |
|------|--------|---------|
| `web/index.html` | Add Google Maps JavaScript API `<script>` tag | Load Maps JS SDK for web platform |

### Dart Configuration

| File | Change | Purpose |
|------|--------|---------|
| `lib/core/services/map_service.dart` | Replace `_apiKey` constant with `String.fromEnvironment` | Read API key from `--dart-define` at build time |

## API Key Flow Per Platform

### Android
```
local.properties (GOOGLE_MAPS_API_KEY=AIza...)
  → build.gradle.kts (manifestPlaceholders)
    → AndroidManifest.xml (${GOOGLE_MAPS_API_KEY})
      → Google Maps Android SDK (reads from manifest at runtime)
```

### iOS
```
Maps.xcconfig (GOOGLE_MAPS_API_KEY=AIza...)
  → Debug.xcconfig / Release.xcconfig (#include)
    → Info.plist ($(GOOGLE_MAPS_API_KEY))
      → AppDelegate.swift (reads from Bundle.main)
        → GMSServices.provideAPIKey() (SDK initialization)
```

### Web
```
web/index.html (script tag with key=AIza...)
  → Google Maps JavaScript API (loaded at page load)
    → google_maps_flutter_web (uses JS API)
```

### Dart (Places API HTTP calls)
```
--dart-define=GOOGLE_MAPS_API_KEY=AIza...
  → String.fromEnvironment('GOOGLE_MAPS_API_KEY')
    → MapService._apiKey (compile-time constant)
      → HTTP requests to Places Autocomplete/Details APIs
```

## Git Ignore Additions

| Pattern | File | Purpose |
|---------|------|---------|
| `ios/Flutter/Maps.xcconfig` | `.gitignore` | Prevent iOS API key from being committed |

Note: `android/local.properties` is already gitignored by the
default Flutter `.gitignore`.

## No New Dart Models

This feature only touches configuration files and one existing
constant in `map_service.dart`. No new models, controllers, screens,
or widgets are created.
