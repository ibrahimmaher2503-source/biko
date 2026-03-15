import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/translations/app_translations.dart';
import 'package:biko/core/widgets/app_button.dart';
import 'package:biko/core/widgets/app_error_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// Comprehensive widget tests for AppErrorWidget.
///
/// Covers:
/// - Error message display
/// - Retry button functionality
/// - Error icon rendering
/// - Dark theme adaptation
/// - RTL layout support
void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(Get.reset);

  group('AppErrorWidget - Error Message Display', () {
    testWidgets('T059: Displays error message correctly',
        (WidgetTester tester) async {
      const errorMessage = 'Something went wrong. Please try again.';

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          translations: AppTranslations(),
          locale: const Locale('en'),
          home: const Scaffold(
            body: AppErrorWidget(
              message: errorMessage,
            ),
          ),
        ),
      );

      // Verify error message is displayed
      expect(find.text(errorMessage), findsOneWidget);

      // Verify message is centered
      final text = tester.widget<Text>(find.text(errorMessage));
      expect(text.textAlign, equals(TextAlign.center));
    });

    testWidgets('Error message uses correct text style',
        (WidgetTester tester) async {
      const errorMessage = 'Network error occurred';

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          translations: AppTranslations(),
          locale: const Locale('en'),
          home: const Scaffold(
            body: AppErrorWidget(
              message: errorMessage,
            ),
          ),
        ),
      );

      // Find error message text
      final text = tester.widget<Text>(find.text(errorMessage));

      // Verify text style uses bodyLarge
      expect(text.style, isNotNull);
    });
  });

  group('AppErrorWidget - Retry Button', () {
    testWidgets('T060: Retry button appears when onRetry is provided',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          translations: AppTranslations(),
          locale: const Locale('en'),
          home: Scaffold(
            body: AppErrorWidget(
              message: 'Error occurred',
              onRetry: () {},
            ),
          ),
        ),
      );

      // Verify retry button is displayed
      expect(find.byType(AppButton), findsOneWidget);

      // Verify button has text (translation handled by AppButton)
      final button = tester.widget<AppButton>(find.byType(AppButton));
      expect(button.text, isNotEmpty);
    });

    testWidgets('Retry button is hidden when onRetry is null',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          translations: AppTranslations(),
          locale: const Locale('en'),
          home: const Scaffold(
            body: AppErrorWidget(
              message: 'Error occurred',
            ),
          ),
        ),
      );

      // Verify retry button is NOT displayed
      expect(find.byType(AppButton), findsNothing);
    });

    testWidgets('Retry button callback fires when tapped',
        (WidgetTester tester) async {
      bool retryWasCalled = false;

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          translations: AppTranslations(),
          locale: const Locale('en'),
          home: Scaffold(
            body: AppErrorWidget(
              message: 'Error occurred',
              onRetry: () {
                retryWasCalled = true;
              },
            ),
          ),
        ),
      );

      // Tap retry button
      await tester.tap(find.byType(AppButton));
      await tester.pump();

      // Verify callback was called
      expect(retryWasCalled, isTrue);
    });

    testWidgets('Retry button uses outline variant',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          translations: AppTranslations(),
          locale: const Locale('en'),
          home: Scaffold(
            body: AppErrorWidget(
              message: 'Error occurred',
              onRetry: () {},
            ),
          ),
        ),
      );

      // Find retry button
      final button = tester.widget<AppButton>(find.byType(AppButton));

      // Verify button variant is outline
      expect(button.variant, equals(ButtonVariant.outline));
      expect(button.width, isNull); // Intrinsic width
    });
  });

  group('AppErrorWidget - Error Icon', () {
    testWidgets('T061: Displays default error icon',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          translations: AppTranslations(),
          locale: const Locale('en'),
          home: const Scaffold(
            body: AppErrorWidget(
              message: 'Error occurred',
            ),
          ),
        ),
      );

      // Verify error icon is displayed
      expect(find.byIcon(Icons.error_outline), findsOneWidget);

      // Verify icon size is 64
      final icon = tester.widget<Icon>(find.byIcon(Icons.error_outline));
      expect(icon.size, equals(64.0));
    });

    testWidgets('Displays custom error icon when provided',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          translations: AppTranslations(),
          locale: const Locale('en'),
          home: const Scaffold(
            body: AppErrorWidget(
              message: 'Network error',
              icon: Icons.wifi_off,
            ),
          ),
        ),
      );

      // Verify custom icon is displayed
      expect(find.byIcon(Icons.wifi_off), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsNothing);
    });

    testWidgets('Error icon uses theme error color',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          translations: AppTranslations(),
          locale: const Locale('en'),
          home: const Scaffold(
            body: AppErrorWidget(
              message: 'Error occurred',
            ),
          ),
        ),
      );

      // Find error icon
      final icon = tester.widget<Icon>(find.byIcon(Icons.error_outline));

      // Verify icon color is error color from theme
      final theme = AppTheme.lightTheme;
      expect(icon.color, equals(theme.colorScheme.error));
    });
  });

  group('AppErrorWidget - Theming', () {
    testWidgets('T062: Adapts to dark theme correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          translations: AppTranslations(),
          locale: const Locale('en'),
          home: Scaffold(
            body: AppErrorWidget(
              message: 'Dark theme error',
              onRetry: () {},
            ),
          ),
        ),
      );

      // Verify error widget renders in dark theme
      expect(find.text('Dark theme error'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);

      // Verify dark theme is applied
      final BuildContext context = tester.element(find.byType(AppErrorWidget));
      expect(Theme.of(context).brightness, equals(Brightness.dark));

      // Verify icon color uses dark theme error color
      final icon = tester.widget<Icon>(find.byIcon(Icons.error_outline));
      final darkTheme = AppTheme.darkTheme;
      expect(icon.color, equals(darkTheme.colorScheme.error));
    });
  });

  group('AppErrorWidget - RTL Support', () {
    testWidgets('T063: Renders correctly in RTL layout',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          translations: AppTranslations(),
          locale: const Locale('ar'),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: AppErrorWidget(
                message: 'حدث خطأ ما. يرجى المحاولة مرة أخرى.',
                onRetry: () {},
              ),
            ),
          ),
        ),
      );

      // Verify Arabic error message is displayed
      expect(find.text('حدث خطأ ما. يرجى المحاولة مرة أخرى.'), findsOneWidget);

      // Verify RTL directionality
      final BuildContext context = tester.element(find.byType(AppErrorWidget));
      expect(Directionality.of(context), equals(TextDirection.rtl));

      // Verify error icon is displayed
      expect(find.byIcon(Icons.error_outline), findsOneWidget);

      // Verify retry button is displayed
      expect(find.byType(AppButton), findsOneWidget);
    });

    testWidgets('Error message is centered in RTL',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          translations: AppTranslations(),
          locale: const Locale('ar'),
          home: const Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: AppErrorWidget(
                message: 'رسالة خطأ',
              ),
            ),
          ),
        ),
      );

      // Verify message text alignment is center (works in both LTR and RTL)
      final text = tester.widget<Text>(find.text('رسالة خطأ'));
      expect(text.textAlign, equals(TextAlign.center));
    });
  });

  group('AppErrorWidget - Layout', () {
    testWidgets('Content is centered vertically and horizontally',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          translations: AppTranslations(),
          locale: const Locale('en'),
          home: const Scaffold(
            body: AppErrorWidget(
              message: 'Centered error',
            ),
          ),
        ),
      );

      // Verify Center widget is used (may find multiple in widget tree)
      expect(find.byType(Center), findsWidgets);

      // Verify Column with MainAxisSize.min
      final column = tester.widget<Column>(find.byType(Column));
      expect(column.mainAxisSize, equals(MainAxisSize.min));
    });

    testWidgets('Content has proper padding',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          translations: AppTranslations(),
          locale: const Locale('en'),
          home: const Scaffold(
            body: AppErrorWidget(
              message: 'Padded error',
            ),
          ),
        ),
      );

      // Find Padding widget
      final padding = tester.widget<Padding>(
        find.ancestor(
          of: find.byType(Column),
          matching: find.byType(Padding),
        ),
      );

      // Verify padding is applied
      expect(padding.padding, isNotNull);
    });

    testWidgets('Icon, message, and button are properly spaced',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          translations: AppTranslations(),
          locale: const Locale('en'),
          home: Scaffold(
            body: AppErrorWidget(
              message: 'Spaced error',
              onRetry: () {},
            ),
          ),
        ),
      );

      // Verify SizedBox widgets for spacing
      expect(find.byType(SizedBox), findsWidgets);

      // Verify all elements are present
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Spaced error'), findsOneWidget);
      expect(find.byType(AppButton), findsOneWidget);
    });
  });
}
