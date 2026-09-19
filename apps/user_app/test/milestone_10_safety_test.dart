import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/features/orders/order_models.dart';

void main() {
  test('assigned Driver identity accepts verified vehicle presentation', () {
    final driver = DriverSummary.fromJson({
      'driver_public_id': '10000000-0000-4000-8000-000000000021',
      'driver_first_name': 'أحمد',
      'driver_type': 'INDEPENDENT',
      'completed_trip_count': 18,
      'driver_verified': true,
      'motorcycle_brand': 'Honda',
      'motorcycle_model': 'CB',
      'motorcycle_plate_number': 'ا ب ج 123',
    });
    expect(driver.driverVerified, isTrue);
    expect(driver.motorcyclePlateNumber, 'ا ب ج 123');
    expect(driver.driverPhotoUrl, isNull);
  });
}
