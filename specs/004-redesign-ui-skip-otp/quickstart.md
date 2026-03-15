# Quickstart: Redesign Screen UIs with Theme Compliance & Skip OTP

**Branch**: `004-redesign-ui-skip-otp` | **Date**: 2026-03-01

---

## Prerequisites

- Flutter SDK installed and on PATH
- Project dependencies installed (`flutter pub get`)
- An Android emulator or iOS simulator running (or physical device connected)
- No Firebase configuration required (OTP bypass eliminates this dependency)

## Build & Run

```bash
# Ensure dependencies are up to date
flutter pub get

# Run the driver app (most screens are in driver flow)
flutter run -t lib/main_driver.dart

# Or run the customer app
flutter run -t lib/main_customer.dart
```

## Verification Checklist

### 1. OTP Bypass (SC-007, SC-008)

1. Open `lib/core/constants/dev_config.dart`
2. Verify `skipOtp = true`
3. Run the app
4. Complete onboarding (or skip)
5. On the phone login screen, enter any valid Egyptian number (e.g., `1012345678`)
6. Tap "Continue"
7. **Expected**: App navigates directly to Profile Setup — no OTP screen, no Firebase errors
8. To test real OTP: change `skipOtp` to `false`, ensure Firebase is configured, re-run

### 2. Theme Compliance — Light Mode (SC-001, SC-002, SC-003, SC-004, SC-005)

1. Run the app in light mode (system or forced)
2. Navigate through: Splash → Onboarding → Phone Login → Profile Setup
3. **Check**: All buttons use AppButton (consistent height, radius, style)
4. **Check**: All text fields use AppTextField (consistent border, fill, focus)
5. **Check**: No visually inconsistent colors (all surfaces, borders, text match theme)
6. **Check**: Cards and containers use `AppColorsExtension` surface/border colors

### 3. Theme Compliance — Dark Mode (SC-005)

1. Switch device to dark mode
2. Navigate through all 7 screens
3. **Check**: No white backgrounds appearing on dark surfaces
4. **Check**: No invisible text (dark text on dark background)
5. **Check**: Borders and dividers are visible but subtle
6. **Check**: Info tip box (driver registration) adapts to dark palette

### 4. RTL Mode (SC-006)

1. Switch app language to Arabic
2. Navigate through all screens
3. **Check**: Typography uses Cairo font
4. **Check**: Layouts mirror (back arrows flip, text aligns right)
5. **Check**: Buttons still work correctly (trailing icons flip properly)

### 5. Static Analysis (SC-009)

```bash
flutter analyze
```

**Expected**: No new errors or warnings. Info-level lints are acceptable.

### 6. Hardcoded Value Search (SC-001, SC-004)

```bash
# Search for hardcoded Color(0x values in feature files (should find only brand colors)
grep -rn "Color(0x" lib/features/

# Search for bare button widgets (should find zero)
grep -rn "FilledButton\|ElevatedButton\|OutlinedButton" lib/features/ --include="*_screen.dart"

# Search for bare TextField (should find zero in screens)
grep -rn "TextField(" lib/features/ --include="*_screen.dart"

# Search for hardcoded BorderRadius.circular (should find zero)
grep -rn "BorderRadius.circular" lib/features/
```

## Key Files

| File | Role |
|---|---|
| `lib/core/constants/dev_config.dart` | OTP bypass flag (single location) |
| `lib/core/theme/app_theme.dart` | Theme system with AppColorsExtension |
| `lib/core/widgets/app_button.dart` | Shared button (all screens use this) |
| `lib/core/widgets/app_text_field.dart` | Shared text field (all screens use this) |

## Troubleshooting

| Issue | Cause | Fix |
|---|---|---|
| Firebase crash on startup | Firebase not configured | Ensure `DevConfig.skipOtp = true` |
| OTP screen still appears | Bypass flag is false | Set `DevConfig.skipOtp = true` in `dev_config.dart` |
| Colors look wrong in dark mode | Using hardcoded light colors | Use `Theme.of(context).extension<AppColorsExtension>()!` |
| `AppColorsExtension` returns null | Extension not registered on theme | Check `AppTheme.lightTheme` has `extensions: [...]` |
