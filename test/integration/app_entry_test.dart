import 'package:biko/core/routes/admin_pages.dart';
import 'package:biko/core/routes/app_routes.dart';
import 'package:biko/core/routes/customer_pages.dart';
import 'package:biko/core/routes/driver_pages.dart';
import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/translations/app_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(Get.reset);

  // ==================== T-INT-01: Customer App Entry ====================

  group('T-INT-01: Customer app entry test', () {
    test('CustomerPages.pages is non-empty', () {
      final pages = CustomerPages.pages;
      expect(pages, isNotEmpty);
    });

    test('customer demo theme route exists', () {
      final pages = CustomerPages.pages;
      final demoRoute = pages.where((p) => p.name == AppRoutes.demoTheme);
      expect(demoRoute, isNotEmpty);
    });

    testWidgets('customer GetMaterialApp builds without error', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          title: 'BikeRide Customer Test',
          translations: AppTranslations(),
          locale: const Locale('ar'),
          fallbackLocale: const Locale('en'),
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: const Scaffold(body: Text('Customer')),
        ),
      );

      expect(find.text('Customer'), findsOneWidget);
    });
  });

  // ==================== T-INT-02: Driver App Entry ====================

  group('T-INT-02: Driver app entry test', () {
    test('DriverPages.pages is non-empty', () {
      final pages = DriverPages.pages;
      expect(pages, isNotEmpty);
    });

    test('driver demo theme route exists', () {
      final pages = DriverPages.pages;
      final demoRoute = pages.where((p) => p.name == AppRoutes.demoTheme);
      expect(demoRoute, isNotEmpty);
    });

    testWidgets('driver GetMaterialApp builds without error', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          title: 'BikeRide Driver Test',
          translations: AppTranslations(),
          locale: const Locale('ar'),
          fallbackLocale: const Locale('en'),
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: const Scaffold(body: Text('Driver')),
        ),
      );

      expect(find.text('Driver'), findsOneWidget);
    });
  });

  // ==================== T-INT-03: Admin App Entry ====================

  group('T-INT-03: Admin app entry test', () {
    test('AdminPages.pages is non-empty', () {
      final pages = AdminPages.pages;
      expect(pages, isNotEmpty);
    });

    test('admin login route exists', () {
      final pages = AdminPages.pages;
      final loginRoute = pages.where((p) => p.name == AppRoutes.adminLogin);
      expect(loginRoute, isNotEmpty);
    });

    testWidgets('admin GetMaterialApp builds without error', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          title: 'BikeRide Admin Test',
          translations: AppTranslations(),
          locale: const Locale('en'),
          fallbackLocale: const Locale('ar'),
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: const Scaffold(body: Text('Admin')),
        ),
      );

      expect(find.text('Admin'), findsOneWidget);
    });
  });

  // ==================== T-INT-04: Shared Core Module ====================

  group('T-INT-04: Shared core module test', () {
    test('AppRoutes has essential route constants', () {
      // Core routes all apps need
      expect(AppRoutes.splash, isNotEmpty);
    });

    test('AppTheme provides light and dark themes', () {
      expect(AppTheme.lightTheme, isA<ThemeData>());
      expect(AppTheme.darkTheme, isA<ThemeData>());
    });

    test('AppTranslations has ar and en locales', () {
      final translations = AppTranslations();
      expect(translations.keys.containsKey('ar'), isTrue);
      expect(translations.keys.containsKey('en'), isTrue);
    });

    test('all three page registries have unique routes', () {
      final customerRoutes = CustomerPages.pages.map((p) => p.name).toSet();
      final driverRoutes = DriverPages.pages.map((p) => p.name).toSet();
      final adminRoutes = AdminPages.pages.map((p) => p.name).toSet();

      // Each registry should have routes
      expect(customerRoutes, isNotEmpty);
      expect(driverRoutes, isNotEmpty);
      expect(adminRoutes, isNotEmpty);

      // Admin routes should be distinct from customer routes (different prefixes)
      final adminOnly = adminRoutes.difference(customerRoutes);
      expect(adminOnly, isNotEmpty);
    });

    test('themes have Material 3 enabled', () {
      expect(AppTheme.lightTheme.useMaterial3, isTrue);
      expect(AppTheme.darkTheme.useMaterial3, isTrue);
    });
  });
}
