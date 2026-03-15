# Research Decisions: Redesign Screen UIs with Theme Compliance & Skip OTP

**Branch**: `004-redesign-ui-skip-otp` | **Date**: 2026-03-01

---

## R-001: How to extend AppTheme with semantic colors

**Context**: Screens use ~15 different hardcoded Tailwind-derived colors (`#1E293B`, `#334155`, `#E2E8F0`, `#F1F5F9`, etc.) for surfaces, borders, and status states. The Material ColorScheme has limited semantic slots. We need a way to provide these colors that adapts to light/dark mode.

**Options**:
1. **ThemeExtension<AppColorsExtension>** — Flutter 3's official mechanism for custom theme properties. Registered on ThemeData, accessed via `Theme.of(context).extension<AppColorsExtension>()`.
2. **Static constants on AppTheme** — Simple `AppTheme.surfaceElevated` static const values. Easy to access but doesn't adapt to light/dark mode without manual checks.
3. **Separate light/dark maps** — `AppTheme.lightColors` and `AppTheme.darkColors` maps. Verbose, error-prone.

**Decision**: Option 1 — `ThemeExtension<AppColorsExtension>`. This is the Flutter-recommended approach, automatically resolves light/dark, and integrates with `Theme.of(context)` for consistency. The extension will include:
- Surface variants: `surfaceElevated`, `surfaceContainer`
- Border colors: `border`, `borderSubtle`
- Status colors: `info`, `infoBg`, `infoBorder`, `success`, `successBg`, `warning`, `warningBg`
- Neutral text: `textMuted` (for 0.5-0.6 opacity text patterns)

**Spec Trace**: FR-001, FR-002, FR-003, US2

---

## R-002: AppButton filled variant — new variant or adjust existing primary?

**Context**: The existing `AppButton` uses `ElevatedButton` for `ButtonVariant.primary`, which has Material 3 elevation/tonal styling. Screens create bare `FilledButton` widgets because they want a flat filled button (no elevation, solid primary color, white text). The spec requires a `filled` variant (FR-012).

**Options**:
1. **Add `ButtonVariant.filled`** — New enum value using `FilledButton` internally. Keeps `primary` as `ElevatedButton` (elevated look).
2. **Change `primary` to use `FilledButton`** — Replace the internal `ElevatedButton` with `FilledButton`. Breaking change to existing `primary` variant behavior, but no screens actually use `AppButton` yet.
3. **Use `FilledButton.styleFrom` on primary** — Override `ElevatedButton` to look like `FilledButton` via style.

**Decision**: Option 2 — Change `ButtonVariant.primary` to use `FilledButton` instead of `ElevatedButton`. Since no screens currently use `AppButton` (all use bare buttons), there is zero breaking impact. The theme already defines `elevatedButtonTheme` but screens don't use it through `AppButton`. This gives us the flat filled look screens want without adding variant complexity.

**Spec Trace**: FR-005, FR-012, SC-002

---

## R-003: AppButton trailing icon — how to support "Continue →" pattern

**Context**: Multiple screens show buttons with text + trailing arrow icon (e.g., "Continue →", "Get Started →"). `AppButton` already has `trailingIcon` parameter with RTL flipping. The current implementation works. The spec requires trailing icon support (FR-011).

**Options**:
1. **Already supported** — `AppButton.trailingIcon` exists and handles RTL. No changes needed.
2. **Add explicit icon size/color control** — Allow customization of the icon.

**Decision**: Option 1 — Already supported. The `trailingIcon` parameter already exists on `AppButton` with RTL-aware flipping. The icon inherits color from the button's foreground color via the theme. No changes needed specifically for trailing icon support.

**Spec Trace**: FR-011

---

## R-004: Where to place the OTP bypass flag

**Context**: The spec requires a single-location boolean constant for OTP bypass (FR-017). It should be clearly visible and easy to find.

**Options**:
1. **New file `lib/core/constants/dev_config.dart`** — Dedicated dev configuration file with a `DevConfig` class containing `static const bool skipOtp = true`.
2. **Inside `app_constants.dart`** — Add to existing constants file. Pros: fewer files. Cons: mixes dev-only flags with app constants.
3. **Environment variable via `flutter_dotenv`** — Flexible but heavy for a single boolean.

**Decision**: Option 1 — New `lib/core/constants/dev_config.dart`. A dedicated file makes the dev flag clearly visible, easy to find, and separated from production constants. The file name signals its purpose. When the app ships to production, this file is the single place to audit.

**Spec Trace**: FR-013, FR-017, SC-008

---

## R-005: How the OTP bypass interacts with SplashController

**Context**: The `SplashController._determineDestination()` checks `FirebaseAuth.instance.currentUser`. When OTP is bypassed, there is no Firebase user session. The splash must route to `phoneLogin` (for new users to enter profile setup flow) without throwing Firebase errors (FR-015).

**Options**:
1. **Splash checks DevConfig.skipOtp** — If true, skip the Firebase auth check entirely and route to `phoneLogin` if onboarding is complete (treating user as unauthenticated).
2. **Create a mock Firebase user** — Complex, fragile, unnecessary.
3. **Splash ignores auth entirely when bypass on** — Similar to option 1 but also skips profile/driver checks.

**Decision**: Option 1 — Add a `DevConfig.skipOtp` check in `SplashController._determineDestination()`. When bypass is enabled and there is no Firebase user, route to `phoneLogin` (normal unauthenticated flow). This is the minimal change — the existing `currentUser == null` check already handles this case; we just need to ensure no Firebase initialization failure crashes the flow. The `AppInitializer` already handles Firebase init failure gracefully ("continuing in offline mode").

**Spec Trace**: FR-015, SC-007

---

## R-006: How AuthController handles OTP bypass

**Context**: When the user taps "Continue" on PhoneLoginScreen with bypass enabled, the app should navigate directly to `profileSetup` without calling Firebase Auth at all (FR-014).

**Options**:
1. **Guard in `sendOtp()`** — Check `DevConfig.skipOtp` at the start of `sendOtp()`. If true, skip Firebase call and navigate directly to `profileSetup`.
2. **Guard in PhoneLoginScreen** — Check bypass in the UI before calling `sendOtp()`.
3. **Override `AuthService.sendOtp()`** — Add bypass inside the service layer.

**Decision**: Option 1 — Add bypass guard at the start of `AuthController.sendOtp()`. When `DevConfig.skipOtp` is true: validate phone number (so the UX feels realistic), then navigate directly to `AppRoutes.profileSetup` via `Get.offAllNamed()`. This keeps the bypass logic in the controller (not scattered in UI), preserves the real OTP code path untouched (FR-016), and makes the flow testable.

**Spec Trace**: FR-014, FR-016, SC-007

---

## R-007: Duplicate border radius constants — AppTheme vs AppConstants

**Context**: Both `AppTheme` and `AppConstants` define identical border radius values (`radiusDefault=8`, `radiusLarge=12`, `radiusXl=16`, `radiusFull=9999`). This duplication is confusing — screens should have one canonical source.

**Options**:
1. **Keep both, use AppTheme in widgets** — AppTheme is the "styling" source. AppConstants handles non-visual constants. Duplicating radius is acceptable.
2. **Remove from AppConstants, keep in AppTheme** — Single source of truth in AppTheme for all visual styling.
3. **Remove from AppTheme, keep in AppConstants** — Theme focuses on ThemeData; constants hold numeric values.

**Decision**: Option 2 — Remove radius constants from `AppConstants` and keep them only in `AppTheme`. The radius values are purely visual styling concerns, and `AppTheme` is the canonical source for all styling. This eliminates confusion about which source to use. All screen code will reference `AppTheme.radiusLarge` (not `AppConstants.radiusLarge`). Note: use `BorderRadius.circular(AppTheme.radiusLarge)` everywhere.

**Spec Trace**: FR-004, SC-004

---

## R-008: Strategy for replacing hardcoded colors in screens

**Context**: There are ~50+ hardcoded color instances across 7 screens and 7 widgets. A systematic approach is needed.

**Options**:
1. **Per-screen refactoring** — Process each screen file individually, replacing all hardcoded values.
2. **Per-color-category refactoring** — Replace all surface colors across all files, then all border colors, etc.
3. **Bottom-up: widgets first, then screens** — Fix shared widgets (PhoneInputField, OtpInputField, etc.) first, then screens.

**Decision**: Option 3 — Bottom-up approach. Order:
1. Extend `AppTheme` with `AppColorsExtension` (provides the semantic colors)
2. Enhance `AppButton` (so screens can switch to it)
3. Fix shared widgets (PhoneInputField, OtpInputField, DocumentUploadItem, SocialLoginButtons, PageIndicator, StepProgressIndicator)
4. Fix each screen (Splash → Onboarding → PhoneLogin → OTP → ProfileSetup → DriverRegistration → PendingApproval)

This order ensures dependencies are resolved before dependents. When we reach screens, both the theme colors AND the fixed widgets are already available.

**Spec Trace**: FR-007, SC-001
