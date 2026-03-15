# Feature Specification: Profile Auto-Fill, Theme Chooser, Debug Logging & Home Page

**Feature Branch**: `006-profile-theme-home`
**Created**: 2026-03-01
**Status**: Draft
**Input**: User description: "fill name auto from google auth in profile page and add choose theme on it also print when debug all snackbar messages we need to start development home page"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Auto-Fill Profile from Google Auth (Priority: P1)

When a user signs in with Google and lands on the profile setup screen, the name field should be pre-populated with their Google account display name and their avatar should be pre-loaded from their Google profile photo. The user can still edit the name or change the photo before completing setup.

**Why this priority**: This removes friction from onboarding for Google users. Without it, users who just authenticated with Google are forced to re-type their name — a redundant step that feels broken.

**Independent Test**: Sign in with a Google account that has a display name and profile photo, land on profile setup, verify the name field is pre-filled and avatar is shown. Edit the name, complete profile, verify the edited name is saved (not the original Google name).

**Acceptance Scenarios**:

1. **Given** a user signs in with Google for the first time, **When** the profile setup screen loads, **Then** the name field is pre-filled with the Google account display name
2. **Given** a user signs in with Google for the first time, **When** the profile setup screen loads, **Then** the avatar displays the Google profile photo
3. **Given** a Google-signed-in user on profile setup, **When** the user edits the pre-filled name and taps Complete, **Then** the edited name is saved (not the Google name)
4. **Given** a user signs in via phone OTP (no Google), **When** the profile setup screen loads, **Then** the name field is empty and avatar is the default placeholder (no regression)

---

### User Story 2 - Theme Chooser on Profile Setup (Priority: P2)

The profile setup screen should include a theme selector (Light / Dark) alongside the existing language selector. The selected theme is applied immediately as a live preview and persisted when the user completes their profile. On subsequent app launches, the saved theme preference is restored.

**Why this priority**: Theme selection is a strong personalization feature that increases user satisfaction. Adding it during onboarding means users start with their preferred look from day one.

**Independent Test**: Open profile setup, toggle between Light and Dark themes, verify the screen updates immediately. Complete profile, restart the app, verify the theme persists.

**Acceptance Scenarios**:

1. **Given** the user is on the profile setup screen, **When** they view the settings, **Then** a theme selector (Light / Dark) is visible below the language selector
2. **Given** the user is on profile setup, **When** they select Dark theme, **Then** the app immediately switches to dark mode as a live preview
3. **Given** the user selects Dark theme and completes profile, **When** the app is reopened later, **Then** the app loads in Dark mode
4. **Given** the user does not change the theme, **When** they complete profile, **Then** the default theme (Light) is used

---

### User Story 3 - Debug Snackbar Logging (Priority: P2)

During development (debug mode), all snackbar messages shown to the user should also be printed to the console/debug log. This helps developers catch and trace user-facing messages without needing to visually monitor the app screen.

**Why this priority**: Equal to theme chooser. This is a developer-experience improvement that speeds up debugging and ensures no user-facing message goes unnoticed during development.

**Independent Test**: Trigger any snackbar (e.g., Google sign-in error, name required validation), verify the snackbar title and message appear in the debug console output. Build in release mode and verify no debug prints appear.

**Acceptance Scenarios**:

1. **Given** the app is running in debug mode, **When** any snackbar is displayed, **Then** the snackbar title and message are printed to the debug console
2. **Given** the app is running in release mode, **When** a snackbar is displayed, **Then** nothing is printed to the console
3. **Given** a snackbar with an empty message body, **When** it is displayed in debug mode, **Then** only the title is printed (no empty line)

---

### User Story 4 - Customer Home Page (Priority: P3)

After profile setup, the customer is navigated to a home page. Currently this route exists but has no real implementation. The home page should display a welcoming layout with the user's name, a map placeholder area for future pickup selection, and a service type selector (Ride / Delivery). This is the foundational screen that all future customer features build upon.

**Why this priority**: The home page is critical for the app to feel like a real product, but it depends on profile setup being complete. It is the entry point for all customer interactions.

**Independent Test**: Complete profile setup as a customer, verify navigation to home page, verify user name is displayed, verify service selector (Ride / Delivery) is visible, verify map placeholder area is present.

**Acceptance Scenarios**:

1. **Given** a customer completes profile setup, **When** they are navigated to the home page, **Then** the home page loads with the user's name displayed
2. **Given** the customer is on the home page, **When** they view the screen, **Then** they see a map placeholder area and service type options (Ride / Delivery)
3. **Given** the customer is on the home page, **When** they tap Ride or Delivery, **Then** the selected service type is visually highlighted
4. **Given** the customer is a returning user, **When** the app opens, **Then** they land directly on the home page (not profile setup)

---

### Edge Cases

- What happens when Google account has no display name? The name field remains empty (same as phone auth flow).
- What happens when Google profile photo URL fails to load? Fall back to the default avatar placeholder.
- What happens if the user selects a theme but the app crashes before completing profile? The theme preference is not persisted until profile is completed, but the live preview change is lost.
- What happens if the user's Firestore document is missing when the home page loads? Show a graceful error and redirect to login.
- What happens if the user has no internet on the home page? Show cached/last-known user data if available, or a retry prompt.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST pre-fill the profile name field with the Google account display name when the user signed in via Google
- **FR-002**: System MUST pre-load the profile avatar with the Google account profile photo URL when the user signed in via Google
- **FR-003**: System MUST allow the user to edit the pre-filled name before saving
- **FR-004**: System MUST NOT pre-fill any fields when the user signed in via phone OTP (existing behavior preserved)
- **FR-005**: System MUST display a theme selector (Light / Dark) on the profile setup screen
- **FR-006**: System MUST apply the selected theme immediately as a live preview
- **FR-007**: System MUST persist the selected theme preference when the user completes their profile
- **FR-008**: System MUST restore the persisted theme on app launch
- **FR-009**: System MUST print all snackbar titles and messages to the debug console when running in debug mode
- **FR-010**: System MUST NOT print snackbar messages to the console in release mode
- **FR-011**: Home page MUST display the user's name from their profile
- **FR-012**: Home page MUST display a map placeholder area for future pickup/dropoff selection
- **FR-013**: Home page MUST display a service type selector with Ride and Delivery options
- **FR-014**: Home page MUST visually indicate the currently selected service type

### Key Entities

- **User Profile**: Name, avatar URL, language preference, theme preference — collected during onboarding
- **Theme Preference**: Light or Dark — stored locally and in the user's Firestore document
- **Service Type**: Ride or Delivery — user's selected intent on the home page

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Google-authenticated users complete profile setup with zero re-typing of their name (name is pre-filled)
- **SC-002**: Theme selection applies instantly with no visible delay or screen flash
- **SC-003**: Selected theme persists across app restarts 100% of the time
- **SC-004**: 100% of snackbar messages appear in debug console when running in debug mode
- **SC-005**: Customer home page loads within 2 seconds of profile completion
- **SC-006**: All four user stories can be independently tested and demonstrated
