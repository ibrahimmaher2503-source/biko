# Navigation Contract: OTP Bypass Flow

**Branch**: `004-redesign-ui-skip-otp` | **Date**: 2026-03-01

---

## Normal Flow (OTP bypass OFF — `DevConfig.skipOtp = false`)

```
Splash → [onboarding_completed?]
  ├── NO  → Onboarding → PhoneLogin → [sendOtp] → OtpVerification → [verifyOtp]
  │                                                                       ↓
  │                                                              ProfileSetup → ...
  └── YES → [FirebaseAuth.currentUser?]
        ├── NULL → PhoneLogin → [sendOtp] → OtpVerification → [verifyOtp]
        │                                                          ↓
        │                                                 ProfileSetup → ...
        └── EXISTS → [profile complete?]
              ├── NO  → ProfileSetup → [driver?] → DriverRegistration → PendingApproval
              └── YES → [driver?]
                    ├── YES → [approved?]
                    │     ├── NO  → PendingApproval
                    │     └── YES → DriverHome
                    └── NO  → CustomerHome
```

## Bypass Flow (OTP bypass ON — `DevConfig.skipOtp = true`)

```
Splash → [onboarding_completed?]
  ├── NO  → Onboarding → PhoneLogin → [Continue tapped]
  │                                        ↓
  │                              (skip OTP, skip Firebase)
  │                                        ↓
  │                                   ProfileSetup → ...
  └── YES → [FirebaseAuth.currentUser?]
        ├── NULL → PhoneLogin → [Continue tapped]
        │                            ↓
        │                  (skip OTP, skip Firebase)
        │                            ↓
        │                       ProfileSetup → ...
        └── EXISTS → (same as normal flow — bypass doesn't interfere with existing sessions)
```

---

## Key Behavioral Changes

### SplashController._determineDestination()

| Step | Normal | Bypass |
|---|---|---|
| 1. Check onboarding | Same | Same |
| 2. Check FirebaseAuth.currentUser | Throws if Firebase not initialized | Check `DevConfig.skipOtp` — if true and user is null, return `phoneLogin` without Firebase dependency |
| 3. Fetch user profile | Same | Same (only reached if user exists) |
| 4. Driver approval check | Same | Same |

**Change**: Wrap the Firebase auth check:
```
if (DevConfig.skipOtp) {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) return AppRoutes.phoneLogin;
  // If user exists (real session), continue normal flow
}
```

### AuthController.sendOtp()

| Step | Normal | Bypass |
|---|---|---|
| 1. Validate phone | Same | Same (validates for realistic UX) |
| 2. Set state to sendingOtp | Same | Skip |
| 3. Call AuthService.sendOtp() | Firebase call | Skip entirely |
| 4. Navigate to OTP screen | Via _onCodeSent callback | Navigate directly to profileSetup |

**Change**: Early return at start of `sendOtp()`:
```
if (DevConfig.skipOtp) {
  if (!isValidEgyptianPhone(cleaned)) {
    errorMessage.value = 'error.invalid_phone'.tr;
    return;
  }
  phoneNumber.value = cleaned;
  Get.offAllNamed(AppRoutes.profileSetup);
  return;
}
```

### ProfileSetupController.completeProfile()

No changes needed. When OTP is bypassed, there is no Firebase user, so `AuthService.currentUser` will be null. The `completeProfile()` method should handle this gracefully — it can't write to Firestore without a user UID. For dev purposes, the profile setup screen will render and the user can test the UI, but the "Complete" action will need a mock UID or simply skip the Firestore write.

**Recommended approach**: In `completeProfile()`, check `DevConfig.skipOtp` — if true and no Firebase user exists, navigate to the next screen without persisting to Firestore (pure UI testing mode).

---

## Route Table (No Changes)

No new routes are added. The bypass uses existing routes with altered navigation paths.

| Route | Screen | Notes |
|---|---|---|
| `/splash` | SplashScreen | Modified: bypass-aware auth check |
| `/onboarding` | OnboardingScreen | No change |
| `/auth/phone` | PhoneLoginScreen | No change (calls AuthController.sendOtp) |
| `/auth/otp` | OtpVerificationScreen | Skipped when bypass enabled |
| `/auth/profile-setup` | ProfileSetupScreen | No change (destination of bypass) |
| `/driver/register` | DriverRegistrationScreen | No change |
| `/driver/pending` | PendingApprovalScreen | No change |
