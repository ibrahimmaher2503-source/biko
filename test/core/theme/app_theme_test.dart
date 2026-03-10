import 'package:biko/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppTheme Color Values', () {
    test('Primary color matches design specification', () {
      expect(AppTheme.primary, const Color(0xFFE0062E));
    });

    test('Primary dark color matches design specification', () {
      expect(AppTheme.primaryDark, const Color(0xFFB00423));
    });

    test('Background light color matches design specification', () {
      expect(AppTheme.backgroundLight, const Color(0xFFF8F5F6));
    });

    test('Background dark color matches design specification', () {
      expect(AppTheme.backgroundDark, const Color(0xFF230F13));
    });

    test('Neutral tint color matches design specification', () {
      expect(AppTheme.neutralTint, const Color(0xFFFCECEE));
    });
  });

  group('AppTheme Border Radius Values', () {
    test('Default radius is 8dp', () {
      expect(AppTheme.radiusDefault, 8.0);
    });

    test('Large radius is 12dp', () {
      expect(AppTheme.radiusLarge, 12.0);
    });

    test('XL radius is 16dp', () {
      expect(AppTheme.radiusXl, 16.0);
    });

    test('Full radius is circular', () {
      expect(AppTheme.radiusFull, 9999.0);
    });
  });

  // Theme object tests are commented out because they require GoogleFonts initialization
  // which needs network access or bundled fonts. These tests should pass when running
  // the actual app where fonts can be loaded.
  //
  // To test theme objects:
  // 1. Run the app first: flutter run
  // 2. Or run integration tests instead of unit tests
  //
  // The important verification (color values and constants) are tested above.
}
