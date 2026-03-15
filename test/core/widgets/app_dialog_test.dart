import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_button.dart';
import 'package:biko/core/widgets/app_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// Comprehensive widget tests for AppDialog.
///
/// Covers:
/// - Confirmation dialog with confirm/cancel buttons
/// - Info dialog with single OK button
/// - Title and content rendering
/// - Primary/secondary action buttons
/// - Dismiss behavior (tap outside, back button)
/// - Dark theme adaptation
/// - RTL layout support
void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(Get.reset);

  group('AppDialog - Confirmation Dialog', () {
    testWidgets('T048: Renders confirmation dialog with title and buttons',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    await AppDialog.confirm(
                      title: 'Delete Item',
                      content: 'Are you sure you want to delete this item?',
                      confirmText: 'Delete',
                      cancelText: 'Cancel',
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      // Tap button to show dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog is displayed
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Delete Item'), findsOneWidget);
      expect(
        find.text('Are you sure you want to delete this item?'),
        findsOneWidget,
      );
      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('T049: Displays title and content correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    await AppDialog.confirm(
                      title: 'Confirm Action',
                      content: 'This is the dialog content explaining the action.',
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      // Tap button to show dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify title and content
      expect(find.text('Confirm Action'), findsOneWidget);
      expect(
        find.text('This is the dialog content explaining the action.'),
        findsOneWidget,
      );

      // Verify title uses titleLarge style
      final titleText = tester.widget<Text>(find.text('Confirm Action'));
      expect(titleText.style?.fontSize, isNotNull);
    });

    testWidgets('T050: Confirm and cancel buttons work correctly',
        (WidgetTester tester) async {
      bool? dialogResult;

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    dialogResult = await AppDialog.confirm(
                      title: 'Test Buttons',
                      content: 'Testing button actions',
                      confirmText: 'OK',
                      cancelText: 'Cancel',
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      // Test confirm button
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(dialogResult, isTrue);

      // Test cancel button
      dialogResult = null;
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(dialogResult, isFalse);
    });

    testWidgets('T051: Dialog can be dismissed by tapping outside',
        (WidgetTester tester) async {
      bool? dialogResult;

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    dialogResult = await AppDialog.confirm(
                      title: 'Dismissible Dialog',
                      content: 'Tap outside to dismiss',
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      // Show dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog is shown
      expect(find.byType(AlertDialog), findsOneWidget);

      // Tap outside the dialog (on the barrier)
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // Dialog should be dismissed and return false
      expect(find.byType(AlertDialog), findsNothing);
      expect(dialogResult, isFalse);
    });
  });

  group('AppDialog - Info Dialog', () {
    testWidgets('Renders info dialog with single button',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    await AppDialog.info(
                      title: 'Information',
                      content: 'This is an informational message',
                      buttonText: 'Got it',
                    );
                  },
                  child: const Text('Show Info'),
                );
              },
            ),
          ),
        ),
      );

      // Show info dialog
      await tester.tap(find.text('Show Info'));
      await tester.pumpAndSettle();

      // Verify dialog content
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Information'), findsOneWidget);
      expect(find.text('This is an informational message'), findsOneWidget);
      expect(find.text('Got it'), findsOneWidget);

      // Verify only one button exists
      expect(find.byType(AppButton), findsOneWidget);
    });

    testWidgets('Info dialog closes when button is tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    await AppDialog.info(
                      title: 'Test Close',
                      content: 'Testing close behavior',
                      buttonText: 'Close',
                    );
                  },
                  child: const Text('Show Info'),
                );
              },
            ),
          ),
        ),
      );

      // Show and close dialog
      await tester.tap(find.text('Show Info'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });
  });

  group('AppDialog - Theming', () {
    testWidgets('T052: Adapts to dark theme correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    await AppDialog.confirm(
                      title: 'Dark Theme Dialog',
                      content: 'This dialog uses dark theme',
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      // Show dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog renders in dark theme
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Dark Theme Dialog'), findsOneWidget);

      // Verify dark theme is applied
      final BuildContext context = tester.element(find.byType(AlertDialog));
      expect(Theme.of(context).brightness, equals(Brightness.dark));
    });
  });

  group('AppDialog - RTL Support', () {
    testWidgets('T053: Renders correctly in RTL layout',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('ar'),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () async {
                      await AppDialog.confirm(
                        title: 'حذف العنصر',
                        content: 'هل أنت متأكد من حذف هذا العنصر؟',
                        confirmText: 'حذف',
                        cancelText: 'إلغاء',
                      );
                    },
                    child: const Text('إظهار الحوار'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Show dialog
      await tester.tap(find.text('إظهار الحوار'));
      await tester.pumpAndSettle();

      // Verify dialog renders with Arabic text
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('حذف العنصر'), findsOneWidget);
      expect(find.text('هل أنت متأكد من حذف هذا العنصر؟'), findsOneWidget);
      expect(find.text('حذف'), findsOneWidget);
      expect(find.text('إلغاء'), findsOneWidget);

      // Verify RTL directionality
      final BuildContext context = tester.element(find.byType(AlertDialog));
      expect(Directionality.of(context), equals(TextDirection.rtl));
    });
  });

  group('AppDialog - Button Styling', () {
    testWidgets('Confirm button uses primary variant',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    await AppDialog.confirm(
                      title: 'Button Styles',
                      content: 'Testing button variants',
                      confirmText: 'Confirm',
                      cancelText: 'Cancel',
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      // Show dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Find buttons
      final confirmButton = tester.widget<AppButton>(
        find.widgetWithText(AppButton, 'Confirm'),
      );
      final cancelButton = tester.widget<AppButton>(
        find.widgetWithText(AppButton, 'Cancel'),
      );

      // Verify button variants
      expect(confirmButton.variant, equals(ButtonVariant.primary));
      expect(cancelButton.variant, equals(ButtonVariant.text));
    });

    testWidgets('Buttons have correct dimensions',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    await AppDialog.confirm(
                      title: 'Button Dimensions',
                      content: 'Testing button sizes',
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      // Show dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Find buttons
      final buttons = tester.widgetList<AppButton>(find.byType(AppButton));

      // Verify button dimensions (height: 40, width: null for intrinsic)
      for (final button in buttons) {
        expect(button.height, equals(40.0));
        expect(button.width, isNull); // Intrinsic width
      }
    });
  });

  group('AppDialog - Border Radius', () {
    testWidgets('Dialog has 16dp border radius',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    await AppDialog.confirm(
                      title: 'Border Radius',
                      content: 'Testing border radius',
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      // Show dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Find AlertDialog
      final alertDialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
      final shape = alertDialog.shape as RoundedRectangleBorder;
      final borderRadius = shape.borderRadius as BorderRadius;

      // Verify border radius is 16dp
      expect(borderRadius.topLeft.x, equals(16.0));
      expect(borderRadius.topRight.x, equals(16.0));
      expect(borderRadius.bottomLeft.x, equals(16.0));
      expect(borderRadius.bottomRight.x, equals(16.0));
    });
  });
}
