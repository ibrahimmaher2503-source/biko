import 'package:driver_app/features/driver/driver_models.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> orderJson(String status) => {
  'id': '10000000-0000-4000-8000-000000000010',
  'pickup_address': 'الاستلام',
  'destination_address': 'التسليم',
  'proposed_price': 80,
  'status': status,
  'created_at': '2026-08-30T00:00:00Z',
  'service_code': 'DELIVERY',
  'service_name': 'توصيل',
};

void main() {
  test(
    'Delivery uses one pickup action and one final code action, never OTP',
    () {
      expect(
        DriverOrder.fromJson(orderJson('DRIVER_ON_WAY')).nextAction,
        DriverTripAction.deliveryPickup,
      );
      expect(
        DriverOrder.fromJson(orderJson('IN_PROGRESS')).nextAction,
        DriverTripAction.deliveryComplete,
      );
      expect(
        DriverOrder.fromJson(orderJson('DRIVER_ARRIVED')).nextAction,
        isNull,
      );
    },
  );

  test('verification overview maps expiry/rejection and readiness reason', () {
    final overview = DriverVerificationOverview.fromJson({
      'driver_status': 'ACTIVE',
      'ride_safety_equipment_confirmed': false,
      'safety_reason': 'رخصة القيادة منتهية.',
      'driver_documents': [
        {
          'id': 'doc-1',
          'document_type': 'DRIVING_LICENSE',
          'status': 'EXPIRED',
          'expiry_date': '2026-08-30',
          'rejection_reason': null,
        },
      ],
      'motorcycle_documents': [],
      'motorcycle': null,
    });
    expect(overview.readyForNewWork, isFalse);
    expect(overview.driverDocuments.single.status, DocumentStatus.expired);
    expect(overview.safetyEquipmentConfirmed, isFalse);
  });
}
