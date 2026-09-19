# Design Tokens

## Colors
```dart
class AppColors {
  static const primary = Color(0xFF2563EB);
  static const primaryDark = Color(0xFF1D4ED8);
  static const background = Color(0xFFF8FAFC);
  static const surface = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const border = Color(0xFFE2E8F0);
  static const disabled = Color(0xFFCBD5E1);
  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFDC2626);
  static const info = Color(0xFF0EA5E9);
}
```

## Spacing
```dart
class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}
```

## Radius
```dart
class AppRadius {
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const pill = 999.0;
}
```

## Icon Sizes
```dart
class AppIconSize {
  static const sm = 16.0;
  static const md = 20.0;
  static const lg = 24.0;
  static const xl = 32.0;
}
```

## Button Heights
```dart
class AppButtonSize {
  static const normal = 52.0;
  static const large = 56.0;
}
```

## Durations
```dart
class AppDuration {
  static const fast = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 250);
  static const slow = Duration(milliseconds: 350);
}
```

## Typography
عرّف:
```text
displayLarge
titleLarge
titleMedium
bodyLarge
bodyMedium
bodySmall
labelLarge
```

## قاعدة
ممنوع أرقام Styling عشوائية داخل Widgets بدون سبب. استخدم Tokens.
