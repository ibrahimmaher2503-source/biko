# Feature Specification: App Permissions Setup

**Feature Branch**: `010-app-permissions-setup`
**Created**: 2026-03-02
**Status**: Draft
**Input**: User description: "request to send notification and use gps for user and driver"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Request Push Notification Permission (Priority: P1)

As a customer or driver opening the app for the first time, I want
the app to ask for permission to send me push notifications so that
I receive real-time trip updates, bid alerts, and driver arrival
notifications.

Push notifications are critical to the core ride-hailing flow: the
driver needs to know when a new trip request comes in, and the
customer needs to know when a driver accepts their bid, when the
driver arrives, and when the trip is completed. Without push
notifications, both users must keep the app open at all times.

The system needs to register the device with the messaging service,
obtain a device token, save it to the user's profile in the
database, and handle foreground/background notification delivery.

**Why this priority**: Push notifications are the primary
communication channel between the platform and its users.
Without them, the entire bid-accept-track flow is broken — drivers
won't know about new ride requests and customers won't know when
their ride is confirmed.

**Independent Test**: Install the app on a device, open it after
login, grant notification permission when prompted, verify the
permission is recorded, and send a test notification from the
server — it should arrive on the device whether the app is in the
foreground, background, or terminated.

**Acceptance Scenarios**:

1. **Given** a customer opens the app for the first time after
   login, **When** the app initializes, **Then** the system requests
   push notification permission via the native OS prompt.
2. **Given** the user grants notification permission, **When** the
   system registers with the messaging service, **Then** the device
   token is saved to the user's profile in the database.
3. **Given** the app is in the foreground, **When** a push
   notification arrives, **Then** the user sees a local notification
   banner at the top of the screen.
4. **Given** the app is in the background or terminated, **When** a
   push notification arrives, **Then** the system notification tray
   shows the notification with the correct title and body.
5. **Given** the user denies notification permission, **When** the
   app loads, **Then** the app continues to function normally without
   crashing, and no token is saved. The user can enable notifications
   later from device settings.
6. **Given** the user reinstalls the app or clears data, **When**
   the app initializes after login, **Then** a new device token is
   generated and saved, replacing the old one.

---

### User Story 2 - Request Location Permission for Customer App (Priority: P1)

As a customer opening the app, I want the app to request location
permission at the appropriate time so that the app can show my
current position on the map, auto-detect my pickup location, and
find nearby drivers.

Currently, the Android app lacks the required location permission
declarations in its manifest. While location is requested at runtime
in the pickup and home screens, the underlying Android permissions
must be declared for the OS to allow the request.

**Why this priority**: Location is fundamental to the customer
experience. Without proper permission setup on Android, the GPS
features built in earlier features (pickup location, home map)
will fail silently or crash.

**Independent Test**: Install the customer app on an Android device,
open the home screen, verify the location permission prompt appears,
grant it, and confirm the map shows the device's current position.

**Acceptance Scenarios**:

1. **Given** the customer app is installed on an Android device,
   **When** the home screen loads and needs location, **Then** the
   system shows the Android location permission dialog.
2. **Given** the customer grants location permission, **When** the
   home screen or pickup screen requests GPS, **Then** the device
   returns the current position and the map centers on it.
3. **Given** the customer denies location permission, **When** the
   app attempts to use GPS, **Then** the app shows a friendly
   message explaining that location is needed and offers a way to
   open device settings.
4. **Given** the customer selects "Don't ask again" on Android,
   **When** location is needed, **Then** the app detects the
   permanently denied state and provides a settings deep-link
   instead of re-requesting.

---

### User Story 3 - Request Location Permission for Driver App (Priority: P1)

As a driver using the driver app, I want the app to request both
foreground and background location permissions so that the platform
can track my position in real-time while I'm online and available
for ride requests, even when the app is in the background.

The driver app requires background location access because drivers
keep the app running while riding. The system writes the driver's
GPS position to the real-time database every 3 seconds. Without
background location, the position updates stop as soon as the
driver switches to another app (e.g., to read a message or check
navigation).

**Why this priority**: Real-time driver tracking is essential for
the platform. Customers need to see driver positions on the map,
and the system needs driver locations to match them with nearby
ride requests.

**Independent Test**: Install the driver app on an Android device,
log in as a driver, go online, grant foreground and background
location permissions, minimize the app, and verify that the driver's
position continues to update in the real-time database.

**Acceptance Scenarios**:

1. **Given** a driver opens the driver app, **When** the driver
   goes online for the first time, **Then** the system requests
   foreground location permission.
2. **Given** a driver has granted foreground location permission,
   **When** the system needs background tracking, **Then** the app
   requests background location permission with a clear explanation
   of why it's needed.
3. **Given** a driver grants background location permission, **When**
   the driver is online and the app is in the background, **Then**
   GPS position updates continue every 3 seconds to the real-time
   database.
4. **Given** a driver denies background location, **When** the
   driver goes online, **Then** the system warns the driver that
   their position may not update reliably when the app is minimized,
   but allows them to continue with foreground-only tracking.
5. **Given** the driver app is running on Android, **When** the OS
   requires a foreground service for background GPS, **Then** the
   app shows a persistent notification indicating that location
   tracking is active.

---

### User Story 4 - Handle Notification Channels on Android (Priority: P2)

As a user on Android, I want notifications to be organized into
channels so that I can control which types of notifications I
receive (e.g., trip updates vs promotional messages) and so that
notifications appear with appropriate importance levels.

Android 8.0+ requires notification channels. Without them, push
notifications may not display at all. Different types of
notifications need different channels: trip-critical alerts should
be high-priority (with sound), while promotions should be
lower-priority.

**Why this priority**: Required for Android 8.0+ notification
delivery, but the core notification plumbing (US1) must work first.

**Independent Test**: Send different types of test notifications
from the server, verify they appear in the correct notification
channel with appropriate sound/vibration settings, and check that
the user can independently mute channels in device settings.

**Acceptance Scenarios**:

1. **Given** the app is installed on Android 8.0+, **When** the app
   initializes, **Then** two notification channels are created:
   "Trip Updates" (high importance, sound enabled) and "Promotions"
   (default importance).
2. **Given** a trip-related notification arrives, **When** displayed
   on Android, **Then** it uses the "Trip Updates" channel and plays
   a notification sound.
3. **Given** the user mutes the "Promotions" channel in device
   settings, **When** a promotional notification arrives, **Then**
   it is silently delivered without sound.

---

### Edge Cases

- What happens when the device token expires or becomes invalid?
  The system should listen for token refresh events and update the
  stored token automatically. This happens transparently without
  user action.
- What happens when the user logs out? The device token stored in
  the user's profile should be cleared to prevent notifications
  from being sent to the device after logout.
- What happens when the user is logged into both the customer and
  driver apps on the same device? Each app instance gets its own
  device token. The user's profile stores the most recent token
  per app.
- What happens when Android's battery optimization kills the
  background location service? The foreground service notification
  is the primary mitigation — Android is less likely to kill
  services with persistent notifications. The app should also
  restart tracking when brought back to the foreground.
- What happens when the user upgrades from Android 12 to 13? On
  Android 13+, notification permission must be explicitly requested
  at runtime. The system should detect this and request the runtime
  permission on first launch after upgrade.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST request push notification permission
  from the user on both Android and iOS after the user logs in for
  the first time.
- **FR-002**: The system MUST obtain a device messaging token after
  permission is granted and save it to the user's profile in the
  database.
- **FR-003**: The system MUST display incoming notifications when
  the app is in the foreground using a local notification banner.
- **FR-004**: The system MUST deliver notifications when the app is
  in the background or terminated via the OS notification system.
- **FR-005**: The system MUST listen for token refresh events and
  update the stored token in the database when it changes.
- **FR-006**: The system MUST clear the stored device token when
  the user logs out.
- **FR-007**: The system MUST declare location permissions
  (foreground) in the Android manifest for the customer app.
- **FR-008**: The system MUST declare foreground and background
  location permissions plus foreground service permission in the
  Android manifest for the driver app.
- **FR-009**: The system MUST create notification channels on
  Android 8.0+ at app startup for organized notification delivery.
- **FR-010**: The system MUST handle all permission denial states
  gracefully without crashing, providing appropriate fallback
  behavior and guidance to the user.

## Assumptions

- The messaging service is already configured in the project (the
  Firebase project exists and is linked).
- The same project is used for both the customer and driver apps.
- The customer app only needs foreground location access. Background
  location is a driver-only requirement.
- The notification permission request happens after login (not on
  the splash screen) to avoid showing the prompt before the user has
  context about why the app needs it.
- The driver's foreground service notification (for background GPS)
  uses a simple persistent notification — no complex UI is needed.
- Android permission declarations in the manifest are shared across
  the app. The runtime request logic in controllers determines which
  permissions are actually requested per app variant.
- iOS location permission descriptions were already added in a
  previous feature (009-maps-platform-setup). This feature focuses
  on the Android permission declarations and the notification
  plumbing for both platforms.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Push notifications are delivered to the device within
  5 seconds of being sent, on both Android and iOS, in foreground,
  background, and terminated states.
- **SC-002**: The device messaging token is stored in the user's
  profile within 3 seconds of granting notification permission.
- **SC-003**: Location permission prompts appear correctly on
  Android without crashes or silent failures.
- **SC-004**: The driver's GPS position continues to update in the
  real-time database every 3 seconds even when the driver app is
  in the background, for at least 30 minutes continuously.
- **SC-005**: All permission denial paths are handled gracefully —
  the app never crashes when a permission is denied, and the user
  sees a clear explanation of what they're missing.
