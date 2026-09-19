import 'dart:math';

import 'package:app_core/app_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user_app/features/orders/order_providers.dart';
import 'package:user_app/features/orders/order_models.dart';
import 'package:user_app/features/orders/order_rules.dart';

Map<String, dynamic> orderJson({
  String service = 'RIDE',
  String status = 'BIDDING',
  DateTime? expiresAt,
  Map<String, dynamic>? delivery,
}) => {
  'id': '10000000-0000-4000-8000-000000000001',
  'pickup_lat': 30.0566,
  'pickup_lng': 31.3301,
  'pickup_address': 'ميدان رابعة، مدينة نصر',
  'destination_lat': 30.1133,
  'destination_lng': 31.346,
  'destination_address': 'ميدان الحجاز، مصر الجديدة',
  'proposed_price': 80,
  'agreed_price': status == 'BIDDING' ? null : 90,
  'driver_id': status == 'BIDDING' ? null : 'driver-1',
  'status': status,
  'created_at': '2026-08-30T12:00:00Z',
  'bidding_expires_at': (expiresAt ?? DateTime.utc(2026, 8, 30, 12, 1, 30))
      .toIso8601String(),
  'cancellation_reason': null,
  'cancellation_type': null,
  'service': {'code': service},
  'delivery': delivery,
};

void main() {
  group('Milestone 7 User Core contracts', () {
    test('creation intent is UUID v4 and each deliberate booking is new', () {
      final first = newCreationIntentId(random: Random(1));
      final second = newCreationIntentId(random: Random(2));
      expect(
        first,
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
      expect(second, isNot(first));
    });

    test('Ride parses without Delivery-only data', () {
      final order = CustomerOrder.fromJson(orderJson());
      expect(order.service, ServiceType.ride);
      expect(order.delivery, isNull);
    });

    test('Delivery preserves recipient and parcel data for Book Again', () {
      final order = CustomerOrder.fromJson(
        orderJson(
          service: 'DELIVERY',
          status: 'CANCELLED',
          delivery: {
            'recipient_name': 'منى',
            'recipient_phone': '01000000000',
            'parcel_weight_kg': 8,
            'declared_value': 3000,
          },
        ),
      );
      final draft = order.bookAgainDraft();
      expect(draft.service, ServiceType.delivery);
      expect(draft.pickup.displayAddress, order.pickup.displayAddress);
      expect(
        draft.destination.displayAddress,
        order.destination.displayAddress,
      );
      expect(draft.proposedPrice, 80);
      expect(draft.delivery?.recipientName, 'منى');
      expect(draft.delivery?.parcelWeightKg, 8);
      expect(draft.delivery?.declaredValue, 3000);
    });

    test('Delivery weight accepts the frozen upper boundary only', () {
      expect(parcelWeight('0'), isNotNull);
      expect(parcelWeight('0.1'), isNull);
      expect(parcelWeight('8'), isNull);
      expect(parcelWeight('8.01'), isNotNull);
    });

    test('Delivery declared value accepts 0 through 3000 only', () {
      expect(declaredValue('-1'), isNotNull);
      expect(declaredValue('0'), isNull);
      expect(declaredValue('3000'), isNull);
      expect(declaredValue('3000.01'), isNotNull);
    });

    test('proposed price is required, numeric, and positive', () {
      expect(positivePrice(''), isNotNull);
      expect(positivePrice('abc'), isNotNull);
      expect(positivePrice('0'), isNotNull);
      expect(positivePrice('80'), isNull);
    });

    test('customer cancellation matrix matches the frozen contract', () {
      expect(customerCanCancel(OrderStatus.bidding), isTrue);
      expect(cancellationReasonRequired(OrderStatus.bidding), isFalse);
      for (final status in [
        OrderStatus.driverAssigned,
        OrderStatus.driverOnWay,
        OrderStatus.driverArrived,
      ]) {
        expect(customerCanCancel(status), isTrue);
        expect(cancellationReasonRequired(status), isTrue);
      }
      expect(customerCanCancel(OrderStatus.inProgress), isFalse);
      expect(customerCanCancel(OrderStatus.completed), isFalse);
      expect(customerCanCancel(OrderStatus.cancelled), isFalse);
      expect(customerCanCancel(OrderStatus.expired), isFalse);
    });

    test('terminal states are exactly Completed, Cancelled, and Expired', () {
      expect(isTerminalOrder(OrderStatus.completed), isTrue);
      expect(isTerminalOrder(OrderStatus.cancelled), isTrue);
      expect(isTerminalOrder(OrderStatus.expired), isTrue);
      expect(isTerminalOrder(OrderStatus.inProgress), isFalse);
    });

    test('server bidding expiry drives local elapsed state', () {
      final expired = CustomerOrder.fromJson(
        orderJson(expiresAt: DateTime.utc(2026, 8, 30, 11, 59)),
      );
      final active = CustomerOrder.fromJson(
        orderJson(expiresAt: DateTime.utc(2026, 8, 30, 12, 2)),
      );
      final now = DateTime.utc(2026, 8, 30, 12);
      expect(expired.biddingElapsed(now), isTrue);
      expect(active.biddingElapsed(now), isFalse);
    });

    test(
      'privacy-safe offer model consumes no phone, email, rating, or docs',
      () {
        final offer = DriverOffer.fromJson({
          'offer_id': 'offer-1',
          'offered_price': 90,
          'driver_public_id': 'driver-1',
          'driver_first_name': 'أحمد',
          'driver_photo_url': null,
          'driver_type': 'INDEPENDENT',
          'office_display_name': null,
          'completed_trip_count': 42,
          'driver_phone': 'must-not-be-used',
          'driver_email': 'must-not-be-used@example.com',
          'rating': 5,
        });
        expect(offer.driverFirstName, 'أحمد');
        expect(offer.completedTripCount, 42);
        expect(offer.toSummary().driverType, DriverType.independent);
      },
    );

    test('known backend failures map to safe Arabic recovery messages', () {
      expect(
        customerMutationMessage(
          const PostgrestException(
            message: 'Offer is not active',
            code: 'P0001',
          ),
        ),
        contains('لم يعد متاحًا'),
      );
      expect(
        customerMutationMessage(
          const PostgrestException(
            message: 'Cancellation reason is required after driver assignment',
            code: '22023',
          ),
        ),
        contains('سبب الإلغاء'),
      );
      expect(
        customerMutationMessage(
          const PostgrestException(
            message: 'private raw detail',
            code: 'XX000',
          ),
        ),
        isNot(contains('private raw detail')),
      );
      expect(
        customerMutationMessage(
          const PostgrestException(
            message: 'Route quote has expired',
            code: 'P0001',
          ),
        ),
        contains('أعد حساب المسار'),
      );
    });

    test('history is explicitly bounded', () {
      expect(orderHistoryLimit, 30);
    });

    test('Book Again never reuses a trusted route quote', () {
      final draft = CustomerOrder.fromJson(
        orderJson(status: 'EXPIRED')..addAll({
          'route_distance_meters': 5000,
          'route_duration_seconds': 900,
          'route_polyline': 'encoded',
          'suggested_price': 80,
          'minimum_customer_price': 56,
        }),
      ).bookAgainDraft();
      expect(draft.routeQuote, isNull);
    });

    test(
      'shared presentation remains authoritative for service and status',
      () {
        expect(serviceTypeLabel('RIDE'), 'رحلة');
        expect(orderStatusLabel(OrderStatus.driverOnWay), 'في الطريق للعميل');
        expect(orderStatusLabel(OrderStatus.expired), 'منتهية');
      },
    );
  });
}
