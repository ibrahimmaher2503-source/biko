# Feature Specification: Redesign Screen UIs with Theme Compliance & Skip OTP Verification

**Feature Branch**: `004-redesign-ui-skip-otp`
**Created**: 2026-03-01
**Status**: Draft
**Input**: User description: "Redesign all screens UI based on app themes and skip mobile verification now"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Consistent Theme-Based Screen UI (Priority: P1)

As a user navigating through the app (splash, onboarding, phone login, OTP, profile setup, driver registration, pending status), I see a visually consistent experience where all screens share the same color palette, typography, button styles, input field styles, and spacing. Every screen looks like it belongs to the same app.

**Why this priority**: Visual inconsistency is the most visible quality issue. Currently, screens use hardcoded colors (Tailwind-derived hex values like `#1E293B`, `#334155`, `#E2E8F0`) instead of the app's theme system. This makes dark mode unreliable, RTL transitions jarring, and future theme changes require editing every file individually.

**Independent Test**: Open each screen in both light and dark mode. Verify all buttons look identical (same height, radius, color, typography), all text fields share the same style, and no screen uses colors that differ from the established theme palette. Toggle between Arabic and English and verify fonts switch correctly and layouts mirror properly.

**Acceptance Scenarios**:

1. **Given** the app is in light mode, **When** I navigate through all 7 screens, **Then** every filled button uses the same primary background color from the theme (not hardcoded), same corner radius from theme constants, and same text style from theme typography.
2. **Given** the app is in dark mode, **When** I navigate through all 7 screens, **Then** all backgrounds, cards, borders, and text colors adapt correctly using the theme's dark ColorScheme with no hardcoded light-mode colors appearing.
3. **Given** I switch the app language to Arabic, **When** I view any screen, **Then** typography uses Cairo font, layout mirrors to RTL, and directional icons (back arrows) flip correctly.
4. **Given** the `AppButton` shared widget exists, **When** I inspect any screen's button, **Then** it uses `AppButton` and no screen creates its own `FilledButton`, `ElevatedButton`, or `OutlinedButton` with manual styling overrides.
5. **Given** the `AppTextField` shared widget exists, **When** I inspect any screen's text input, **Then** it uses `AppTextField` or a specialized wrapper that delegates to `AppTextField`. No screen creates bare `TextField` widgets with manual decoration.

---

### User Story 2 - Extended Theme System for Missing Semantic Colors (Priority: P2)

As a developer, when I build screens I can access all needed colors from the theme without resorting to hardcoded hex values. The theme provides semantic surface variants, border colors, info/success/warning states, and neutral tones for both light and dark modes.

**Why this priority**: The current theme has primary and background colors but lacks intermediate neutral tones (surface variants, border colors) and semantic status colors (info blue, success green). Screens fill this gap with hardcoded hex values. Providing these in the theme eliminates the root cause of inconsistency.

**Independent Test**: After the theme extension is added, search the entire `lib/features/` directory for hardcoded `Color(0x` patterns. The count should be near zero (only third-party brand colors like Google red and Facebook blue are acceptable exceptions).

**Acceptance Scenarios**:

1. **Given** the theme system is extended, **When** a developer needs a surface, border, or info color, **Then** they can access it via theme extensions or constants with no need to guess hex values.
2. **Given** the extended theme, **When** switching between light and dark mode, **Then** all semantic colors (info, success, warning, surface variants, borders) automatically adapt to the correct dark-mode equivalents.
3. **Given** any screen file in `lib/features/`, **When** I search for `Color(0xFF`, **Then** only brand-specific colors (Google, Facebook) appear. All other colors reference the theme.

---

### User Story 3 - Skip OTP Verification for Development (Priority: P1)

As a developer testing the app during development, I can bypass the real OTP flow entirely. When I tap "Continue" on the phone login screen, the app navigates directly to the profile setup screen (or the appropriate post-auth destination) without sending an actual OTP, without showing the OTP verification screen, and without requiring Firebase Auth to be configured.

**Why this priority**: OTP verification requires a working Firebase project, real phone numbers, and waiting for SMS delivery, all of which block rapid UI development and testing. Skipping this unblocks the entire flow for design iteration.

**Independent Test**: Run the app. Enter any phone number on the login screen. Tap Continue. The app immediately navigates to the profile setup screen without any OTP prompt or Firebase call.

**Acceptance Scenarios**:

1. **Given** OTP bypass is enabled, **When** I enter any phone number and tap Continue, **Then** the app skips the OTP screen and navigates directly to the next logical screen in the flow (profile setup for new users).
2. **Given** OTP bypass is enabled, **When** the app launches, **Then** no Firebase Auth calls are made during the authentication flow.
3. **Given** OTP bypass is a development-only feature, **When** a developer wants to re-enable real OTP, **Then** they can do so by changing a single boolean flag. The real OTP code remains intact and untouched.

---

### Edge Cases

- What happens when a screen is viewed on a very small device (320px width)? Do themed components overflow or clip?
- How does the info tip box (driver registration) render in dark mode with the extended theme colors?
- How does the skip-OTP flag interact with the splash screen's auth check? The splash screen must detect the mocked/bypassed state and route correctly.
- What happens if OTP bypass is enabled but the user already has a real Firebase session? The bypass should still work without conflicts.

## Requirements *(mandatory)*

### Functional Requirements

**Theme Extension**

- **FR-001**: The theme system MUST provide semantic surface variant colors (elevated surface, surface container, surface tint) for both light and dark modes, replacing all hardcoded neutral colors (`#1E293B`, `#334155`, `#E2E8F0`, `#F1F5F9`, `#F8F5F6`).
- **FR-002**: The theme system MUST provide semantic border colors for both light and dark modes, accessible via theme data or constants.
- **FR-003**: The theme system MUST provide info, success, and warning state colors (background, foreground, and border variants) for both light and dark modes, replacing hardcoded blue and green hex values.
- **FR-004**: All border radius values used in screens MUST reference theme constants (e.g., `radiusDefault`, `radiusLarge`, `radiusXl`, `radiusFull`). No hardcoded `BorderRadius.circular(N)` calls.

**Screen Redesign**

- **FR-005**: Every screen MUST use the shared button widget for all interactive buttons (primary actions, secondary actions, text actions, outline actions). No screen may create its own button widget with manual style overrides.
- **FR-006**: Every screen MUST use the shared text field widget (or a specialized widget that wraps it) for all text input fields. No screen may create bare text input widgets with manual decoration.
- **FR-007**: Every screen MUST derive all colors from the theme system. No hardcoded color values except for third-party brand colors.
- **FR-008**: Every screen MUST derive all text styles from the theme typography system. No hardcoded text style properties except where a theme style is extended with minor overrides (e.g., adding a specific color via `.copyWith()`).
- **FR-009**: All 7 screens (Splash, Onboarding, PhoneLogin, OtpVerification, ProfileSetup, DriverRegistration, PendingApproval) MUST render correctly in both light and dark modes with all colors derived from theme.
- **FR-010**: All 7 screens MUST render correctly in both Arabic (RTL) and English (LTR) modes with appropriate font switching and layout mirroring.

**Shared Widget Enhancements**

- **FR-011**: The shared button widget MUST support a trailing icon variant (icon after text) to match design patterns showing buttons like "Continue (arrow)" and "Get Started (arrow)".
- **FR-012**: The shared button widget MUST support the filled button style matching the design system (primary background, white text, rounded corners, shadow).

**Skip OTP**

- **FR-013**: The app MUST provide a development bypass flag that, when enabled, skips phone verification entirely.
- **FR-014**: When OTP bypass is enabled, tapping "Continue" on the phone login screen MUST navigate directly to the profile setup screen without sending any OTP or showing the OTP verification screen.
- **FR-015**: When OTP bypass is enabled, the splash screen auth check MUST treat the user as unauthenticated (new user flow) rather than failing due to missing auth state.
- **FR-016**: The real OTP verification code MUST remain completely intact and functional. The bypass MUST be implemented as a conditional branch, not by removing or commenting out OTP logic.
- **FR-017**: The bypass flag MUST be a clearly visible, single-location constant (not scattered across multiple files).

**Widget Updates**

- **FR-018**: The `PhoneInputField` widget MUST use theme colors for its container, borders, and text instead of hardcoded hex values.
- **FR-019**: The `OtpInputField` widget MUST use theme colors for its field backgrounds, borders, and focus states instead of hardcoded hex values.
- **FR-020**: The `DocumentUploadItem` widget MUST use theme colors for its container, icon background, borders, and status indicators instead of hardcoded hex values.
- **FR-021**: The `SocialLoginButtons` widget MUST use theme colors for its border and divider (third-party brand icon colors are acceptable exceptions).

### Key Entities

- **AppTheme (extended)**: Expanded with semantic color system covering surface variants, border colors, and status state colors (info, success, warning) for both light and dark modes.
- **AppButton (enhanced)**: Expanded with filled variant and trailing icon support to cover all button patterns used across screens.
- **Dev Config**: A development configuration constant controlling OTP bypass behavior, stored in a single location.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Zero hardcoded `Color(0xFF...)` values in any screen or feature widget file (except third-party brand colors), verified by text search across `lib/features/`.
- **SC-002**: Zero instances of bare `FilledButton`, `ElevatedButton`, `OutlinedButton`, or `TextButton` in any screen file. All replaced by the shared button widget.
- **SC-003**: Zero instances of bare `TextField` in screen files. All replaced by the shared text field widget or specialized wrappers.
- **SC-004**: Zero instances of `BorderRadius.circular(N)` in screen and widget files. All replaced by theme radius constants.
- **SC-005**: All 7 screens render correctly in dark mode without any light-mode artifacts (white backgrounds on dark, invisible text, wrong border colors).
- **SC-006**: All 7 screens render correctly in Arabic RTL mode with proper font switching and layout mirroring.
- **SC-007**: The complete app flow (splash to onboarding to phone login to profile setup) is navigable without any Firebase configuration when the OTP bypass flag is enabled.
- **SC-008**: The OTP bypass can be disabled by changing a single boolean, restoring the full phone verification flow.
- **SC-009**: Static analysis passes with no new errors or warnings introduced by the redesign.

## Assumptions

- The existing theme system and shared widgets (`AppButton`, `AppTextField`, `AppCard`, `AppLoading`, `AppSnackbar`) are the canonical styling source. Screens must conform to them, not the other way around.
- The stitch HTML design files remain the visual reference for layout and spacing, but colors and component styles must come from the theme.
- The OTP bypass is strictly for development. It will not ship to production. A single constant in a dev config file is sufficient; no need for environment variables or build flavors.
- The shared button widget may need minor enhancements (filled variant, trailing icon) to cover all button patterns used in screens, but its API surface should remain simple.
- Third-party brand colors (Google `#DB4437`, Facebook `#1877F2`) are acceptable as hardcoded values since they represent external brand guidelines, not app theme colors.
- The 7 screens in scope are those created in spec 003 (splash-onboarding): SplashScreen, OnboardingScreen, PhoneLoginScreen, OtpVerificationScreen, ProfileSetupScreen, DriverRegistrationScreen, PendingApprovalScreen.
