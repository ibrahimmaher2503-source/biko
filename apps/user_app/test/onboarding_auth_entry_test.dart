import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user_app/app/user_theme.dart';
import 'package:user_app/features/onboarding/user_auth_entry.dart';

Widget _app() => ProviderScope(
  child: MaterialApp(
    theme: buildUserTheme(),
    builder: (context, child) =>
        Directionality(textDirection: TextDirection.rtl, child: child!),
    home: const UserAuthEntry(),
  ),
);

void main() {
  testWidgets(
    'first launch exposes the three onboarding steps then auth choice',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(_app());
      await tester.pump();

      expect(find.text('مرحبًا بك في بيكو'), findsOneWidget);
      await tester.tap(find.text('التالي'));
      await tester.pumpAndSettle();
      expect(find.text('اطلب بطريقتك'), findsOneWidget);
      await tester.tap(find.text('التالي'));
      await tester.pumpAndSettle();
      expect(find.text('اطلب وأنت مطمئن'), findsOneWidget);

      await tester.tap(find.text('ابدأ الآن'));
      await tester.pumpAndSettle();
      expect(find.text('كيف تريد المتابعة؟'), findsOneWidget);
    },
  );

  testWidgets('skip persists onboarding completion', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(_app());
    await tester.pump();

    await tester.tap(find.text('تخطي'));
    await tester.pumpAndSettle();
    expect(
      (await SharedPreferences.getInstance()).getBool(
        'user_onboarding_seen_v1',
      ),
      isTrue,
    );
    expect(find.text('كيف تريد المتابعة؟'), findsOneWidget);
  });

  testWidgets('returning user can choose the shared signup form', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'user_onboarding_seen_v1': true});
    await tester.pumpWidget(_app());
    await tester.pump();

    await tester.tap(find.text('إنشاء حساب'));
    await tester.pumpAndSettle();
    expect(find.text('إنشاء حساب'), findsWidgets);
    expect(find.text('البريد الإلكتروني'), findsOneWidget);
  });

  testWidgets('onboarding remains scrollable on a short large-text viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 500);
    tester.view.devicePixelRatio = 1;
    tester.binding.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(
      tester.binding.platformDispatcher.clearTextScaleFactorTestValue,
    );
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
