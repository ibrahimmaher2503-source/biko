# Quickstart: Driver Authentication & Onboarding

**Branch**: `012-driver-auth-onboarding` | **Date**: 2026-03-02

## Prerequisites

- Flutter SDK installed
- Firebase project configured (Firebase Auth, Firestore, Storage)
- Google Sign-In configured (already done)
- Facebook Developer App created with App ID and Secret (new requirement)
- Facebook sign-in provider enabled in Firebase Console (new requirement)

## Development Setup

```bash
# Switch to feature branch
git checkout 012-driver-auth-onboarding

# Install dependencies (after adding flutter_facebook_auth)
flutter pub get

# Run driver app
flutter run -t lib/main_driver.dart

# Run with dev OTP bypass (no Firebase needed)
# Set DevConfig.skipOtp = true in lib/core/constants/dev_config.dart
```

## Driver App Flow

```
SplashScreen
  ├─ First launch → OnboardingScreen (3 driver slides)
  │                    └─ PhoneLoginScreen
  │                         ├─ Phone OTP → OtpVerificationScreen → ProfileSetupScreen
  │                         ├─ Google Sign-In → ProfileSetupScreen
  │                         └─ Facebook Sign-In → ProfileSetupScreen
  │                              └─ DriverRegistrationScreen
  │                                   └─ PendingApprovalScreen
  ├─ Returning (no profile) → ProfileSetupScreen
  ├─ Returning (pending) → PendingApprovalScreen
  └─ Returning (approved) → DriverHomeScreen
```

## Key Files for This Feature

### Already Complete (review only)
- `lib/features/onboarding/` — Full onboarding flow with driver slides
- `lib/features/auth/screens/phone_login_screen.dart` — Phone login UI
- `lib/features/auth/screens/otp_verification_screen.dart` — OTP verification UI
- `lib/features/auth/screens/profile_setup_screen.dart` — Profile setup UI
- `lib/features/auth/controllers/auth_controller.dart` — Auth state management
- `lib/features/auth/controllers/profile_setup_controller.dart` — Profile flow
- `lib/features/driver_registration/` — Full registration flow
- `lib/features/splash/` — App routing logic
- `lib/core/routes/driver_pages.dart` — Driver route definitions
- `lib/core/translations/app_translations.dart` — All translation keys

### Files to Modify
- `pubspec.yaml` — Add `flutter_facebook_auth` dependency
- `lib/core/models/enums.dart` — Add `signingInWithFacebook` to AuthState
- `lib/core/services/auth_service.dart` — Add `signInWithFacebook()` method
- `lib/features/auth/controllers/auth_controller.dart` — Add Facebook sign-in handler
- `lib/features/auth/widgets/social_login_buttons.dart` — Wire Facebook button
- `lib/features/onboarding/controllers/onboarding_controller.dart` — App-type-specific persistence key
- `lib/features/splash/controllers/splash_controller.dart` — App-type-specific persistence check
- `lib/features/driver_registration/screens/pending_approval_screen.dart` — Contact Support button
- `android/app/src/main/AndroidManifest.xml` — Facebook SDK config
- `ios/Runner/Info.plist` — Facebook SDK config

### Manual Configuration Steps
1. Create Facebook App at developers.facebook.com
2. Add Android platform with package name and key hash
3. Add iOS platform with bundle ID
4. Enable Facebook provider in Firebase Console → Authentication → Sign-in method
5. Enter Facebook App ID and App Secret in Firebase Console

## Testing

```bash
# Run all tests
flutter test

# Run specific test
flutter test test/features/auth/

# Run driver app with dev bypass
# (skips Firebase OTP, useful for UI testing)
```

## Dev Bypass

In `lib/core/constants/dev_config.dart`:
- `skipOtp = true` — Skips Firebase OTP, routes directly to profile setup
- Useful for testing the full flow without Firebase phone auth
