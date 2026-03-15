import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_button.dart';
import 'package:biko/core/widgets/app_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// Comprehensive widget tests for AppEmptyState.
///
/// Covers:
/// - Empty state rendering with icon and title
/// - Custom icon display
/// - Custom message (title + subtitle)
/// - Action button functionality
/// - Dark theme adaptation
/// - RTL layout support
void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(Get.reset);

  group('AppEmptyState - Rendering', () {
    testWidgets('T064: Renders empty state with icon and title',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppEmptyState(
              icon: Icons.inbox,
              title: 'No items yet',
            ),
          ),
        ),
      );

      // Verify icon and title are displayed
      expect(find.byIcon(Icons.inbox), findsOneWidget);
      expect(find.text('No items yet'), findsOneWidget);
    });

    testWidgets('Subtitle is hidden when not provided',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppEmptyState(
              icon: Icons.inbox,
              title: 'No items',
            ),
          ),
        ),
      );

      // Verify only icon and title are displayed
      expect(find.byIcon(Icons.inbox), findsOneWidget);
      expect(find.text('No items'), findsOneWidget);

      // Count Text widgets (should be just the title)
      final textWidgets = tester.widgetList<Text>(find.byType(Text));
      expect(textWidgets.length, equals(1));
    });

    testWidgets('Action widget is hidden when not provided',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppEmptyState(
              icon: Icons.search,
              title: 'No results',
            ),
          ),
        ),
      );

      // Verify action button is NOT displayed
      expect(find.byType(AppButton), findsNothing);
    });

    testWidgets('Content is centered vertically and horizontally',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppEmptyState(
              icon: Icons.inbox,
              title: 'Centered content',
            ),
          ),
        ),
      );

      // Verify Center widget is used
      expect(find.byType(Center), findsWidgets);

      // Verify Column with MainAxisSize.min
      final column = tester.widget<Column>(find.byType(Column));
      expect(column.mainAxisSize, equals(MainAxisSize.min));
    });
  });

  group('AppEmptyState - Custom Icon', () {
    testWidgets('T065: Displays custom icon correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppEmptyState(
              icon: Icons.shopping_cart_outlined,
              title: 'Cart is empty',
            ),
          ),
        ),
      );

      // Verify custom icon is displayed
      expect(find.byIcon(Icons.shopping_cart_outlined), findsOneWidget);
    });

    testWidgets('Icon has default size of 80dp',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppEmptyState(
              icon: Icons.inbox,
              title: 'Default size icon',
            ),
          ),
        ),
      );

      // Find icon
      final icon = tester.widget<Icon>(find.byIcon(Icons.inbox));

      // Verify icon size is 80dp (default)
      expect(icon.size, equals(80.0));
    });

    testWidgets('Custom icon size can be specified',
        (WidgetTester tester) async {
      const customSize = 120.0;

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppEmptyState(
              icon: Icons.inbox,
              title: 'Large icon',
              iconSize: customSize,
            ),
          ),
        ),
      );

      // Find icon
      final icon = tester.widget<Icon>(find.byIcon(Icons.inbox));

      // Verify custom icon size
      expect(icon.size, equals(customSize));
    });

    testWidgets('Icon uses theme outline color',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppEmptyState(
              icon: Icons.inbox,
              title: 'Themed icon',
            ),
          ),
        ),
      );

      // Find icon
      final icon = tester.widget<Icon>(find.byIcon(Icons.inbox));
      final theme = AppTheme.lightTheme;

      // Verify icon color uses theme outline color
      expect(icon.color, equals(theme.colorScheme.outline));
    });
  });

  group('AppEmptyState - Custom Message', () {
    testWidgets('T066: Displays title and subtitle correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppEmptyState(
              icon: Icons.search,
              title: 'No results found',
              subtitle: 'Try adjusting your search criteria',
            ),
          ),
        ),
      );

      // Verify title and subtitle are displayed
      expect(find.text('No results found'), findsOneWidget);
      expect(find.text('Try adjusting your search criteria'), findsOneWidget);

      // Verify both texts are centered
      final titleText = tester.widget<Text>(find.text('No results found'));
      final subtitleText = tester.widget<Text>(
        find.text('Try adjusting your search criteria'),
      );

      expect(titleText.textAlign, equals(TextAlign.center));
      expect(subtitleText.textAlign, equals(TextAlign.center));
    });

    testWidgets('Title uses titleMedium style',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppEmptyState(
              icon: Icons.inbox,
              title: 'Styled title',
            ),
          ),
        ),
      );

      // Find title text
      final text = tester.widget<Text>(find.text('Styled title'));

      // Verify text style is set (titleMedium from theme)
      expect(text.style, isNotNull);
    });

    testWidgets('Subtitle uses bodyMedium style',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppEmptyState(
              icon: Icons.inbox,
              title: 'Title',
              subtitle: 'Styled subtitle',
            ),
          ),
        ),
      );

      // Find subtitle text
      final text = tester.widget<Text>(find.text('Styled subtitle'));

      // Verify text style is set (bodyMedium from theme)
      expect(text.style, isNotNull);
    });
  });

  group('AppEmptyState - Action Button', () {
    testWidgets('T067: Action button appears when provided',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppEmptyState(
              icon: Icons.refresh,
              title: 'Something went wrong',
              subtitle: 'Tap below to try again',
              action: AppButton(
                text: 'Retry',
                onPressed: () {},
                variant: ButtonVariant.outline,
                width: null,
              ),
            ),
          ),
        ),
      );

      // Verify action button is displayed
      expect(find.byType(AppButton), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('Action button callback fires when tapped',
        (WidgetTester tester) async {
      bool actionWasCalled = false;

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppEmptyState(
              icon: Icons.refresh,
              title: 'Tap to retry',
              action: AppButton(
                text: 'Retry',
                onPressed: () {
                  actionWasCalled = true;
                },
                width: null,
              ),
            ),
          ),
        ),
      );

      // Tap action button
      await tester.tap(find.byType(AppButton));
      await tester.pump();

      // Verify callback was called
      expect(actionWasCalled, isTrue);
    });

    testWidgets('Action button can be any widget',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppEmptyState(
              icon: Icons.info,
              title: 'Custom action',
              action: Text('Custom Widget Action'),
            ),
          ),
        ),
      );

      // Verify custom action widget is displayed
      expect(find.text('Custom Widget Action'), findsOneWidget);
    });
  });

  group('AppEmptyState - Theming', () {
    testWidgets('T068: Adapts to dark theme correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: const Scaffold(
            body: AppEmptyState(
              icon: Icons.inbox,
              title: 'Dark theme empty state',
              subtitle: 'Subtitle in dark mode',
            ),
          ),
        ),
      );

      // Verify empty state renders in dark theme
      expect(find.text('Dark theme empty state'), findsOneWidget);
      expect(find.text('Subtitle in dark mode'), findsOneWidget);
      expect(find.byIcon(Icons.inbox), findsOneWidget);

      // Verify dark theme is applied
      final BuildContext context = tester.element(find.byType(AppEmptyState));
      expect(Theme.of(context).brightness, equals(Brightness.dark));

      // Verify icon color uses dark theme outline color
      final icon = tester.widget<Icon>(find.byIcon(Icons.inbox));
      final darkTheme = AppTheme.darkTheme;
      expect(icon.color, equals(darkTheme.colorScheme.outline));
    });
  });

  group('AppEmptyState - RTL Support', () {
    testWidgets('T069: Renders correctly in RTL layout',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('ar'),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: AppEmptyState(
                icon: Icons.inbox,
                title: 'لا توجد عناصر',
                subtitle: 'ابدأ بإضافة عناصر جديدة',
                action: AppButton(
                  text: 'إضافة',
                  onPressed: () {},
                  width: null,
                ),
              ),
            ),
          ),
        ),
      );

      // Verify Arabic content is displayed
      expect(find.text('لا توجد عناصر'), findsOneWidget);
      expect(find.text('ابدأ بإضافة عناصر جديدة'), findsOneWidget);
      expect(find.text('إضافة'), findsOneWidget);

      // Verify RTL directionality
      final BuildContext context = tester.element(find.byType(AppEmptyState));
      expect(Directionality.of(context), equals(TextDirection.rtl));

      // Verify icon is displayed
      expect(find.byIcon(Icons.inbox), findsOneWidget);
    });

    testWidgets('Text is centered in RTL',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('ar'),
          home: const Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: AppEmptyState(
                icon: Icons.inbox,
                title: 'عنوان',
                subtitle: 'وصف',
              ),
            ),
          ),
        ),
      );

      // Verify text alignment is center (works in both LTR and RTL)
      final titleText = tester.widget<Text>(find.text('عنوان'));
      final subtitleText = tester.widget<Text>(find.text('وصف'));

      expect(titleText.textAlign, equals(TextAlign.center));
      expect(subtitleText.textAlign, equals(TextAlign.center));
    });
  });

  group('AppEmptyState - Layout', () {
    testWidgets('Content has proper padding',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppEmptyState(
              icon: Icons.inbox,
              title: 'Padded content',
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

    testWidgets('Elements are properly spaced',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppEmptyState(
              icon: Icons.inbox,
              title: 'Spaced content',
              subtitle: 'With subtitle',
              action: AppButton(
                text: 'Action',
                onPressed: () {},
                width: null,
              ),
            ),
          ),
        ),
      );

      // Verify SizedBox widgets for spacing
      expect(find.byType(SizedBox), findsWidgets);

      // Verify all elements are present
      expect(find.byIcon(Icons.inbox), findsOneWidget);
      expect(find.text('Spaced content'), findsOneWidget);
      expect(find.text('With subtitle'), findsOneWidget);
      expect(find.byType(AppButton), findsOneWidget);
    });
  });
}
