# Feature Specification: Map Integration

**Feature Branch**: `014-map-integration`  
**Created**: 2026-03-03  
**Status**: Draft  
**Input**: User description: "Based on the TODO comments in app_map_widget.dart where your cursor currently is, here is what needs to be implemented: Google Maps Integration: Replace the current placeholder Container with an actual GoogleMap widget from the google_maps_flutter package. Real-time Location Tracking: Use the geolocator package to fetch and display the user's or driver's live location on the map. Route Visualization & Polylines: Use the flutter_polyline_points package to draw paths between the pickup and dropoff locations when a trip is active. Marker Clustering: Render custom map markers to show multiple available drivers cleanly for the customer or admin screens. Map Styling: Apply custom map JSON styles to seamlessly support the app's established light and dark themes."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - View Real-Time Location (Priority: P1)

Users (Customers and Drivers) need to see their real-time location on a map to know where they are and verify that the app accurately tracks them for ride or delivery matching.

**Why this priority**: Without accurate self-location, core app functionality (booking a ride or getting assigned a ride) is impossible.

**Independent Test**: Can be fully tested by opening the app and observing the blue dot (user location) accurately reflecting the device's physical location.

**Acceptance Scenarios**:

1. **Given** the user has granted location permissions, **When** they open a screen with the map widget, **Then** the map should center on their current location and display a user location indicator.
2. **Given** the user is moving, **When** they are viewing the map, **Then** their location indicator should update in real-time.

---

### User Story 2 - View Available Drivers (Priority: P2)

Customers need to see available drivers clustered on the map around their location to understand supply and estimate wait times.

**Why this priority**: Builds trust and shows the scale of the service, directly impacting booking conversion.

**Independent Test**: Can be fully tested by mocking driver locations and verifying that custom markers appear and cluster appropriately based on zoom level.

**Acceptance Scenarios**:

1. **Given** multiple drivers are online nearby, **When** the customer views the map, **Then** custom markers representing drivers should be visible.
2. **Given** drivers are very close to each other, **When** the user zooms out, **Then** the markers should cluster together cleanly to prevent map clutter.

---

### User Story 3 - Trip Route Visualization (Priority: P2)

Users need to see the polyline route between the pickup and dropoff locations when a trip is active to understand the path and estimate arrival.

**Why this priority**: Essential for active trip tracking and providing visibility into the journey.

**Independent Test**: Can be fully tested by providing mock pickup and dropoff coordinates and verifying that a route polyline is correctly drawn on the map.

**Acceptance Scenarios**:

1. **Given** an active trip with a pickup and dropoff location, **When** the map is rendered, **Then** a visible polyline should connect the two points.
2. **Given** a polyline is drawn, **When** the map is displayed, **Then** the camera should adjust to keep the entire route visible within the viewport.

---

### User Story 4 - Themed Map Styling (Priority: P3)

Users need the map to seamlessly blend with the app's overall design system (light/dark mode) for a cohesive UI experience.

**Why this priority**: Highly impacts the perceived quality and premium feel of the application.

**Independent Test**: Can be fully tested by toggling the device or app theme and observing the map tile colors updating accordingly.

**Acceptance Scenarios**:

1. **Given** the app is in light mode, **When** the map is displayed, **Then** it should use the custom light JSON style.
2. **Given** the app is in dark mode, **When** the map is displayed, **Then** it should use the custom dark JSON style.

---

### Edge Cases

- What happens when the user revokes location permissions while the map is active?
- How does the system handle weak or lost GPS signals?
- What happens if the directions API fails to return a polyline route (e.g., disconnected regions)?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST integrate `google_maps_flutter` to render the interactive map.
- **FR-002**: System MUST use `geolocator` to fetch the device's current location and update it in real-time.
- **FR-003**: System MUST request and handle location permissions gracefully.
- **FR-004**: System MUST render custom image markers for vehicles/drivers.
- **FR-005**: System MUST implement marker clustering when multiple markers are in close proximity.
- **FR-006**: System MUST fetch and draw polylines for routes using `flutter_polyline_points`.
- **FR-007**: System MUST apply custom JSON map styles corresponding to the current app theme (Light/Dark).
- **FR-008**: System MUST dynamically bounds-fit the camera when displaying routes or multiple markers.

### Key Entities

- **Location**: Represents latitude and longitude coordinates.
- **Marker**: Represents a point of interest (driver, pickup, dropoff) on the map with a custom icon.
- **Route**: Represents the polyline data and bounds connecting two or more locations.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The map loads and centers on the user's location within 2 seconds of the screen rendering.
- **SC-002**: Location updates are reflected on the map with less than 1 second of latency from the device GPS.
- **SC-003**: Route polylines are fetched and drawn accurately without exceeding API rate limits.
- **SC-004**: The map accurately reflects the app's current theme (light or dark) 100% of the time upon loading.
