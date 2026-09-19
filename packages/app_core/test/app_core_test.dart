import 'package:app_core/app_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shared backend enum names match PostgreSQL values', () {
    expect(OrderStatus.driverAssigned.databaseValue, 'DRIVER_ASSIGNED');
    expect(DriverType.officeDriver.databaseValue, 'OFFICE_DRIVER');
    expect(DriverStatus.active.databaseValue, 'ACTIVE');
    expect(ServiceType.values.map((value) => value.databaseValue), [
      'RIDE',
      'DELIVERY',
    ]);
  });
}
