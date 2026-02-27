# Widget Library API Contracts

**Feature**: 001-theme-widgets-setup
**Date**: 2026-02-27
**Version**: 1.0.0

## Overview

This document defines the public API contracts for all shared widgets in the BikeRide core widget library. These contracts guarantee a stable interface that all three apps (Customer, Driver, Admin) can depend on.

## Design Principles

1. **Consistency**: All widgets follow the same naming conventions and parameter patterns
2. **Themeable**: All widgets automatically adapt to theme changes (light/dark mode)
3. **Localized**: All widgets support RTL/LTR layouts automatically
4. **Accessible**: All widgets maintain minimum 48dp touch targets and semantic labels
5. **Type-safe**: Required parameters prevent invalid states at compile time

---

## 1. AppButton

**Purpose**: Primary action button widget with multiple visual variants and loading state support.

### Constructor

```dart
AppButton({
  Key? key,
  required String text,
  required VoidCallback? onPressed,
  ButtonVariant variant = ButtonVariant.primary,
  bool isLoading = false,
  IconData? leadingIcon,
  IconData? trailingIcon,
  double? width,
  double height = 56.0,
})
```

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| text | String | ✅ | - | Button label text (localized by caller) |
| onPressed | VoidCallback? | ✅ | - | Callback when pressed; null = disabled |
| variant | ButtonVariant | ❌ | primary | Visual style (primary, secondary, outline, text) |
| isLoading | bool | ❌ | false | Shows loading spinner, disables interaction |
| leadingIcon | IconData? | ❌ | null | Icon before text (auto-flips for RTL) |
| trailingIcon | IconData? | ❌ | null | Icon after text (auto-flips for RTL) |
| width | double? | ❌ | null | Fixed width; null = expand to fill |
| height | double | ❌ | 56.0 | Button height in dp |

### Variants

```dart
enum ButtonVariant {
  primary,    // Filled button with primary color
  secondary,  // Filled button with surface color
  outline,    // Outlined button with primary border
  text,       // Text-only button, no background
}
```

### Behavior

- **Disabled state**: `onPressed == null` → 50% opacity, no tap response
- **Loading state**: `isLoading == true` → shows CircularProgressIndicator, ignores taps
- **RTL support**: Leading/trailing icons flip positions in RTL mode
- **Accessibility**: Semantic label from `text` parameter, minimum 48dp height
- **Animation**: Scale to 0.98 on press, 200ms duration

### Example Usage

```dart
// Primary button
AppButton(
  text: 'Get Started'.tr,
  onPressed: () => Get.toNamed(Routes.home),
)

// Loading state
AppButton(
  text: 'Submitting'.tr,
  onPressed: _submit,
  isLoading: _isSubmitting,
)

// With icon
AppButton(
  text: 'Continue'.tr,
  onPressed: _next,
  trailingIcon: Icons.arrow_forward,
)

// Outline variant
AppButton(
  text: 'Cancel'.tr,
  onPressed: () => Get.back(),
  variant: ButtonVariant.outline,
)
```

### Visual Contract

- **Height**: Always 56dp (minimum touch target)
- **Border radius**: 12dp (xl from theme)
- **Padding**: 16dp horizontal, 12dp vertical
- **Text style**: Theme.textTheme.labelLarge (16sp, weight 700)
- **Elevation**: 2dp for primary/secondary, 0dp for outline/text

---

## 2. AppTextField

**Purpose**: Text input field with validation, icons, and RTL support.

### Constructor

```dart
AppTextField({
  Key? key,
  required TextEditingController controller,
  String? label,
  String? hint,
  String? errorText,
  IconData? prefixIcon,
  IconData? suffixIcon,
  bool obscureText = false,
  bool enabled = true,
  TextInputType keyboardType = TextInputType.text,
  TextInputAction textInputAction = TextInputAction.done,
  int? maxLength,
  int maxLines = 1,
  String? Function(String?)? validator,
  VoidCallback? onTap,
  ValueChanged<String>? onChanged,
  VoidCallback? onEditingComplete,
})
```

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| controller | TextEditingController | ✅ | - | Controls text value |
| label | String? | ❌ | null | Floating label text |
| hint | String? | ❌ | null | Placeholder text when empty |
| errorText | String? | ❌ | null | Validation error message |
| prefixIcon | IconData? | ❌ | null | Icon at start (auto-flips for RTL) |
| suffixIcon | IconData? | ❌ | null | Icon at end (auto-flips for RTL) |
| obscureText | bool | ❌ | false | Hides text for passwords |
| enabled | bool | ❌ | true | Enables/disables input |
| keyboardType | TextInputType | ❌ | text | Input type (text, number, phone, email) |
| textInputAction | TextInputAction | ❌ | done | Action button on keyboard |
| maxLength | int? | ❌ | null | Max character count |
| maxLines | int | ❌ | 1 | Number of lines (1 = single line) |
| validator | Function? | ❌ | null | Validation function |
| onTap | VoidCallback? | ❌ | null | Called when tapped |
| onChanged | ValueChanged? | ❌ | null | Called on text change |
| onEditingComplete | VoidCallback? | ❌ | null | Called when editing done |

### Behavior

- **Error state**: `errorText != null` → red border, error text below field
- **Disabled state**: `enabled == false` → gray background, no interaction
- **Focus state**: Blue border (primary color), floating label animates up
- **RTL support**: Text and icons flip automatically
- **Accessibility**: Semantic label from `label`, error announced by screen reader

### Example Usage

```dart
// Basic text field
AppTextField(
  controller: _nameController,
  label: 'Full Name'.tr,
  hint: 'Enter your full name'.tr,
  prefixIcon: Icons.person,
)

// Phone number input
AppTextField(
  controller: _phoneController,
  label: 'Phone Number'.tr,
  keyboardType: TextInputType.phone,
  prefixIcon: Icons.phone,
  validator: (value) => Validators.phone(value),
)

// Password field
AppTextField(
  controller: _passwordController,
  label: 'Password'.tr,
  obscureText: true,
  suffixIcon: Icons.visibility_off,
)

// With error
AppTextField(
  controller: _emailController,
  label: 'Email'.tr,
  errorText: _emailError,
)
```

### Visual Contract

- **Height**: 56dp (minimum touch target)
- **Border radius**: 12dp (xl from theme)
- **Border**: 1dp solid, color depends on state (default: gray, focus: primary, error: red)
- **Focus ring**: 2dp ring with primary color at 20% opacity
- **Text style**: Theme.textTheme.bodyLarge (16sp)
- **Label style**: Theme.textTheme.labelMedium (12sp when floating)

---

## 3. AppCard

**Purpose**: Container widget with elevation, rounded corners, and optional tap handling.

### Constructor

```dart
AppCard({
  Key? key,
  required Widget child,
  VoidCallback? onTap,
  EdgeInsets padding = const EdgeInsets.all(16),
  double elevation = 2,
  Color? backgroundColor,
  double borderRadius = 12,
})
```

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| child | Widget | ✅ | - | Content inside the card |
| onTap | VoidCallback? | ❌ | null | Tap callback; null = not tappable |
| padding | EdgeInsets | ❌ | all(16) | Inner padding |
| elevation | double | ❌ | 2 | Shadow depth (0-24) |
| backgroundColor | Color? | ❌ | null | Background color (null = theme surface) |
| borderRadius | double | ❌ | 12 | Corner radius |

### Behavior

- **Tappable**: `onTap != null` → shows InkWell ripple effect on tap
- **Non-tappable**: `onTap == null` → no ripple, static container
- **Theme adaptation**: Background color defaults to theme.colorScheme.surface
- **Elevation**: Uses Material elevation system (shadow + surface tint)

### Example Usage

```dart
// Static card
AppCard(
  child: Column(
    children: [
      Text('Card Title'),
      Text('Card content'),
    ],
  ),
)

// Tappable card
AppCard(
  onTap: () => Get.toNamed(Routes.details),
  child: ListTile(
    title: Text('Tap me'),
    trailing: Icon(Icons.arrow_forward),
  ),
)

// Custom elevation
AppCard(
  elevation: 8,
  child: Image.network(imageUrl),
)
```

### Visual Contract

- **Padding**: 16dp default (customizable)
- **Border radius**: 12dp default (customizable)
- **Elevation**: 2dp default (0-24 range)
- **Background**: Theme surface color
- **Ripple**: InkWell with primary color at 12% opacity (if tappable)

---

## 4. AppLoading

**Purpose**: Loading indicator with optional overlay for blocking interactions.

### Constructor

```dart
AppLoading({
  Key? key,
  bool showOverlay = false,
  Color? color,
  double size = 40,
  String? message,
})
```

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| showOverlay | bool | ❌ | false | Shows full-screen dimmed overlay |
| color | Color? | ❌ | null | Spinner color (null = primary) |
| size | double | ❌ | 40 | Spinner diameter |
| message | String? | ❌ | null | Optional loading message below spinner |

### Behavior

- **Overlay mode**: `showOverlay == true` → blocks all interactions, dims background
- **Inline mode**: `showOverlay == false` → shows spinner in place, doesn't block
- **Color**: Defaults to theme primary color if not specified
- **Animation**: Continuous rotation, Material spinner style

### Example Usage

```dart
// Inline loading
if (_isLoading)
  AppLoading()

// Full-screen overlay
if (_isProcessing)
  AppLoading(
    showOverlay: true,
    message: 'Processing payment...'.tr,
  )

// Custom color
AppLoading(
  color: Colors.white,
  size: 24,
)
```

### Visual Contract

- **Size**: 40dp default (customizable)
- **Color**: Theme primary color
- **Overlay opacity**: 50% black when `showOverlay == true`
- **Message style**: Theme.textTheme.bodyMedium, centered below spinner

---

## 5. AppSnackbar

**Purpose**: Utility for showing temporary messages (success, error, info, warning).

### Static Methods

```dart
class AppSnackbar {
  static void show({
    required String message,
    SnackbarType type = SnackbarType.info,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onTap,
  })

  static void success(String message, {Duration? duration})
  static void error(String message, {Duration? duration})
  static void info(String message, {Duration? duration})
  static void warning(String message, {Duration? duration})
}
```

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| message | String | ✅ | - | Snackbar text content |
| type | SnackbarType | ❌ | info | Visual style (success, error, info, warning) |
| duration | Duration | ❌ | 3 seconds | Auto-dismiss duration |
| onTap | VoidCallback? | ❌ | null | Callback when snackbar tapped |

### Snackbar Types

```dart
enum SnackbarType {
  success,  // Green background, checkmark icon
  error,    // Red background, error icon
  info,     // Blue background, info icon
  warning,  // Orange background, warning icon
}
```

### Behavior

- **Auto-dismiss**: Disappears after `duration` (default 3 seconds)
- **Manual dismiss**: Swipe to dismiss or tap close button
- **Queue**: Multiple snackbars queue and show sequentially
- **Position**: Bottom of screen (above navigation bar if present)

### Example Usage

```dart
// Success message
AppSnackbar.success('Profile updated successfully'.tr);

// Error message
AppSnackbar.error('Failed to connect to server'.tr);

// Custom duration
AppSnackbar.show(
  message: 'Processing...'.tr,
  type: SnackbarType.info,
  duration: Duration(seconds: 5),
);

// With tap action
AppSnackbar.show(
  message: 'New message received'.tr,
  type: SnackbarType.info,
  onTap: () => Get.toNamed(Routes.messages),
);
```

### Visual Contract

- **Height**: 56dp minimum
- **Border radius**: 12dp
- **Margin**: 16dp from edges
- **Padding**: 16dp horizontal, 12dp vertical
- **Icon size**: 24dp
- **Text style**: Theme.textTheme.bodyMedium (14sp, white text)
- **Background colors**:
  - Success: #4CAF50 (green)
  - Error: #F44336 (red)
  - Info: #2196F3 (blue)
  - Warning: #FF9800 (orange)

---

## 6. AppMapWidget

**Purpose**: Placeholder widget for future Google Maps integration.

### Constructor

```dart
AppMapWidget({
  Key? key,
  double height = 300,
  LatLng? initialPosition,
  double zoom = 15,
})
```

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| height | double | ❌ | 300 | Widget height |
| initialPosition | LatLng? | ❌ | null | Starting map position |
| zoom | double | ❌ | 15 | Initial zoom level |

### Behavior

- **Current implementation**: Shows placeholder with "Map will be implemented" message
- **Future implementation**: Will integrate google_maps_flutter package
- **RTL support**: Map controls will flip for RTL

### Example Usage

```dart
// Basic map placeholder
AppMapWidget()

// With custom height
AppMapWidget(
  height: 400,
  initialPosition: LatLng(30.0444, 31.2357), // Cairo
)
```

### Visual Contract

- **Height**: 300dp default (customizable)
- **Border radius**: 12dp
- **Placeholder**: Gray background with centered text and map icon

---

## Breaking Change Policy

**Version**: 1.0.0

This API is in **initial release**. Breaking changes may occur before 1.0 stable.

### Allowed Changes (Non-breaking)
- ✅ Adding new optional parameters with defaults
- ✅ Adding new widget variants
- ✅ Adding new static methods to AppSnackbar
- ✅ Internal implementation changes
- ✅ Performance optimizations

### Disallowed Changes (Breaking)
- ❌ Removing or renaming required parameters
- ❌ Changing parameter types
- ❌ Removing widget variants
- ❌ Changing default behavior significantly
- ❌ Removing widgets

### Deprecation Process
1. Mark deprecated API with `@Deprecated('Use X instead')` annotation
2. Keep deprecated API functional for at least 2 minor versions
3. Document migration path in comments
4. Remove in next major version

---

## Testing Contracts

All widgets MUST have:
1. **Unit tests**: Constructor validation, parameter handling
2. **Widget tests**: Rendering in light/dark themes, RTL/LTR modes
3. **Golden tests**: Visual regression for all variants
4. **Accessibility tests**: Semantic labels, touch target sizes

---

## Changelog

### 1.0.0 (2026-02-27)
- Initial API definition
- Six widgets: AppButton, AppTextField, AppCard, AppLoading, AppSnackbar, AppMapWidget
- Support for light/dark themes, RTL/LTR layouts
