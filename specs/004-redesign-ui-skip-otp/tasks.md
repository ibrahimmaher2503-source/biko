# Tasks: Redesign Screen UIs with Theme Compliance & Skip OTP

**Input**: Design documents from `/specs/004-redesign-ui-skip-otp/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/navigation.md, quickstart.md

**Tests**: Not requested — no test tasks generated.

**Organization**: Tasks are grouped by user story. US2 (theme extension) is implemented before US1 (screen redesign) because US1 depends on the semantic colors US2 provides.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Phase 1: Setup

**Purpose**: Create dev configuration and clean up duplicate constants

- [x] T001 Create DevConfig class with `skipOtp = true` flag in `lib/core/constants/dev_config.dart`. Single static class with `static const bool skipOtp = true`. See research R-004.
- [x] T002 Remove duplicate border radius constants (`radiusDefault`, `radiusLarge`, `radiusXl`, `radiusFull`) from `lib/core/constants/app_constants.dart`. These are already defined in `AppTheme` and `AppTheme` is the canonical source. See research R-007.

---

## Phase 2: US2 — Extended Theme System for Missing Semantic Colors (Priority: P2)

**Goal**: Extend AppTheme with `AppColorsExtension` ThemeExtension so all semantic colors (surfaces, borders, info/success/warning states) are available from the theme and adapt to light/dark mode automatically.

**Independent Test**: Search `lib/core/theme/app_theme.dart` for `AppColorsExtension`. Verify it has 12 color properties. Verify it is registered on both `lightTheme` and `darkTheme`. Access `Theme.of(context).extension<AppColorsExtension>()` — it should return non-null in both modes.

### Implementation for US2

- [x] T003 [US2] Create `AppColorsExtension` class extending `ThemeExtension<AppColorsExtension>` in `lib/core/theme/app_theme.dart`. Include 12 properties: `surfaceElevated`, `surfaceContainer`, `border`, `borderSubtle`, `textMuted`, `info`, `infoBg`, `infoBorder`, `success`, `successBg`, `warning`, `warningBg`. Implement required `copyWith()` and `lerp()` methods. See data-model.md for exact light/dark values.
- [x] T004 [US2] Register `AppColorsExtension` on both `lightTheme` and `darkTheme` in `lib/core/theme/app_theme.dart`. Add `extensions: <ThemeExtension<dynamic>>[AppColorsExtension(...)]` to both ThemeData instances with the correct light and dark color values from data-model.md.
- [x] T005 [P] [US2] Enhance `AppButton` — change `ButtonVariant.primary` from `ElevatedButton` to `FilledButton` in `lib/core/widgets/app_button.dart`. In the `_buildButton` method, replace the `ButtonVariant.primary` case to use `FilledButton(onPressed: ..., child: content)` instead of `ElevatedButton`. Also add `FilledButton` theme data to both `lightTheme` and `darkTheme` in `lib/core/theme/app_theme.dart` (primary background, white text, radiusXl, 56dp height). See research R-002.

**Checkpoint**: Theme extension is available. `AppButton` primary uses `FilledButton`. All screens can now access semantic colors and use `AppButton`.

---

## Phase 3: US1 — Consistent Theme-Based Screen UI (Priority: P1) — MVP

**Goal**: Every screen uses `AppButton` for buttons, `AppTextField` for text fields, theme colors (via `AppColorsExtension` and `colorScheme`) for all non-brand colors, and `AppTheme` radius constants for all border radius values. No hardcoded `Color(0x...)`, no bare `FilledButton`/`TextButton`/`OutlinedButton`, no bare `TextField`, no hardcoded `BorderRadius.circular(N)`.

**Independent Test**: Open each of the 7 screens in both light and dark mode. Verify buttons look identical (same height, radius, color). Toggle to Arabic and verify fonts switch and layouts mirror. Run `grep -rn "Color(0x" lib/features/` — only Google/Facebook brand colors should appear. Run `grep -rn "BorderRadius.circular" lib/features/` — should find zero results. Run `grep -rn "FilledButton\|ElevatedButton\|OutlinedButton" lib/features/ --include="*_screen.dart"` — should find zero results.

### Widgets (fix shared widgets first — all parallelizable)

- [x] T006 [P] [US1] Replace hardcoded colors in `PageIndicator` — replace `Color(0xFF334155)` and `Color(0xFFE2E8F0)` with `AppColorsExtension.border` / `.borderSubtle`, replace hardcoded `BorderRadius.circular(4)` with `BorderRadius.circular(AppTheme.radiusDefault / 2)` in `lib/features/onboarding/widgets/page_indicator.dart`
- [x] T007 [P] [US1] Replace hardcoded colors in `PhoneInputField` — replace `Color(0xFF1E293B)` / `Colors.white` background with `ext.surfaceContainer` / `ext.surfaceElevated`, replace `Color(0xFF334155)` / `Color(0xFFE2E8F0)` borders with `ext.border`, replace `BorderRadius.circular(12)` with `BorderRadius.circular(AppTheme.radiusLarge)` in `lib/features/auth/widgets/phone_input_field.dart`
- [x] T008 [P] [US1] Replace hardcoded colors in `OtpInputField` — replace `Color(0xFF1E293B)` / `Colors.white` background with `ext.surfaceContainer` / `ext.surfaceElevated`, replace `Color(0xFF334155)` / `Color(0xFFE2E8F0)` borders with `ext.border`, replace all three `BorderRadius.circular(12)` with `BorderRadius.circular(AppTheme.radiusLarge)` in `lib/features/auth/widgets/otp_input_field.dart`
- [x] T009 [P] [US1] Replace hardcoded border colors in `SocialLoginButtons` — replace `Color(0xFF334155)` / `Color(0xFFE2E8F0)` border with `ext.border`, replace `BorderRadius.circular(12)` with `BorderRadius.circular(AppTheme.radiusLarge)`. KEEP brand colors `Color(0xFFDB4437)` (Google) and `Color(0xFF1877F2)` (Facebook) as-is in `lib/features/auth/widgets/social_login_buttons.dart`
- [x] T010 [P] [US1] Replace hardcoded colors in `DocumentUploadItem` — replace `Color(0xFFF8F5F6)` / `Colors.white.withValues(alpha: 0.05)` bg with `ext.surfaceContainer`, replace `Color(0xFFF1F5F9)` / border colors with `ext.border`, replace `Color(0xFFDCFCE7)` with `ext.successBg`, replace `Color(0xFF16A34A)` with `ext.success`, replace all `BorderRadius.circular(12)` with `BorderRadius.circular(AppTheme.radiusLarge)` in `lib/features/driver_registration/widgets/document_upload_item.dart`
- [x] T011 [P] [US1] Replace hardcoded radius in `StepProgressIndicator` — replace `BorderRadius.circular(3)` with `BorderRadius.circular(AppTheme.radiusDefault / 2)` in `lib/features/driver_registration/widgets/step_progress_indicator.dart`

### Screens (all parallelizable — each is a different file)

- [x] T012 [P] [US1] Redesign `SplashScreen` — replace bare `FilledButton.icon` with `AppButton` (variant: primary, leadingIcon: refresh). No hardcoded colors to fix (already uses theme). In `lib/features/splash/screens/splash_screen.dart`
- [x] T013 [P] [US1] Redesign `OnboardingScreen` — replace bare `TextButton` (skip) with `AppButton` (variant: text), replace bare `FilledButton` (next/get started) with `AppButton` (variant: primary, trailingIcon: arrow_forward). Replace `BorderRadius.circular(12)` with `BorderRadius.circular(AppTheme.radiusLarge)`. Replace hardcoded `TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)` with theme typography. In `lib/features/onboarding/screens/onboarding_screen.dart`
- [x] T014 [P] [US1] Redesign `PhoneLoginScreen` — replace bare `FilledButton` (continue) with `AppButton` (variant: primary, trailingIcon: arrow_forward, isLoading support). Replace hardcoded `Colors.white` TextStyles with `colorScheme.onPrimary`. Replace `BorderRadius.circular(12)` with `BorderRadius.circular(AppTheme.radiusLarge)`. In `lib/features/auth/screens/phone_login_screen.dart`
- [x] T015 [P] [US1] Redesign `OtpVerificationScreen` — replace bare `FilledButton` (verify) with `AppButton` (variant: primary, trailingIcon), replace bare `TextButton` (resend) with `AppButton` (variant: text). Replace `BorderRadius.circular(20)` with `BorderRadius.circular(AppTheme.radiusFull)`, replace `BorderRadius.circular(12)` with `BorderRadius.circular(AppTheme.radiusLarge)`. Replace hardcoded button TextStyles with theme typography. In `lib/features/auth/screens/otp_verification_screen.dart`
- [x] T016 [P] [US1] Redesign `ProfileSetupScreen` — replace bare `TextField` (name) with `AppTextField`, replace bare `FilledButton` (complete) with `AppButton` (variant: primary, trailingIcon). Replace `Color(0xFF1E293B)` / `Color(0xFF334155)` / `Color(0xFFE2E8F0)` / `Color(0xFFF1F5F9)` with `AppColorsExtension` colors. Replace all four `BorderRadius.circular(12/16)` with `AppTheme.radiusLarge` / `AppTheme.radiusXl`. In `lib/features/auth/screens/profile_setup_screen.dart`
- [x] T017 [P] [US1] Redesign `DriverRegistrationScreen` — replace both bare `TextField` widgets (motorcycle model, plate number) with `AppTextField`, replace bare `FilledButton` (submit) with `AppButton`. Replace `Color(0xFFF8F5F6)` / border colors with `AppColorsExtension` colors. Replace info tip colors (`Color(0xFFEFF6FF)`, `Color(0xFFDBEAFE)`, `Color(0xFF2563EB)`, `Color(0xFF1E3A5F)`) with `ext.infoBg`, `ext.infoBorder`, `ext.info`. Replace all six `BorderRadius.circular(8/12)` with `AppTheme` constants. In `lib/features/driver_registration/screens/driver_registration_screen.dart`
- [x] T018 [P] [US1] Redesign `PendingApprovalScreen` — replace bare `FilledButton` (contact support) with `AppButton` (variant: primary), replace bare `TextButton` (back home) with `AppButton` (variant: text). Replace `Color(0xFF1E293B)` / `Color(0xFF334155)` / `Color(0xFFF1F5F9)` with `AppColorsExtension` colors. Replace both `BorderRadius.circular(12)` with `BorderRadius.circular(AppTheme.radiusLarge)`. In `lib/features/driver_registration/screens/pending_approval_screen.dart`

**Checkpoint**: All 7 screens and 7 widgets use theme-only colors, AppButton, AppTextField, and AppTheme radius constants. US1 is fully functional and testable.

---

## Phase 4: US3 — Skip OTP Verification for Development (Priority: P1)

**Goal**: When `DevConfig.skipOtp` is `true`, tapping "Continue" on the phone login screen skips the OTP verification screen entirely and navigates directly to profile setup. No Firebase Auth calls are made. The real OTP code remains intact.

**Independent Test**: Run the app with `DevConfig.skipOtp = true`. Enter any valid Egyptian phone number. Tap Continue. App should navigate directly to profile setup — no OTP screen, no Firebase errors. Then set `skipOtp = false` — the real OTP flow should work unchanged.

### Implementation for US3

- [x] T019 [US3] Add OTP bypass guard in `AuthController.sendOtp()` — at the start of `sendOtp()`, check `DevConfig.skipOtp`. If true: validate phone with `isValidEgyptianPhone()`, set `phoneNumber.value`, navigate to `AppRoutes.profileSetup` via `Get.offAllNamed()`, and return early. Real OTP code remains untouched below the guard. See contracts/navigation.md for exact flow. In `lib/features/auth/controllers/auth_controller.dart`
- [x] T020 [US3] Add OTP bypass check in `SplashController._determineDestination()` — when `DevConfig.skipOtp` is true and `FirebaseAuth.instance.currentUser` is null, return `AppRoutes.phoneLogin` directly without letting Firebase auth check throw. The existing `currentUser == null` path already returns `phoneLogin`, but wrap the Firebase access in a try-catch or conditional to prevent crashes when Firebase is not configured. See contracts/navigation.md. In `lib/features/splash/controllers/splash_controller.dart`

**Checkpoint**: OTP bypass works end-to-end. Full app flow navigable without Firebase: splash → onboarding → phone login → profile setup.

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Verify all success criteria, fix any remaining issues

- [x] T021 Run `flutter analyze` and fix any new errors or warnings introduced by the redesign. Target: zero new errors (SC-009). In project root.
- [x] T022 Run hardcoded value search across `lib/features/` to verify: zero `Color(0x` except brand colors (SC-001), zero bare `FilledButton`/`ElevatedButton`/`OutlinedButton`/`TextButton` in screen files (SC-002), zero bare `TextField` in screen files (SC-003), zero `BorderRadius.circular` in feature files (SC-004). Fix any remaining violations.
- [x] T023 Verify dark mode rendering — launch app in dark mode, navigate all 7 screens, confirm no light-mode artifacts (white backgrounds, invisible text, wrong borders) per SC-005.
- [x] T024 Verify RTL rendering — switch to Arabic, navigate all 7 screens, confirm Cairo font, layout mirroring, and icon flipping per SC-006.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **US2 (Phase 2)**: Depends on Phase 1 (T001 for DevConfig, T002 for clean radius). BLOCKS US1.
- **US1 (Phase 3)**: Depends on Phase 2 completion (needs AppColorsExtension and enhanced AppButton)
- **US3 (Phase 4)**: Depends on Phase 1 (needs DevConfig.skipOtp). Can run in parallel with US1.
- **Polish (Phase 5)**: Depends on Phases 3 and 4 completion

### User Story Dependencies

- **US2 (P2)**: Foundation — must complete first. Creates theme extension used by US1.
- **US1 (P1)**: Depends on US2. Main body of work — 7 screens + 6 widgets.
- **US3 (P1)**: Independent of US1/US2. Only depends on DevConfig (Phase 1).

### Within US1 (Phase 3)

- Widgets (T006-T011) should complete before screens (T012-T018) because screens import these widgets
- All widget tasks [P] can run in parallel (different files)
- All screen tasks [P] can run in parallel (different files)

### Parallel Opportunities

- T001 and T002 can run in parallel (different files)
- T003/T004 and T005 can run in parallel (T005 touches app_button.dart, T003/T004 touch app_theme.dart)
- T006-T011 (all 6 widget fixes) can run in parallel
- T012-T018 (all 7 screen fixes) can run in parallel
- T019 and T020 can run in parallel (different controllers)
- US3 (Phase 4) can run in parallel with US1 (Phase 3) since they touch different files

---

## Parallel Example: US1 Widget Fixes

```
# Launch all widget fixes together (6 parallel tasks):
T006: PageIndicator in lib/features/onboarding/widgets/page_indicator.dart
T007: PhoneInputField in lib/features/auth/widgets/phone_input_field.dart
T008: OtpInputField in lib/features/auth/widgets/otp_input_field.dart
T009: SocialLoginButtons in lib/features/auth/widgets/social_login_buttons.dart
T010: DocumentUploadItem in lib/features/driver_registration/widgets/document_upload_item.dart
T011: StepProgressIndicator in lib/features/driver_registration/widgets/step_progress_indicator.dart
```

## Parallel Example: US1 Screen Fixes

```
# Launch all screen fixes together (7 parallel tasks):
T012: SplashScreen in lib/features/splash/screens/splash_screen.dart
T013: OnboardingScreen in lib/features/onboarding/screens/onboarding_screen.dart
T014: PhoneLoginScreen in lib/features/auth/screens/phone_login_screen.dart
T015: OtpVerificationScreen in lib/features/auth/screens/otp_verification_screen.dart
T016: ProfileSetupScreen in lib/features/auth/screens/profile_setup_screen.dart
T017: DriverRegistrationScreen in lib/features/driver_registration/screens/driver_registration_screen.dart
T018: PendingApprovalScreen in lib/features/driver_registration/screens/pending_approval_screen.dart
```

---

## Implementation Strategy

### MVP First (US2 + US3 — Theme Extension + OTP Bypass)

1. Complete Phase 1: Setup (T001-T002)
2. Complete Phase 2: US2 — Theme Extension (T003-T005)
3. Complete Phase 4: US3 — OTP Bypass (T019-T020)
4. **STOP and VALIDATE**: App navigable without Firebase, theme extension accessible
5. Proceed to US1 screen redesign

### Incremental Delivery

1. Setup + US2 → Theme system ready, AppButton enhanced
2. Add US3 → App navigable without Firebase (dev unblocked)
3. Add US1 widgets → Shared widgets theme-compliant
4. Add US1 screens → All screens theme-compliant
5. Polish → Full verification of all 9 success criteria

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- US2 is P2 in the spec but must be implemented first because US1 depends on it
- US3 is independent and can be interleaved at any point after Phase 1
- The color mapping reference in data-model.md provides the exact replacement for each hardcoded color
- Brand colors (Google `0xFFDB4437`, Facebook `0xFF1877F2`) are explicitly excluded from replacement per spec
- Each screen task includes ALL changes for that screen (colors, buttons, text fields, radius) as a single atomic task
