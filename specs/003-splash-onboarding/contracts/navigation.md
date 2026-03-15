# Navigation Contract: Splash, Onboarding, and Authentication Flow

**Feature Branch**: `003-splash-onboarding`
**Date**: 2026-03-01

## Route Definitions

All routes use GetX named navigation. Route constants are defined in `lib/core/routes/app_routes.dart`.

### Route Table

| Route | Screen | Controller | Binding | Parameters |
|-------|--------|------------|---------|------------|
| `/splash` | `SplashScreen` | `SplashController` | `SplashBinding` | None |
| `/onboarding` | `OnboardingScreen` | `OnboardingController` | `OnboardingBinding` | `appType: String` (via Get.arguments) |
| `/auth/phone` | `PhoneLoginScreen` | `AuthController` | — (permanent) | None |
| `/auth/otp` | `OtpVerificationScreen` | `AuthController` | — (permanent) | `phoneNumber: String`, `verificationId: String` (via Get.arguments) |
| `/auth/profile-setup` | `ProfileSetupScreen` | `ProfileSetupController` | `ProfileSetupBinding` | None |
| `/driver/register` | `DriverRegistrationScreen` | `DriverRegistrationController` | `DriverRegistrationBinding` | None |
| `/driver/pending` | `PendingApprovalScreen` | None (stateless) | None | None |

---

## Navigation Flow

### Splash → Next Screen (offAllNamed — clears stack)

```
SplashScreen
  ├── onboarding NOT completed → Get.offAllNamed(AppRoutes.onboarding, arguments: appType)
  ├── NOT authenticated → Get.offAllNamed(AppRoutes.phoneLogin)
  ├── profile NOT complete → Get.offAllNamed(AppRoutes.profileSetup)
  ├── [driver] NOT approved → Get.offAllNamed(AppRoutes.pendingApproval)
  ├── [customer] → Get.offAllNamed(AppRoutes.customerHome)
  └── [driver, approved] → Get.offAllNamed(AppRoutes.driverHome)
```

### Onboarding → Phone Login (offAllNamed — clears stack)

```
OnboardingScreen
  ├── "Skip" button → Get.offAllNamed(AppRoutes.phoneLogin)
  └── "Get Started" (last slide) → Get.offAllNamed(AppRoutes.phoneLogin)
```

Onboarding sets `onboarding_completed = true` in SharedPreferences before navigating.

### Phone Login → OTP (toNamed — pushes onto stack)

```
PhoneLoginScreen
  └── "Continue" (valid phone) → Get.toNamed(
        AppRoutes.otpVerification,
        arguments: {
          'phoneNumber': '+20XXXXXXXXXX',
          'verificationId': 'firebase_verification_id',
        },
      )
```

### OTP → Profile Setup / Home (offAllNamed — clears stack)

```
OtpVerificationScreen
  ├── new user → Get.offAllNamed(AppRoutes.profileSetup)
  └── returning user → Get.offAllNamed(AppRoutes.customerHome / AppRoutes.driverHome)
```

### Profile Setup → Next (offAllNamed — clears stack)

```
ProfileSetupScreen
  ├── [customer app] → Get.offAllNamed(AppRoutes.customerHome)
  └── [driver app] → Get.offAllNamed(AppRoutes.driverRegistration)
```

### Driver Registration → Pending (offAllNamed — clears stack)

```
DriverRegistrationScreen
  └── "Submit Application" → Get.offAllNamed(AppRoutes.pendingApproval)
```

### Pending Approval → Home (offAllNamed — clears stack)

```
PendingApprovalScreen
  └── "Back to Home" → Get.offAllNamed(AppRoutes.driverHome)
```

---

## Back Navigation

| From | Back behavior |
|------|---------------|
| Splash | N/A (initial route) |
| Onboarding | System back exits app (no previous route) |
| Phone Login | System back exits app OR returns to onboarding (if first launch, but onboarding was offAllNamed so no back) |
| OTP Verification | `Get.back()` → returns to Phone Login (number pre-filled) |
| Profile Setup | No back button (user must complete profile) |
| Driver Registration | No back button (user must complete registration) |
| Pending Approval | "Back to Home" button (not system back) |

---

## GetX Bindings Contract

### SplashBinding
```dart
class SplashBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => SplashController());
  }
}
```

### OnboardingBinding
```dart
class OnboardingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => OnboardingController());
  }
}
```

### ProfileSetupBinding
```dart
class ProfileSetupBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ProfileSetupController());
  }
}
```

### DriverRegistrationBinding
```dart
class DriverRegistrationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => DriverRegistrationController());
  }
}
```

### AuthController (Global — NOT in binding)
```dart
// Registered in AppInitializer with Get.put(permanent: true)
// Available on all auth screens without binding
```

---

## GetPage Route Registration

```dart
// In GetMaterialApp:
getPages: [
  GetPage(
    name: AppRoutes.splash,
    page: () => const SplashScreen(),
    binding: SplashBinding(),
  ),
  GetPage(
    name: AppRoutes.onboarding,
    page: () => const OnboardingScreen(),
    binding: OnboardingBinding(),
  ),
  GetPage(
    name: AppRoutes.phoneLogin,
    page: () => const PhoneLoginScreen(),
  ),
  GetPage(
    name: AppRoutes.otpVerification,
    page: () => const OtpVerificationScreen(),
  ),
  GetPage(
    name: AppRoutes.profileSetup,
    page: () => const ProfileSetupScreen(),
    binding: ProfileSetupBinding(),
  ),
  GetPage(
    name: AppRoutes.driverRegistration,
    page: () => const DriverRegistrationScreen(),
    binding: DriverRegistrationBinding(),
  ),
  GetPage(
    name: AppRoutes.pendingApproval,
    page: () => const PendingApprovalScreen(),
  ),
]
```

---

## Arguments Contract

### Onboarding Arguments
```dart
// Passed via Get.arguments
// Type: String — identifies which app ('customer' | 'driver')
final String appType = Get.arguments as String;
```

### OTP Screen Arguments
```dart
// Passed via Get.arguments
// Type: Map<String, String>
final args = Get.arguments as Map<String, String>;
final phoneNumber = args['phoneNumber']!;     // E.164 format
final verificationId = args['verificationId']!; // Firebase verification ID
```
