import 'dart:async';

import 'package:app_core/app_core.dart';
import 'package:driver_app/features/driver/driver_models.dart';
import 'package:driver_app/features/driver/driver_operational_events.dart';
import 'package:driver_app/features/driver/driver_providers.dart';
import 'package:driver_app/features/driver/driver_screens.dart';
import 'package:driver_app/features/driver/driver_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const orderId = '22222222-2222-4222-8222-222222222222';

OperationalNotification event(String type, {String target = 'ACTIVE_ORDER'}) =>
    OperationalNotification(
      id: '11111111-1111-4111-8111-111111111111',
      type: type,
      targetType: target,
      orderId: orderId,
      title: 'تحديث',
      body: 'الحالة الحالية متاحة.',
    );

DriverOffer offer(int index) => DriverOffer(
  id: 'offer-$index',
  orderId: 'order-$index',
  price: 80,
  status: OfferStatus.active,
  pickupAddress: 'استلام $index',
  destinationAddress: 'وجهة $index',
  createdAt: DateTime.utc(2026, 8, 30, 12).subtract(Duration(minutes: index)),
);

class DelayedPageService extends DriverService {
  DelayedPageService()
    : super(
        SupabaseClient(
          'http://localhost',
          'test-only',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
      );

  final page = Completer<List<DriverOffer>>();

  @override
  Future<List<DriverOffer>> loadWaitingOffers({DriverOffer? after}) =>
      page.future;
}

void main() {
  test('new work refreshes only geographic discovery', () {
    expect(driverResourcesFor(event('NEW_WORK', target: 'REQUESTS')), {
      DriverOperationalResource.requests,
    });
  });

  test('active lifecycle does not refresh profile, history, or earnings', () {
    expect(driverResourcesFor(event('DRIVER_ON_WAY')), {
      DriverOperationalResource.activeOrder,
      DriverOperationalResource.order,
      DriverOperationalResource.offer,
    });
  });

  test('keyset remains reachable when an earlier active offer disappears', () {
    final all = List.generate(60, offer);
    final firstPage = all.take(50).toList();
    final cursor = firstPage.last;
    final changed = all
        .skip(1)
        .where((candidate) {
          final byTime = candidate.createdAt!.compareTo(cursor.createdAt!);
          return byTime < 0 ||
              (byTime == 0 && candidate.id.compareTo(cursor.id) < 0);
        })
        .take(50)
        .toList();

    expect(
      changed.map((value) => value.id),
      all.skip(50).map((value) => value.id),
    );
  });

  test(
    'generation reset rejects delayed response after refresh/session change',
    () {
      final generation = WaitingOffersGeneration();
      final stale = generation.capture();
      generation.reset();
      expect(generation.accepts(stale), isFalse);
    },
  );

  testWidgets('delayed old page cannot append after first-page refresh', (
    tester,
  ) async {
    final service = DelayedPageService();
    final firstPage = ValueNotifier<List<DriverOffer>>(
      List.generate(50, offer),
    );
    addTearDown(firstPage.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [driverServiceProvider.overrideWithValue(service)],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ValueListenableBuilder<List<DriverOffer>>(
                valueListenable: firstPage,
                builder: (_, offers, _) => WaitingOffersList(offers: offers),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.ensureVisible(find.text('عرض المزيد'));
    await tester.tap(find.text('عرض المزيد'));
    await tester.pump();
    expect(find.text('جاري التحميل...'), findsOneWidget);
    firstPage.value = List.generate(50, (index) => offer(index + 1));
    await tester.pump();
    service.page.complete([offer(99)]);
    await tester.pump();

    expect(find.text('طلب order-99'), findsNothing);
    expect(find.text('عرض المزيد'), findsOneWidget);
  });
}
