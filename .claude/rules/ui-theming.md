# UI, Theming & Shared Widgets

## Theme System
- Use `AppTheme.lightTheme` / `AppTheme.darkTheme` — Material 3.
- Access // Use AppTheme for ALL colors:
  AppTheme.primaryColor          // Brand orange/primary
  AppTheme.backgroundColor       // Screen background
  AppTheme.cardColor             // Card/surface color
  AppTheme.textPrimary           // Main text
  AppTheme.textSecondary         // Subtitle/hint text
  AppTheme.errorColor            // Error red
  AppTheme.successColor          // Success green
  AppTheme.warningColor          // Warning yellow
  AppTheme.dividerColor          // Dividers/borders
  AppTheme.shimmerBase           // Loading shimmer base
  AppTheme.shimmerHighlight      // Loading shimmer highlight

// Typography:
AppTextStyles.heading1         // Large headings
AppTextStyles.heading2         // Section headings
AppTextStyles.body1            // Body text
AppTextStyles.body2            // Secondary body
AppTextStyles.caption          // Small labels
AppTextStyles.button           // Button text

// Dimensions:
AppDimensions.paddingS         // 8
AppDimensions.paddingM         // 16
AppDimensions.paddingL         // 24
AppDimensions.radiusS          // 8
AppDimensions.radiusM          // 12
AppDimensions.radiusL          // 20 

- Available tokens: `surfaceElevated`, `surfaceContainer`, `border`, `borderSubtle`, `textMuted`, `info`, `success`, `warning` + backgrounds.
- Primary brand color: `#E0062E` (BikeRide red).
- Never use hardcoded `Colors.*` except for shadows and text-on-primary.

## Fonts
- English: Plus Jakarta Sans
- Arabic: Cairo
- Applied via `AppTheme.getThemeWithLocale(locale)`.

## Shared Widgets (Use Instead of Raw Material)
- `AppButton` — not `ElevatedButton` / `TextButton`
- `AppTextField` — not `TextField` / `TextFormField`
- `AppCard` — not `Card`
- `AppLoading` — not `CircularProgressIndicator`
- `AppSnackbar` — not `ScaffoldMessenger.showSnackBar`
- `AppMapWidget` — for map views
- All live in `lib/core/widgets/`.

## Directionality
- Icons implying direction must flip in RTL.
- Use `EdgeInsetsDirectional` when left/right padding differs.
- Use `TextDirection.rtl` aware layouts.
