import 'package:driver_app/features/driver/driver_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('earnings preserves unknown legacy commission', () {
    final known = DriverEarningEntry.fromJson({
      'order_id': 'new',
      'completed_at': '2026-09-13T01:00:00Z',
      'gross_fare': 100,
      'financial_status': 'SNAPSHOTTED',
      'platform_commission_amount': 10,
      'driver_net_amount': 90,
    });
    final legacy = DriverEarningEntry.fromJson({
      'order_id': 'old',
      'completed_at': '2026-09-01T01:00:00Z',
      'gross_fare': 80,
      'financial_status': 'UNKNOWN',
      'platform_commission_amount': null,
      'driver_net_amount': null,
    });

    expect(known.isFinanciallyKnown, isTrue);
    expect(known.platformCommission, 10);
    expect(known.driverNet, 90);
    expect(legacy.isFinanciallyKnown, isFalse);
    expect(legacy.platformCommission, isNull);
    expect(legacy.driverNet, isNull);
  });
}
