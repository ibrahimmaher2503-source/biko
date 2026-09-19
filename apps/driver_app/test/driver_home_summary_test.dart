import 'package:driver_app/features/driver/driver_models.dart';
import 'package:driver_app/features/driver/driver_screens.dart';
import 'package:app_core/app_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('home summary counts and totals only completed earnings for today', () {
    final today = DateTime(2026, 9, 13, 12);
    final data = DriverEarningsData(
      driverType: DriverType.independent,
      entries: [
        _entry('today-1', DateTime(2026, 9, 13, 8), 80, 72),
        _entry('today-2', DateTime(2026, 9, 13, 18), 95.5, 85.95),
        _entry('yesterday', DateTime(2026, 9, 12, 23, 59), 200, 180),
      ],
    );

    final summary = driverHomeTodaySummary(data, today);

    expect(summary.trips, 2);
    expect(summary.earnings, 157.95);
    expect(summary.earningsKnown, isTrue);
  });
}

DriverEarningEntry _entry(
  String id,
  DateTime completedAt,
  double grossFare,
  double driverNet,
) => DriverEarningEntry(
  orderId: id,
  completedAt: completedAt,
  grossFare: grossFare,
  isFinanciallyKnown: true,
  driverNet: driverNet,
);
