# Feature Specification: Set Pickup Location

**Feature Branch**: `008-set-pickup-location`
**Created**: 2026-03-02
**Status**: Draft
**Input**: User description: "As a customer who tapped 'Where to?', I want to set my pickup location, so that the driver knows where to come."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Search for Pickup Address (Priority: P1)

As a customer on the pickup location screen, I want to type an
address or place name into a search field and see matching results
so that I can quickly find my exact pickup point.

The customer taps the search bar on the home screen ("Where do you
want to go?") and is navigated to the pickup location screen. The
screen shows a search field at the top, a map in the background,
and their current GPS location pre-filled as the default pickup.
As the customer types, autocomplete suggestions appear filtered to
Egyptian addresses. Tapping a suggestion selects it and moves the
map pin to that location.

**Why this priority**: Address search is the primary way customers
will specify pickup — most users know their location by name, not
by coordinates. Without this, customers cannot begin a trip.

**Independent Test**: Open the app, tap the search bar on home
screen, type a partial address (e.g., "Benha Uni"), verify
autocomplete results appear, tap one, verify the map pin moves to
the selected location and the address displays correctly.

**Acceptance Scenarios**:

1. **Given** the customer is on the pickup screen, **When** they
   type at least 2 characters into the search field, **Then** a
   list of matching Egyptian addresses appears within 2 seconds.
2. **Given** autocomplete results are visible, **When** the
   customer taps a result, **Then** the map centers on that
   location and the address field updates with the full address.
3. **Given** the customer types a query with no matches, **When**
   the results load, **Then** a "No results found" message
   appears.
4. **Given** the customer has selected a pickup location, **When**
   they tap the confirm button, **Then** the system navigates to
   the set dropoff screen, passing the selected pickup location.

---

### User Story 2 - Use Current Location as Pickup (Priority: P1)

As a customer who is standing at their pickup point, I want to
use my current GPS location as the pickup so I do not have to
type anything.

When the pickup screen opens, the system automatically detects the
customer's GPS position and reverse-geocodes it to a readable
address. This is shown as the default pickup. The customer can
accept it immediately by tapping "Confirm Pickup" without any
manual input.

**Why this priority**: Most ride-hailing trips start from where
the customer currently is. Pre-filling the GPS location removes
friction for the majority use case.

**Independent Test**: Open the pickup screen with location
services enabled, verify the map shows a pin at the current GPS
position, verify the address field shows the reverse-geocoded
address, tap "Confirm Pickup" without typing anything, verify
navigation to the dropoff screen with the GPS-based pickup.

**Acceptance Scenarios**:

1. **Given** the customer opens the pickup screen with GPS enabled,
   **When** the screen loads, **Then** the map pin is placed at
   their current position and the address field shows the
   reverse-geocoded address.
2. **Given** the GPS location is pre-filled, **When** the customer
   taps "Confirm Pickup" without searching, **Then** the system
   navigates to the dropoff screen with the current location as
   pickup.
3. **Given** GPS is disabled or permission denied, **When** the
   screen loads, **Then** the map shows a default view of the
   customer's last known location (if available) or a default city
   center, and the address field is empty, prompting the customer
   to search manually.

---

### User Story 3 - Adjust Pickup by Dragging the Map (Priority: P2)

As a customer who needs to fine-tune their pickup to an exact
spot (e.g., a specific building entrance), I want to drag the
map so the center pin lands precisely where I want the driver to
come.

The pickup screen has a fixed pin in the center of the map. When
the customer drags/pans the map, the pin stays centered and the
map moves underneath it. When the customer stops dragging, the
system reverse-geocodes the new center position and updates the
address field.

**Why this priority**: Search is often approximate (e.g., finds
the university but not the specific gate). Map adjustment lets
customers pinpoint the exact spot, which is critical for driver
navigation in Egypt where addresses can be imprecise.

**Independent Test**: Open the pickup screen, drag the map to a
different location, verify the address field updates to match
the new map center, tap "Confirm Pickup" and verify the adjusted
location is passed to the dropoff screen.

**Acceptance Scenarios**:

1. **Given** the pickup screen is showing a location, **When** the
   customer drags the map and releases, **Then** the address field
   updates with the reverse-geocoded address of the new map center
   within 1 second.
2. **Given** the customer drags the map to an area where
   reverse-geocoding returns no result, **When** the drag ends,
   **Then** the address field shows "Selected location" with the
   coordinates as a fallback, and the confirm button remains
   enabled.

---

### User Story 4 - Select Pickup from Recent/Saved Locations (Priority: P2)

As a returning customer, I want to quickly select a pickup from
my recently used or saved locations so I do not have to search
every time.

Below the search field, a list of saved locations (Home, Work) and
recent locations appears. Tapping one immediately sets it as the
pickup, moves the map pin, and fills the address field — ready to
confirm.

**Why this priority**: Repeat users take similar trips. Saved and
recent locations dramatically reduce friction for returning
customers. However, this depends on US1 being complete first since
the location data structure must exist.

**Independent Test**: Open the pickup screen with at least one
recent location available, verify the recent locations list
appears below the search field, tap a recent location, verify the
map moves to that location and the address updates, confirm and
verify the selected location is passed forward.

**Acceptance Scenarios**:

1. **Given** the customer has previously used locations, **When**
   the pickup screen loads, **Then** saved locations (Home, Work)
   appear at the top and recent locations appear below them.
2. **Given** a recent location is visible, **When** the customer
   taps it, **Then** the map pin moves to that location and the
   address field updates immediately.
3. **Given** the customer has no saved or recent locations, **When**
   the pickup screen loads, **Then** the recent/saved section is
   hidden and only the search field and map are shown.

---

### Edge Cases

- What happens when the customer's GPS accuracy is poor (>50m)?
  The system uses the location but displays a visual indicator
  that accuracy is low, encouraging manual adjustment.
- What happens when the customer has no internet connection?
  The map tiles may not load. The system shows an offline message
  and allows the customer to retry or go back.
- What happens when Google Places API returns an error or is
  rate-limited? The system shows a user-friendly error message
  ("Could not search addresses, please try again") and allows
  retry.
- What happens when the customer presses back after selecting a
  location? The selected location is discarded and the customer
  returns to the home screen.
- What happens when the pickup screen receives pre-filled data
  (e.g., from a recent location tap on the home screen)? The
  screen opens with the passed location already set on the map
  and address field, ready for confirmation or adjustment.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST display an interactive map centered on
  the customer's current GPS location when the pickup screen opens.
- **FR-002**: System MUST show a fixed center pin on the map that
  represents the selected pickup point.
- **FR-003**: System MUST provide a search field that accepts text
  input and returns address autocomplete suggestions filtered to
  Egypt.
- **FR-004**: System MUST display autocomplete results after the
  customer types at least 2 characters, with results appearing
  within 2 seconds.
- **FR-005**: System MUST reverse-geocode the map center position
  to a readable address whenever the map is moved or a location
  is selected.
- **FR-006**: System MUST update the address field and map pin
  when the customer selects an autocomplete result.
- **FR-007**: System MUST allow the customer to pan/drag the map
  to fine-tune the pickup location, updating the address on
  release.
- **FR-008**: System MUST pre-fill the pickup location from GPS
  on screen load when location permission is granted.
- **FR-009**: System MUST handle the case where GPS is unavailable
  by showing the last known location or a default city view and
  prompting manual search.
- **FR-010**: System MUST provide a "Confirm Pickup" button that
  navigates to the set dropoff screen, passing the selected
  location data (name, address, latitude, longitude).
- **FR-011**: System MUST display saved locations (Home, Work) and
  recent locations below the search field when available.
- **FR-012**: System MUST accept pre-filled location data passed
  via navigation arguments (e.g., from recent location tap on
  home screen) and display it on load.
- **FR-013**: System MUST support both Arabic (RTL) and English
  (LTR) layouts, with all text localized.
- **FR-014**: System MUST display a back button that returns the
  customer to the home screen, discarding any selection.

### Key Entities

- **Place**: Represents a geographic location the customer can
  select as pickup. Attributes: display name, full address,
  latitude, longitude. Can be constructed from GPS reverse-geocode
  results, address search results, or saved location data.
- **Saved Location**: A user-labeled place (e.g., "Home", "Work")
  stored persistently. Extends Place with a label and icon type.
- **Recent Location**: A previously used pickup or dropoff point,
  ordered by recency. Attributes: same as Place plus a timestamp.

## Assumptions

- The customer is authenticated before reaching this screen.
- Location permission is requested during onboarding or on first
  access if not yet granted.
- The Google Maps API key is configured and available via
  environment variables.
- The Google Places API key is the same as the Maps API key
  (standard Google Cloud setup).
- Results are biased to Egypt (country=eg) by default; no
  international address support is needed.
- The "Confirm Pickup" action navigates to a separate "Set
  Dropoff" screen (the next feature in the trip creation flow).
  This spec does not cover the dropoff screen.
- The pickup screen uses the route `/customer/trip/pickup`
  already defined in the app routes.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Customers can select a pickup location (via search,
  GPS, map drag, or recent location) and confirm it in under 15
  seconds for the GPS path and under 30 seconds for the search
  path.
- **SC-002**: Address autocomplete suggestions appear within 2
  seconds of the customer typing 2+ characters.
- **SC-003**: 95% of pickup selections successfully pass valid
  location data (name, address, latitude, longitude) to the
  dropoff screen.
- **SC-004**: The screen loads with the customer's current GPS
  location pre-filled within 3 seconds when location services are
  enabled.
- **SC-005**: The feature works correctly in both Arabic (RTL)
  and English (LTR) modes with no layout or text rendering issues.
- **SC-006**: The feature gracefully handles GPS unavailability,
  network errors, and API failures without crashing, always
  providing a fallback path for the customer.
