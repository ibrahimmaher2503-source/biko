// Basic smoke test verifying core app components exist.
//
// Note: Full CustomerApp cannot be tested without Firebase initialization.
// For app entry tests, see test/integration/app_entry_test.dart.

import 'package:biko/core/routes/app_routes.dart';
import 'package:biko/core/routes/customer_pages.dart';
import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/translations/app_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Verify core components are accessible
    expect(AppTheme.lightTheme, isA<ThemeData>());
    expect(AppTheme.darkTheme, isA<ThemeData>());
    expect(AppTranslations().keys, isNotEmpty);
    expect(CustomerPages.pages, isNotEmpty);
    expect(AppRoutes.splash, isNotEmpty);
  });
}
