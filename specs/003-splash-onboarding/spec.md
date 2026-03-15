# Feature Specification: Splash, Onboarding, and Authentication Flow

**Feature Branch**: `003-splash-onboarding`
**Created**: 2026-02-28
**Status**: Draft
**Input**: User description: "Build full splash and onboarding for driver and user with same design using stitch files, common widgets, themes, routes with GetX, Firebase auth, and all required models and services"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Splash Screen with App Initialization (Priority: P1)

When a user opens either the Customer or Driver app for the first time, they see a branded splash screen displaying the BikeRide logo and app name while the app initializes Firebase, checks authentication state, and determines where to navigate the user next (onboarding for first launch, phone login for unauthenticated users, or home screen for returning authenticated users).

**Why this priority**: The splash screen is the very first thing any user sees. It gates all subsequent navigation and must correctly determine the user's state to route them appropriately. Without this, no other screen can be reached.

**Independent Test**: Can be fully tested by launching the app and verifying the splash screen appears, displays the brand identity, and navigates to the correct next screen based on user state (first launch → onboarding, unauthenticated → phone login, authenticated → home).

**Acceptance Scenarios**:

1. **Given** a user opens the app for the first time, **When** the splash screen loads and initialization completes, **Then** the user is navigated to the onboarding screen
2. **Given** a user has completed onboarding but is not logged in, **When** the splash screen loads, **Then** the user is navigated to the phone login screen
3. **Given** a user is already authenticated, **When** the splash screen loads, **Then** the user is navigated to the home screen (customer home or driver home based on app type)
4. **Given** a driver user is authenticated but their application is pending, **When** the splash screen loads, **Then** the driver is navigated to the application pending status screen

---

### User Story 2 - Customer Onboarding Flow (Priority: P2)

A first-time customer sees a 3-slide onboarding carousel introducing BikeRide's key value propositions: speed ("Beat the Traffic"), fair pricing ("Your Price, Your Choice"), and a third selling point. Each slide shows an illustration, a bold headline, a supporting description, pagination dots showing progress, and navigation controls (Skip to bypass, Next to advance, Get Started on the last slide to proceed to phone login).

**Why this priority**: Onboarding educates new customers about the platform's unique features before they register, increasing conversion and reducing confusion. It's the first meaningful interaction after the splash screen.

**Independent Test**: Can be fully tested by launching the app as a first-time user, swiping through all 3 slides, verifying each slide displays correct content with illustrations, confirming Skip navigates to phone login from any slide, and confirming Get Started on the last slide navigates to phone login.

**Acceptance Scenarios**:

1. **Given** a first-time customer user, **When** onboarding loads, **Then** slide 1 ("Beat the Traffic") is displayed with illustration, headline, description, pagination dots (1/3 active), Skip button, and Next button
2. **Given** the user is on slide 1, **When** they tap Next or swipe left, **Then** slide 2 ("Your Price, Your Choice") is displayed with pagination dots (2/3 active)
3. **Given** the user is on the last slide, **When** they tap "Get Started", **Then** they are navigated to the phone login screen
4. **Given** the user is on any slide, **When** they tap "Skip", **Then** they are navigated to the phone login screen
5. **Given** the user swipes through slides, **When** they reach the last slide, **Then** the "Next" button changes to "Get Started"

---

### User Story 3 - Driver Onboarding Flow (Priority: P2)

A first-time driver sees a 3-slide onboarding carousel introducing BikeRide's driver value propositions: freedom ("Be Your Own Boss"), safety ("Safe & Reliable"), and a third selling point. The layout, pagination, and navigation controls match the customer onboarding design for consistency, but with driver-specific content and illustrations.

**Why this priority**: Same importance as customer onboarding — it's the driver's first meaningful interaction and sets expectations for the platform. Grouped at P2 with customer onboarding since they share the same widget architecture.

**Independent Test**: Can be fully tested by launching the driver app as a first-time user, verifying all 3 driver-specific slides display correct content, and confirming navigation controls work identically to the customer onboarding.

**Acceptance Scenarios**:

1. **Given** a first-time driver user, **When** onboarding loads, **Then** slide 1 ("Be Your Own Boss") is displayed with a delivery driver illustration, headline with "Boss" in primary color, description, and pagination dots (1/3 active)
2. **Given** the user is on slide 2, **When** it displays, **Then** "Safe & Reliable" headline with motorcycle/shield illustration is shown, with pagination dots (2/3 active)
3. **Given** the user completes onboarding, **When** they tap "Get Started", **Then** they are navigated to the phone login screen

---

### User Story 4 - Phone Number Authentication (Priority: P3)

A user (customer or driver) enters their Egyptian mobile phone number (+20 prefix) to receive a verification code via SMS. The phone login screen shows the BikeRide brand with a Cairo map background, a phone number input field with the Egypt country code pre-filled, a Continue button that triggers OTP delivery, and optional social login buttons (Google, Facebook). A terms/privacy notice is displayed at the bottom.

**Why this priority**: Authentication is the gateway to all app functionality. Users cannot access any features without completing phone verification. Depends on splash (P1) and onboarding (P2) being in place for proper navigation.

**Independent Test**: Can be fully tested by entering a valid Egyptian phone number, tapping Continue, and verifying that an OTP code is delivered via Firebase Auth. Invalid numbers should show appropriate error messages.

**Acceptance Scenarios**:

1. **Given** a user arrives at the phone login screen, **When** the screen loads, **Then** they see the BikeRide branding with map background, phone input with +20 prefix, Continue button, social login options, and terms/privacy links
2. **Given** a user enters a valid 11-digit Egyptian phone number, **When** they tap Continue, **Then** an OTP is sent via SMS and the user is navigated to the OTP verification screen
3. **Given** a user enters an invalid phone number (wrong length or format), **When** they tap Continue, **Then** an error message is displayed and no OTP is sent
4. **Given** a user is on the phone login screen, **When** they tap the back arrow, **Then** they return to the onboarding screen (if first launch) or remain on login (if returning user)

---

### User Story 5 - OTP Verification (Priority: P3)

After entering their phone number, the user is shown a 4-digit OTP input screen. They enter the code received via SMS. The screen shows a countdown timer (30 seconds) after which a "Resend Code" option becomes active. Successfully entering the correct code authenticates the user. For new users, they proceed to profile setup. For returning users, they proceed to the home screen.

**Why this priority**: Directly follows phone login and completes the authentication cycle. Cannot function without the phone login screen being built first.

**Independent Test**: Can be fully tested by entering the correct 4-digit OTP and verifying authentication succeeds, trying an incorrect code and verifying an error is shown, and waiting for the timer to expire to verify the resend option activates.

**Acceptance Scenarios**:

1. **Given** a user arrives at the OTP screen, **When** it loads, **Then** they see the heading "Verify Your Number", the masked phone number, 4 input fields for the code, a 30-second countdown timer, and a Verify button
2. **Given** a user enters the correct 4-digit code, **When** they tap Verify, **Then** they are authenticated and navigated to profile setup (new user) or home screen (returning user)
3. **Given** a user enters an incorrect code, **When** they tap Verify, **Then** an error message is shown and the input fields are cleared
4. **Given** the 30-second timer has expired, **When** the user taps "Resend Code", **Then** a new OTP is sent and the timer resets
5. **Given** the timer is still counting down, **When** the user looks at "Resend Code", **Then** it is disabled/inactive

---

### User Story 6 - Profile Setup (Priority: P4)

A new user (customer or driver) completes their profile by uploading an avatar photo, entering their full name, and selecting their preferred language (English or Arabic). Submitting the profile saves the information and navigates the customer to the home screen or the driver to the registration documents screen.

**Why this priority**: Profile setup is required before a user can use the app, but it depends on successful authentication (P3). It's the final step in the onboarding funnel for customers.

**Independent Test**: Can be fully tested by uploading a photo, entering a name, selecting a language, and tapping Complete Profile. Verify the profile data is saved and navigation proceeds correctly based on app type.

**Acceptance Scenarios**:

1. **Given** a new user arrives at profile setup, **When** the screen loads, **Then** they see an avatar upload area with camera icon, a Full Name text field with person icon, a language selector (English/Arabic toggle), and a Complete Profile button
2. **Given** a user fills in all fields, **When** they tap Complete Profile, **Then** their profile is saved and they are navigated to the customer home screen (customer app) or driver registration screen (driver app)
3. **Given** a user does not enter a name, **When** they tap Complete Profile, **Then** a validation error is shown on the name field
4. **Given** a user selects Arabic as their language, **When** they confirm, **Then** the app switches to Arabic (RTL) immediately

---

### User Story 7 - Driver Registration with Document Upload (Priority: P5)

After completing their profile, a driver enters vehicle information (motorcycle model, plate number) and uploads 4 required documents: National ID Card (front and back), Driving License, Vehicle Registration, and Criminal Record (Fish w Tashbih). A multi-step progress indicator shows their progress through the registration flow. Each document shows its upload status (pending, uploaded/completed). A tip box reminds drivers to ensure photos are clear. Submitting the application sends the data for admin review.

**Why this priority**: Driver-specific registration that only applies to the driver app. Depends on profile setup (P4) being complete. This is the most complex screen in the flow with form inputs, file uploads, and multi-step navigation.

**Independent Test**: Can be fully tested by entering vehicle details, uploading all 4 documents, and tapping Submit Application. Verify the application is saved and the user is navigated to the pending status screen.

**Acceptance Scenarios**:

1. **Given** a driver arrives at the registration screen, **When** it loads, **Then** they see a 4-step progress indicator (step 2 highlighted), vehicle form fields (Motorcycle Model, Plate Number), and 4 document upload items with status indicators
2. **Given** a driver taps a document item (e.g., National ID Card), **When** the upload dialog opens, **Then** they can select a photo from camera or gallery
3. **Given** a driver has uploaded a document, **When** they view that document item, **Then** it shows a green checkmark indicating completion
4. **Given** a driver has completed all required fields and uploads, **When** they tap "Submit Application", **Then** the application is saved and they are navigated to the pending status screen
5. **Given** a driver has not uploaded all required documents, **When** they tap "Submit Application", **Then** a message indicates which documents are still required

---

### User Story 8 - Driver Application Pending Status (Priority: P5)

After submitting their application, a driver sees a status screen showing "Application Under Review" with a progress tracker (Documents Submitted with checkmark, Verification Pending). The screen informs the driver they will be notified within 24 hours. A "Contact Support" button allows them to reach out, and a "Back to Home" button returns them to a limited home state.

**Why this priority**: The final screen in the driver onboarding funnel. Only relevant after the driver submits their registration. Provides important status feedback.

**Independent Test**: Can be fully tested by navigating to the pending screen and verifying the status message, progress tracker, and action buttons display correctly and function as expected.

**Acceptance Scenarios**:

1. **Given** a driver has submitted their application, **When** the pending status screen loads, **Then** they see an illustration, "Application Under Review" heading, notification timeline message, a status tracker showing "Documents Submitted" (checked) and "Verification Pending" (pending), and two action buttons
2. **Given** a driver taps "Contact Support", **When** the action triggers, **Then** a support communication channel opens (in-app or external)
3. **Given** a driver taps "Back to Home", **When** the action triggers, **Then** they are navigated to a limited driver home screen

---

### Edge Cases

- What happens if Firebase initialization fails during splash screen? (Show error screen with retry option)
- What happens if the user force-closes the app during onboarding and reopens? (Resume from splash, re-check onboarding completion state)
- What happens if the phone number is already registered? (Proceed to OTP normally — returning user flow)
- What happens if the OTP expires before the user enters it? (Show expiry message and prompt to resend)
- What happens if network connectivity is lost during authentication? (Show offline error message with retry)
- What happens if the user tries to upload an image larger than the allowed size? (Show file size limit error and reject the upload)
- What happens if the user navigates back from OTP screen? (Return to phone login with their number pre-filled)
- What happens if the user switches language during profile setup? (App direction and language update immediately, preserving form data)

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST display a branded splash screen with the BikeRide logo and app name on both Customer and Driver apps
- **FR-002**: Splash screen MUST check first-launch state, authentication state, and user profile completion to determine navigation destination
- **FR-003**: Splash screen MUST persist the "onboarding completed" flag locally so onboarding is shown only once per device
- **FR-004**: Customer onboarding MUST display 3 swipeable slides with illustrations, headlines, descriptions, and pagination dots
- **FR-005**: Customer onboarding slide content MUST include: Slide 1 — "Beat the Traffic" (speed/agility), Slide 2 — "Your Price, Your Choice" (fair bidding), Slide 3 — a third value proposition
- **FR-006**: Driver onboarding MUST display 3 swipeable slides with illustrations, headlines, descriptions, and pagination dots
- **FR-007**: Driver onboarding slide content MUST include: Slide 1 — "Be Your Own Boss" (freedom), Slide 2 — "Safe & Reliable" (trust/insurance), Slide 3 — a third value proposition
- **FR-008**: Onboarding screens MUST provide "Skip" button visible on all slides and "Get Started" button on the last slide
- **FR-009**: Onboarding pagination dots MUST indicate the current slide using the primary color (#e0062e) with an elongated active indicator (w-8) versus inactive dots (w-2)
- **FR-010**: Both onboarding flows MUST share the same reusable page widget, differing only in content data (titles, descriptions, illustrations)
- **FR-011**: Phone login screen MUST display a map background with Cairo area, BikeRide branding ("Yalla! Let's get moving"), and a phone number input with +20 Egypt prefix
- **FR-012**: Phone login MUST validate that the entered number is a valid 11-digit Egyptian mobile number before sending OTP
- **FR-013**: Phone login MUST trigger Firebase Phone Authentication to send an OTP code via SMS
- **FR-014**: Phone login screen MUST display "OR CONTINUE WITH" section with Google and Facebook social login options
- **FR-015**: Phone login screen MUST display Terms of Service and Privacy Policy links at the bottom
- **FR-016**: OTP verification screen MUST display 4 individual digit input fields with auto-advance focus behavior
- **FR-017**: OTP verification screen MUST show a 30-second countdown timer with visual indicator; "Resend Code" MUST be disabled until timer expires
- **FR-018**: OTP verification MUST validate the entered code against Firebase Auth and navigate appropriately on success
- **FR-019**: Profile setup screen MUST display avatar upload (camera/gallery), full name input, and language selector (English/Arabic toggle)
- **FR-020**: Profile setup MUST validate that the full name field is not empty before allowing submission
- **FR-021**: Profile setup MUST save user profile data (name, avatar URL, language preference) to Firestore `users/{uid}` document
- **FR-022**: Selecting a language in profile setup MUST immediately switch the app's locale and text direction
- **FR-023**: After profile setup, customer users MUST be navigated to the customer home screen
- **FR-024**: After profile setup, driver users MUST be navigated to the driver registration documents screen
- **FR-025**: Driver registration screen MUST display a 4-step progress indicator and vehicle information form fields (Motorcycle Model, Plate Number)
- **FR-026**: Driver registration screen MUST display 4 required document upload items: National ID Card, Driving License, Vehicle Registration, Criminal Record
- **FR-027**: Each document upload item MUST show status (pending with dashed circle/add icon, or completed with green checkmark)
- **FR-028**: Driver registration MUST save vehicle information and document file URLs to Firestore (`driver_profiles/{uid}` and `documents/{doc_id}`)
- **FR-029**: Driver registration MUST upload document images to Firebase Storage under a driver-specific path
- **FR-030**: Application pending status screen MUST display "Application Under Review" message, a status tracker, "Contact Support" button, and "Back to Home" button
- **FR-031**: All screens MUST support Arabic (RTL) and English (LTR) layouts with proper text direction, icon flipping, and font switching (Cairo for Arabic, Plus Jakarta Sans for English)
- **FR-032**: All screens MUST support light and dark mode using the established theme system
- **FR-033**: All navigation MUST use GetX named routes as defined in `app_routes.dart`
- **FR-034**: All text strings MUST be localized through language JSON files — no hardcoded strings in widget code

### Key Entities

- **User**: Represents an authenticated user with uid, name, phone, type (customer/driver), status, wallet balance, language preference, avatar URL, and FCM token
- **Driver Profile**: Extended information for drivers including national ID, license number, vehicle details, approval status, and online status
- **Document**: An uploaded verification document with driver reference, document type, file URL, review status, and admin notes
- **Onboarding Slide**: Content data for a single onboarding page including title, description, illustration asset, and position index

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users complete the full flow from splash to home screen (or pending status for drivers) in under 5 minutes on first launch
- **SC-002**: Onboarding carousel responds to swipe gestures and button taps with smooth transitions (no visible jank or delay)
- **SC-003**: 95% of OTP codes are received and entered successfully within the 30-second timer window
- **SC-004**: All screens render correctly in both Arabic (RTL) and English (LTR) modes without layout breaking, text overflow, or icon misalignment
- **SC-005**: All screens render correctly in both light and dark themes with proper contrast and readability
- **SC-006**: Profile data (name, avatar, language) persists correctly and is retrievable after app restart
- **SC-007**: Driver document uploads complete successfully with files accessible via their stored URLs
- **SC-008**: The shared onboarding page widget is reused across both Customer and Driver apps with zero code duplication for layout logic
- **SC-009**: Users can navigate backward through the flow (OTP → phone login, profile setup → OTP) without losing previously entered data
- **SC-010**: Splash screen determines correct navigation destination within 3 seconds of app launch

## Assumptions

1. Firebase project is already configured with Phone Authentication enabled and Egypt (+20) as an allowed region
2. Firebase Storage is configured and accessible for document uploads
3. The core theme system and shared widgets from spec 001 are fully implemented and available
4. Onboarding illustrations will be stored as local assets bundled with the app (not fetched from a remote server)
5. Social login (Google, Facebook) will be implemented as future enhancements — buttons are displayed but may initially show "coming soon" or be non-functional
6. The "third slide" content for both customer and driver onboarding will follow the same design pattern as the existing slides
7. Document upload uses the device camera or photo gallery via `image_picker` package
8. The 30-second OTP timer is a client-side countdown; actual OTP expiry is controlled by Firebase Auth server-side
9. First-launch detection uses local storage (`shared_preferences`) to persist the "onboarding completed" flag
10. The driver registration is a multi-step flow but this spec covers the documents step (step 2 of 4); other steps will be added in future specs

## Dependencies

- Spec 001 (Theme System and Shared Widgets) — provides AppButton, AppTextField, AppCard, AppLoading, theme colors, typography, and localization infrastructure
- Firebase Auth (Phone Authentication) — for OTP-based phone verification
- Firebase Storage — for document image uploads
- Firebase Cloud Firestore — for persisting user profiles, driver profiles, and documents
- `shared_preferences` package — for storing first-launch and onboarding completion flags
- `image_picker` package — for camera/gallery access during document upload and avatar selection

## Out of Scope

- Google and Facebook social login implementation (buttons shown, functionality deferred)
- Admin approval workflow for driver documents (admin panel feature)
- Push notification setup for driver application status updates
- Language selection screen as a standalone screen (language is selected during profile setup)
- Customer home screen and driver home screen implementations
- Payment setup or wallet initialization
- Firestore security rules updates
- Cloud Functions for user creation triggers
- Map integration on the phone login screen (static image or gradient background acceptable as placeholder)