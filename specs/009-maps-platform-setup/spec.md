# Feature Specification: Google Maps Platform Setup

**Feature Branch**: `009-maps-platform-setup`
**Created**: 2026-03-02
**Status**: Draft
**Input**: User description: "no maps show also add it in ios and web"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Display Interactive Map on Android (Priority: P1)

As a customer using the Android app, I want to see an interactive
Google Map on the pickup location screen so that I can visually
select where I want to be picked up.

Currently the map is blank or fails to load because the Google Maps
API key is not configured with a valid value. The system needs a
valid API key registered in the Android platform configuration so
the Google Maps SDK can authenticate and render map tiles.

**Why this priority**: Android is the primary development and testing
platform. Without a working map on Android, the entire pickup
feature (008) is non-functional and cannot be tested.

**Independent Test**: Open the customer app on an Android device or
emulator, navigate to the pickup location screen, and verify that
a fully interactive Google Map renders with map tiles, supports
pan/zoom gestures, and shows the center pin.

**Acceptance Scenarios**:

1. **Given** the app is installed on an Android device, **When** the
   customer navigates to the pickup screen, **Then** a full-screen
   Google Map renders with visible map tiles within 5 seconds.
2. **Given** the map has loaded, **When** the customer pinches to
   zoom or swipes to pan, **Then** the map responds to gestures and
   loads new tiles smoothly.
3. **Given** the API key is missing or invalid, **When** the map
   attempts to load, **Then** the system shows an error state rather
   than a blank/grey screen.

---

### User Story 2 - Display Interactive Map on iOS (Priority: P1)

As a customer using the iOS app, I want to see the same interactive
Google Map on the pickup screen so the experience is consistent
across platforms.

The iOS platform requires its own Google Maps SDK initialization.
The API key must be provided in the iOS app delegate, and the
required native frameworks must be linked. Without this setup, the
map will not render on iPhone or iPad devices. Location permission
descriptions must also be added for iOS to allow GPS access.

**Why this priority**: iOS is a primary target platform alongside
Android. Both must work for the app to launch.

**Independent Test**: Open the customer app on an iOS simulator or
device, navigate to the pickup screen, and verify the Google Map
renders identically to Android — with tiles, gestures, and center
pin working correctly.

**Acceptance Scenarios**:

1. **Given** the app is installed on an iOS device, **When** the
   customer navigates to the pickup screen, **Then** a full-screen
   Google Map renders with visible map tiles within 5 seconds.
2. **Given** the iOS app is running, **When** the customer uses the
   Google Places search, **Then** autocomplete results appear and
   selecting one moves the map — identical to Android behavior.
3. **Given** location permission is requested on iOS, **When** the
   system prompt appears, **Then** it shows a clear Arabic/English
   description of why location access is needed.

---

### User Story 3 - Display Interactive Map on Web (Priority: P2)

As an admin or developer previewing the app in a web browser, I want
the Google Map to render in the Flutter Web build so that
web-based testing and the admin panel can display map content.

Flutter Web requires the Google Maps JavaScript SDK to be loaded
via a script tag in the web entry point. Without it, the
google_maps_flutter package cannot render on the web platform.

**Why this priority**: The admin panel is Flutter Web and may need
maps for trip visualization. Also enables web-based testing during
development. Lower priority than mobile since the primary users are
on Android and iOS.

**Independent Test**: Run the customer app as a Flutter Web build,
navigate to the pickup screen, and verify the Google Map renders
in the browser with tile loading and basic gestures.

**Acceptance Scenarios**:

1. **Given** the app is running as Flutter Web, **When** the user
   navigates to a screen with a map, **Then** the Google Map renders
   with visible tiles in the browser.
2. **Given** the web build is running, **When** the user interacts
   with the map via mouse scroll and drag, **Then** the map responds
   to zoom and pan gestures.

---

### Edge Cases

- What happens when the Google Maps API key has incorrect
  restrictions (e.g., Maps SDK not enabled)? The map will show a
  grey grid or an error watermark. The system should display a
  user-facing error message.
- What happens when the device has no internet connection? Map tiles
  fail to load. The system should show a cached map or an offline
  indicator (existing edge case from feature 008).
- What happens when the Google Maps API key quota is exceeded? The
  map stops loading tiles. This is a billing/quota issue outside the
  app but should be monitored.
- What happens when the iOS location permission description is
  missing? The app will crash when requesting location access. The
  permission description must be present before requesting location.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST configure a valid Google Maps API key
  for the Android platform so the Google Maps SDK renders map tiles.
- **FR-002**: The system MUST configure the Google Maps SDK for iOS
  by initializing the API key in the iOS app startup.
- **FR-003**: The system MUST add location permission descriptions
  to the iOS configuration for location access prompts in both
  Arabic and English.
- **FR-004**: The system MUST load the Google Maps JavaScript SDK in
  the Flutter Web entry point so maps render in the browser.
- **FR-005**: The system MUST use a centralized, configurable
  approach for the API key used in server-side HTTP calls (Places
  API) rather than embedding it directly in source code.
- **FR-006**: The system MUST NOT commit actual API keys to version
  control. Keys should be managed via environment configuration with
  placeholder files and setup instructions.

## Assumptions

- The developer has a Google Cloud Console project with the
  following APIs enabled: Maps SDK for Android, Maps SDK for iOS,
  Maps JavaScript API, Places API.
- The API key has appropriate application restrictions configured
  (Android app SHA-1, iOS bundle identifier, web HTTP referrer).
- The same API key can be used across all three platforms (common
  Google Cloud setup) or separate keys can be used per platform.
- The developer will replace placeholder values with their actual
  API key during local setup. A setup guide will document this
  process.
- The existing Firebase API key in google-services.json is separate
  from the Google Maps API key and may not have Maps API scopes
  enabled.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The Google Map renders with visible tiles on the
  pickup screen within 5 seconds on all three platforms (Android,
  iOS, Web).
- **SC-002**: Map gestures (pan, zoom) work correctly on all three
  platforms.
- **SC-003**: The Places API search returns autocomplete results on
  all three platforms when a valid API key is provided.
- **SC-004**: No actual API keys are committed to version control.
  All keys are provided via environment configuration or developer
  setup instructions.
