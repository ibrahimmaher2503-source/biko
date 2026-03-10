import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppLoading Widget Tests', () {
    testWidgets('Inline mode renders correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppLoading(),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(Center), findsWidgets); // At least one Center widget

      // Verify inline mode by checking AppLoading widget property
      final appLoading = tester.widget<AppLoading>(find.byType(AppLoading));
      expect(appLoading.showOverlay, false);
    });

    testWidgets('Overlay mode renders correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppLoading(
              showOverlay: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(Container), findsWidgets); // Container for overlay background

      // Verify overlay mode by checking AppLoading widget property
      final appLoading = tester.widget<AppLoading>(find.byType(AppLoading));
      expect(appLoading.showOverlay, true);
    });

    testWidgets('Message displays correctly in inline mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppLoading(
              message: 'Loading data...',
            ),
          ),
        ),
      );

      expect(find.text('Loading data...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Message displays correctly in overlay mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppLoading(
              showOverlay: true,
              message: 'Please wait...',
            ),
          ),
        ),
      );

      expect(find.text('Please wait...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Verify overlay mode by checking AppLoading widget property
      final appLoading = tester.widget<AppLoading>(find.byType(AppLoading));
      expect(appLoading.showOverlay, true);
    });

    testWidgets('No message when message is null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppLoading(),
          ),
        ),
      );

      expect(find.byType(Text), findsNothing); // No message text
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Custom size works correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppLoading(
              size: 60.0,
            ),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(find.ancestor(
        of: find.byType(CircularProgressIndicator),
        matching: find.byType(SizedBox),
      ).first);

      expect(sizedBox.width, 60.0);
      expect(sizedBox.height, 60.0);
    });

    testWidgets('Default size is 40', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppLoading(),
          ),
        ),
      );

      final appLoading = tester.widget<AppLoading>(find.byType(AppLoading));
      expect(appLoading.size, 40.0);
    });

    testWidgets('Custom color works correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppLoading(
              color: Colors.amber,
            ),
          ),
        ),
      );

      final progressIndicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      final valueColor = progressIndicator.valueColor as AlwaysStoppedAnimation<Color>;

      expect(valueColor.value, Colors.amber);
    });

    testWidgets('Default color is primary color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppLoading(),
          ),
        ),
      );

      final progressIndicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      final valueColor = progressIndicator.valueColor as AlwaysStoppedAnimation<Color>;

      expect(valueColor.value, AppTheme.primary);
    });

    testWidgets('Overlay has semi-transparent background', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppLoading(
              showOverlay: true,
            ),
          ),
        ),
      );

      // Find the Container used for the overlay background
      final containers = tester.widgetList<Container>(find.byType(Container));
      final overlayContainer = containers.firstWhere(
        (container) => container.color != null,
      );

      expect(overlayContainer.color, Colors.black.withValues(alpha: 0.5));
    });

    testWidgets('Message text is white in overlay mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppLoading(
              showOverlay: true,
              message: 'Loading...',
            ),
          ),
        ),
      );

      final text = tester.widget<Text>(find.text('Loading...'));
      expect(text.style?.color, Colors.white);
    });

    testWidgets('Message text uses theme color in inline mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppLoading(
              message: 'Loading...',
            ),
          ),
        ),
      );

      final text = tester.widget<Text>(find.text('Loading...'));
      final theme = AppTheme.lightTheme;

      expect(text.style?.color, theme.colorScheme.onSurface);
    });
  });

  // Golden tests are commented out because they require image comparison infrastructure
  // To run golden tests:
  // 1. Ensure goldens directory exists: test/core/widgets/goldens/
  // 2. Generate reference images: flutter test --update-goldens
  // 3. Run golden tests: flutter test
  //
  // group('AppLoading Golden Tests', () {
  //   testWidgets('Inline mode golden test', (tester) async {
  //     await tester.pumpWidget(
  //       MaterialApp(
  //         theme: AppTheme.lightTheme,
  //         home: const Scaffold(
  //           body: AppLoading(),
  //         ),
  //       ),
  //     );
  //
  //     await expectLater(
  //       find.byType(Scaffold),
  //       matchesGoldenFile('goldens/app_loading_inline.png'),
  //     );
  //   });
  //
  //   testWidgets('Overlay mode golden test', (tester) async {
  //     await tester.pumpWidget(
  //       MaterialApp(
  //         theme: AppTheme.lightTheme,
  //         home: const Scaffold(
  //           body: AppLoading(
  //             showOverlay: true,
  //             message: 'Loading your data...',
  //           ),
  //         ),
  //       ),
  //     );
  //
  //     await expectLater(
  //       find.byType(Scaffold),
  //       matchesGoldenFile('goldens/app_loading_overlay.png'),
  //     );
  //   });
  // });
}
