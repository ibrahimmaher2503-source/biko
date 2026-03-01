# Tasks: Google Sign-In

**Input**: Design documents from `/specs/005-google-sign-in/`
**Prerequisites**: plan.md (required), spec.md (required), data-model.md, research.md, quickstart.md

**Tests**: Not requested in feature specification. Test tasks omitted.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Phase 1: Setup

**Purpose**: Add Google Sign-In dependency and configure the project

- [x] T001 Add `google_sign_in` package dependency to `pubspec.yaml` and run `flutter pub get`

**Note**: Developer must also manually complete these Firebase Console steps before testing:
1. Enable Google Sign-In provider in Firebase Console > Authentication > Sign-in method
2. Add SHA-1 fingerprint for Android (`cd android && ./gradlew signingReport`)
3. Add reversed client ID URL scheme in `ios/Runner/Info.plist` for iOS

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Model updates and translation strings that all user stories depend on

- [x] T002 [P] Add `signingInWithGoogle` value to `AuthState` enum in `lib/core/models/enums.dart`
- [x] T003 [P] Add `email` (String?) and `authProviders` (List\<String\>) fields to `UserModel` in `lib/core/models/user_model.dart` — update constructor, `fromJson`, `toJson`, and `copyWith`
- [x] T004 [P] Add Google sign-in translation strings to `lib/core/translations/app_translations.dart` — add `error.google_sign_in_failed` in both Arabic and English sections

**Checkpoint**: Foundation ready — models and translations in place for user story implementation

---

## Phase 3: User Story 1 + 2 — Sign in with Google & Returning User Navigation (Priority: P1) MVP

**Goal**: Replace the "Coming Soon" Google button with a functional sign-in flow. New users go to profile setup, returning users go to home, pending drivers go to pending approval.

**Independent Test**: Tap the Google button on the login screen, complete Google account selection, and verify correct navigation. Cancel the picker and verify no error. Sign in again as returning user and verify direct navigation to home.

**Why combined**: US2 (returning user navigation) is inherently fulfilled by the existing `_navigateAfterAuth()` logic when US1's `signInWithGoogle()` calls it. They share the same code path and cannot be independently implemented.

### Implementation

- [x] T005 [US1] Add `signInWithGoogle()` static method to `AuthService` in `lib/core/services/auth_service.dart` — use `GoogleSignIn().signIn()` to get Google account, create `GoogleAuthProvider.credential()` from idToken/accessToken, call `FirebaseAuth.signInWithCredential()`, return `UserCredential?` (null if user cancelled)
- [x] T006 [P] [US1] Add `signOutGoogle()` static method to `AuthService` in `lib/core/services/auth_service.dart` — call `GoogleSignIn().signOut()` then `FirebaseAuth.signOut()`
- [x] T007 [US1] Add `signInWithGoogle()` method to `AuthController` in `lib/features/auth/controllers/auth_controller.dart` — set state to `signingInWithGoogle`, call `AuthService.signInWithGoogle()`, handle null (cancelled → reset to idle), handle success (set authenticated → call `_navigateAfterAuth()`), handle error (set error state with localized message)
- [x] T008 [US1] Update `isLoading` getter in `AuthController` in `lib/features/auth/controllers/auth_controller.dart` — add `_authState.value == AuthState.signingInWithGoogle` to the condition
- [x] T009 [US1] Update `signOut()` method in `AuthController` in `lib/features/auth/controllers/auth_controller.dart` — call `AuthService.signOutGoogle()` instead of `AuthService.signOut()` to ensure Google session is also cleared
- [x] T010 [US1] Wire Google button to `AuthController.signInWithGoogle()` in `lib/features/auth/widgets/social_login_buttons.dart` — replace `_showComingSoon()` call for Google button with `Get.find<AuthController>().signInWithGoogle()`, add `Obx` wrapper to show loading indicator when `authState == signingInWithGoogle`, keep Facebook button unchanged with `_showComingSoon()`

**Checkpoint**: Google sign-in works end-to-end. New users reach profile setup. Returning users reach home. Cancelled sign-in returns to login. Facebook button still shows "Coming Soon".

---

## Phase 4: User Story 3 — Error Handling (Priority: P2)

**Goal**: Ensure all Google sign-in failures show clear, localized error messages and the user can retry or fall back to phone authentication.

**Independent Test**: Simulate network failure or sign-in error, verify localized error message appears, verify Google button is re-enabled, verify phone OTP flow still works normally.

### Implementation

- [x] T011 [US3] Add error state reset logic to `signInWithGoogle()` in `lib/features/auth/controllers/auth_controller.dart` — ensure `errorMessage` is cleared before attempt, ensure state resets to `idle` (not `error`) after displaying error so the user can retry, ensure phone OTP controls remain functional after a Google sign-in failure
- [x] T012 [US3] Add error display for Google sign-in in `lib/features/auth/widgets/social_login_buttons.dart` — show error snackbar using `errorMessage` from `AuthController` when Google sign-in fails, ensure Google button returns to tappable state after error

**Checkpoint**: All error scenarios handled. User sees localized errors and can retry Google or switch to phone OTP.

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Final verification and cleanup

- [ ] T013 Verify phone OTP flow is unaffected — test full phone OTP login flow to ensure no regressions in `lib/features/auth/controllers/auth_controller.dart`
- [ ] T014 Verify RTL layout — test Google sign-in button and error messages render correctly in Arabic RTL mode in `lib/features/auth/widgets/social_login_buttons.dart`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 (`google_sign_in` package must be installed)
- **US1 + US2 (Phase 3)**: Depends on Phase 2 (models and translations must exist)
- **US3 (Phase 4)**: Depends on Phase 3 (error handling builds on core sign-in flow)
- **Polish (Phase 5)**: Depends on Phase 4 (all functionality must be complete)

### Within Phase Task Dependencies

- **Phase 2**: T002, T003, T004 are all [P] — can run in parallel (different files)
- **Phase 3**: T005 must complete before T007. T006 can run in parallel with T005. T007 must complete before T008, T009. T010 depends on T007 being complete.
- **Phase 4**: T011 before T012
- **Phase 5**: T013 and T014 can run in parallel

### Parallel Opportunities

```text
# Phase 2 — all three in parallel (different files):
T002: enums.dart
T003: user_model.dart
T004: app_translations.dart

# Phase 3 — T005 and T006 in parallel (same file but independent methods):
T005: AuthService.signInWithGoogle()
T006: AuthService.signOutGoogle()

# Phase 5 — both in parallel:
T013: Phone OTP regression test
T014: RTL layout verification
```

---

## Implementation Strategy

### MVP First (User Story 1 + 2)

1. Complete Phase 1: Setup (1 task)
2. Complete Phase 2: Foundational (3 tasks, parallelizable)
3. Complete Phase 3: US1 + US2 (6 tasks)
4. **STOP and VALIDATE**: Test Google sign-in end-to-end
5. Deploy/demo if ready — Google sign-in is functional

### Full Delivery

1. Complete MVP (Phases 1-3)
2. Complete Phase 4: US3 — Error handling (2 tasks)
3. Complete Phase 5: Polish (2 tasks)
4. All 14 tasks complete — feature is production-ready

---

## Notes

- Total: **14 tasks** across 5 phases
- US1 + US2 (P1): 6 implementation tasks — combined because they share the same code path
- US3 (P2): 2 implementation tasks — error handling refinement
- Setup/Foundational: 4 tasks
- Polish: 2 tasks
- No new files created — all modifications to existing files
- Key file touch count: `auth_controller.dart` (4 tasks), `auth_service.dart` (2 tasks), `social_login_buttons.dart` (2 tasks)
