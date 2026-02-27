# Research: Core Theme System and Shared Widgets

**Feature**: 001-theme-widgets-setup
**Date**: 2026-02-27
**Status**: Complete

## Overview

This document consolidates research findings for implementing a centralized theme system and shared widget library in a multi-app Flutter architecture using GetX state management.

## Research Topics

### 1. Flutter Theme Management with GetX

**Decision**: Use GetX reactive ThemeMode with GetMaterialApp

**Rationale**:
- GetX provides built-in theme switching via `Get.changeTheme()` and `Get.changeThemeMode()`
- GetMaterialApp automatically handles theme updates without manual rebuilds
- ThemeData can be made reactive using `.obs` and accessed globally via Get.theme
- Supports both light/dark themes and custom theme switching logic

**Implementation Approach**:
```dart
// In app initialization
GetMaterialApp(
  theme: AppTheme.lightTheme,
  darkTheme: AppTheme.darkTheme,
  themeMode: ThemeMode.system, // or controlled via GetX controller
)

// For runtime switching
Get.changeThemeMode(ThemeMode.dark);
// OR
Get.changeTheme(AppTheme.customTheme);
```

**Alternatives Considered**:
- Provider + ChangeNotifier: Rejected (violates GetX-only mandate from CLAUDE.md)
- Manual InheritedWidget: Rejected (GetX provides better DX and less boilerplate)
- Riverpod: Rejected (violates GetX-only mandate)

**References**:
- GetX Theme Documentation: https://pub.dev/packages/get#theme
- Flutter ThemeData API: https://api.flutter.dev/flutter/material/ThemeData-class.html

---

### 2. Typography: Google Fonts vs Local Fonts for Arabic

**Decision**: Use google_fonts package with fallback to local assets

**Rationale**:
- google_fonts package handles font downloading and caching automatically
- Supports Arabic fonts (Cairo) with proper RTL rendering
- Can fallback to bundled fonts if network unavailable (offline support)
- Reduces initial app bundle size (fonts loaded on-demand, then cached)
- Simpler API: `GoogleFonts.cairo()` vs manual TextStyle configuration

**Implementation Approach**:
```dart
// In app_theme.dart
TextTheme buildTextTheme(Locale locale) {
  if (locale.languageCode == 'ar') {
    return GoogleFonts.cairoTextTheme();
  } else {
    return GoogleFonts.plusJakartaSansTextTheme();
  }
}

// With offline fallback
GoogleFonts.config.allowRuntimeFetching = true;
```

**Alternatives Considered**:
- Bundle fonts in assets/: Rejected (increases APK size, manual font management)
- Use system fonts only: Rejected (no design consistency across devices)
- flutter_localizations default fonts: Rejected (doesn't match design specs)

**Considerations**:
- Include font license files in assets/ for compliance
- Pre-cache fonts during splash screen for offline use
- Font weights needed: 300, 400, 500, 600, 700, 800

**References**:
- google_fonts package: https://pub.dev/packages/google_fonts
- Cairo font: https://fonts.google.com/specimen/Cairo
- Plus Jakarta Sans: https://fonts.google.com/specimen/Plus+Jakarta+Sans

---

### 3. RTL Layout Best Practices in Flutter

**Decision**: Use Directionality widget at app root + MediaQuery.of(context).textDirection checks

**Rationale**:
- Flutter's Directionality widget automatically flips layouts for RTL
- Most Material widgets (Row, Column, Align, etc.) respect text direction
- Icons and asymmetric layouts need manual flipping via direction checks
- GetX locale management integrates seamlessly with Directionality

**Implementation Approach**:
```dart
// App root
GetMaterialApp(
  locale: Get.locale, // Reactive locale from GetX
  builder: (context, child) {
    return Directionality(
      textDirection: Get.locale?.languageCode == 'ar'
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: child!,
    );
  },
)

// In custom widgets with asymmetric layouts
final isRtl = Directionality.of(context) == TextDirection.rtl;
return Row(
  children: [
    if (!isRtl) leadingIcon,
    Text('...'),
    if (isRtl) leadingIcon,
  ],
);
```

**Alternatives Considered**:
- Manually flip every widget: Rejected (error-prone, doesn't scale)
- Use Intl.defaultLocale: Rejected (GetX provides better integration)
- Separate RTL/LTR widget trees: Rejected (code duplication)

**Testing Strategy**:
- Golden tests with RTL locale to catch layout issues
- Test all custom widgets in both directions
- Verify icon rotation (arrows, back buttons) flips correctly

**References**:
- Flutter RTL Guide: https://docs.flutter.dev/development/accessibility-and-localization/internationalization#directionality-and-locale-awareness
- Material Design RTL: https://m2.material.io/design/usability/bidirectionality.html

---

### 4. Visual Regression Testing with Golden Tests

**Decision**: Use flutter_test golden files with goldens/ directory structure

**Rationale**:
- Built into flutter_test, no additional dependencies
- Captures pixel-perfect snapshots of widgets
- Detects unintended visual changes in themes/widgets
- Critical for theme system (color changes affect entire app)

**Implementation Approach**:
```dart
testWidgets('AppButton matches golden in light mode', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: AppButton(
          text: 'Test Button',
          onPressed: () {},
        ),
      ),
    ),
  );

  await expectLater(
    find.byType(AppButton),
    matchesGoldenFile('goldens/app_button_light.png'),
  );
});
```

**Directory Structure**:
```
test/
└── core/
    └── widgets/
        ├── goldens/
        │   ├── app_button_light.png
        │   ├── app_button_dark.png
        │   ├── app_button_rtl.png
        │   └── ...
        └── app_button_test.dart
```

**Alternatives Considered**:
- alchemist package: Rejected (adds dependency, built-in goldens sufficient)
- screenshot testing libraries: Rejected (overcomplicated for widget tests)
- Manual visual QA only: Rejected (doesn't scale, error-prone)

**Workflow**:
1. Generate initial goldens: `flutter test --update-goldens`
2. Run tests normally: `flutter test` (compares against goldens)
3. Review diffs when tests fail (intentional changes vs regressions)
4. Update goldens after approved design changes

**References**:
- Golden File Testing: https://docs.flutter.dev/cookbook/testing/widget/golden-files
- flutter_test API: https://api.flutter.dev/flutter/flutter_test/matchesGoldenFile.html

---

### 5. Multi-App Initialization Patterns in Flutter

**Decision**: Shared core initialization function + app-specific config injected

**Rationale**:
- Reduces code duplication across three entry points
- Centralizes Firebase, GetX, and localization setup
- Allows app-specific routes and controllers to be injected
- Easier to maintain and test initialization logic

**Implementation Approach**:
```dart
// lib/core/services/firebase_service.dart
class FirebaseService {
  static Future<void> initialize() async {
    await Firebase.initializeApp();
  }
}

// lib/core/app_initializer.dart
class AppInitializer {
  static Future<void> init({
    required Widget Function() appBuilder,
    required String appName,
  }) async {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Firebase
    await FirebaseService.initialize();

    // Register global controllers
    Get.put(AuthController(), permanent: true);

    // Run app
    runApp(appBuilder());
  }
}

// lib/main_customer.dart
void main() async {
  await AppInitializer.init(
    appName: 'BikeRide Customer',
    appBuilder: () => CustomerApp(),
  );
}

// lib/main_driver.dart
void main() async {
  await AppInitializer.init(
    appName: 'BikeRide Driver',
    appBuilder: () => DriverApp(),
  );
}
```

**Alternatives Considered**:
- Duplicate initialization in each main: Rejected (violates DRY, hard to maintain)
- Single entry point with runtime switching: Rejected (complicates builds, increases bundle size)
- Flavors with build configs: Considered for future (currently using separate entry points for clarity)

**Benefits**:
- Consistent initialization across all apps
- Easy to add new global services or controllers
- Testable initialization logic (can mock Firebase, etc.)
- Clear separation between shared core and app-specific code

**References**:
- Flutter multi-flavor setup: https://docs.flutter.dev/deployment/flavors
- Firebase initialization: https://firebase.google.com/docs/flutter/setup

---

### 6. Color System Organization

**Decision**: Use ColorScheme with custom extensions for semantic colors

**Rationale**:
- Flutter's ColorScheme integrates with Material widgets automatically
- Extensions allow adding custom semantic colors (e.g., neutral tint, success, error)
- Type-safe access: `Theme.of(context).colorScheme.primary`
- Supports light/dark mode out of the box

**Implementation Approach**:
```dart
// In app_theme.dart
class AppTheme {
  static const Color primaryRed = Color(0xFFE0062E);
  static const Color primaryDark = Color(0xFFB00423);
  static const Color backgroundLight = Color(0xFFF8F5F6);
  static const Color backgroundDark = Color(0xFF230F13);
  static const Color neutralTint = Color(0xFFFCECEE);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: primaryRed,
      secondary: primaryDark,
      surface: backgroundLight,
      background: backgroundLight,
      // ... additional colors
    ).copyWith(
      // Custom semantic colors via extension
      surfaceTint: neutralTint,
    ),
  );
}
```

**Alternatives Considered**:
- Raw Color constants everywhere: Rejected (not reactive, hard to theme)
- Custom theme class ignoring ColorScheme: Rejected (loses Material widget integration)
- Theme extensions only: Considered (might use for additional semantic colors)

**References**:
- ColorScheme documentation: https://api.flutter.dev/flutter/material/ColorScheme-class.html
- Material 3 theming: https://m3.material.io/styles/color/overview

---

### 7. Widget Library API Design

**Decision**: Consistent prop names, required callbacks, optional variants

**Rationale**:
- Consistent API across all shared widgets improves DX
- Required `onPressed` for buttons prevents accidental no-op buttons
- Optional variants (primary, secondary, outline) via enum parameter
- All widgets support loading state where applicable

**API Conventions**:
```dart
// AppButton
AppButton({
  required String text,
  required VoidCallback? onPressed, // null = disabled
  ButtonVariant variant = ButtonVariant.primary,
  bool isLoading = false,
  IconData? leadingIcon,
  IconData? trailingIcon,
})

// AppTextField
AppTextField({
  required TextEditingController controller,
  String? label,
  String? hint,
  String? errorText,
  IconData? prefixIcon,
  IconData? suffixIcon,
  bool obscureText = false,
  TextInputType keyboardType = TextInputType.text,
  String? Function(String?)? validator,
})

// AppCard
AppCard({
  required Widget child,
  VoidCallback? onTap,
  EdgeInsets padding = const EdgeInsets.all(16),
  double elevation = 2,
})
```

**Benefits**:
- Predictable API (developers learn once, use everywhere)
- Type safety (required fields catch errors at compile time)
- Extensible (easy to add new optional parameters)
- Consistent with Material widget conventions

**References**:
- Flutter API design guidelines: https://github.com/flutter/flutter/wiki/Style-guide-for-Flutter-repo

---

## Summary

All research topics resolved. Key decisions:
1. ✅ GetX for reactive theme management
2. ✅ google_fonts package for Cairo + Plus Jakarta Sans
3. ✅ Directionality widget for RTL support
4. ✅ Golden tests for visual regression
5. ✅ Shared initialization function for multi-app
6. ✅ ColorScheme with extensions for color system
7. ✅ Consistent widget API conventions

No blockers identified. Ready to proceed to Phase 1: Data Model & Contracts.
