# Research: Google Sign-In

**Feature**: 005-google-sign-in
**Date**: 2026-03-01

## R-001: Flutter Google Sign-In Package

**Decision**: Use `google_sign_in` package (official Flutter plugin by Google)

**Rationale**: This is the official, maintained Flutter plugin for Google Sign-In. It works seamlessly with `firebase_auth` — the credential from `google_sign_in` is passed directly to `FirebaseAuth.signInWithCredential()`. The project already uses `firebase_auth: ^5.0.0`.

**Alternatives considered**:
- Manual OAuth2 flow via WebView: Too complex, poor UX, reinvents the wheel
- `flutter_appauth`: Designed for generic OAuth2, overkill when using Firebase

## R-002: Firebase Auth Google Provider Integration

**Decision**: Use `GoogleAuthProvider.credential()` to create a Firebase credential from Google Sign-In tokens, then call `FirebaseAuth.signInWithCredential()`

**Rationale**: This is the standard Firebase-recommended pattern. It reuses the existing `_navigateAfterAuth()` flow in AuthController since both phone and Google auth produce a `UserCredential`.

**Flow**:
1. `GoogleSignIn().signIn()` → Google account picker
2. Get `GoogleSignInAuthentication` (idToken + accessToken)
3. Create `GoogleAuthProvider.credential(idToken, accessToken)`
4. Call `FirebaseAuth.signInWithCredential(credential)` → `UserCredential`
5. Check Firestore for existing user → navigate accordingly

## R-003: Android Configuration

**Decision**: SHA-1 fingerprint must be added to Firebase Console (manual step by developer)

**Rationale**: Google Sign-In on Android requires the app's SHA-1 signing key registered in the Firebase project. This is a Firebase Console configuration step, not a code change. The `google-services.json` file is already present in the project.

**Steps**:
1. Run `./gradlew signingReport` in `android/` to get debug SHA-1
2. Add SHA-1 fingerprint in Firebase Console > Project Settings > Android app
3. Re-download `google-services.json` (or it auto-updates via FlutterFire)
4. Enable Google Sign-In provider in Firebase Console > Authentication > Sign-in method

## R-004: iOS Configuration

**Decision**: Add reversed client ID as URL scheme in `ios/Runner/Info.plist`

**Rationale**: Required by the Google Sign-In SDK on iOS to handle the OAuth redirect callback.

**Steps**:
1. Open `GoogleService-Info.plist` and find `REVERSED_CLIENT_ID`
2. Add it as a URL scheme in `Info.plist` under `CFBundleURLTypes`
3. Enable Google Sign-In provider in Firebase Console (shared with Android)

## R-005: Account Linking Strategy

**Decision**: Handle `account-exists-with-different-credential` error by attempting to link providers

**Rationale**: When a user signs in with Google but already has a phone-authenticated account with the same email, Firebase throws this error. The solution is to:
1. Catch the error
2. Sign in with the existing provider first
3. Link the Google credential to the existing account

**However**: In BikeRide's case, phone auth users don't have an email on file (phone-only). So this conflict is unlikely unless the user manually set an email. For the MVP, we'll handle the error gracefully with an error message and document account linking as a future enhancement if needed.

**Simpler approach for MVP**: Let Firebase handle it — if Google email doesn't conflict, create new user. If it does, Firebase will merge automatically when the same UID is used.

## R-006: UserModel Extension

**Decision**: Add optional `email` and `authProviders` fields to `UserModel`

**Rationale**: Google sign-in provides an email and display name. The `email` field captures this. The `authProviders` list tracks which auth methods a user has used (useful for profile display and future account management).

**Impact**: Backward compatible — both fields are optional with null/empty defaults. Existing phone-only users won't be affected.

## R-007: Loading State for Google Sign-In

**Decision**: Add `signingInWithGoogle` value to `AuthState` enum

**Rationale**: The Google sign-in flow is a separate state from `sendingOtp` and `verifying`. The UI needs to show a loading indicator specifically on the Google button while keeping the phone input and continue button in their normal state.

## R-008: Web Support

**Decision**: Web requires a Google client ID configured in `index.html` meta tag

**Rationale**: For Flutter Web, Google Sign-In needs the web client ID from Firebase Console added as a meta tag. However, since the customer and driver apps are mobile-only (Admin panel is web but doesn't use Google Sign-In per spec), this is lower priority. Include it for completeness since FlutterFire already configured a web app.
