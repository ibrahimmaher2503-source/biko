# Quickstart: Profile Auto-Fill, Theme Chooser, Debug Logging & Home Page

**Feature**: `006-profile-theme-home`
**Date**: 2026-03-01

## Prerequisites

- [x] Google Sign-In implemented (branch `005-google-sign-in`)
- [x] `shared_preferences` package in `pubspec.yaml`
- [x] `ProfileSetupController` and `ProfileSetupScreen` exist
- [x] `AppTheme.lightTheme` and `AppTheme.darkTheme` defined
- [x] `AppRoutes.customerHome` route constant defined
- [ ] Firebase Auth configured and working (for Google profile data)

## Files to Create

| File | Purpose |
|------|---------|
| `lib/core/widgets/app_snackbar.dart` | Centralized snackbar helper with debug logging |
| `lib/features/home/screens/customer_home_screen.dart` | Customer home page UI |
| `lib/features/home/controllers/home_controller.dart` | Home page state management |
| `lib/features/home/bindings/home_binding.dart` | Home page dependency injection |

## Files to Modify

| File | Change |
|------|--------|
| `lib/core/models/user_model.dart` | Add `theme` field |
| `lib/core/translations/app_translations.dart` | Add theme, home page, and snackbar strings |
| `lib/features/auth/controllers/profile_setup_controller.dart` | Add Google auto-fill in `onInit()`, add theme selection, persist theme |
| `lib/features/auth/screens/profile_setup_screen.dart` | Add theme selector UI |
| `lib/core/app_initializer.dart` | Load theme from SharedPreferences before `runApp()` |
| `lib/main_customer.dart` | Use restored `ThemeMode` instead of `ThemeMode.system` |
| `lib/core/routes/customer_pages.dart` | Add `customerHome` route with binding |
| All files calling `Get.snackbar()` | Replace with `AppSnackbar.show()` |

## Key Implementation Notes

1. **Google auto-fill**: `AuthService.currentUser?.displayName` and `AuthService.currentUser?.photoURL` are available after Google sign-in. Check these in `ProfileSetupController.onInit()`.

2. **Theme switching**: Use `Get.changeThemeMode(ThemeMode.dark)` for immediate effect. Store `'light'` or `'dark'` string in both SharedPreferences and Firestore.

3. **Debug snackbar**: Use `kDebugMode` from `flutter/foundation.dart` to gate console output. Tree-shaken in release builds.

4. **Home page**: Follow existing binding pattern (`Get.lazyPut<HomeController>()`). Map area is a placeholder — no Google Maps SDK needed yet.

## Testing Checklist

- [ ] Sign in with Google → profile name and avatar pre-filled
- [ ] Sign in with phone → profile name empty, avatar placeholder (no regression)
- [ ] Toggle theme on profile setup → immediate visual change
- [ ] Complete profile with Dark theme → restart app → Dark theme persists
- [ ] Trigger error snackbar → check debug console for message
- [ ] Build release mode → no snackbar prints in console
- [ ] Complete profile as customer → navigate to home page
- [ ] Home page shows user name, map placeholder, Ride/Delivery selector
- [ ] Test all above in Arabic RTL mode
