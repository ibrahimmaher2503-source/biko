# Feature Specification: Customer Home Services Overview

**Feature Branch**: `007-home-services-overview`
**Created**: 2026-03-01
**Status**: Draft
**Input**: User description: "create home module for user using themes, lang, widgets shared and app color. Update core code as needed but finally give me the same design like stitch/home_services_overview"
**Reference Design**: `stitch/home_services_overview/screen.png`

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Service Cards (Ride, Delivery, Merchant) (Priority: P1)

The home screen presents three service cards that let the customer quickly choose what they need. A large prominent "Take a Ride" card with a "POPULAR" badge and "Book Now" action is the primary call-to-action. Below it, two side-by-side cards offer "Package Delivery" and "Merchant Orders". Each card has an icon, title, and short description. The Merchant Orders card uses the brand primary color as a gradient background to stand out.

**Why this priority**: These service cards are the core navigation entry points of the entire app. Without them, users cannot initiate any ride or delivery request. They define the app's value proposition at a glance.

**Independent Test**: Open the home screen. Verify all three service cards are visible with correct styling. Tap "Book Now" on the ride card and verify navigation to the ride booking flow. Tap the delivery card and verify navigation to the delivery request flow. Tap the merchant card and verify it shows a "Coming Soon" message.

**Acceptance Scenarios**:

1. **Given** a logged-in customer on the home screen, **When** they view the service cards section, **Then** they see a large "Take a Ride" card with a "POPULAR" badge, description text, a motorcycle illustration, and a "Book Now" button.
2. **Given** a logged-in customer, **When** they view below the ride card, **Then** they see two equal-width cards: "Package Delivery" (with package icon) and "Merchant Orders" (with store icon on a brand-colored gradient background).
3. **Given** a logged-in customer, **When** they tap "Book Now" on the ride card, **Then** they are navigated to the ride booking flow (set pickup screen).
4. **Given** a logged-in customer, **When** they tap the delivery card, **Then** they are navigated to the delivery request flow.
5. **Given** a logged-in customer, **When** they tap the merchant card, **Then** they see a "Coming Soon" notification since merchant orders are not yet available.

---

### User Story 2 - Location Header & Wallet Badge (Priority: P1)

When a customer opens the home screen, they see their current city/area name prominently displayed at the top with a location indicator, alongside a wallet balance badge showing their available EGP balance. This gives the customer immediate context about where they are and how much money is available.

**Why this priority**: The header establishes trust and context. Showing the location confirms the app knows where the user is. The wallet badge enables quick balance checks without navigating away, reducing friction before booking.

**Independent Test**: Open the home screen after login. Verify the location area shows the user's city. Verify the wallet badge displays the current EGP balance. Tap the wallet badge and verify it navigates to the wallet screen.

**Acceptance Scenarios**:

1. **Given** a logged-in customer with a wallet balance of 150 EGP, **When** they open the home screen, **Then** they see "Current Location" label with their city name and a wallet badge showing "EGP 150".
2. **Given** a logged-in customer with 0 EGP balance, **When** they open the home screen, **Then** the wallet badge shows "EGP 0".
3. **Given** a logged-in customer, **When** they tap the wallet badge, **Then** they are navigated to the wallet screen.

---

### User Story 3 - Bottom Navigation Bar (Priority: P1)

A persistent bottom navigation bar provides access to the five main sections of the customer app: Home, Rides, a central action button (+), Wallet, and Profile. The Home tab is highlighted as active when on the home screen. The center button is elevated and uses the brand primary color, serving as a quick-create action for new ride or delivery requests.

**Why this priority**: The bottom navigation bar is essential for app-wide navigation. Without it, users cannot move between major sections of the app.

**Independent Test**: Open the home screen. Verify the bottom navigation bar is visible with all 5 items. Tap each nav item and verify navigation to the correct screen. Verify Home tab shows active state.

**Acceptance Scenarios**:

1. **Given** a logged-in customer on the home screen, **When** they view the bottom of the screen, **Then** they see a navigation bar with Home (active), Rides, + button (center, elevated), Wallet, and Profile tabs.
2. **Given** a customer on the home screen, **When** they tap the Rides tab, **Then** they are navigated to the rides/trip history screen.
3. **Given** a customer on the home screen, **When** they tap the Wallet tab, **Then** they are navigated to the wallet screen.
4. **Given** a customer on the home screen, **When** they tap the Profile tab, **Then** they are navigated to the profile screen.
5. **Given** a customer on the home screen, **When** they tap the center + button, **Then** they are navigated to the ride/delivery creation flow.

---

### User Story 4 - Search Bar (Priority: P2)

A floating search bar below the header allows customers to quickly search for a destination. It serves as an alternative entry point to the ride/delivery flow by letting the user type where they want to go.

**Why this priority**: The search bar is a secondary entry point. Users can already access rides via the service cards, but the search bar provides a faster path for users who already know their destination.

**Independent Test**: Open the home screen. Verify the search bar is visible with placeholder text. Tap the search bar and verify it navigates to the destination search screen.

**Acceptance Scenarios**:

1. **Given** a logged-in customer on the home screen, **When** they view the search area, **Then** they see a search bar with a search icon and placeholder text "Where do you want to go?".
2. **Given** a logged-in customer, **When** they tap the search bar, **Then** they are navigated to the set-pickup/destination search screen.

---

### User Story 5 - Recent Locations (Priority: P2)

Below the service cards, a "Recent Locations" section shows the customer's previously used pickup/dropoff locations for quick re-use. Each location shows an icon (history or custom like work/home), the location name, and the address. A "See All" link shows all saved/recent locations.

**Why this priority**: Recent locations reduce friction for repeat trips. This is a convenience feature that enhances the experience but is not required for core functionality.

**Independent Test**: Complete at least one trip with a specific destination. Return to the home screen. Verify the recent locations section shows the previously used location with name and address. Tap a recent location and verify it pre-fills the destination.

**Acceptance Scenarios**:

1. **Given** a customer who has previously completed trips, **When** they view the home screen, **Then** they see a "Recent Locations" section with up to 5 recently used locations.
2. **Given** a customer with recent locations, **When** they tap a location item, **Then** the destination is pre-filled and they are navigated to the ride booking flow.
3. **Given** a customer with no trip history, **When** they view the home screen, **Then** the recent locations section is hidden.
4. **Given** a customer with recent locations, **When** they tap "See All", **Then** they see their full location history.

---

### User Story 6 - Map Background & Dark Mode Support (Priority: P3)

The home screen displays a subtle grayscale map of the user's current area as a background layer behind the content. This provides visual context about the user's location. The entire home screen adapts correctly to both light and dark themes, and renders properly in both Arabic (RTL) and English (LTR) layouts.

**Why this priority**: The map background and theme/RTL polish are visual refinements. They enhance the design but do not affect core functionality.

**Independent Test**: Open the home screen. Verify a map or map-style background is visible behind the content. Switch to dark mode and verify all elements adapt. Switch to Arabic and verify RTL mirroring.

**Acceptance Scenarios**:

1. **Given** a logged-in customer on the home screen, **When** they view the screen background, **Then** they see a subtle map-style background with a gradient overlay ensuring content readability.
2. **Given** a customer in dark mode, **When** they view the home screen, **Then** all cards, text, icons, and backgrounds use appropriate dark theme colors.
3. **Given** a customer using Arabic language, **When** they view the home screen, **Then** all elements are mirrored correctly for RTL layout including card positions, text alignment, and icon directions.

---

### Edge Cases

- What happens when the user's wallet balance fails to load? Display "---" as balance and allow tapping to retry/navigate to wallet.
- What happens when location services are disabled? Show "Location unavailable" text with a prompt to enable location services.
- What happens when the user has no internet connection? Show cached data (last known balance, location, recent locations) with an offline indicator.
- How does the layout adapt in Arabic RTL mode? All cards, icons, and text mirror correctly. Chevrons on recent locations flip direction.
- What happens when the user scrolls? The header (location + wallet) remains fixed. Content below scrolls vertically.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST display the user's current city/area name in the header with a location indicator icon.
- **FR-002**: System MUST display the user's wallet balance (in EGP) in a tappable badge that navigates to the wallet screen.
- **FR-003**: System MUST display a search bar with placeholder text that navigates to the destination search screen when tapped.
- **FR-004**: System MUST display a prominent "Take a Ride" service card with a "POPULAR" badge, description, motorcycle illustration, and "Book Now" button.
- **FR-005**: System MUST display a "Package Delivery" card with a package icon, title, and description.
- **FR-006**: System MUST display a "Merchant Orders" card with a store icon on a brand-colored gradient background, title, and description.
- **FR-007**: System MUST navigate to the ride booking flow when the user taps "Book Now" or the ride card.
- **FR-008**: System MUST navigate to the delivery request flow when the user taps the delivery card.
- **FR-009**: System MUST show a "Coming Soon" notification when the user taps the merchant orders card.
- **FR-010**: System MUST display a "Recent Locations" section showing up to 5 previously used locations with name and address.
- **FR-011**: System MUST hide the "Recent Locations" section when the user has no trip history.
- **FR-012**: System MUST pre-fill the destination when the user taps a recent location.
- **FR-013**: System MUST display a persistent bottom navigation bar with Home, Rides, center action (+) button, Wallet, and Profile tabs.
- **FR-014**: System MUST highlight the active tab using the brand primary color.
- **FR-015**: System MUST navigate to the appropriate screen for each bottom navigation tab.
- **FR-016**: System MUST support both Arabic (RTL) and English (LTR) layouts with correct mirroring.
- **FR-017**: System MUST support both light and dark themes with appropriate color adaptations.
- **FR-018**: System MUST display a map-style background with gradient overlay for readability.
- **FR-019**: All text content MUST use localized strings (no hardcoded text).

### Key Entities

- **Location**: User's current area/city, displayed as a human-readable place name with coordinates.
- **Wallet Balance**: User's available balance in EGP from their wallet record.
- **Service Type**: Three categories (Ride, Package Delivery, Merchant Orders) with visual identity and navigation targets.
- **Recent Location**: Previously used address with display name, full address text, and coordinates.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of UI elements from the reference design (`stitch/home_services_overview/screen.png`) are represented on the home screen including header, search bar, three service cards, recent locations, and bottom navigation.
- **SC-002**: Users can navigate to the ride booking flow within 1 tap from the home screen (via "Book Now", ride card, search bar, or + button).
- **SC-003**: The home screen renders correctly in both Arabic (RTL) and English (LTR) with all elements properly mirrored.
- **SC-004**: The home screen renders correctly in both light and dark themes with appropriate color adaptations.
- **SC-005**: The bottom navigation bar provides access to all 5 major app sections from a single tap.
- **SC-006**: Users can check their wallet balance without leaving the home screen.
- **SC-007**: Users with trip history can re-use a previous destination within 2 taps from the home screen.

## Assumptions

- The user's current location is derived from device GPS. If unavailable, the app shows "Location unavailable". Full GPS integration and geocoding are handled by a separate location service feature.
- The wallet balance is read from the user's wallet document. Real-time wallet updates are not required on this screen (balance refreshes on screen load).
- "Take a Ride" and "Package Delivery" card taps navigate to existing or placeholder booking routes. The full booking flow is a separate feature.
- "Merchant Orders" is not yet implemented. Tapping the card shows a "Coming Soon" notification.
- Recent locations are read from trip history. The initial implementation may show hardcoded placeholder items if the trip history feature is not yet built, with the section hidden when no data exists.
- The map background uses a static map image or grayscale placeholder initially. Live interactive maps are a separate feature.
- The bottom navigation bar is built as a reusable component that will persist across other main screens in future features.
- The motorcycle illustration on the ride card uses a local asset image. If no asset is available, a motorcycle icon placeholder is used.
- The existing basic home screen (greeting header + ride/delivery toggle + map placeholder) will be completely replaced by this new design.
