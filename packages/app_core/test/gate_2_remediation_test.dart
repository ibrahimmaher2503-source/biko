import 'dart:async';

import 'package:app_core/app_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('J safe Arabic auth mapping never leaks backend details', () {
    final cases = <Object, String>{
      const AuthException('internal secret', code: 'invalid_credentials'):
          'البريد الإلكتروني أو كلمة المرور غير صحيحة.',
      const AuthException('internal secret', code: 'email_address_invalid'):
          'أدخل بريدًا إلكترونيًا صحيحًا.',
      const AuthException('internal secret', statusCode: '429'):
          'محاولات كثيرة. انتظر قليلًا ثم حاول مرة أخرى.',
      TimeoutException('internal secret'):
          'الاتصال غير متاح. تحقق من الإنترنت وحاول مرة أخرى.',
      const AuthException('internal secret'):
          'تعذر إكمال العملية. حاول مرة أخرى.',
      const AuthException('internal secret', code: 'email_exists'):
          'يوجد حساب بهذا البريد. سجل الدخول أو استعد كلمة المرور.',
      const AuthException('internal secret', code: 'email_not_confirmed'):
          'أكد بريدك الإلكتروني أولًا.',
      const AuthException('internal secret', code: 'session_not_found'):
          'انتهت الجلسة. سجل الدخول مرة أخرى.',
    };
    for (final entry in cases.entries) {
      expect(authErrorMessage(entry.key), entry.value);
      expect(authErrorMessage(entry.key), isNot(contains('internal secret')));
    }
  });

  test('G/I uncertain write blocks actions and retries reads only', () async {
    final controller = MutationReconciler(readAttempts: 1);
    addTearDown(controller.dispose);
    var writes = 0;
    var reads = 0;
    var online = false;
    var serverOffer = false;
    var renderedOffer = false;
    final phases = <RecoveryPhase>[];
    controller.addListener(() => phases.add(controller.phase));
    await controller.run(
      mutate: () async {
        writes++;
        serverOffer = true;
        throw TimeoutException('response lost');
      },
      refresh: () async {
        reads++;
        if (!online) throw TimeoutException('offline');
        renderedOffer = serverOffer;
        return renderedOffer;
      },
      revalidateAuth: () async {},
    );
    expect(controller.outcome, MutationOutcome.uncertain);
    expect(controller.phase, RecoveryPhase.unavailable);
    await controller.run(
      mutate: () async {
        writes++;
      },
      refresh: () async => true,
      revalidateAuth: () async {},
    );
    expect(writes, 1);
    online = true;
    await controller.retryRead();
    expect(reads, 2);
    expect(writes, 1);
    expect(renderedOffer, isTrue);
    expect(controller.blocksActions, isFalse);
    expect(
      phases,
      containsAllInOrder([
        RecoveryPhase.submitting,
        RecoveryPhase.checking,
        RecoveryPhase.unavailable,
        RecoveryPhase.checking,
        RecoveryPhase.idle,
      ]),
    );
  });

  test(
    'success and business failure refresh, session failure revalidates',
    () async {
      final controller = MutationReconciler();
      addTearDown(controller.dispose);
      var reads = 0;
      var authChecks = 0;
      await controller.run(
        mutate: () async {},
        refresh: () async {
          reads++;
          return true;
        },
        revalidateAuth: () async {},
      );
      expect(controller.outcome, MutationOutcome.success);
      await controller.run(
        mutate: () async {
          throw const BusinessFailure('تغيرت الحالة');
        },
        refresh: () async {
          reads++;
          return true;
        },
        revalidateAuth: () async {},
      );
      expect(controller.outcome, MutationOutcome.businessFailure);
      await controller.run(
        mutate: () async {
          throw const AuthException('expired', code: 'session_not_found');
        },
        refresh: () async {
          reads++;
          return true;
        },
        revalidateAuth: () async {
          authChecks++;
        },
      );
      expect(controller.outcome, MutationOutcome.authFailure);
      expect(authChecks, 1);
      expect(reads, 3);
      expect(
        classifyMutationError(
          const PostgrestException(message: 'expired', code: 'PGRST301'),
        ),
        MutationOutcome.authFailure,
      );
    },
  );

  testWidgets('I shared checking unavailable retry recovered states', (
    tester,
  ) async {
    var retries = 0;
    Future<void> render(RecoveryPhase phase) => tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: ConnectionStateView(
              phase: phase,
              onRetry: () {
                retries++;
              },
            ),
          ),
        ),
      ),
    );
    await render(RecoveryPhase.checking);
    expect(find.text('جاري التحقق من الحالة...'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    await render(RecoveryPhase.unavailable);
    expect(find.textContaining('الاتصال غير متاح'), findsOneWidget);
    await tester.tap(find.text('إعادة التحقق'));
    expect(retries, 1);
    await render(RecoveryPhase.idle);
    expect(find.text('تم تحديث الحالة.'), findsOneWidget);
  });

  testWidgets('M shared status price route service and date presentation', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              Builder(
                builder: (context) => StatusBadge(
                  label: orderStatusLabel(OrderStatus.driverOnWay),
                  color: orderStatusColor(context, OrderStatus.driverOnWay),
                ),
              ),
              const PriceDisplay(95.5),
              const RouteSummary(
                pickupAddress: 'مدينة نصر',
                destinationAddress: 'مصر الجديدة',
              ),
              const ServiceTypeBadge(code: 'DELIVERY'),
            ],
          ),
        ),
      ),
    );
    expect(find.text('في الطريق للعميل'), findsOneWidget);
    expect(find.text('95.50 ج.م'), findsOneWidget);
    expect(find.text('مدينة نصر'), findsOneWidget);
    expect(find.text('مصر الجديدة'), findsOneWidget);
    expect(find.text('توصيل'), findsOneWidget);
    expect(formatOrderDate(DateTime(2026, 8, 30)), '2026/08/30');
    expect(tester.takeException(), isNull);
  });

  testWidgets('M shared order presentation inherits the app color scheme', (
    tester,
  ) async {
    const scheme = ColorScheme.light(
      primary: Colors.deepPurple,
      secondary: Colors.orange,
      tertiary: Colors.teal,
      onSurface: Colors.black,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(colorScheme: scheme),
        home: const Scaffold(
          body: Column(
            children: [
              PriceDisplay(95.5),
              RouteSummary(
                pickupAddress: 'مدينة نصر',
                destinationAddress: 'مصر الجديدة',
              ),
              ServiceTypeBadge(code: 'DELIVERY'),
            ],
          ),
        ),
      ),
    );
    expect(
      tester.widget<Text>(find.text('95.50 ج.م')).style?.color,
      scheme.onSurface,
    );
    expect(
      tester
          .widget<Icon>(find.byIcon(Icons.radio_button_checked_rounded))
          .color,
      scheme.tertiary,
    );
    expect(
      tester.widget<Text>(find.text('توصيل')).style?.color,
      scheme.secondary,
    );
  });
}
