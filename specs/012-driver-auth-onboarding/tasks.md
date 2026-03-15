# Tasks: Driver Authentication & Onboarding

**Input**: Design documents from `specs/012-driver-auth-onboarding/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md

**Tests**: Not explicitly requested in spec. Test tasks omitted.

**Organization**: Tasks are grouped by user story. Research revealed ~90% of the feature is already implemented. Tasks focus on the **3 identified gaps**: Facebook Sign-In (US2), onboarding persistence fix (US1), and Contact Support button (US5). User Stories 3 and 4 are already complete with no gaps — verified in research phase.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US5)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Add Facebook auth dependency, update shared enums and translations needed by multiple stories

- [X] T001 Add `flutter_facebook_auth` dependency to `pubspec.yaml` and run `flutter pub get`
- [X] T002 [P] Add `signingInWithFacebook` value to AuthState enum in `lib/core/models/enums.dart` — insert after `signingInWithGoogle`. Update `isLoading` getter in AuthController to include this state.
- [X] T003 [P] Add Facebook-specific translation keys to `lib/core/translations/app_translations.dart` — add `'error.facebook_sign_in_failed': 'فشل تسجيل الدخول بفيسبوك'` (AR) and `'error.facebook_sign_in_failed': 'Facebook sign-in failed'` (EN). Also add support contact translation keys: `'pending.support_message'` in AR and EN with template text "Hello, I submitted my driver application and need help. My ID: {uid}"

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Add Facebook auth method to shared AuthService — blocks US2 Facebook sign-in tasks

**Depends on**: Phase 1 (T001 for dependency, T002 for enum)

- [X] T004 Add `signInWithFacebook()` static method to `lib/core/services/auth_service.dart` — follow the existing `signInWithGoogle()` pattern exactly: call `FacebookAuth.instance.login(permissions: ['public_profile', 'email'])`, check for cancellation (return null), extract access token, create `FacebookAuthProvider.credential(accessToken)`, call `_auth.signInWithCredential(credential)`, return `UserCredential?`. Import `flutter_facebook_auth` at the top. Add `signOutFacebook()` that calls `FacebookAuth.instance.logOut()` and integrate it into the existing `signOut()` flow.

**Checkpoint**: Foundation ready — user story implementation can now begin in parallel

---

## Phase 3: User Story 1 — Driver Onboarding Introduction (Priority: P1) MVP

**Goal**: Fix onboarding "seen" persistence to be app-type-specific so driver and customer onboarding are tracked independently.

**Independent Test**: Launch driver app fresh → see onboarding. Complete it. Relaunch → onboarding skipped. Install customer app on same device → customer onboarding still shows (different key).

**Existing status**: Onboarding slides, screen, widgets, and navigation are 100% complete. Only the SharedPreferences key needs to be app-type-specific.

### Implementation for User Story 1

- [X] T005 [US1] Update `_completeOnboarding()` in `lib/features/onboarding/controllers/onboarding_controller.dart` — change the SharedPreferences key from `'onboarding_completed'` to `'onboarding_completed_$appType'` where `appType` is the string from `Get.arguments` (already passed as `'customer'` or `'driver'`). Store the appType in a field during `onInit()` for reuse.
- [X] T006 [US1] Update `_determineDestination()` in `lib/features/splash/controllers/splash_controller.dart` — change the SharedPreferences read from `'onboarding_completed'` to the app-type-specific key. Determine app type from the app's context: in driver app (`main_driver.dart`), pass `'driver'` as initial route argument; in customer app, pass `'customer'`. If no app type available, check both keys and default to showing onboarding if the driver-specific key is false.

**Checkpoint**: US1 is fully functional — driver onboarding tracked independently from customer

---

## Phase 4: User Story 2 — Driver Phone Authentication (Priority: P1)

**Goal**: Add Facebook Sign-In as a working alternative auth method alongside existing phone OTP and Google Sign-In.

**Independent Test**: Tap Facebook button on phone login screen → Facebook auth dialog opens → login succeeds → driver is authenticated and navigated to profile setup (new user) or home (returning user).

**Existing status**: Phone OTP and Google Sign-In are 100% complete. Facebook button exists in UI but shows "Coming Soon". OTP verification, timer, resend, post-auth navigation — all complete.

**Depends on**: Phase 2 (T004 for AuthService.signInWithFacebook)

### Implementation for User Story 2

- [X] T007 [US2] Add `signInWithFacebook()` method to `lib/features/auth/controllers/auth_controller.dart` — mirror the existing `signInWithGoogle()` method exactly: set `_authState.value = AuthState.signingInWithFacebook`, call `AuthService.signInWithFacebook()`, handle null return (user cancelled → reset to idle), call `_navigateAfterAuth()` on success, catch errors → reset to idle + set `errorMessage` + show `AppSnackbar.error('error.facebook_sign_in_failed'.tr)`. Also update `signOut()` to call `AuthService.signOutFacebook()`.
- [X] T008 [P] [US2] Wire Facebook button in `lib/features/auth/widgets/social_login_buttons.dart` — replace the `_showComingSoon()` callback on the Facebook button's `onTap` with `authController.signInWithFacebook()`. Add a loading state check: when `authController.authState == AuthState.signingInWithFacebook`, show a CircularProgressIndicator inside the Facebook button (same pattern as the Google button loading state). Disable both social buttons while either is loading.
- [X] T009 [P] [US2] Configure Android for Facebook SDK in `android/app/src/main/AndroidManifest.xml` — add inside `<application>` tag: `<meta-data android:name="com.facebook.sdk.ApplicationId" android:value="@string/facebook_app_id"/>`, `<meta-data android:name="com.facebook.sdk.ClientToken" android:value="@string/facebook_client_token"/>`. Add Facebook activity: `<activity android:name="com.facebook.FacebookActivity" android:configChanges="keyboard|keyboardHidden|screenLayout|screenSize|orientation" android:theme="@style/com_facebook_activity_theme"/>`. Create `android/app/src/main/res/values/strings.xml` with `facebook_app_id` and `facebook_client_token` placeholder values (to be filled with real values from Meta Developer Console).
- [X] T010 [P] [US2] Configure iOS for Facebook SDK in `ios/Runner/Info.plist` — add `CFBundleURLTypes` entry with `CFBundleURLSchemes` containing `fb{APP_ID}`. Add `FacebookAppID` key with placeholder value. Add `FacebookClientToken` key with placeholder value. Add `FacebookDisplayName` with "BikeRide". Add `fbapi`, `fb-messenger-share-api` to `LSApplicationQueriesSchemes` array.

**Checkpoint**: US2 is fully functional — drivers can authenticate via Phone OTP, Google, or Facebook

---

## User Story 3 — Driver Profile Setup (Priority: P1) — ALREADY COMPLETE

**Status**: Fully implemented in previous features. Profile setup screen (`lib/features/auth/screens/profile_setup_screen.dart`), controller (`lib/features/auth/controllers/profile_setup_controller.dart`), avatar upload, name validation, language toggle, theme toggle, and routing to driver registration — all working. No tasks required.

**Verified in**: research.md — Existing Code Coverage Matrix

---

## User Story 4 — Driver Vehicle & Document Registration (Priority: P1) — ALREADY COMPLETE

**Status**: Fully implemented in previous features. Driver registration screen (`lib/features/driver_registration/screens/driver_registration_screen.dart`), vehicle form, 4 document upload slots with checkmarks, step progress indicator, form validation, Firestore submission, status update to `pendingApproval` — all working. No tasks required.

**Verified in**: research.md — Existing Code Coverage Matrix

---

## Phase 5: User Story 5 — Application Pending Status (Priority: P2)

**Goal**: Make the "Contact Support" button functional on the pending approval screen, opening WhatsApp with a pre-filled support message.

**Independent Test**: Navigate to pending approval screen → tap "Contact Support" → WhatsApp opens with pre-filled message including driver context.

**Existing status**: Pending screen UI is complete — illustration, "Application Under Review" heading, status timeline, "Back to Home" link all work. Only "Contact Support" button has a TODO placeholder.

### Implementation for User Story 5

- [X] T011 [US5] Implement Contact Support button in `lib/features/driver_registration/screens/pending_approval_screen.dart` — replace the TODO/placeholder onTap of the "Contact Support" button with a method that: (1) gets the current user UID from `AuthService.currentUser?.uid`, (2) constructs a WhatsApp URL: `https://wa.me/+20XXXXXXXXXX?text={encoded_message}` using the `'pending.support_message'.tr` translation key with UID interpolated, (3) calls `launchUrl(Uri.parse(url))` from `url_launcher` package, (4) wraps in try-catch — if WhatsApp is not installed, fall back to `launchUrl(Uri.parse('mailto:support@bikeride.eg?subject=Driver Application - $uid'))`. Import `url_launcher` at the top.

**Checkpoint**: US5 is fully functional — pending drivers can contact support via WhatsApp

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Verify the complete driver flow end-to-end and ensure RTL/localization compliance

- [X] T012 Run `flutter analyze` to verify no static analysis warnings or errors across all modified files
- [ ] T013 Verify full driver app flow end-to-end: launch `main_driver.dart` → splash → onboarding (3 slides, skip, get started) → phone login → OTP → profile setup → driver registration → pending approval. Confirm all navigation paths work correctly.
- [ ] T014 [P] Verify all modified screens render correctly in Arabic (RTL) — switch language to Arabic and confirm: onboarding slides flip direction, phone input maintains +20 prefix on right side, social login buttons layout correctly, pending screen timeline reads right-to-left, Contact Support button text is Arabic
- [ ] T015 [P] Verify Facebook auth error states — confirm loading spinner shows during Facebook login, error snackbar appears on failure, cancellation returns to idle state gracefully, both Google and Facebook buttons disable while either is loading

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 (T001 for package, T002 for enum)
- **US1 (Phase 3)**: Depends on Phase 1 only — independent of Facebook auth work
- **US2 (Phase 4)**: Depends on Phase 2 (T004 for AuthService method)
- **US5 (Phase 5)**: Depends on Phase 1 only (T003 for translation keys) — independent of Facebook auth
- **Polish (Phase 6)**: Depends on all story phases being complete

### User Story Independence

- **US1 (Onboarding persistence)**: Fully independent — touches only onboarding and splash controllers
- **US2 (Facebook sign-in)**: Depends on foundational AuthService method — touches only auth files
- **US5 (Contact Support)**: Fully independent — touches only pending approval screen
- **US3 and US4**: Already complete — no work needed

### Within Each User Story

- T005 before T006 (onboarding controller saves key before splash reads it)
- T007 before T008 (controller method before widget wiring)
- T009 and T010 can run in parallel (different platforms)

### Parallel Opportunities

```
Phase 1 (parallel):
  T002 (enum update) || T003 (translations)  — different files

Phase 3 + Phase 5 (parallel after Phase 1):
  T005-T006 (US1 onboarding) || T011 (US5 contact support)  — different features

Phase 4 (parallel within):
  T008 (widget) || T009 (Android config) || T010 (iOS config)  — different files
  (all depend on T007 for controller method)

Phase 6 (parallel):
  T014 (RTL check) || T015 (Facebook error states)  — different verification areas
```

---

## Implementation Strategy

### MVP First (US1 — Onboarding Persistence Fix)

1. Complete Phase 1: Setup (T001–T003)
2. Complete Phase 3: US1 (T005–T006)
3. **VALIDATE**: Driver onboarding tracked independently from customer
4. The entire existing flow (splash → onboarding → auth → profile → registration → pending) already works

### Incremental Delivery

1. Setup + US1 → Onboarding persistence fixed (MVP — full flow already works)
2. Foundational + US2 → Facebook sign-in enabled (major feature addition)
3. US5 → Contact Support functional (quick win)
4. Polish → End-to-end verification

### Task Summary

| Phase | Story | Tasks | Effort |
|-------|-------|-------|--------|
| Phase 1: Setup | — | T001–T003 | Low |
| Phase 2: Foundational | — | T004 | Medium |
| Phase 3: US1 | Onboarding persistence | T005–T006 | Low |
| Phase 4: US2 | Facebook sign-in | T007–T010 | Medium |
| Phase 5: US5 | Contact Support | T011 | Low |
| Phase 6: Polish | — | T012–T015 | Low |
| **Total** | | **15 tasks** | |

---

## Notes

- US3 (Profile Setup) and US4 (Registration) are fully implemented — verified in research.md code audit
- Facebook App ID and Client Token are placeholder values — real values require manual Meta Developer Console setup
- The `url_launcher` package was added to `pubspec.yaml` during implementation for Contact Support
- All existing screens already match the stitch designs closely — no UI refactoring tasks needed
- The `DevConfig.skipOtp` bypass continues to work for development without Firebase
