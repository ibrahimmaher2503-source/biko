import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppCard Widget Tests', () {
    testWidgets('Non-tappable card renders correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppCard(
              child: Text('Card Content'),
            ),
          ),
        ),
      );

      expect(find.text('Card Content'), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(InkWell), findsNothing); // No InkWell for non-tappable
    });

    testWidgets('Tappable card includes InkWell', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppCard(
              onTap: () => tapped = true,
              child: const Text('Tappable Card'),
            ),
          ),
        ),
      );

      expect(find.text('Tappable Card'), findsOneWidget);
      expect(find.byType(InkWell), findsOneWidget);

      await tester.tap(find.byType(AppCard));
      await tester.pump();

      expect(tapped, true);
    });

    testWidgets('Default padding is 16dp', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppCard(
              child: Text('Default Padding'),
            ),
          ),
        ),
      );

      // Verify default padding by checking the AppCard widget property
      final appCard = tester.widget<AppCard>(find.byType(AppCard));
      expect(appCard.padding, 16.0);
    });

    testWidgets('Custom padding works correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppCard(
              padding: 24.0,
              child: Text('Custom Padding'),
            ),
          ),
        ),
      );

      // Verify custom padding by checking the AppCard widget property
      final appCard = tester.widget<AppCard>(find.byType(AppCard));
      expect(appCard.padding, 24.0);
    });

    testWidgets('Default elevation is 2', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppCard(
              child: Text('Default Elevation'),
            ),
          ),
        ),
      );

      final card = tester.widget<Card>(find.byType(Card));
      expect(card.elevation, 2.0);
    });

    testWidgets('Custom elevation works correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppCard(
              elevation: 4.0,
              child: Text('Custom Elevation'),
            ),
          ),
        ),
      );

      final card = tester.widget<Card>(find.byType(Card));
      expect(card.elevation, 4.0);
    });

    testWidgets('Custom background color works correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppCard(
              backgroundColor: Colors.amber,
              child: Text('Custom Color'),
            ),
          ),
        ),
      );

      final card = tester.widget<Card>(find.byType(Card));
      expect(card.color, Colors.amber);
    });

    testWidgets('Default border radius is 12dp', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppCard(
              child: Text('Default Radius'),
            ),
          ),
        ),
      );

      final card = tester.widget<Card>(find.byType(Card));
      final shape = card.shape as RoundedRectangleBorder;
      final borderRadius = shape.borderRadius as BorderRadius;

      expect(borderRadius.topLeft.x, AppTheme.radiusLarge);
    });

    testWidgets('Custom border radius works correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppCard(
              borderRadius: 20.0,
              child: Text('Custom Radius'),
            ),
          ),
        ),
      );

      final card = tester.widget<Card>(find.byType(Card));
      final shape = card.shape as RoundedRectangleBorder;
      final borderRadius = shape.borderRadius as BorderRadius;

      expect(borderRadius.topLeft.x, 20.0);
    });

    testWidgets('Card respects theme card color when backgroundColor is null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppCard(
              child: Text('Theme Color'),
            ),
          ),
        ),
      );

      final card = tester.widget<Card>(find.byType(Card));
      final theme = AppTheme.lightTheme;

      expect(card.color, theme.cardTheme.color);
    });

    testWidgets('InkWell border radius matches card border radius', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppCard(
              borderRadius: 16.0,
              onTap: () {},
              child: const Text('Matched Radius'),
            ),
          ),
        ),
      );

      final inkWell = tester.widget<InkWell>(find.byType(InkWell));
      final borderRadius = inkWell.borderRadius as BorderRadius;

      expect(borderRadius.topLeft.x, 16.0);
    });
  });

  // Golden tests are commented out because they require image comparison infrastructure
  // To run golden tests:
  // 1. Ensure goldens directory exists: test/core/widgets/goldens/
  // 2. Generate reference images: flutter test --update-goldens
  // 3. Run golden tests: flutter test
  //
  // group('AppCard Golden Tests', () {
  //   testWidgets('Non-tappable card golden test', (tester) async {
  //     await tester.pumpWidget(
  //       MaterialApp(
  //         theme: AppTheme.lightTheme,
  //         home: Scaffold(
  //           body: Center(
  //             child: SizedBox(
  //               width: 300,
  //               child: AppCard(
  //                 child: Column(
  //                   mainAxisSize: MainAxisSize.min,
  //                   children: const [
  //                     Text('Card Title', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
  //                     SizedBox(height: 8),
  //                     Text('Card description goes here'),
  //                   ],
  //                 ),
  //               ),
  //             ),
  //           ),
  //         ),
  //       ),
  //     );
  //
  //     await expectLater(
  //       find.byType(AppCard),
  //       matchesGoldenFile('goldens/app_card_default.png'),
  //     );
  //   });
  //
  //   testWidgets('Card with elevation 4 golden test', (tester) async {
  //     await tester.pumpWidget(
  //       MaterialApp(
  //         theme: AppTheme.lightTheme,
  //         home: Scaffold(
  //           body: Center(
  //             child: SizedBox(
  //               width: 300,
  //               child: AppCard(
  //                 elevation: 4.0,
  //                 child: const Text('Elevated Card'),
  //               ),
  //             ),
  //           ),
  //         ),
  //       ),
  //     );
  //
  //     await expectLater(
  //       find.byType(AppCard),
  //       matchesGoldenFile('goldens/app_card_elevated.png'),
  //     );
  //   });
  // });
}
