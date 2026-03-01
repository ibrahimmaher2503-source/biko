# Quickstart: Google Sign-In

**Feature**: 005-google-sign-in
**Date**: 2026-03-01

## Prerequisites

Before implementing, complete these manual setup steps:

### 1. Firebase Console Configuration
- Go to Firebase Console > Authentication > Sign-in method
- Enable **Google** as a sign-in provider
- Note the Web client ID (needed for Android and Web)

### 2. Android SHA-1 Fingerprint
```bash
cd android
./gradlew signingReport
```
- Copy the SHA-1 from the debug variant
- Add it in Firebase Console > Project Settings > Your Android app > Add fingerprint
- Re-download `google-services.json` if needed

### 3. iOS URL Scheme
- Open `ios/Runner/GoogleService-Info.plist`
- Find the `REVERSED_CLIENT_ID` value
- Add it as a URL scheme in `ios/Runner/Info.plist`:
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>YOUR_REVERSED_CLIENT_ID</string>
    </array>
  </dict>
</array>
```

### 4. Install Package
```bash
flutter pub add google_sign_in
```

## Implementation Order

1. **Add dependency**: `google_sign_in` to `pubspec.yaml`
2. **Update AuthState enum**: Add `signingInWithGoogle`
3. **Update UserModel**: Add `email` and `authProviders` fields
4. **Update AuthService**: Add `signInWithGoogle()` and `signOutGoogle()` methods
5. **Update AuthController**: Add `signInWithGoogle()` method using same `_navigateAfterAuth()` flow
6. **Update SocialLoginButtons**: Replace `_showComingSoon()` with `AuthController.signInWithGoogle()`
7. **Add translations**: Google sign-in error strings in Arabic and English
8. **Update FirestoreService**: Handle user creation for Google-authenticated users (set email, authProviders)

## Key Files to Modify

| File | Change |
|------|--------|
| `pubspec.yaml` | Add `google_sign_in` dependency |
| `lib/core/models/enums.dart` | Add `signingInWithGoogle` to `AuthState` |
| `lib/core/models/user_model.dart` | Add `email`, `authProviders` fields |
| `lib/core/services/auth_service.dart` | Add `signInWithGoogle()`, `signOutGoogle()` |
| `lib/features/auth/controllers/auth_controller.dart` | Add `signInWithGoogle()`, update `signOut()` |
| `lib/features/auth/widgets/social_login_buttons.dart` | Wire Google button to controller |
| `lib/core/translations/app_translations.dart` | Add Google sign-in error strings |

## Testing Checklist

- [ ] Tap Google button → Google account picker appears
- [ ] Select account → authenticated → correct navigation
- [ ] Cancel picker → no error, stays on login screen
- [ ] New Google user → goes to profile setup
- [ ] Returning Google user → goes to home
- [ ] Sign out → clears Google session
- [ ] Error handling → localized error message shown
- [ ] Phone OTP flow still works unchanged
- [ ] Facebook button still shows "Coming Soon"
