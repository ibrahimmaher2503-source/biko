import 'package:app_core/app_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shared controls expose only enabled accessibility tap actions', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var taps = 0;
    for (final state in ['enabled', 'disabled', 'loading']) {
      final enabled = state != 'disabled';
      final loading = state == 'loading';
      void onTap() => taps++;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                PrimaryButton(
                  label: 'primary',
                  onPressed: enabled ? onTap : null,
                  isLoading: loading,
                ),
                DestructiveButton(
                  label: 'destructive',
                  onPressed: enabled ? onTap : null,
                  isLoading: loading,
                ),
                LocationField(
                  label: 'location',
                  onTap: onTap,
                  enabled: enabled,
                  isLoading: loading,
                ),
              ],
            ),
          ),
        ),
      );
      for (final label in ['primary', 'destructive', 'location']) {
        final node = tester.getSemantics(find.bySemanticsLabel(label));
        expect(
          node.getSemanticsData().hasAction(SemanticsAction.tap),
          state == 'enabled',
        );
        if (state == 'enabled') {
          tester
              .renderObject(find.bySemanticsLabel(label))
              .owner!
              .semanticsOwner!
              .performAction(node.id, SemanticsAction.tap);
        }
      }
    }
    expect(taps, 3);
    semantics.dispose();
  });

  testWidgets('Biko foundation keeps navigation compact and capsule-free', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildBikoTheme(),
        home: Scaffold(
          bottomNavigationBar: AppBottomNavigation(
            currentIndex: 0,
            onDestinationSelected: (_) {},
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                label: 'الرئيسية',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                label: 'الحساب',
              ),
            ],
          ),
        ),
      ),
    );

    final theme = Theme.of(tester.element(find.byType(NavigationBar)));
    expect(theme.navigationBarTheme.height, 64);
    expect(theme.navigationBarTheme.indicatorColor, Colors.transparent);
    expect(find.text('الرئيسية'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shared input, loading and destructive states remain semantic', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildBikoTheme(),
        home: Scaffold(
          body: ListView(
            children: [
              LocationField(
                label: 'نقطة الاستلام',
                onTap: () {},
                address: 'مدينة نصر',
              ),
              PriceInput(controller: controller, validator: (_) => null),
              const InlineLoading(label: 'جاري حساب المسار'),
              DestructiveButton(
                label: 'إلغاء الطلب',
                onPressed: () {},
                isLoading: true,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('مدينة نصر'), findsOneWidget);
    final decoration = tester.widget<InputDecorator>(
      find.descendant(
        of: find.byType(LocationField),
        matching: find.byType(InputDecorator),
      ),
    );
    expect(
      decoration.decoration.floatingLabelBehavior,
      FloatingLabelBehavior.always,
    );
    expect(find.text('ج.م'), findsOneWidget);
    expect(find.text('جاري حساب المسار'), findsOneWidget);
    expect(find.byType(ButtonLoading), findsOneWidget);
    expect(find.bySemanticsLabel('إلغاء الطلب'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
