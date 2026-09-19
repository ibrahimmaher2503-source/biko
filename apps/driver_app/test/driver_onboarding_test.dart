import 'package:driver_app/features/driver/driver_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('independent onboarding validates required data', (tester) async {
    var submitted = false;
    await tester.pumpWidget(
      MaterialApp(
        home: DriverOnboardingScreen(onSubmit: (_) async => submitted = true),
      ),
    );

    expect(find.text('سائق مستقل'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('driver-onboarding-submit')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('driver-onboarding-submit')));
    await tester.pump();

    expect(find.text('اكتب الاسم بالكامل.'), findsOneWidget);
    expect(find.text('اختر تاريخ الميلاد.'), findsOneWidget);
    expect(submitted, isFalse);
  });

  testWidgets('valid onboarding sends one callback and shows pending state', (
    tester,
  ) async {
    DriverOnboardingApplication? application;
    var continueCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: DriverOnboardingScreen(
          initialDateOfBirth: DateTime(1990, 1, 1),
          onSubmit: (value) async => application = value,
          onSubmitted: () => continueCalls++,
        ),
      ),
    );

    Future<void> fill(Key key, String value) async {
      await tester.ensureVisible(find.byKey(key));
      await tester.enterText(find.byKey(key), value);
    }

    await fill(const Key('driver-full-name-field'), 'سائق بيكو');
    await fill(const Key('driver-phone-field'), '01012345678');
    await fill(const Key('driver-plate-number-field'), 'أ ب ج 123');
    await fill(const Key('driver-brand-field'), 'Honda');
    await fill(const Key('driver-model-field'), 'CG');
    await fill(const Key('driver-color-field'), 'أحمر');
    await fill(const Key('driver-model-year-field'), '2022');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('driver-onboarding-submit')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('driver-onboarding-submit')));
    await tester.pump();

    expect(application, isNotNull);
    expect(application!.fullName, 'سائق بيكو');
    expect(application!.phone, '01012345678');
    expect(application!.dateOfBirth, DateTime(1990, 1, 1));
    expect(application!.modelYear, 2022);
    expect(find.text('تم إرسال طلبك للمراجعة'), findsOneWidget);
    expect(continueCalls, 0);

    await tester.tap(find.text('متابعة'));
    expect(continueCalls, 1);
  });
}
