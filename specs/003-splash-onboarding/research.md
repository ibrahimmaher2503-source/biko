# Research: Splash, Onboarding, and Authentication Flow

**Feature Branch**: `003-splash-onboarding`
**Date**: 2026-03-01

## R-001: Firebase Phone Auth Integration with GetX

**Decision**: Use `firebase_auth` package directly within `AuthController` (GetX). The controller wraps `FirebaseAuth.instance.verifyPhoneNumber()` and manages the verification lifecycle through observable state.

**Rationale**: Firebase Phone Auth provides built-in OTP delivery and verification for Egypt (+20 numbers). GetX's reactive state management maps naturally to the multi-step auth flow (idle → sending → codeSent → verifying → success/error). No additional wrapper library needed.

**Alternatives considered**:
- `phone_auth_handler` package — adds abstraction but hides Firebase internals, making error handling harder. Rejected.
- BLoC pattern — contradicts CLAUDE.md mandate to always use GetX. Rejected.

**Implementation pattern**:
```dart
// AuthController manages the full lifecycle
class AuthController extends GetxController {
  final _verificationId = ''.obs;
  final _authState = AuthState.idle.obs;

  Future<void> sendOtp(String phoneNumber) async {
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: _onAutoVerify,
      verificationFailed: _onVerificationFailed,
      codeSent: _onCodeSent,
      codeAutoRetrievalTimeout: _onTimeout,
    );
  }
}
```

---

## R-002: Onboarding Carousel Implementation

**Decision**: Use Flutter's built-in `PageView` with `PageController` for the onboarding carousel. A shared `OnboardingPage` widget renders each slide, parameterized by content data (title, description, illustration asset, highlight word).

**Rationale**: `PageView` is the standard Flutter widget for swipeable pages. It handles gesture detection, page snapping, and animation natively. No third-party carousel package needed. The stitch designs show a simple 3-page swipe with pagination dots — well within `PageView` capabilities.

**Alternatives considered**:
- `smooth_page_indicator` package — only for dots. We can build the simple dot indicator (w-8 active, w-2 inactive) in ~30 lines. No package needed.
- `carousel_slider` — overkill for a 3-page onboarding. Adds unnecessary dependency. Rejected.
- `introduction_screen` — opinionated package with limited customization for our design. Rejected.

**Implementation pattern**:
- `OnboardingController` (GetX) holds `PageController`, current page index, and slide data
- `OnboardingPage` widget is a stateless widget taking `OnboardingSlide` data
- Both customer and driver onboarding use the same widget, different data
- Pagination dots built as a simple `Row` of `AnimatedContainer` widgets

---

## R-003: First-Launch Detection & Navigation Routing

**Decision**: Use `shared_preferences` (already in pubspec.yaml) to store a boolean `onboarding_completed` flag. The splash screen reads this flag, checks `FirebaseAuth.instance.currentUser`, and routes accordingly.

**Rationale**: `shared_preferences` is lightweight, synchronous after initialization, and already a project dependency. The flag needs only to persist across app restarts on a single device — perfect fit.

**Navigation decision tree** (from splash):
```
1. Is onboarding completed? NO → /onboarding
2. Is user authenticated? NO → /auth/phone
3. Is user profile complete? NO → /auth/profile-setup
4. [Driver app only] Is driver approved? NO → /driver/pending
5. Otherwise → /customer/home or /driver/home
```

**Alternatives considered**:
- Hive for local storage — more powerful but overkill for a single boolean. Rejected.
- Firebase Remote Config for flags — network-dependent, inappropriate for first-launch detection. Rejected.

---

## R-004: OTP Input Field Implementation

**Decision**: Build a custom `OtpInputField` widget using 4 individual `TextField` widgets with `FocusNode` management for auto-advance behavior. Each field accepts exactly 1 digit and automatically moves focus to the next field.

**Rationale**: The stitch design (authentication_otp_verification) shows 4 separate input boxes (h-16 w-14) with individual focus states. A custom implementation gives exact control over sizing, styling, and focus behavior matching the design.

**Alternatives considered**:
- `pin_code_fields` package — close match but styling customization is limited for our specific design (rounded-xl borders, primary color focus ring). Rejected.
- `otp_text_field` package — similar limitations. Rejected.
- Single `TextField` with letter spacing — doesn't match the design showing separate boxes. Rejected.

**Implementation details**:
- 4 `TextEditingController` instances + 4 `FocusNode` instances
- `onChanged` callback on each field: when length == 1, advance focus to next
- Backspace handling: when field is empty and backspace pressed, move focus to previous
- Auto-submit when all 4 digits entered

---

## R-005: Image Upload Strategy (Avatar & Documents)

**Decision**: Use `image_picker` package for camera/gallery selection. Upload to Firebase Storage under structured paths. Store download URL in Firestore.

**Rationale**: `image_picker` is the standard Flutter approach for camera/gallery access. Firebase Storage provides secure, scalable file storage with automatic CDN.

**Storage paths**:
- Avatar: `users/{uid}/avatar.jpg`
- Documents: `documents/{uid}/{docType}_{timestamp}.jpg`

**Image processing**:
- Resize to max 1024px width before upload (using `image_picker`'s `maxWidth` parameter)
- JPEG quality: 80% (good balance of quality vs. file size)
- Max file size check: 5MB client-side validation

**Alternatives considered**:
- Direct base64 in Firestore — size limits (1MB per document). Rejected.
- Cloudinary — external dependency when Firebase Storage is already in stack. Rejected.

---

## R-006: Missing Package Dependencies

**Decision**: Add the following packages to pubspec.yaml:

| Package | Version | Purpose |
|---------|---------|---------|
| `firebase_auth` | ^5.0.0 | Phone OTP authentication |
| `cloud_firestore` | ^5.0.0 | User/driver profile persistence |
| `firebase_storage` | ^12.0.0 | Document and avatar uploads |
| `image_picker` | ^1.0.0 | Camera/gallery access |

**Rationale**: These are already listed in CLAUDE.md's key dependencies section. They're essential Firebase packages for auth, data, and storage that weren't added in spec 001 (which focused on theme/widgets only).

**Note**: `firebase_messaging` (FCM) is NOT needed for this spec — push notifications are out of scope.

---

## R-007: Phone Number Validation (Egypt)

**Decision**: Validate Egyptian phone numbers client-side before sending to Firebase Auth. Format: 11 digits starting with `01` (after +20 prefix).

**Validation rules**:
- Must be exactly 11 digits (after country code)
- Must start with `01` (Egyptian mobile prefix)
- Accepted prefixes: `010`, `011`, `012`, `015` (Egyptian mobile operators: Vodafone, Etisalat, Orange, WE)
- Full international format sent to Firebase: `+20XXXXXXXXXX` (10 digits after +20)

**Rationale**: Firebase Auth requires E.164 format. Client-side validation prevents unnecessary API calls for obviously invalid numbers.

---

## R-008: 30-Second OTP Timer

**Decision**: Implement a client-side countdown timer using `Timer.periodic` within `AuthController`. The timer is purely visual — actual OTP expiry is server-side (Firebase default: 60 seconds).

**Rationale**: The stitch design shows a "00:30" countdown with a timer icon. This is a UX pattern to prevent spam resending. The timer does not control actual OTP validity.

**Implementation**:
- `RxInt secondsRemaining = 30.obs` in controller
- `Timer.periodic(Duration(seconds: 1))` decrements until 0
- Resend button enabled when `secondsRemaining == 0`
- On resend: reset to 30 and restart timer

---

## R-009: Splash Screen Timing & Animation

**Decision**: Show splash for minimum 2 seconds (for brand visibility) while performing initialization checks in parallel. If checks complete before 2 seconds, wait. If checks take longer, wait for completion.

**Rationale**: Spec SC-010 requires navigation within 3 seconds. 2-second minimum gives brand exposure while leaving 1 second margin for Firebase/SharedPreferences reads.

**Initialization sequence** (parallel where possible):
1. Read `onboarding_completed` from SharedPreferences
2. Check `FirebaseAuth.instance.currentUser`
3. If authenticated, fetch user profile from Firestore
4. Determine navigation destination
5. Navigate with `Get.offAllNamed()`

---

## R-010: Onboarding Third Slide Content

**Decision**: Based on the stitch designs and spec analysis:

**Customer App (3 slides)**:
1. "Beat the Traffic" — Speed/agility (screenshot: motorcycle rider in city)
2. "Your Price, Your Choice" — Fair bidding (stitch: handshake illustration)
3. "Fast Delivery" — Delivery capability (follows same pattern)

**Driver App (3 slides)**:
1. "Be Your Own Boss" — Freedom (stitch: happy delivery driver)
2. "Safe & Reliable" — Trust/insurance (stitch: motorcycle with shield)
3. "Earn More" — Earnings potential (follows same pattern)

**Rationale**: The spec mentions a "third selling point" without specifying. These choices align with the app's core value propositions (ride + delivery for customers, earnings for drivers).

---

## R-011: Social Login Buttons (Deferred)

**Decision**: Display Google and Facebook buttons as per the phone login stitch design, but they will show a "Coming Soon" snackbar when tapped. No actual OAuth implementation.

**Rationale**: Spec explicitly states: "Social login (Google, Facebook) will be implemented as future enhancements — buttons are displayed but may initially show 'coming soon' or be non-functional."

---

## R-012: Map Background on Phone Login

**Decision**: Use a static map image of Cairo as the background for the phone login screen, overlaid with a red gradient tint matching the stitch design.

**Rationale**: Spec states "Static image or gradient background acceptable as placeholder." The stitch screenshot shows a Google Maps view of Cairo with a red overlay. A static image avoids Google Maps SDK dependency for a non-interactive decorative element.

**Implementation**: Store a pre-captured Cairo map image in `assets/images/cairo_map.png` and overlay with a gradient from `primary.withOpacity(0.7)` to `primary.withOpacity(0.85)`.
