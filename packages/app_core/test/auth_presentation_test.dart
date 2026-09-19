import 'package:app_core/app_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'shared auth defaults to login and mode change conceals password',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: EmailPasswordAuthPage(appName: 'بيكو', description: 'حسابك'),
          ),
        ),
      );
      expect(find.text('تسجيل الدخول'), findsWidgets);
      await tester.enterText(
        find.byType(TextFormField).last,
        'example-password',
      );
      await tester.tap(find.byTooltip('إظهار كلمة المرور'));
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byType(TextField).last).obscureText,
        isFalse,
      );
      await tester.ensureVisible(find.text('ليس لديك حساب؟ إنشاء حساب'));
      await tester.tap(find.text('ليس لديك حساب؟ إنشاء حساب'));
      await tester.pump();
      final password = tester.widget<TextField>(find.byType(TextField).last);
      expect(password.obscureText, isTrue);
      expect(password.controller!.text, isEmpty);
      expect(password.textInputAction, TextInputAction.done);
      expect(tester.takeException(), isNull);
    },
  );
}
