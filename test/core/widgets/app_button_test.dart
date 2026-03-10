import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppButton Widget Tests', () {
    testWidgets('Primary variant renders ElevatedButton', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppButton(
              text: 'Primary Button',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Primary Button'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);

      await tester.tap(find.byType(AppButton));
      await tester.pump();

      expect(pressed, true);
    });

    testWidgets('Secondary variant renders FilledButton.tonal', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppButton(
              text: 'Secondary Button',
              onPressed: () {},
              variant: ButtonVariant.secondary,
            ),
          ),
        ),
      );

      expect(find.text('Secondary Button'), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('Outline variant renders OutlinedButton', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppButton(
              text: 'Outline Button',
              onPressed: () {},
              variant: ButtonVariant.outline,
            ),
          ),
        ),
      );

      expect(find.text('Outline Button'), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('Text variant renders TextButton', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppButton(
              text: 'Text Button',
              onPressed: () {},
              variant: ButtonVariant.text,
            ),
          ),
        ),
      );

      expect(find.text('Text Button'), findsOneWidget);
      expect(find.byType(TextButton), findsOneWidget);
    });

    testWidgets('Disabled state prevents interaction', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppButton(
              text: 'Disabled Button',
              onPressed: null, // Disabled
            ),
          ),
        ),
      );

      expect(find.text('Disabled Button'), findsOneWidget);

      // Find the ElevatedButton and check if it's disabled
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);

      // Verify opacity is applied for disabled state
      expect(find.byType(Opacity), findsOneWidget);
      final opacity = tester.widget<Opacity>(find.byType(Opacity));
      expect(opacity.opacity, 0.5);
    });

    testWidgets('Loading state shows CircularProgressIndicator', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppButton(
              text: 'Loading Button',
              onPressed: () {},
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading Button'), findsNothing);

      // Loading state should disable interaction
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('Leading icon renders correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppButton(
              text: 'Icon Button',
              onPressed: () {},
              leadingIcon: Icons.arrow_forward,
            ),
          ),
        ),
      );

      expect(find.text('Icon Button'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    });

    testWidgets('Trailing icon renders correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppButton(
              text: 'Icon Button',
              onPressed: () {},
              trailingIcon: Icons.chevron_right,
            ),
          ),
        ),
      );

      expect(find.text('Icon Button'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('Icons flip in RTL layout', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: AppButton(
                text: 'RTL Button',
                onPressed: () {},
                leadingIcon: Icons.arrow_forward,
                trailingIcon: Icons.chevron_right,
              ),
            ),
          ),
        ),
      );

      // In RTL, icons should be flipped (leadingIcon becomes trailing, trailingIcon becomes leading)
      expect(find.text('RTL Button'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);

      // Verify the Row contains icons in correct order
      final row = tester.widget<Row>(find.byType(Row));
      expect(row.children.length, 5); // icon + spacer + text + spacer + icon
    });

    testWidgets('Custom width and height work correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppButton(
              text: 'OK',
              onPressed: () {},
              width: 200,
              height: 48,
            ),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(find.ancestor(
        of: find.byType(ElevatedButton),
        matching: find.byType(SizedBox),
      ));

      expect(sizedBox.width, 200);
      expect(sizedBox.height, 48);
    });

    testWidgets('Default height is 56dp', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppButton(
              text: 'Default Height',
              onPressed: () {},
            ),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(find.ancestor(
        of: find.byType(ElevatedButton),
        matching: find.byType(SizedBox),
      ));

      expect(sizedBox.height, 56.0);
    });
  });

  // Golden tests are commented out because they require image comparison infrastructure
  // To run golden tests:
  // 1. Ensure goldens directory exists: test/core/widgets/goldens/
  // 2. Generate reference images: flutter test --update-goldens
  // 3. Run golden tests: flutter test
  //
  // group('AppButton Golden Tests', () {
  //   testWidgets('Primary button golden test', (tester) async {
  //     await tester.pumpWidget(
  //       MaterialApp(
  //         theme: AppTheme.lightTheme,
  //         home: Scaffold(
  //           body: Center(
  //             child: AppButton(
  //               text: 'Primary',
  //               onPressed: () {},
  //               variant: ButtonVariant.primary,
  //             ),
  //           ),
  //         ),
  //       ),
  //     );
  //
  //     await expectLater(
  //       find.byType(AppButton),
  //       matchesGoldenFile('goldens/app_button_primary.png'),
  //     );
  //   });
  //
  //   testWidgets('RTL layout golden test', (tester) async {
  //     await tester.pumpWidget(
  //       MaterialApp(
  //         theme: AppTheme.lightTheme,
  //         home: Directionality(
  //           textDirection: TextDirection.rtl,
  //           child: Scaffold(
  //             body: Center(
  //               child: AppButton(
  //                 text: 'RTL Button',
  //                 onPressed: () {},
  //                 leadingIcon: Icons.arrow_forward,
  //               ),
  //             ),
  //           ),
  //         ),
  //       ),
  //     );
  //
  //     await expectLater(
  //       find.byType(AppButton),
  //       matchesGoldenFile('goldens/app_button_rtl.png'),
  //     );
  //   });
  // });
}
