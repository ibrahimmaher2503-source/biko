# Data Model: Redesign Screen UIs with Theme Compliance & Skip OTP

**Branch**: `004-redesign-ui-skip-otp` | **Date**: 2026-03-01

---

## New Entities

### AppColorsExtension (ThemeExtension)

A Flutter `ThemeExtension<AppColorsExtension>` registered on both `lightTheme` and `darkTheme` in `AppTheme`. Provides semantic colors that adapt to the current brightness mode.

| Property | Type | Light Value | Dark Value | Purpose |
|---|---|---|---|---|
| `surfaceElevated` | `Color` | `Colors.white` | `Color(0xFF2D1316)` | Card backgrounds, elevated containers |
| `surfaceContainer` | `Color` | `Color(0xFFF1F5F9)` | `Color(0xFF1E293B)` | Input field backgrounds, secondary containers |
| `border` | `Color` | `Color(0xFFE2E8F0)` | `Color(0xFF334155)` | Default border color for cards, inputs |
| `borderSubtle` | `Color` | `Color(0xFFF1F5F9)` | `Color(0xFF1E293B)` | Subtle/light border for dividers |
| `textMuted` | `Color` | `Color(0xFF64748B)` | `Color(0xFF94A3B8)` | Secondary/muted text |
| `info` | `Color` | `Color(0xFF2563EB)` | `Color(0xFF60A5FA)` | Info icon/text foreground |
| `infoBg` | `Color` | `Color(0xFFEFF6FF)` | `Color(0xFF1E3A5F)` | Info tip background |
| `infoBorder` | `Color` | `Color(0xFFDBEAFE)` | `Color(0xFF2563EB)` | Info tip border |
| `success` | `Color` | `Color(0xFF16A34A)` | `Color(0xFF4ADE80)` | Success icon/text foreground |
| `successBg` | `Color` | `Color(0xFFDCFCE7)` | `Color(0xFF14532D)` | Success status background |
| `warning` | `Color` | `Color(0xFFD97706)` | `Color(0xFFFBBF24)` | Warning icon/text foreground |
| `warningBg` | `Color` | `Color(0xFFFEF3C7)` | `Color(0xFF78350F)` | Warning status background |

**Access pattern**: `Theme.of(context).extension<AppColorsExtension>()!.surfaceElevated`

**Methods**:
- `copyWith(...)` — required by ThemeExtension
- `lerp(other, t)` — required by ThemeExtension for animated transitions

---

### DevConfig (Static Constants)

A simple class with static constants for development-only configuration flags.

| Property | Type | Default | Purpose |
|---|---|---|---|
| `skipOtp` | `bool` | `true` | Skip Firebase Phone Auth OTP verification flow |

**Location**: `lib/core/constants/dev_config.dart`

**Access pattern**: `DevConfig.skipOtp`

---

## Modified Entities

### AppButton — ButtonVariant Enum Update

| Variant | Before | After |
|---|---|---|
| `primary` | `ElevatedButton` (elevated, shadow) | `FilledButton` (flat, solid primary bg, white text) |
| `secondary` | `FilledButton.tonal` | `FilledButton.tonal` (unchanged) |
| `outline` | `OutlinedButton` | `OutlinedButton` (unchanged) |
| `text` | `TextButton` | `TextButton` (unchanged) |

No new parameters needed — `trailingIcon` already exists.

### AppTheme — Theme Registration

Add `AppColorsExtension` to both `lightTheme` and `darkTheme` via:
```
extensions: <ThemeExtension<dynamic>>[
  AppColorsExtension(light values...),
],
```

### AppConstants — Remove Duplicate Radius

Remove `radiusDefault`, `radiusLarge`, `radiusXl`, `radiusFull` from `AppConstants`. These are already defined in `AppTheme` and having them in both places causes confusion about the canonical source.

---

## Unchanged Entities

- **AppTextField** — Already fully theme-compliant. Uses `InputDecorationTheme` from theme. No changes needed.
- **UserModel, DriverProfileModel** — No data model changes. This is a pure UI refactoring.
- **AppRoutes** — No new routes added. OTP bypass changes navigation flow but uses existing routes.
- **AppTranslations** — No new translation keys needed (no new UI text).

---

## Color Mapping Reference

This table maps every hardcoded color found in screens to its theme replacement.

| Hardcoded Value | Hex | Used For | Theme Replacement |
|---|---|---|---|
| `Color(0xFF1E293B)` | slate-800 | Dark mode card/input bg | `ext.surfaceContainer` |
| `Color(0xFF334155)` | slate-700 | Dark mode borders | `ext.border` |
| `Color(0xFFE2E8F0)` | slate-200 | Light mode borders | `ext.border` |
| `Color(0xFFF1F5F9)` | slate-100 | Light mode subtle bg/border | `ext.borderSubtle` |
| `Color(0xFFF8F5F6)` | custom pink-tint | Light mode input bg | `ext.surfaceContainer` (or `colorScheme.surface`) |
| `Colors.white` | white | Light mode card bg | `ext.surfaceElevated` |
| `Color(0xFFEFF6FF)` | blue-50 | Info tip background | `ext.infoBg` |
| `Color(0xFFDBEAFE)` | blue-100 | Info tip border | `ext.infoBorder` |
| `Color(0xFF2563EB)` | blue-600 | Info icon | `ext.info` |
| `Color(0xFF1E3A5F)` | blue-900 | Info text | `ext.info` |
| `Color(0xFFDCFCE7)` | green-100 | Success badge bg | `ext.successBg` |
| `Color(0xFF16A34A)` | green-600 | Success check icon | `ext.success` |
| `Color(0xFFDB4437)` | Google red | Google brand | KEEP (brand color) |
| `Color(0xFF1877F2)` | Facebook blue | Facebook brand | KEEP (brand color) |
| `Colors.white` in TextStyle | white | Button text on primary | `colorScheme.onPrimary` (implicit via FilledButton) |
| `AppTheme.primary` in TextStyle | red | Accent text | `colorScheme.primary` |
| Various `.withValues(alpha: 0.x)` | opacity variants | Muted text, disabled | `ext.textMuted` or `colorScheme.onSurface.withValues(alpha:)` |
