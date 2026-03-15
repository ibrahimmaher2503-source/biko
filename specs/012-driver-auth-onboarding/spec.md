# Feature Specification: Driver Authentication & Onboarding

**Feature Branch**: `012-driver-auth-onboarding`
**Created**: 2026-03-02
**Status**: Draft
**Input**: User description: "Implement full auth module for driver with onboarding screens"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Driver Onboarding Introduction (Priority: P1)

A new driver opens the BikeRide Driver app for the first time. They are presented with a series of onboarding slides that introduce the platform's value proposition: freedom to set their own schedule, safety and reliability of the platform, and earning potential. The driver can swipe through 3 slides, skip onboarding entirely, or tap "Get Started" on the final slide to proceed to authentication.

**Why this priority**: First-time drivers need to understand the platform's value before committing to registration. This is the entry gate to the entire driver experience.

**Independent Test**: Can be fully tested by launching the driver app for the first time and verifying all 3 slides display correctly with proper content, navigation, and skip functionality.

**Acceptance Scenarios**:

1. **Given** the driver opens the app for the first time, **When** the splash screen completes, **Then** the onboarding screen is displayed with the first slide ("Be Your Own Boss" — freedom theme)
2. **Given** the driver is on any onboarding slide, **When** they swipe left, **Then** the next slide is shown with a smooth transition and the page indicator updates
3. **Given** the driver is on any onboarding slide (except the first), **When** they swipe right, **Then** the previous slide is shown
4. **Given** the driver is on any onboarding slide, **When** they tap "Skip", **Then** they are navigated directly to the phone login screen
5. **Given** the driver is on the last onboarding slide, **When** the button text changes to "Get Started" and they tap it, **Then** they are navigated to the phone login screen
6. **Given** the driver has completed onboarding previously, **When** they reopen the app, **Then** onboarding is not shown again (skipped directly to splash → auth check)

---

### User Story 2 - Driver Phone Authentication (Priority: P1)

A driver enters their Egyptian mobile number (+20 prefix) on the phone login screen. The system sends a 4-digit OTP via SMS. The driver enters the OTP on the verification screen within the 30-second countdown window. Upon successful verification, the system checks if the driver has a profile — if not, they proceed to profile setup.

**Why this priority**: Authentication is the foundational requirement for all subsequent driver flows. Without it, no other feature is accessible.

**Independent Test**: Can be fully tested by entering a valid Egyptian phone number, receiving OTP, and verifying it leads to profile setup for new users or the appropriate next screen for returning users.

**Acceptance Scenarios**:

1. **Given** the driver is on the phone login screen, **When** they enter a valid 10-digit Egyptian number (starting with 10, 11, 12, or 15), **Then** the "Continue" button becomes enabled
2. **Given** the driver taps "Continue" with a valid number, **When** the OTP is sent successfully, **Then** they are navigated to the OTP verification screen and a 30-second countdown timer starts
3. **Given** the driver is on the OTP screen, **When** they enter the correct 4-digit code, **Then** they are authenticated and navigated to the next appropriate screen
4. **Given** the driver enters an incorrect OTP, **When** verification fails, **Then** an error message is displayed and they can retry
5. **Given** the 30-second timer expires, **When** the driver taps "Resend Code", **Then** a new OTP is sent and the timer resets
6. **Given** the driver is on the phone login screen, **When** they tap the Google sign-in button, **Then** the Google authentication flow is initiated as an alternative login method
7. **Given** the driver is on the phone login screen, **When** they tap the Facebook sign-in button, **Then** the Facebook authentication flow is initiated as an alternative login method
8. **Given** the driver is a new user who just authenticated, **When** no profile exists for their account, **Then** they are navigated to the profile setup screen
9. **Given** the driver is a returning user with a complete profile, **When** they authenticate, **Then** they are navigated to the driver home screen (if approved) or pending approval screen (if pending)

---

### User Story 3 - Driver Profile Setup (Priority: P1)

After authentication, a new driver sets up their basic profile. They upload a profile photo, enter their full name, and select their preferred language (English or Arabic). Upon completing the profile, the system saves their information and navigates them to the driver registration screen.

**Why this priority**: Profile information is required before driver registration can proceed. It establishes the driver's identity in the system.

**Independent Test**: Can be fully tested by completing the profile form with a photo, name, and language selection, then verifying the data is saved and the driver proceeds to registration.

**Acceptance Scenarios**:

1. **Given** the driver is on the profile setup screen, **When** the screen loads, **Then** they see a photo upload area, a "Full Name" input field, and a language toggle (English / Arabic)
2. **Given** the driver taps the photo upload area, **When** they select a photo from their gallery or take a new one, **Then** the photo is displayed in the circular avatar area
3. **Given** the driver has filled in their name, **When** they tap "Complete Profile", **Then** their profile data is saved and they are navigated to the driver registration screen
4. **Given** the driver has not entered a name, **When** they tap "Complete Profile", **Then** a validation error is shown requiring the name field
5. **Given** the driver selects Arabic, **When** the language changes, **Then** the entire app switches to Arabic with RTL layout
6. **Given** the driver selects English, **When** the language changes, **Then** the entire app switches to English with LTR layout

---

### User Story 4 - Driver Vehicle & Document Registration (Priority: P1)

After profile setup, the driver proceeds to register their vehicle and upload required documents. They enter their motorcycle model and plate number, then upload 4 required documents: National ID Card (front and back), Driving License, Vehicle Registration, and Criminal Record (Fish w Tashbih). The screen shows a multi-step progress indicator. Once all fields are completed and all 4 documents are uploaded, the driver submits their application.

**Why this priority**: Document verification is essential for driver activation. Without complete documentation, a driver cannot be approved to take rides.

**Independent Test**: Can be fully tested by entering vehicle details, uploading all 4 documents, and submitting the application, then verifying the data is persisted and the status changes to pending.

**Acceptance Scenarios**:

1. **Given** the driver is on the registration screen, **When** it loads, **Then** they see vehicle info fields (motorcycle model, plate number), a "Required Documents" section with 4 upload slots, a step progress indicator, and a "Submit Application" button
2. **Given** the driver taps a document upload slot (e.g., National ID Card), **When** they select an image, **Then** the document is uploaded and a green checkmark replaces the upload icon for that slot
3. **Given** the driver has uploaded fewer than 4 documents, **When** they tap "Submit Application", **Then** a warning message is shown asking them to upload all required documents
4. **Given** the driver has entered vehicle model and plate number and uploaded all 4 documents, **When** they tap "Submit Application", **Then** the application is submitted, their user status changes to "pending approval", and they are navigated to the pending approval screen
5. **Given** the driver is filling in the plate number, **When** they enter a value, **Then** the system accepts alphanumeric characters (e.g., "ABC 123")
6. **Given** a document upload fails (network issue), **When** the error occurs, **Then** a user-friendly error message is shown and the driver can retry the upload
7. **Given** the driver taps "Help" in the top-right corner, **When** the help option is tapped, **Then** guidance is provided about what documents are needed and acceptable formats
8. **Given** there is a quality warning note at the bottom, **When** the screen is displayed, **Then** the note reads: "Ensure all photos are clear and text is readable. Blurry documents may delay your activation process."

---

### User Story 5 - Application Pending Status (Priority: P2)

After submitting their application, the driver sees a status screen showing their application is under review. The screen displays a motorcycle illustration, a clear "Application Under Review" heading, a status timeline showing "Documents Submitted" (completed) and "Verification Pending" (in progress), and options to contact support or go back to home.

**Why this priority**: Drivers need clear feedback about their application status to set expectations and reduce support inquiries. This is a retention screen that prevents drop-off.

**Independent Test**: Can be fully tested by navigating to the pending screen after submission and verifying the correct status information and action buttons are displayed.

**Acceptance Scenarios**:

1. **Given** the driver has submitted their application, **When** they are navigated to the pending screen, **Then** they see the "Application Under Review" heading, a timeline with "Documents Submitted" (green checkmark) and "Verification Pending" (in progress indicator), and a message: "We have received your application. We will notify you within 24 hours."
2. **Given** the driver is on the pending screen, **When** they tap "Contact Support", **Then** the appropriate support channel is opened (phone, email, or in-app support)
3. **Given** the driver is on the pending screen, **When** they tap "Back to Home", **Then** they are navigated to a limited home screen or the app closes gracefully
4. **Given** the driver relaunches the app while still pending, **When** the splash screen completes, **Then** they are routed directly to the pending approval screen (not onboarding or login)
5. **Given** an admin approves the driver's application, **When** the driver next opens the app, **Then** they are navigated to the driver home screen instead of the pending screen

---

### Edge Cases

- What happens when the driver's phone has no internet during OTP sending? The system shows a connectivity error and allows retry.
- What happens when the driver closes the app mid-OTP entry? On relaunch, they must restart the authentication flow.
- What happens when a document upload is interrupted by losing connection? The partially uploaded file is discarded and the slot remains in the "not uploaded" state so the driver can retry.
- What happens when the driver tries to register with a phone number already associated with a customer account? The system allows this — users can have different roles but the post-auth navigation routes them based on the app they are using (driver app).
- What happens when the driver rotates the device during onboarding? The layout adapts to the new orientation gracefully without losing the current slide position.
- What happens when the driver's profile photo exceeds the maximum file size? The image is compressed before upload. If it still exceeds limits, a friendly error is shown.
- What happens when the driver tries to go back from profile setup to login? They can navigate back, which effectively signs them out and returns to the login screen.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST display 3 driver-specific onboarding slides with illustrations, titles, descriptions, page indicators, and "Next" / "Get Started" button progression
- **FR-002**: System MUST provide a "Skip" button on all onboarding slides (except the last, where "Get Started" serves the same purpose) that navigates directly to the phone login screen
- **FR-003**: System MUST persist that onboarding has been completed so it is not shown again on subsequent app launches
- **FR-004**: System MUST display a phone login screen with Egypt country code (+20) pre-selected, a phone number input field, a "Continue" button, and social login options (Google, Facebook)
- **FR-005**: System MUST validate Egyptian phone numbers (10 digits starting with 10, 11, 12, or 15) before sending OTP
- **FR-006**: System MUST send a 4-digit OTP via SMS and navigate to the verification screen upon successful send
- **FR-007**: System MUST display a 30-second countdown timer on the OTP screen with a "Resend Code" option that activates when the timer expires
- **FR-008**: System MUST verify the OTP and, upon success, check whether the user has a complete profile to determine the next navigation destination
- **FR-009**: System MUST support Google sign-in as an alternative authentication method
- **FR-010**: System MUST support Facebook sign-in as an alternative authentication method
- **FR-011**: System MUST display a profile setup screen with photo upload, full name input, and language selection (English / Arabic) after first-time authentication
- **FR-012**: System MUST validate that the driver's name is provided before allowing profile completion
- **FR-013**: System MUST switch the app language and text direction (LTR/RTL) when the language toggle is changed
- **FR-014**: System MUST display a driver registration screen with vehicle model input, plate number input, 4 document upload slots, a step progress indicator, and a "Submit Application" button
- **FR-015**: System MUST accept image uploads for each of the 4 required documents: National ID Card, Driving License, Vehicle Registration, and Criminal Record
- **FR-016**: System MUST show a visual indicator (green checkmark) when a document is successfully uploaded
- **FR-017**: System MUST validate that all vehicle fields are filled and all 4 documents are uploaded before allowing application submission
- **FR-018**: System MUST create a driver profile record and update the user's status to "pending approval" upon successful application submission
- **FR-019**: System MUST display a pending approval screen with a status timeline, review message, "Contact Support" button, and "Back to Home" link after submission
- **FR-020**: System MUST route returning drivers with "pending approval" status directly to the pending screen on app launch (bypassing onboarding and login)
- **FR-021**: System MUST route returning approved drivers directly to the driver home screen on app launch
- **FR-022**: All text content MUST be localized in both Arabic and English, with Arabic as the default language
- **FR-023**: All screens MUST render correctly in both RTL (Arabic) and LTR (English) layouts

### Key Entities

- **Driver User**: A user of type "driver" with attributes: unique ID, name, phone number, avatar photo URL, preferred language, account status (active, pending approval, suspended), and profile completeness flag
- **Driver Profile**: Vehicle information associated with a driver: motorcycle model, plate number. Linked to the driver user by unique ID
- **Driver Document**: A verification document uploaded by a driver: document type (national ID, license, vehicle registration, criminal record), file reference, review status (pending, approved, rejected), and optional admin note. Multiple documents belong to one driver
- **Onboarding State**: A local persistence flag indicating whether the driver has seen the onboarding slides, preventing repeated display

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Drivers can complete the full journey from app launch to application submission in under 5 minutes (excluding document photo preparation time)
- **SC-002**: 90% of drivers successfully complete OTP verification on their first attempt
- **SC-003**: The onboarding flow achieves a completion rate of at least 80% (drivers who start onboarding and proceed to login)
- **SC-004**: All screens render correctly in both Arabic (RTL) and English (LTR) with no layout breakage or text truncation
- **SC-005**: Document upload success rate is at least 95% under normal network conditions
- **SC-006**: Drivers with pending approval status are correctly routed to the pending screen on every app launch with 100% accuracy
- **SC-007**: The authentication flow supports phone OTP, Google, and Facebook sign-in methods, each completing in under 30 seconds (excluding user input time)

## Assumptions

- The existing customer onboarding infrastructure (OnboardingScreen, OnboardingController, OnboardingPage widget, PageIndicator widget) can be reused for driver onboarding with different slide content and data
- The existing authentication screens (PhoneLoginScreen, OtpVerificationScreen) and AuthController are shared between customer and driver apps
- The existing ProfileSetupScreen and ProfileSetupController handle profile creation for both customer and driver users
- The existing DriverRegistrationScreen, DriverRegistrationController, and related widgets handle the vehicle/document registration flow
- The splash screen already handles routing logic for returning users (checking auth state and user status)
- Facebook sign-in follows the same pattern as the existing Google sign-in implementation
- Document uploads are stored via the existing StorageService with appropriate folder structure per driver
- The "Contact Support" button on the pending screen opens a URL (e.g., WhatsApp, email) — exact channel follows standard app support patterns
- Driver onboarding slides use different illustrations and text from customer slides, but share the same widget structure and navigation pattern
