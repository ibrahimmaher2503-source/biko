import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user_app/features/orders/order_tracking.dart';
import 'package:user_app/features/orders/order_models.dart';
import 'package:app_core/app_core.dart';

void main() {
  test('tracking parses only the canonical server tracking shape', () {
    final tracking = OrderTracking.fromJson({
      'latitude': 30.051,
      'longitude': 31.241,
      'driver_location_updated_at': '2026-09-08T10:00:00Z',
      'eta_seconds': 180,
      'eta_updated_at': '2026-09-08T10:00:05Z',
      'is_stale': false,
    });
    expect(tracking.etaSeconds, 180);
    expect(tracking.isStale, isFalse);
  });

  test('late tracking reads are rejected after an order or session switch', () {
    final guard = OrderTrackingRequestGuard();
    final oldRead = guard.begin();
    final currentRead = guard.begin();
    expect(guard.isCurrent(oldRead), isFalse);
    expect(guard.isCurrent(currentRead), isTrue);
    guard.cancel();
    expect(guard.isCurrent(currentRead), isFalse);
  });

  test('locally retained tracking becomes stale without polling', () {
    final tracking = OrderTracking.fromJson({
      'latitude': 30.051,
      'longitude': 31.241,
      'driver_location_updated_at': '2026-09-08T10:00:00Z',
      'is_stale': false,
    });
    expect(
      isTrackingStale(tracking, now: DateTime.utc(2026, 9, 8, 10, 1, 59)),
      isFalse,
    );
    expect(
      isTrackingStale(tracking, now: DateTime.utc(2026, 9, 8, 10, 2)),
      isTrue,
    );
  });

  test('ETA expires independently from a fresh Driver location', () {
    final tracking = OrderTracking.fromJson({
      'latitude': 30.051,
      'longitude': 31.241,
      'driver_location_updated_at': '2026-09-08T10:00:30Z',
      'eta_seconds': 120,
      'eta_updated_at': '2026-09-08T10:00:00Z',
      'is_stale': false,
    });
    expect(
      hasFreshEta(tracking, now: DateTime.utc(2026, 9, 8, 10, 0, 59)),
      isTrue,
    );
    expect(
      hasFreshEta(tracking, now: DateTime.utc(2026, 9, 8, 10, 1)),
      isFalse,
    );
  });

  testWidgets(
    'missing session exits the tracking spinner without subscribing',
    (tester) async {
      final service = _DeferredTrackingService();
      await tester.pumpWidget(
        MaterialApp(
          home: AssignedDriverTrackingCard(
            order: _order('one'),
            service: service,
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();
      expect(service.loads, isEmpty);
      expect(find.textContaining('موقع السائق غير متاح'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

class _DeferredTrackingService extends OrderTrackingService {
  _DeferredTrackingService()
    : super(
        SupabaseClient(
          'http://localhost',
          'test-anon-key',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
      );
  final loads = <Completer<OrderTracking?>>[];
  @override
  Future<OrderTracking?> load(String _) {
    final result = Completer<OrderTracking?>();
    loads.add(result);
    return result.future;
  }
}

CustomerOrder _order(String id) => CustomerOrder(
  id: id,
  service: ServiceType.ride,
  pickup: const LocationSelection(
    displayAddress: 'a',
    latitude: 30,
    longitude: 31,
  ),
  destination: const LocationSelection(
    displayAddress: 'b',
    latitude: 30.1,
    longitude: 31.1,
  ),
  proposedPrice: 1,
  status: OrderStatus.driverOnWay,
  createdAt: DateTime.utc(2026),
  driverId: 'driver',
);

OrderTracking _tracking() => OrderTracking.fromJson({
  'latitude': 30,
  'longitude': 31,
  'driver_location_updated_at': DateTime.now().toUtc().toIso8601String(),
  'is_stale': false,
});
