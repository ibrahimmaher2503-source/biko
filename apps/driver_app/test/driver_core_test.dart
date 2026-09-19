import 'package:app_core/app_core.dart';
import 'package:driver_app/features/driver/driver_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'driver order maps every trusted lifecycle state to one next action',
    () {
      const expected = {
        'DRIVER_ASSIGNED': DriverTripAction.onWay,
        'DRIVER_ON_WAY': DriverTripAction.arrived,
        'DRIVER_ARRIVED': DriverTripAction.start,
        'IN_PROGRESS': DriverTripAction.complete,
        'COMPLETED': null,
      };

      for (final entry in expected.entries) {
        final order = DriverOrder.fromJson({
          'id': 'order-id',
          'pickup_address': 'نقطة الاستلام',
          'destination_address': 'الوجهة',
          'proposed_price': 80,
          'agreed_price': '95.50',
          'status': entry.key,
          'created_at': '2026-08-30T00:00:00Z',
          'completed_at': entry.key == 'COMPLETED'
              ? '2026-08-30T01:00:00Z'
              : null,
          'service_types': {'code': 'RIDE', 'name_ar': 'رحلة'},
        });

        expect(order.nextAction, entry.value);
        expect(
          order.canDriverCancel,
          const {
            'DRIVER_ASSIGNED',
            'DRIVER_ON_WAY',
            'DRIVER_ARRIVED',
          }.contains(entry.key),
        );
        expect(order.displayPrice, 95.5);
        expect(order.serviceName, 'رحلة');
      }
    },
  );

  test('driver account eligibility follows the trusted ACTIVE status', () {
    final active = DriverAccount.fromJson({
      'id': 'driver-id',
      'driver_type': DriverType.independent.databaseValue,
      'status': DriverStatus.active.databaseValue,
      'is_online': false,
      'office_id': null,
    });
    final pending = DriverAccount.fromJson({
      'id': 'pending-driver-id',
      'driver_type': DriverType.officeDriver.databaseValue,
      'status': DriverStatus.pending.databaseValue,
      'is_online': false,
      'office_id': 'office-id',
    });

    expect(active.canGoOnline, isTrue);
    expect(pending.canGoOnline, isFalse);
  });

  test('driver lifecycle actions use imperative operational labels', () {
    expect(DriverTripAction.onWay.label, 'ابدأ التحرك');
    expect(DriverTripAction.arrived.label, 'وصلت');
    expect(DriverTripAction.start.label, 'ابدأ الرحلة');
    expect(DriverTripAction.complete.label, 'إنهاء الرحلة');
    expect(DriverTripAction.deliveryPickup.label, 'تم استلام الشحنة');
    expect(DriverTripAction.deliveryComplete.label, 'إدخال كود تأكيد التسليم');
  });

  test('earnings contract keeps driver type without inventing commission', () {
    const data = DriverEarningsData(
      driverType: DriverType.officeDriver,
      orders: [],
    );

    expect(data.driverType, DriverType.officeDriver);
    expect(data.orders, isEmpty);
  });

  test('geographic request projection keeps map and server radius context', () {
    final order = DriverOrder.fromJson({
      'id': 'order-id',
      'pickup_address': 'الاستلام',
      'destination_address': 'الوجهة',
      'pickup_lat': 30.0444,
      'pickup_lng': 31.2357,
      'destination_lat': 30.1,
      'destination_lng': 31.3,
      'proposed_price': 80,
      'agreed_price': null,
      'status': 'BIDDING',
      'created_at': '2026-08-30T00:00:00Z',
      'completed_at': null,
      'service_code': 'RIDE',
      'service_name': 'رحلة',
      'route_distance_meters': 5000,
      'route_duration_seconds': 900,
      'route_polyline': 'encoded',
      'driver_distance_meters': 1800,
      'dispatch_radius_meters': 2000,
    });
    expect(order.hasRouteCoordinates, isTrue);
    expect(order.driverDistanceMeters, 1800);
    expect(order.dispatchRadiusMeters, 2000);
    expect(order.routeDurationSeconds, 900);
  });
}
