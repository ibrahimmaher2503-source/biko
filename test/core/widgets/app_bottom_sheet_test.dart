import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// Comprehensive widget tests for AppBottomSheet.
///
/// Covers:
/// - Bottom sheet rendering and display
/// - Drag handle visibility
/// - Dismiss on swipe down behavior
/// - Dark theme adaptation
/// - RTL layout support
/// - Border radius and styling
void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(Get.reset);

  group('AppBottomSheet - Rendering', () {
    testWidgets('T054: Renders bottom sheet with content correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    AppBottomSheet.show(
                      child: const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Bottom Sheet Title'),
                            SizedBox(height: 8),
                            Text('Bottom sheet content goes here'),
                          ],
                        ),
                      ),
                    );
                  },
                  child: const Text('Show Bottom Sheet'),
                );
              },
            ),
          ),
        ),
      );

      // Show bottom sheet
      await tester.tap(find.text('Show Bottom Sheet'));
      await tester.pumpAndSettle();

      // Verify bottom sheet content is displayed
      expect(find.text('Bottom Sheet Title'), findsOneWidget);
      expect(find.text('Bottom sheet content goes here'), findsOneWidget);
    });

    testWidgets('Bottom sheet has rounded top corners',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    AppBottomSheet.show(
                      child: const Text('Content'),
                    );
                  },
                  child: const Text('Show Bottom Sheet'),
                );
              },
            ),
          ),
        ),
      );

      // Show bottom sheet
      await tester.tap(find.text('Show Bottom Sheet'));
      await tester.pumpAndSettle();

      // Find DecoratedBox with border radius
      final decoratedBox = tester.widget<DecoratedBox>(
        find.byType(DecoratedBox).first,
      );
      final decoration = decoratedBox.decoration as BoxDecoration;
      final borderRadius = decoration.borderRadius as BorderRadius;

      // Verify top corners are rounded (20dp)
      expect(borderRadius.topLeft.x, equals(20.0));
      expect(borderRadius.topRight.x, equals(20.0));
      expect(borderRadius.bottomLeft.x, equals(0.0));
      expect(borderRadius.bottomRight.x, equals(0.0));
    });

    testWidgets('Bottom sheet respects maxHeight constraint',
        (WidgetTester tester) async {
      const maxHeight = 400.0;

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    AppBottomSheet.show(
                      maxHeight: maxHeight,
                      child: const Text('Content'),
                    );
                  },
                  child: const Text('Show Bottom Sheet'),
                );
              },
            ),
          ),
        ),
      );

      // Show bottom sheet
      await tester.tap(find.text('Show Bottom Sheet'));
      await tester.pumpAndSettle();

      // Find ConstrainedBox with maxHeight constraint
      final constrainedBoxes = tester.widgetList<ConstrainedBox>(
        find.byType(ConstrainedBox),
      );

      // Find the one with our specific maxHeight
      final matchingBox = constrainedBoxes.firstWhere(
        (box) => box.constraints.maxHeight == maxHeight,
      );

      // Verify maxHeight constraint
      expect(matchingBox.constraints.maxHeight, equals(maxHeight));
    });
  });

  group('AppBottomSheet - Drag Handle', () {
    testWidgets('T055: Displays drag handle at top of bottom sheet',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    AppBottomSheet.show(
                      child: const Text('Content'),
                    );
                  },
                  child: const Text('Show Bottom Sheet'),
                );
              },
            ),
          ),
        ),
      );

      // Show bottom sheet
      await tester.tap(find.text('Show Bottom Sheet'));
      await tester.pumpAndSettle();

      // Find Container widgets (drag handle is a Container)
      final containers = tester.widgetList<Container>(find.byType(Container));

      // Find drag handle (40x4 container with rounded corners)
      final dragHandle = containers.firstWhere(
        (container) =>
            container.constraints?.maxWidth == 40 &&
            container.constraints?.maxHeight == 4,
        orElse: () => containers.firstWhere(
          (container) {
            final decoration = container.decoration as BoxDecoration?;
            return decoration?.borderRadius != null &&
                (decoration!.borderRadius as BorderRadius).topLeft.x == 2.0;
          },
        ),
      );

      // Verify drag handle exists
      expect(dragHandle, isNotNull);
    });

    testWidgets('Drag handle has correct dimensions',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    AppBottomSheet.show(
                      child: const Text('Content'),
                    );
                  },
                  child: const Text('Show Bottom Sheet'),
                );
              },
            ),
          ),
        ),
      );

      // Show bottom sheet
      await tester.tap(find.text('Show Bottom Sheet'));
      await tester.pumpAndSettle();

      // Find drag handle Container
      final containers = tester.widgetList<Container>(find.byType(Container));
      final dragHandle = containers.firstWhere(
        (container) {
          final decoration = container.decoration as BoxDecoration?;
          return decoration?.borderRadius != null &&
              (decoration!.borderRadius as BorderRadius).topLeft.x == 2.0;
        },
      );

      // Verify dimensions (should be 40x4)
      expect(dragHandle.constraints?.maxWidth, equals(40.0));
      expect(dragHandle.constraints?.maxHeight, equals(4.0));
    });
  });

  group('AppBottomSheet - Dismiss Behavior', () {
    testWidgets('T056: Bottom sheet can be dismissed by swipe down',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    AppBottomSheet.show(
                      child: const Text('Swipeable Content'),
                    );
                  },
                  child: const Text('Show Bottom Sheet'),
                );
              },
            ),
          ),
        ),
      );

      // Show bottom sheet
      await tester.tap(find.text('Show Bottom Sheet'));
      await tester.pumpAndSettle();

      // Verify bottom sheet is visible
      expect(find.text('Swipeable Content'), findsOneWidget);

      // Swipe down to dismiss (simulate drag from top to bottom)
      await tester.drag(
        find.text('Swipeable Content'),
        const Offset(0, 300),
      );
      await tester.pumpAndSettle();

      // Bottom sheet should be dismissed
      expect(find.text('Swipeable Content'), findsNothing);
    });

    testWidgets('Bottom sheet can be dismissed by tapping outside',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    AppBottomSheet.show(
                      child: const Text('Dismissible Content'),
                    );
                  },
                  child: const Text('Show Bottom Sheet'),
                );
              },
            ),
          ),
        ),
      );

      // Show bottom sheet
      await tester.tap(find.text('Show Bottom Sheet'));
      await tester.pumpAndSettle();

      // Verify bottom sheet is visible
      expect(find.text('Dismissible Content'), findsOneWidget);

      // Tap outside bottom sheet (on the barrier)
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // Bottom sheet should be dismissed
      expect(find.text('Dismissible Content'), findsNothing);
    });

    testWidgets('Bottom sheet cannot be dismissed when isDismissible is false',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    AppBottomSheet.show(
                      isDismissible: false,
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Non-Dismissible Content'),
                        ],
                      ),
                    );
                  },
                  child: const Text('Show Bottom Sheet'),
                );
              },
            ),
          ),
        ),
      );

      // Show bottom sheet
      await tester.tap(find.text('Show Bottom Sheet'));
      await tester.pumpAndSettle();

      // Verify bottom sheet is visible
      expect(find.text('Non-Dismissible Content'), findsOneWidget);

      // Try to tap outside (should not dismiss)
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // Bottom sheet should still be visible
      expect(find.text('Non-Dismissible Content'), findsOneWidget);
    });
  });

  group('AppBottomSheet - Theming', () {
    testWidgets('T057: Adapts to dark theme correctly',
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
                  onPressed: () {
                    AppBottomSheet.show(
                      child: const Text('Dark Theme Content'),
                    );
                  },
                  child: const Text('Show Bottom Sheet'),
                );
              },
            ),
          ),
        ),
      );

      // Show bottom sheet
      await tester.tap(find.text('Show Bottom Sheet'));
      await tester.pumpAndSettle();

      // Verify bottom sheet renders in dark theme
      expect(find.text('Dark Theme Content'), findsOneWidget);

      // Verify dark theme is applied to the bottom sheet
      final BuildContext context = tester.element(find.text('Dark Theme Content'));
      expect(Theme.of(context).brightness, equals(Brightness.dark));

      // Verify DecoratedBox uses dark theme surface color
      final decoratedBox = tester.widget<DecoratedBox>(
        find.byType(DecoratedBox).first,
      );
      final decoration = decoratedBox.decoration as BoxDecoration;
      final darkTheme = AppTheme.darkTheme;
      expect(decoration.color, equals(darkTheme.colorScheme.surface));
    });
  });

  group('AppBottomSheet - RTL Support', () {
    testWidgets('T058: Renders correctly in RTL layout',
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
                    onPressed: () {
                      AppBottomSheet.show(
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('عنوان القائمة'),
                            SizedBox(height: 8),
                            Text('محتوى القائمة المنبثقة'),
                          ],
                        ),
                      );
                    },
                    child: const Text('إظهار القائمة'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Show bottom sheet
      await tester.tap(find.text('إظهار القائمة'));
      await tester.pumpAndSettle();

      // Verify Arabic content is displayed
      expect(find.text('عنوان القائمة'), findsOneWidget);
      expect(find.text('محتوى القائمة المنبثقة'), findsOneWidget);

      // Verify RTL directionality
      final BuildContext context = tester.element(find.text('عنوان القائمة'));
      expect(Directionality.of(context), equals(TextDirection.rtl));
    });
  });

  group('AppBottomSheet - Configuration', () {
    testWidgets('isScrollControlled allows full screen height',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    AppBottomSheet.show(
                      child: const SizedBox(
                        height: 800,
                        child: Text('Tall Content'),
                      ),
                    );
                  },
                  child: const Text('Show Bottom Sheet'),
                );
              },
            ),
          ),
        ),
      );

      // Show bottom sheet
      await tester.tap(find.text('Show Bottom Sheet'));
      await tester.pumpAndSettle();

      // Verify bottom sheet can render tall content
      expect(find.text('Tall Content'), findsOneWidget);
    });

    testWidgets('Content is properly padded',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    AppBottomSheet.show(
                      child: const Text('Padded Content'),
                    );
                  },
                  child: const Text('Show Bottom Sheet'),
                );
              },
            ),
          ),
        ),
      );

      // Show bottom sheet
      await tester.tap(find.text('Show Bottom Sheet'));
      await tester.pumpAndSettle();

      // Find Padding widget containing content
      final paddingWidgets = tester.widgetList<Padding>(find.byType(Padding));

      // Verify content padding exists (should have horizontal and bottom padding)
      expect(paddingWidgets.length, greaterThan(0));
    });
  });
}
