import 'package:app_core/app_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/features/orders/customer_order_contact.dart';
import 'package:user_app/features/orders/order_models.dart';
import 'dart:async';

import 'widget_test.dart' show testApp, testClient;

class _StaleContactService extends CustomerOrderContactService {
  _StaleContactService() : super(testClient());

  @override
  Future<AssignedDriverContact?> load(String orderId) async => null;
}

class _DelayedContactService extends CustomerOrderContactService {
  _DelayedContactService() : super(testClient());
  final result = Completer<AssignedDriverContact?>();
  @override
  Future<AssignedDriverContact?> load(String _) => result.future;
}

final _order = CustomerOrder(
  id: 'contact-order',
  service: ServiceType.ride,
  pickup: const LocationSelection(
    displayAddress: 'مدينة نصر',
    latitude: 30,
    longitude: 31,
  ),
  destination: const LocationSelection(
    displayAddress: 'مصر الجديدة',
    latitude: 30.1,
    longitude: 31.1,
  ),
  proposedPrice: 80,
  status: OrderStatus.driverAssigned,
  createdAt: DateTime.utc(2026, 9, 8),
);

void main() {
  test(
    'driver call uses a native tel URI without sending automatically',
    () async {
      Uri? captured;
      final opened = await launchDriverCall(
        '+201001234567',
        launcher: (uri) async {
          captured = uri;
          return true;
        },
      );

      expect(opened, isTrue);
      expect(captured, Uri(scheme: 'tel', path: '+201001234567'));
    },
  );

  test('call numbers reject controls, USSD, and punctuation-only values', () {
    expect(normalizeCallPhone('+20 (100) 123-4567'), '+201001234567');
    expect(normalizeCallPhone('*21*123#'), isNull);
    expect(normalizeCallPhone('() --'), isNull);
    expect(normalizeCallPhone('12345'), isNull);
  });

  test('support config accepts only valid official contact targets', () {
    const valid = CustomerSupportContact(
      phone: '+20 (100) 123-4567',
      email: 'help@biko.example',
      website: 'https://support.biko.example/help',
    );
    const invalid = CustomerSupportContact(
      phone: '*21*123#',
      email: 'not-an-email',
      website: 'http://support.biko.example',
    );
    expect(valid.callPhone, '+201001234567');
    expect(valid.mail, 'help@biko.example');
    expect(valid.web, Uri.parse('https://support.biko.example/help'));
    expect(invalid.callPhone, isNull);
    expect(invalid.mail, isNull);
    expect(invalid.web, isNull);
  });

  test('launcher failure remains observable to the caller', () async {
    expect(
      await launchDriverCall('01001234567', launcher: (_) async => false),
      isFalse,
    );
  });

  testWidgets('stale contact is rechecked and support stays unconfigured', (
    tester,
  ) async {
    await tester.pumpWidget(
      testApp(
        Scaffold(body: CustomerOrderContactActions(order: _order)),
        overrides: [
          customerOrderContactProvider(_order.id).overrideWith(
            (_) async => const AssignedDriverContact('+201001234567'),
          ),
          customerOrderContactServiceProvider.overrideWithValue(
            _StaleContactService(),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('call-driver')), findsOneWidget);
    expect(
      find.text('الدعم غير مُعدّ للتواصل المباشر حالياً.'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('call-driver')));
    await tester.pumpAndSettle();
    expect(find.text('وسيلة الاتصال لم تعد متاحة الآن.'), findsOneWidget);
  });

  testWidgets('terminal switch during contact refresh never launches dialer', (
    tester,
  ) async {
    final service = _DelayedContactService();
    var launches = 0;
    final active = _contactOrder(OrderStatus.driverAssigned);
    await tester.pumpWidget(
      testApp(
        CustomerOrderContactActions(
          key: const ValueKey('contact'),
          order: active,
          launcher: (_) async {
            launches++;
            return true;
          },
        ),
        overrides: [
          customerOrderContactProvider(active.id).overrideWith(
            (_) async => const AssignedDriverContact('+201001234567'),
          ),
          customerOrderContactServiceProvider.overrideWithValue(service),
        ],
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('call-driver')));
    await tester.pump();
    await tester.pumpWidget(
      testApp(
        CustomerOrderContactActions(
          key: const ValueKey('contact'),
          order: _contactOrder(OrderStatus.completed),
          launcher: (_) async {
            launches++;
            return true;
          },
        ),
        overrides: [
          customerOrderContactProvider(active.id).overrideWith(
            (_) async => const AssignedDriverContact('+201001234567'),
          ),
          customerOrderContactServiceProvider.overrideWithValue(service),
        ],
      ),
    );
    service.result.complete(const AssignedDriverContact('+201001234567'));
    await tester.pumpAndSettle();
    expect(launches, 0);
  });
}

CustomerOrder _contactOrder(OrderStatus status) => CustomerOrder(
  id: _order.id,
  service: _order.service,
  pickup: _order.pickup,
  destination: _order.destination,
  proposedPrice: _order.proposedPrice,
  status: status,
  createdAt: _order.createdAt,
  driverId: 'driver',
);
