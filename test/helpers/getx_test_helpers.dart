import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/translations/app_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// GetX test helper utilities for setting up and cleaning up GetX state in tests.
///
/// This helper provides methods to:
/// - Enable GetX test mode
/// - Reset GetX instances between tests
/// - Pump widgets wrapped in GetMaterialApp with BikeRide theme
/// - Register mock services for isolated testing
class GetXTestHelper {
  /// Enables GetX test mode (disables logging, makes behavior deterministic).
  ///
  /// MUST be called in setUp() of every GetX test.
  static void setup() {
    Get.testMode = true;
  }

  /// Resets all GetX instances and bindings.
  ///
  /// MUST be called in tearDown() of every GetX test to prevent state leakage.
  static void cleanup() {
    Get.reset();
  }

  /// Pumps a widget wrapped in GetMaterialApp with BikeRide theme and translations.
  ///
  /// This ensures widgets are tested in the same environment as the real app:
  /// - GetX navigation and state management available
  /// - BikeRide theme applied (light/dark mode support)
  /// - Arabic/English translations loaded
  /// - Proper directionality for RTL testing
  ///
  /// Example:
  /// ```dart
  /// await GetXTestHelper.pumpApp(
  ///   tester,
  ///   HomeScreen(),
  ///   locale: const Locale('ar'), // Test in Arabic
  ///   themeMode: ThemeMode.dark,  // Test in dark mode
  /// );
  /// ```
  static Future<void> pumpApp(
    WidgetTester tester,
    Widget child, {
    ThemeMode? themeMode,
    Locale? locale,
    List<GetPage>? pages,
  }) async {
    final effectiveLocale = locale ?? const Locale('ar');

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.getThemeWithLocale(effectiveLocale),
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode ?? ThemeMode.light,
        locale: effectiveLocale,
        translations: AppTranslations(),
        getPages: pages,
        home: Scaffold(body: child),
      ),
    );
  }

  /// Registers all mock services (Auth, Firestore, Location) for isolated testing.
  ///
  /// This replaces real Firebase services with mocks, enabling:
  /// - Offline testing without Firebase backend
  /// - Deterministic test behavior
  /// - Fast test execution
  ///
  /// Call this in setUp() before creating controllers that depend on services.
  ///
  /// Example:
  /// ```dart
  /// setUp(() {
  ///   GetXTestHelper.setup();
  ///   GetXTestHelper.registerMockServices();
  ///   controller = AuthController(); // Uses mock services
  /// });
  /// ```
  static void registerMockServices() {
    // Note: Actual service registration will be implemented once mock services are created.
    // For now, this is a placeholder that will be filled in as services are created.
    // Example implementation:
    // Get.lazyPut<AuthService>(() => MockAuthService());
    // Get.lazyPut<FirestoreService>(() => MockFirestoreService());
    // Get.lazyPut<LocationService>(() => MockLocationService());
  }
}
