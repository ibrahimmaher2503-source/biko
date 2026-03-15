# Research: Google Maps Platform Setup

**Branch**: `009-maps-platform-setup` | **Date**: 2026-03-02

## Research Decisions

### R1: Android API Key — Current State

**Finding**: The Android manifest already has a placeholder API key
configured at `android/app/src/main/AndroidManifest.xml` line 30:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_GOOGLE_MAPS_API_KEY_HERE"/>
```

**Decision**: Replace the placeholder with a `--dart-define`-sourced
value or a property reference. The developer must supply their real
key at build time.

**Approach**: Use Android manifest placeholders via
`build.gradle.kts` property injection:
- Define `GOOGLE_MAPS_API_KEY` in `local.properties` (gitignored).
- Reference it in `build.gradle.kts` as a manifest placeholder.
- AndroidManifest.xml uses `${GOOGLE_MAPS_API_KEY}`.

This keeps the key out of version control while making it available
to the native Maps SDK at build time.

### R2: iOS Google Maps SDK Initialization

**Finding**: The current `ios/Runner/AppDelegate.swift` is a minimal
Flutter template with no Google Maps setup:
```swift
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: ...
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

**Decision**: Add `GMSServices.provideAPIKey()` call in AppDelegate
before `GeneratedPluginRegistrant.register()`.

**Implementation**:
```swift
import GoogleMaps

// In didFinishLaunchingWithOptions, before register():
let mapsApiKey = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_MAPS_API_KEY") as? String ?? ""
GMSServices.provideAPIKey(mapsApiKey)
```

The API key is read from Info.plist at runtime, injected via Xcode
build settings from an xcconfig file that reads from environment or
a gitignored config file.

**Alternative considered**: Hardcoding key directly in
AppDelegate.swift — rejected because it would be committed to
version control (violates FR-006).

### R3: iOS Info.plist Location Permissions

**Finding**: The current Info.plist has NO location permission
descriptions. The `geolocator` package (already a dependency)
requires these keys to request GPS access on iOS. Without them,
the app crashes when requesting location.

**Decision**: Add three location-related keys to Info.plist:
- `NSLocationWhenInUseUsageDescription` — required for foreground GPS
- `NSLocationAlwaysAndWhenInUseUsageDescription` — required for
  driver background tracking (future)
- `NSLocationAlwaysUsageDescription` — backward compatibility

Each must have Arabic and English strings. Since Info.plist only
supports a single string per key, use English (the secondary
language) and rely on iOS localization via `InfoPlist.strings` files
for Arabic.

### R4: iOS API Key Injection Strategy

**Decision**: Use an xcconfig-based approach to inject the API key.

**Approach**:
1. Create `ios/Flutter/Maps.xcconfig` (gitignored) with
   `GOOGLE_MAPS_API_KEY=<actual key>`.
2. Include this file in `Debug.xcconfig` and `Release.xcconfig`.
3. Add `GOOGLE_MAPS_API_KEY` to Info.plist as
   `$(GOOGLE_MAPS_API_KEY)`.
4. Read it in AppDelegate.swift from the Info.plist bundle.

**Alternative considered**: `--dart-define` passed to iOS build —
this works but requires extra plumbing in Xcode to map dart-defines
to native build settings. The xcconfig approach is simpler and more
standard for iOS native configuration.

**Alternative considered**: Directly use `--dart-define` and read
via `String.fromEnvironment` in Dart, then pass to iOS via method
channel — rejected; the Google Maps iOS SDK needs the key BEFORE
Flutter engine initializes.

### R5: Flutter Web Google Maps JavaScript API

**Finding**: The current `web/index.html` has no Google Maps
JavaScript API script tag:
```html
<body>
  <script src="flutter_bootstrap.js" async></script>
</body>
```

**Decision**: Add the Google Maps JavaScript API script tag to
`web/index.html` with the API key passed as a URL parameter.

**Implementation**:
```html
<script src="https://maps.googleapis.com/maps/api/js?key=YOUR_KEY_HERE"></script>
```

For the web platform, the API key must be in the HTML source. This
is inherent to how web APIs work — JavaScript API keys are always
visible in client-side code. Google's recommended approach is to
restrict the key by HTTP referrer in the Cloud Console.

**Risk**: Web API keys are visible in source. This is standard
practice mitigated by:
- HTTP referrer restrictions on the key.
- Separate key for web with only Maps JavaScript API enabled.
- No Places API or other high-cost APIs on the web key.

### R6: MapService API Key Centralization

**Finding**: The current `MapService` in
`lib/core/services/map_service.dart` has a hardcoded placeholder:
```dart
static const String _apiKey = 'YOUR_GOOGLE_MAPS_API_KEY_HERE';
```

**Decision**: Replace with `String.fromEnvironment('GOOGLE_MAPS_API_KEY')`
which reads from `--dart-define=GOOGLE_MAPS_API_KEY=xxx` at build
time.

**Implementation**:
```dart
static const String _apiKey = String.fromEnvironment(
  'GOOGLE_MAPS_API_KEY',
  defaultValue: '',
);
```

The developer passes the key via `--dart-define` when running or
building:
```bash
flutter run --dart-define=GOOGLE_MAPS_API_KEY=AIza...
```

This approach:
- Keeps the key out of source code (FR-006).
- Works for all platforms (Android, iOS, Web).
- Is the official Flutter recommendation for compile-time constants.
- MapService already uses `_apiKey` everywhere — only the
  declaration changes.

**Alternative considered**: Reading from `DevConfig` or adding a
new config constant file — rejected; `String.fromEnvironment` is
the standard Flutter mechanism and doesn't require a separate file
or runtime initialization.

### R7: Error State for Missing/Invalid API Key

**Finding**: When the Google Maps API key is missing or invalid:
- Android: Shows grey tiles with a "For development purposes only"
  watermark, or a grey screen.
- iOS: Shows a blank white/grey map.
- Web: Shows a "This page can't load Google Maps correctly" error
  overlay.

**Decision**: The existing error handling in the pickup screen
(edge case hardening from 008) already shows error states for
offline scenarios. For this feature, no additional error widgets
are needed. The focus is on making the API key WORK on all
platforms, not on adding new error UI.

The spec's acceptance scenario (AS1.3) about showing an error state
for invalid keys is already handled by the existing
`pickup.network_error` and offline message translations.

### R8: Android `local.properties` vs Build-Time Define

**Decision**: Use `local.properties` for the Android API key AND
`--dart-define` for the Dart runtime key. These serve different
purposes:

- `local.properties` → read by `build.gradle.kts` → injected into
  AndroidManifest.xml as a manifest placeholder → used by the native
  Google Maps SDK at app startup.
- `--dart-define` → compiled into Dart code → used by `MapService`
  for HTTP calls to Places API.

The developer sets the key once in `local.properties` and also
passes it via `--dart-define`. A setup guide will document both.

**Simplification option**: It's possible to read the `--dart-define`
value in `build.gradle.kts` via `project.findProperty()`, but this
adds Gradle complexity. The two-location approach is simpler to
understand and debug.

## Summary

| Decision | Choice | Risk |
|----------|--------|------|
| Android key | local.properties → manifest placeholder | Low — standard Android pattern |
| iOS key | xcconfig → Info.plist → AppDelegate | Low — standard iOS pattern |
| iOS permissions | Info.plist + localized strings | None — required for GPS |
| Web key | Script tag in index.html | Low — key restricted by referrer |
| Dart runtime key | `--dart-define` → `String.fromEnvironment` | None — official Flutter approach |
| MapService update | Replace hardcoded string with fromEnvironment | None — one-line change |
| Error handling | Existing error states sufficient | None |
| Key security | No keys in version control, all gitignored | None |
