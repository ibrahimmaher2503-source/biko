import 'package:biko/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Golden test helper utilities for visual regression testing.
///
/// This helper simplifies testing widgets across:
/// - Light and dark themes
/// - RTL (Arabic) and LTR (English) layouts
/// - Multiple screen sizes (responsive design)
///
/// Golden tests capture reference screenshots and compare them against
/// future renders to catch unintended visual regressions.
class GoldenTestHelper {
  /// Test widget in light theme.
  ///
  /// Captures a golden image in `test/core/widgets/goldens/light/{filename}.png`
  ///
  /// Example:
  /// ```dart
  /// await GoldenTestHelper.testLightTheme(
  ///   tester,
  ///   AppButton(text: 'Press Me', onPressed: () {}),
  ///   'app_button_primary',
  /// );
  /// ```
  static Future<void> testLightTheme(
    WidgetTester tester,
    Widget widget,
    String filename,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(body: widget),
      ),
    );

    await expectLater(
      find.byWidget(widget),
      matchesGoldenFile('goldens/light/$filename.png'),
    );
  }

  /// Test widget in dark theme.
  ///
  /// Captures a golden image in `test/core/widgets/goldens/dark/{filename}.png`
  ///
  /// Example:
  /// ```dart
  /// await GoldenTestHelper.testDarkTheme(
  ///   tester,
  ///   AppButton(text: 'Press Me', onPressed: () {}),
  ///   'app_button_primary',
  /// );
  /// ```
  static Future<void> testDarkTheme(
    WidgetTester tester,
    Widget widget,
    String filename,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        home: Scaffold(body: widget),
      ),
    );

    await expectLater(
      find.byWidget(widget),
      matchesGoldenFile('goldens/dark/$filename.png'),
    );
  }

  /// Test widget in RTL (Arabic) layout.
  ///
  /// Captures a golden image in `test/core/widgets/goldens/rtl/{filename}.png`
  ///
  /// Verifies:
  /// - Text direction is right-to-left
  /// - Directional icons flip correctly
  /// - Layouts adapt to RTL properly
  ///
  /// Example:
  /// ```dart
  /// await GoldenTestHelper.testRTL(
  ///   tester,
  ///   AppButton(
  ///     text: 'اضغط عليّ',
  ///     onPressed: () {},
  ///     leadingIcon: Icons.arrow_forward,
  ///   ),
  ///   'app_button_primary_rtl',
  /// );
  /// ```
  static Future<void> testRTL(
    WidgetTester tester,
    Widget widget,
    String filename,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        locale: const Locale('ar'),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(body: widget),
        ),
      ),
    );

    await expectLater(
      find.byWidget(widget),
      matchesGoldenFile('goldens/rtl/$filename.png'),
    );
  }

  /// Test widget at multiple screen sizes (responsive design).
  ///
  /// Captures golden images for each size:
  /// `test/core/widgets/goldens/responsive/{filename}_{width}x{height}.png`
  ///
  /// Example:
  /// ```dart
  /// await GoldenTestHelper.testResponsive(
  ///   tester,
  ///   AppButton(text: 'Press Me', onPressed: () {}),
  ///   'app_button_primary',
  ///   [
  ///     const Size(360, 800),  // Small phone
  ///     const Size(768, 1024), // Tablet
  ///   ],
  /// );
  /// ```
  static Future<void> testResponsive(
    WidgetTester tester,
    Widget widget,
    String filename,
    List<Size> sizes,
  ) async {
    for (final size in sizes) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(body: widget),
        ),
      );

      await expectLater(
        find.byWidget(widget),
        matchesGoldenFile(
          'goldens/responsive/${filename}_${size.width.toInt()}x${size.height.toInt()}.png',
        ),
      );
    }
  }
}
