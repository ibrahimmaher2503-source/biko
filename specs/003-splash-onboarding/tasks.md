# Tasks: Splash, Onboarding, and Authentication Flow

**Input**: Design documents from `/specs/003-splash-onboarding/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/navigation.md, quickstart.md

**Tests**: Not explicitly requested in spec — test tasks omitted. Tests can be added later via `/speckit.checklist`.

**Organization**: Tasks are grouped by user story (US1–US8) to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story (US1–US8)
- Exact file paths included in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Add missing dependencies, create asset structure, register paths

- [X] T001 Add `firebase_auth`, `cloud_firestore`, `firebase_storage`, and `image_picker` packages to `pubspec.yaml` and run `flutter pub get`
- [X] T002 Create asset directories: `assets/images/logo/`, `assets/images/onboarding/`, `assets/images/backgrounds/` and add placeholder PNG files for all 7 illustrations (bikeride_logo, customer_speed, customer_bidding, customer_delivery, driver_freedom, driver_trust, driver_earnings, cairo_map)
- [X] T003 Register new asset paths in `pubspec.yaml` under the `flutter.assets` section: `assets/images/logo/`, `assets/images/onboarding/`, `assets/images/backgrounds/`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core models, services, enums, translations, and route configs that ALL user stories depend on

**CRITICAL**: No user story work can begin until this phase is complete

- [X] T004 Create shared enums file with `UserType`, `UserStatus`, `VehicleType`, `DocumentType`, `DocumentStatus`, and `AuthState` enums in `lib/core/models/enums.dart` — include Firestore snake_case serialization helpers for each enum
- [X] T005 [P] Create `UserModel` with all fields from data-model.md (uid, name, phone, type, status, walletBalance, referralCode, referredBy, lang, avatarUrl, fcmToken, createdAt), `fromJson`/`toJson` serialization, `copyWith`, and validation rules in `lib/core/models/user_model.dart`
- [X] T006 [P] Create `DriverProfileModel` with all fields from data-model.md (uid, nationalId, licenseNumber, vehicleType, plateNumber, vehicleModel, isOnline, isApproved, currentLat, currentLng, ratingAvg, totalTrips, totalEarnings), `fromJson`/`toJson`, and `copyWith` in `lib/core/models/driver_profile_model.dart`
- [X] T007 [P] Create `DocumentModel` with all fields from data-model.md (id, driverUid, type, fileUrl, status, adminNote, createdAt), `fromJson`/`toJson` in `lib/core/models/document_model.dart`
- [X] T008 [P] Create `AuthService` wrapping Firebase Phone Auth — methods: `sendOtp(phoneNumber)` with verifyPhoneNumber callbacks, `verifyOtp(verificationId, smsCode)` returning `UserCredential`, `signOut()`, `get currentUser` in `lib/core/services/auth_service.dart`
- [X] T009 [P] Create `FirestoreService` for user/driver/document CRUD — methods: `getUser(uid)`, `updateUser(uid, data)`, `getDriverProfile(uid)`, `createDriverProfile(profile)`, `updateDriverProfile(uid, data)`, `createDocument(doc)`, `getDocumentsByDriver(uid)` in `lib/core/services/firestore_service.dart`
- [X] T010 [P] Create `StorageService` for Firebase Storage uploads — methods: `uploadAvatar(uid, file)` returning download URL, `uploadDocument(uid, docType, file)` returning download URL, with 1024px maxWidth resize and 5MB validation in `lib/core/services/storage_service.dart`
- [X] T011 Extend `AppTranslations` with all localization keys for splash, onboarding (customer + driver, 3 slides each with title/highlight/description), phone login, OTP verification, profile setup, driver registration, and pending status screens (~80 keys per language) in `lib/core/translations/app_translations.dart`
- [X] T012 [P] Create `customer_pages.dart` with `GetPage` list for customer app routes (splash, onboarding, phoneLogin, otpVerification, profileSetup) with bindings per navigation contract in `lib/core/routes/customer_pages.dart`
- [X] T013 [P] Create `driver_pages.dart` with `GetPage` list for driver app routes (splash, onboarding, phoneLogin, otpVerification, profileSetup, driverRegistration, pendingApproval) with bindings per navigation contract in `lib/core/routes/driver_pages.dart`
- [X] T014 [P] Update `main_customer.dart` to use `GetMaterialApp` with `getPages` from `customer_pages.dart`, `initialRoute: AppRoutes.splash`, `AppTranslations`, locale settings, and theme with `AppTheme.getThemeWithLocale` in `lib/main_customer.dart`
- [X] T015 [P] Update `main_driver.dart` to use `GetMaterialApp` with `getPages` from `driver_pages.dart`, `initialRoute: AppRoutes.splash`, `AppTranslations`, locale settings, and theme with `AppTheme.getThemeWithLocale` in `lib/main_driver.dart`

**Checkpoint**: Foundation ready — all models, services, routes, and translations in place. User story implementation can begin.

---

## Phase 3: User Story 1 — Splash Screen with App Initialization (Priority: P1) MVP

**Goal**: Display branded splash screen, initialize Firebase, check auth/onboarding state, and route to the correct next screen within 3 seconds.

**Independent Test**: Launch app → splash appears with logo → auto-navigates to onboarding (first launch), phone login (unauthenticated), or home (authenticated) within 3 seconds.

### Implementation for User Story 1

- [X] T016 [US1] Create `SplashController` with parallel initialization: read `onboarding_completed` from SharedPreferences, check `FirebaseAuth.currentUser`, fetch user profile from Firestore if authenticated, determine navigation destination per decision tree (research R-003), enforce 2-second minimum display (research R-009), navigate with `Get.offAllNamed` in `lib/features/splash/controllers/splash_controller.dart`
- [X] T017 [P] [US1] Create `SplashBinding` with `Get.lazyPut(() => SplashController())` in `lib/features/splash/bindings/splash_binding.dart`
- [X] T018 [US1] Create `SplashScreen` displaying centered BikeRide logo (`assets/images/logo/bikeride_logo.png`), app name text, and loading indicator on background color from AppTheme, with `Obx` listening to SplashController state in `lib/features/splash/screens/splash_screen.dart`

**Checkpoint**: App launches → splash screen → auto-routes correctly. US1 complete.

---

## Phase 4: User Story 2 — Customer Onboarding Flow (Priority: P2)

**Goal**: 3-slide swipeable carousel with customer-specific content (Beat the Traffic, Your Price Your Choice, Fast Delivery), pagination dots, Skip button, and Get Started on last slide. Navigates to phone login.

**Independent Test**: Launch as first-time customer → swipe through 3 slides → verify illustrations, headlines with colored highlight words, descriptions, pagination dot updates → tap Skip or Get Started → navigates to phone login.

### Implementation for User Story 2

- [X] T019 [P] [US2] Create `OnboardingSlide` data class with fields (title, highlightWord, description, illustration, index) and static `customerSlides` list with 3 slides per data-model.md content in `lib/features/onboarding/data/onboarding_data.dart`
- [X] T020 [P] [US2] Create `PageIndicator` widget — a Row of 3 `AnimatedContainer` dots: active dot w-32 (8*4dp) with primary color, inactive dots w-8 (2*4dp) with slate-200/slate-700 per stitch design (FR-009) in `lib/features/onboarding/widgets/page_indicator.dart`
- [X] T021 [US2] Create `OnboardingPage` stateless widget — takes `OnboardingSlide` data, renders: illustration image with decorative blur blob, headline with `highlightWord` in primary color using RichText, description text, centered layout matching stitch designs (driver_onboarding_freedom/code.html pattern) in `lib/features/onboarding/widgets/onboarding_page.dart`
- [X] T022 [US2] Create `OnboardingController` with `PageController`, `RxInt currentPage`, slide data selection based on `Get.arguments` app type, methods: `nextPage()`, `skip()`, `getStarted()` — both skip and getStarted save `onboarding_completed=true` to SharedPreferences then `Get.offAllNamed(AppRoutes.phoneLogin)` in `lib/features/onboarding/controllers/onboarding_controller.dart`
- [X] T023 [P] [US2] Create `OnboardingBinding` with `Get.lazyPut(() => OnboardingController())` in `lib/features/onboarding/bindings/onboarding_binding.dart`
- [X] T024 [US2] Create `OnboardingScreen` with: top bar (back button + Skip), `PageView.builder` using `OnboardingPage` widgets, bottom area with `PageIndicator` and primary action button (Next on slides 0-1, Get Started on slide 2 with arrow_forward icon), matching stitch layout (p-6, pb-8 spacing) in `lib/features/onboarding/screens/onboarding_screen.dart`

**Checkpoint**: First-time customer launch → splash → onboarding with 3 customer slides → phone login. US2 complete.

---

## Phase 5: User Story 3 — Driver Onboarding Flow (Priority: P2)

**Goal**: Same onboarding carousel with driver-specific content (Be Your Own Boss, Safe & Reliable, Earn More). Reuses all widgets from US2 with different data.

**Independent Test**: Launch driver app as first-time user → swipe through 3 driver slides → verify driver-specific illustrations and text → Get Started navigates to phone login.

### Implementation for User Story 3

- [X] T025 [US3] Add static `driverSlides` list with 3 slides (Be Your Own Boss/Boss, Safe & Reliable/Reliable, Earn More/More) to `OnboardingSlide` class per data-model.md content in `lib/features/onboarding/data/onboarding_data.dart`
- [X] T026 [US3] Add driver onboarding localization keys (onboarding.driver.slide1–3.title, highlight, desc) for both Arabic and English to `lib/core/translations/app_translations.dart`

**Checkpoint**: Driver app first launch → splash → onboarding with 3 driver slides → phone login. US3 complete. Shared widget (SC-008) validated.

---

## Phase 6: User Story 4 — Phone Number Authentication (Priority: P3)

**Goal**: Phone login screen with Cairo map background, BikeRide branding, +20 Egypt phone input with validation, Continue button triggering Firebase OTP, social login buttons (deferred), and terms/privacy links.

**Independent Test**: Navigate to phone login → enter valid Egyptian number (010/011/012/015 prefix, 11 digits) → tap Continue → OTP is sent and user navigates to OTP screen. Enter invalid number → error shown, no OTP sent.

### Implementation for User Story 4

- [X] T027 [P] [US4] Create `PhoneInputField` widget — +20 country code display with Egypt flag, text input accepting 10 digits (after country code), Egyptian number validation per research R-007 (prefixes: 010, 011, 012, 015), formatted display, error state, matching stitch phone login design in `lib/features/auth/widgets/phone_input_field.dart`
- [X] T028 [P] [US4] Create `SocialLoginButtons` widget — Row with Google and Facebook outlined buttons, each shows "Coming Soon" snackbar via `AppSnackbar` on tap per research R-011, matching stitch "OR CONTINUE WITH" section layout in `lib/features/auth/widgets/social_login_buttons.dart`
- [X] T029 [US4] Expand `AuthController` from stub: add `AuthState` observable, `RxString phoneNumber`, `sendOtp(phoneNumber)` calling `AuthService.sendOtp()` with callbacks updating state (idle→sendingOtp→codeSent), phone validation method `isValidEgyptianPhone()`, error handling for `FirebaseAuthException`, and `signOut()` method in `lib/features/auth/controllers/auth_controller.dart`
- [X] T030 [US4] Create `PhoneLoginScreen` with: top section showing Cairo map background image (`assets/images/backgrounds/cairo_map.png`) with primary color gradient overlay, BikeRide logo icon, "Yalla! Let's get moving" headline, "Ride or deliver across Cairo" subtitle; bottom card with `PhoneInputField`, Continue `AppButton` calling `authController.sendOtp()`, `SocialLoginButtons`, terms/privacy text with primary-colored links; matching stitch authentication_phone_login design in `lib/features/auth/screens/phone_login_screen.dart`

**Checkpoint**: Navigate to phone login → enter number → Continue sends OTP → navigates to OTP screen. US4 complete.

---

## Phase 7: User Story 5 — OTP Verification (Priority: P3)

**Goal**: 4-digit OTP input with auto-advance focus, 30-second countdown timer, resend capability, verify against Firebase Auth, route new users to profile setup and returning users to home.

**Independent Test**: Navigate to OTP screen → see masked phone number and 4 input fields → enter correct code → authenticated → routes to profile setup (new) or home (returning). Enter wrong code → error shown. Wait 30s → Resend Code becomes active.

### Implementation for User Story 5

- [X] T031 [P] [US5] Create `OtpInputField` widget — 4 individual `TextField` widgets (h-64 w-56 each, rounded-xl, text-2xl bold, center-aligned), 4 `FocusNode`s with auto-advance on digit entry, backspace moves focus to previous, auto-submit when all 4 filled, focused field shows primary border with ring shadow, returns complete OTP string via callback, matching stitch authentication_otp_verification design in `lib/features/auth/widgets/otp_input_field.dart`
- [X] T032 [US5] Add OTP verification logic to `AuthController`: `verifyOtp(smsCode)` calling `AuthService.verifyOtp()`, `RxInt secondsRemaining = 30.obs`, `startTimer()` with `Timer.periodic` decrementing every second, `resendOtp()` resetting timer to 30 and re-calling `sendOtp()`, `isResendEnabled` computed getter, post-auth routing logic (check if user doc exists in Firestore → new user to profileSetup, returning user to customerHome/driverHome) in `lib/features/auth/controllers/auth_controller.dart`
- [X] T033 [US5] Create `OtpVerificationScreen` with: back button header, "Verify Your Number" heading, masked phone number text (showing last 2 digits), `OtpInputField` widget, timer badge showing "00:XX" with timer icon in primary color, "Didn't receive the code?" text with "Resend Code" button (disabled while timer > 0), Verify `AppButton` with check_circle icon, matching stitch authentication_otp_verification design layout (py-6, gap-4 spacing) in `lib/features/auth/screens/otp_verification_screen.dart`

**Checkpoint**: Full phone auth flow works: phone login → OTP → verified → routes correctly. US5 complete.

---

## Phase 8: User Story 6 — Profile Setup (Priority: P4)

**Goal**: New user completes profile with avatar upload, full name, language selection. Saves to Firestore. Customer → home, Driver → registration.

**Independent Test**: Navigate to profile setup → upload avatar → enter name → select language (app switches immediately) → tap Complete Profile → data saved to Firestore `users/{uid}` → routes to customer home or driver registration.

### Implementation for User Story 6

- [X] T034 [US6] Create `ProfileSetupController` with: `TextEditingController nameController`, `Rx<String?> avatarUrl`, `RxString selectedLang = 'en'.obs`, `pickAvatar()` using image_picker (camera/gallery bottom sheet) then `StorageService.uploadAvatar()`, `selectLanguage(lang)` updating `Get.updateLocale()` immediately per FR-022, `completeProfile()` validating name not empty then saving to Firestore via `FirestoreService.updateUser()` with name/avatarUrl/lang then navigating per contract (customer→customerHome, driver→driverRegistration) in `lib/features/auth/controllers/profile_setup_controller.dart`
- [X] T035 [P] [US6] Create `ProfileSetupBinding` with `Get.lazyPut(() => ProfileSetupController())` in `lib/features/auth/bindings/profile_setup_binding.dart`
- [X] T036 [US6] Create `ProfileSetupScreen` with: back button header with "Set Up Profile" title, circular avatar area (h-128 w-128) with camera badge overlay (bg-primary, photo_camera icon), tap triggers `pickAvatar()`, "Upload Photo" label with "Show us your smile!" helper text; Full Name `AppTextField` with person icon; "Select Language" label with 2-column radio grid (English/Arabic, selected state with primary bg and white text per stitch design); "Complete Profile" `AppButton` with arrow_forward icon; matching stitch authentication_profile_setup layout in `lib/features/auth/screens/profile_setup_screen.dart`

**Checkpoint**: New user can set up profile → data persists → correct navigation. US6 complete.

---

## Phase 9: User Story 7 — Driver Registration with Document Upload (Priority: P5)

**Goal**: Driver enters vehicle info and uploads 4 required documents. 4-step progress indicator, document status tracking, submit sends for admin review.

**Independent Test**: Navigate to driver registration → see step 2 highlighted → enter Motorcycle Model and Plate Number → upload 4 documents (checkmarks appear) → tap Submit Application → data saved to Firestore → navigates to pending status.

### Implementation for User Story 7

- [X] T037 [P] [US7] Create `StepProgressIndicator` widget — 4 horizontal bars (h-6, rounded-full), active step with w-32 bg-primary, inactive with bg-primary/20, gap-8 between bars, current step parameter, matching stitch driver_registration_documents progress bar in `lib/features/driver_registration/widgets/step_progress_indicator.dart`
- [X] T038 [P] [US7] Create `DocumentUploadItem` widget — full-width button with: left icon container (h-48 w-48 rounded-full with shadow), document name and helper text, right status indicator (dashed circle with add icon for pending, green bg with check icon for completed), hover state changing border to primary/30, matching stitch driver_registration_documents document items in `lib/features/driver_registration/widgets/document_upload_item.dart`
- [X] T039 [US7] Create `DriverRegistrationController` with: `TextEditingController` for vehicleModel and plateNumber, `RxMap<DocumentType, String?> uploadedDocuments` tracking upload status, `uploadDocument(DocumentType type)` using image_picker then `StorageService.uploadDocument()` then `FirestoreService.createDocument()`, `isDocumentUploaded(type)` getter, `submitApplication()` validating all fields/docs filled then creating `DriverProfileModel` via `FirestoreService.createDriverProfile()`, updating user status to pendingApproval, then `Get.offAllNamed(AppRoutes.pendingApproval)` in `lib/features/driver_registration/controllers/driver_registration_controller.dart`
- [X] T040 [P] [US7] Create `DriverRegistrationBinding` with `Get.lazyPut(() => DriverRegistrationController())` in `lib/features/driver_registration/bindings/driver_registration_binding.dart`
- [X] T041 [US7] Create `DriverRegistrationScreen` with: sticky header with back button and "Driver Registration" title with backdrop-blur; `StepProgressIndicator` (step 2 active); scrollable content with "Vehicle & Documents" section heading and description; vehicle form fields (Motorcycle Model with two_wheeler icon, Plate Number with uppercase); "Required Documents" heading; 4 `DocumentUploadItem`s (National ID/badge, Driving License/id_card, Vehicle Registration/assignment, Criminal Record/verified_user); blue info tip box ("Ensure all photos are clear..."); sticky bottom "Submit Application" `AppButton`; matching stitch driver_registration_documents layout (px-6, pb-24 for floating button) in `lib/features/driver_registration/screens/driver_registration_screen.dart`

**Checkpoint**: Driver can enter vehicle info, upload all 4 documents, and submit application. US7 complete.

---

## Phase 10: User Story 8 — Driver Application Pending Status (Priority: P5)

**Goal**: Status screen showing "Application Under Review" with timeline tracker, Contact Support and Back to Home buttons.

**Independent Test**: Navigate to pending status screen → see illustration, heading, timeline (Documents Submitted checked, Verification Pending), Contact Support button, Back to Home button → tap Back to Home → navigates to driver home.

### Implementation for User Story 8

- [X] T042 [US8] Create `PendingApprovalScreen` (stateless) with: sticky header with back button and "Status" title with backdrop-blur; centered content with illustration and decorative blur blob; "Application Under Review" heading; "We have received your application. We will notify you within 24 hours." description; status card with vertical timeline — "Documents Submitted" with green check_circle, connecting line, "Verification Pending" with pending icon at opacity 0.6; "Contact Support" primary `AppButton`; "Back to Home" transparent/outline button navigating to `AppRoutes.driverHome`; matching stitch driver_application_pending_status layout in `lib/features/driver_registration/screens/pending_approval_screen.dart`

**Checkpoint**: Complete driver flow: registration → submit → pending status screen. US8 complete.

---

## Phase 11: Polish & Cross-Cutting Concerns

**Purpose**: Edge cases, consistency verification, and cleanup

- [X] T043 Add error handling for Firebase initialization failure in `SplashController` — show error screen with retry option per edge case spec
- [X] T044 Add network connectivity error handling in `AuthController` — show offline error with retry for sendOtp/verifyOtp failures
- [X] T045 [P] Verify all screens render correctly in Arabic RTL mode — check text direction, icon flipping (back arrows), font switching to Cairo, layout mirroring (FR-031)
- [X] T046 [P] Verify all screens render correctly in dark theme — check contrast, background colors (backgroundDark), card colors, text readability (FR-032)
- [X] T047 Remove `demo_theme_screen.dart` and `demo_widgets_screen.dart` demo files and update old `main.dart` to redirect to `main_customer.dart` or remove entirely in `lib/`
- [X] T048 Run `flutter analyze` and fix any lint warnings or errors across all new files
- [X] T049 Validate implementation against quickstart.md — ensure all file paths match, dependencies are correct, and asset registration is complete

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 completion — **BLOCKS all user stories**
- **US1 Splash (Phase 3)**: Depends on Phase 2 — First story to implement (MVP)
- **US2 Customer Onboarding (Phase 4)**: Depends on Phase 2 — Can start in parallel with US1
- **US3 Driver Onboarding (Phase 5)**: Depends on Phase 4 (US2 builds shared widgets)
- **US4 Phone Auth (Phase 6)**: Depends on Phase 2 — Can start in parallel with US1/US2
- **US5 OTP (Phase 7)**: Depends on Phase 6 (US4 builds AuthController base + PhoneLoginScreen)
- **US6 Profile Setup (Phase 8)**: Depends on Phase 2 — Can start in parallel with US1/US2/US4
- **US7 Driver Registration (Phase 9)**: Depends on Phase 2 — Can start in parallel
- **US8 Pending Status (Phase 10)**: Depends on Phase 2 — Can start in parallel
- **Polish (Phase 11)**: Depends on all user stories being complete

### User Story Dependencies

```
Phase 1 (Setup)
    │
    ▼
Phase 2 (Foundational) ─── BLOCKS ALL ───┐
    │                                      │
    ├──► Phase 3: US1 (Splash)            │
    ├──► Phase 4: US2 (Customer Onboarding)│
    │         └──► Phase 5: US3 (Driver Onboarding — needs US2 widgets)
    ├──► Phase 6: US4 (Phone Auth)        │
    │         └──► Phase 7: US5 (OTP — needs US4 AuthController)
    ├──► Phase 8: US6 (Profile Setup)     │
    ├──► Phase 9: US7 (Driver Registration)│
    └──► Phase 10: US8 (Pending Status)   │
                                           │
Phase 11 (Polish) ◄───────────────────────┘
```

### Within Each User Story

- Widgets/data classes before controllers
- Controllers before screens
- Bindings can parallel with controllers (different files)

### Parallel Opportunities

**After Phase 2 completes, these can ALL start in parallel:**
- US1 (Splash) — independent
- US2 (Customer Onboarding) — independent
- US4 (Phone Auth) — independent
- US6 (Profile Setup) — independent
- US7 (Driver Registration) — independent
- US8 (Pending Status) — independent

**Sequential dependencies:**
- US3 waits for US2 (shared onboarding widget)
- US5 waits for US4 (shared AuthController expansion)

---

## Parallel Example: Phase 2 (Foundational)

```
# These can ALL run in parallel (different files):
T005: Create UserModel in lib/core/models/user_model.dart
T006: Create DriverProfileModel in lib/core/models/driver_profile_model.dart
T007: Create DocumentModel in lib/core/models/document_model.dart
T008: Create AuthService in lib/core/services/auth_service.dart
T009: Create FirestoreService in lib/core/services/firestore_service.dart
T010: Create StorageService in lib/core/services/storage_service.dart
T012: Create customer_pages.dart in lib/core/routes/customer_pages.dart
T013: Create driver_pages.dart in lib/core/routes/driver_pages.dart
```

## Parallel Example: After Phase 2

```
# These user stories can start simultaneously:
Agent A: US1 (T016–T018) — Splash screen
Agent B: US2 (T019–T024) — Customer onboarding
Agent C: US4 (T027–T030) — Phone login
Agent D: US6 (T034–T036) — Profile setup
Agent E: US7 (T037–T041) — Driver registration
```

---

## Implementation Strategy

### MVP First (US1 Only)

1. Complete Phase 1: Setup (T001–T003)
2. Complete Phase 2: Foundational (T004–T015)
3. Complete Phase 3: US1 — Splash Screen (T016–T018)
4. **STOP and VALIDATE**: App launches → splash appears → routes correctly
5. Demo-ready with smart routing logic

### Incremental Delivery

1. Setup + Foundational → Foundation ready
2. **US1** (Splash) → App launches and routes → MVP
3. **US2 + US3** (Onboarding) → First-time users see carousel → Demo
4. **US4 + US5** (Phone Auth + OTP) → Users can authenticate → Demo
5. **US6** (Profile Setup) → New users complete profile → Demo
6. **US7 + US8** (Driver Registration + Pending) → Drivers can register → Full feature
7. Polish → Production-ready

### Recommended Order (Single Developer)

Phase 1 → Phase 2 → US1 → US2 → US3 → US4 → US5 → US6 → US7 → US8 → Polish

This follows priority order (P1→P2→P3→P4→P5) and respects sequential dependencies.

---

## Notes

- [P] tasks = different files, no dependencies on incomplete tasks
- [Story] label maps task to specific user story for traceability
- All navigation uses `Get.offAllNamed` except OTP screen (uses `Get.toNamed` for back support)
- AuthController is permanent (Get.put in AppInitializer) — not in any binding
- All other controllers use `Get.lazyPut()` in their respective bindings
- All text strings use GetX `.tr` localization — no hardcoded strings
- Stitch HTML files in `/stitch/` provide pixel-reference for each screen's layout
- Commit after each task or logical group for clean history
