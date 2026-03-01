# Feature Specification: Google Sign-In

**Feature Branch**: `005-google-sign-in`
**Created**: 2026-03-01
**Status**: Draft
**Input**: User description: "complete sign in with google"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Sign in with Google from login screen (Priority: P1)

A new or returning user taps the Google button on the phone login screen and signs in using their Google account. After successful authentication, they are routed to the appropriate screen based on their profile status (new user goes to profile setup, returning user goes to home).

**Why this priority**: This is the core feature — without it, the Google button remains non-functional. It delivers the primary value of offering an alternative, faster authentication method that skips the OTP wait.

**Independent Test**: Can be fully tested by tapping the Google button, completing the Google sign-in flow, and verifying the user lands on the correct post-auth screen.

**Acceptance Scenarios**:

1. **Given** a user is on the phone login screen, **When** they tap the Google button and select a Google account, **Then** they are authenticated and navigated to profile setup (if new) or home (if returning).
2. **Given** a user is on the phone login screen, **When** they tap the Google button and cancel the Google sign-in prompt, **Then** they remain on the phone login screen with no error shown.
3. **Given** a user is on the phone login screen with no internet, **When** they tap the Google button, **Then** they see an appropriate error message.

---

### User Story 2 - Returning Google user bypasses profile setup (Priority: P1)

A user who previously signed in with Google and completed their profile taps the Google button again. The system recognizes them and takes them directly to the home screen without requiring profile setup again.

**Why this priority**: Essential for repeat usage — returning users must not be asked to set up their profile again.

**Independent Test**: Can be tested by signing in with Google after a previous session where the profile was completed, and verifying navigation goes directly to home.

**Acceptance Scenarios**:

1. **Given** a returning user with a completed profile, **When** they sign in with Google, **Then** they are taken directly to the customer or driver home screen.
2. **Given** a returning driver with pending approval status, **When** they sign in with Google, **Then** they are taken to the pending approval screen.

---

### User Story 3 - Error handling during Google sign-in (Priority: P2)

When something goes wrong during the Google sign-in process (network failure, account issue, authentication error), the user sees a clear, localized error message and can retry or fall back to phone authentication.

**Why this priority**: Users need clear feedback when things fail; without it they will be confused and abandon the app.

**Independent Test**: Can be tested by simulating network failures or sign-in errors and verifying error messages appear correctly in both Arabic and English.

**Acceptance Scenarios**:

1. **Given** a network error occurs during Google sign-in, **When** the sign-in fails, **Then** the user sees a localized error message and the Google button becomes tappable again.
2. **Given** the Google sign-in fails for any reason, **When** the error is displayed, **Then** the user can still use phone OTP authentication normally.

---

### Edge Cases

- What happens when a user signs in with Google using an email already linked to a phone-authenticated account? The system should link both providers to the same account.
- What happens when the Google sign-in popup is dismissed without selecting an account? The user remains on the login screen with no error.
- What happens when the device has no Google accounts configured? The system shows the standard Google account picker which allows adding an account.
- What happens if the user signs in with Google on one device and phone OTP on another? Both sessions are valid and share the same user record.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST allow users to authenticate using their Google account via the existing Google button on the login screen.
- **FR-002**: System MUST replace the current "Coming Soon" behavior of the Google button with a functional Google sign-in flow.
- **FR-003**: System MUST create a user record in the database for first-time Google sign-in users, using their Google display name and email as defaults.
- **FR-004**: System MUST route Google-authenticated users through the same post-authentication navigation as phone-authenticated users (profile setup for new users, home for returning users, pending approval for drivers awaiting approval).
- **FR-005**: System MUST display a loading indicator while the Google sign-in is in progress.
- **FR-006**: System MUST display localized error messages (Arabic and English) when Google sign-in fails.
- **FR-007**: System MUST handle the case where the user cancels the Google sign-in prompt gracefully (no error, no state change).
- **FR-008**: System MUST support signing out users who authenticated via Google.
- **FR-009**: When a Google sign-in matches an existing account (same email linked to a phone-authenticated user), the system MUST link the accounts rather than creating a duplicate.
- **FR-010**: The Facebook button MUST remain unchanged (still showing "Coming Soon").

### Key Entities

- **User**: Extended to support Google as an authentication provider alongside phone. Key attributes: Google email, Google display name, authentication provider type.
- **Authentication Provider**: Tracks which method(s) a user has used to sign in (phone, Google), enabling account linking.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can complete Google sign-in within 10 seconds (excluding Google account selection time).
- **SC-002**: 95% of Google sign-in attempts by users with valid Google accounts succeed on the first try.
- **SC-003**: New Google sign-in users reach the profile setup screen within 3 seconds of completing Google authentication.
- **SC-004**: Error messages are displayed within 2 seconds of a sign-in failure in the user's selected language.
- **SC-005**: Returning Google users reach the home screen within 3 seconds of tapping the Google button.

## Assumptions

- The project uses Firebase Authentication, which natively supports Google Sign-In as a provider.
- Google Sign-In will be enabled in the Firebase Console for the project.
- The Google button UI already exists in the SocialLoginButtons widget and only needs its tap handler updated.
- Account linking (Google + phone for same user) follows Firebase's built-in account linking behavior.
- Google sign-in is available for both the Customer and Driver apps (shared auth flow).
- The Admin panel does not use Google sign-in (it has its own login flow).
- No additional user data beyond what Google provides (display name, email, photo URL) is collected during Google sign-in.

## Scope Boundaries

### In Scope
- Making the Google button functional on the phone login screen
- Google sign-in flow (authentication only)
- Post-auth navigation for Google-authenticated users
- Error handling and loading states
- Localized strings for Google sign-in states
- Account linking when Google email matches existing phone user

### Out of Scope
- Facebook sign-in (remains "Coming Soon")
- Apple Sign-In
- Google sign-in for the Admin panel
- Changing the existing phone OTP flow
- Profile setup screen changes (already exists and works)
