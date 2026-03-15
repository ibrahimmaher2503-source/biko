# Quickstart: Splash, Onboarding, and Authentication Flow

**Feature Branch**: `003-splash-onboarding`
**Date**: 2026-03-01

## Prerequisites

1. Flutter SDK 3.9.2+ installed
2. Firebase project configured (see existing `firebase.json`)
3. Firebase Phone Auth enabled in Firebase Console with Egypt (+20) region
4. Firebase Storage enabled in Firebase Console

## Setup

### 1. Install new dependencies

Add to `pubspec.yaml` and run:
```bash
flutter pub add firebase_auth cloud_firestore firebase_storage image_picker
flutter pub get
```

### 2. Asset preparation

Create the following directories and add placeholder images:
```
assets/
├── images/
│   ├── logo/
│   │   └── bikeride_logo.png       # App logo for splash screen
│   ├── onboarding/
│   │   ├── customer_speed.png       # "Beat the Traffic" illustration
│   │   ├── customer_bidding.png     # "Your Price, Your Choice" illustration
│   │   ├── customer_delivery.png    # "Fast Delivery" illustration
│   │   ├── driver_freedom.png       # "Be Your Own Boss" illustration
│   │   ├── driver_trust.png         # "Safe & Reliable" illustration
│   │   └── driver_earnings.png      # "Earn More" illustration
│   └── backgrounds/
│       └── cairo_map.png            # Cairo map for phone login background
└── lang/
    ├── ar.json                      # (existing)
    └── en.json                      # (existing)
```

Register assets in `pubspec.yaml`:
```yaml
flutter:
  assets:
    - assets/lang/
    - assets/images/logo/
    - assets/images/onboarding/
    - assets/images/backgrounds/
```

### 3. Firebase configuration

Ensure Firebase config files are in place:
- Android: `android/app/google-services.json`
- iOS: `ios/Runner/GoogleService-Info.plist`

Enable in Firebase Console:
- Authentication → Phone provider → Enabled
- Cloud Firestore → Create database
- Storage → Get started

## Running the App

### Customer App
```bash
flutter run -t lib/main_customer.dart
```

### Driver App
```bash
flutter run -t lib/main_driver.dart
```

## Feature File Structure

```
lib/
├── core/
│   ├── models/
│   │   ├── user_model.dart           # UserModel with Firestore serialization
│   │   ├── driver_profile_model.dart # DriverProfileModel
│   │   └── document_model.dart       # DocumentModel for driver documents
│   ├── services/
│   │   ├── auth_service.dart         # Firebase Phone Auth wrapper
│   │   ├── firestore_service.dart    # Firestore CRUD operations
│   │   └── storage_service.dart      # Firebase Storage upload
│   ├── translations/
│   │   └── app_translations.dart     # Extended with onboarding/auth strings
│   └── routes/
│       ├── app_routes.dart           # Route constants (exists, no changes)
│       ├── customer_pages.dart       # GetPage list for customer app
│       └── driver_pages.dart         # GetPage list for driver app
│
└── features/
    ├── splash/
    │   ├── screens/
    │   │   └── splash_screen.dart
    │   ├── controllers/
    │   │   └── splash_controller.dart
    │   └── bindings/
    │       └── splash_binding.dart
    │
    ├── onboarding/
    │   ├── screens/
    │   │   └── onboarding_screen.dart
    │   ├── widgets/
    │   │   ├── onboarding_page.dart     # Shared slide widget
    │   │   └── page_indicator.dart      # Pagination dots
    │   ├── controllers/
    │   │   └── onboarding_controller.dart
    │   ├── bindings/
    │   │   └── onboarding_binding.dart
    │   └── data/
    │       └── onboarding_data.dart     # OnboardingSlide definitions
    │
    ├── auth/
    │   ├── screens/
    │   │   ├── phone_login_screen.dart
    │   │   ├── otp_verification_screen.dart
    │   │   └── profile_setup_screen.dart
    │   ├── widgets/
    │   │   ├── otp_input_field.dart      # 4-digit OTP input
    │   │   ├── phone_input_field.dart    # Egypt phone input with +20
    │   │   └── social_login_buttons.dart # Google/Facebook (deferred)
    │   ├── controllers/
    │   │   ├── auth_controller.dart      # Expanded from stub
    │   │   └── profile_setup_controller.dart
    │   └── bindings/
    │       └── profile_setup_binding.dart
    │
    └── driver_registration/
        ├── screens/
        │   ├── driver_registration_screen.dart
        │   └── pending_approval_screen.dart
        ├── widgets/
        │   ├── document_upload_item.dart  # Individual document row
        │   └── progress_indicator.dart    # 4-step progress bar
        ├── controllers/
        │   └── driver_registration_controller.dart
        └── bindings/
            └── driver_registration_binding.dart
```

## Key Implementation Notes

1. **AuthController is global** — registered in `AppInitializer` with `Get.put(permanent: true)`. All other feature controllers use `Get.lazyPut()` in bindings.

2. **Onboarding content is data-driven** — the same `OnboardingPage` widget is used for both customer and driver apps, parameterized by `OnboardingSlide` data.

3. **Navigation uses `offAllNamed`** for most transitions to clear the back stack (splash → onboarding → phone → home). Only OTP screen uses `toNamed` to allow back navigation to phone login.

4. **All strings go through localization** — no hardcoded text in widgets. Use `'key'.tr` GetX syntax.

5. **Firebase writes from Flutter are limited to**: user profile (name, avatar, lang), driver profile (vehicle info), and document records. Wallet/transactions are Cloud Functions only.
