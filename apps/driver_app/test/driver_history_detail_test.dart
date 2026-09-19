import 'package:app_core/app_core.dart';
import 'package:driver_app/features/driver/driver_models.dart';
import 'package:driver_app/features/driver/driver_providers.dart';
import 'package:driver_app/features/driver/driver_screens.dart';
import 'package:driver_app/features/driver/driver_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('history card opens the trusted trip details sheet', (
    tester,
  ) async {
    final order = DriverOrder(
      id: 'order-1',
      serviceCode: 'RIDE',
      serviceName: 'رحلة',
      pickupAddress: 'ميدان التحرير',
      destinationAddress: 'مدينة نصر',
      proposedPrice: 100,
      agreedPrice: 125,
      status: OrderStatus.completed,
      createdAt: DateTime(2026, 9, 12),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          driverHistoryProvider.overrideWith((ref) async => [order]),
        ],
        child: MaterialApp(
          theme: buildDriverTheme(),
          home: const DriverHistoryScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('history-card-order-1')));
    await tester.pumpAndSettle();

    expect(find.text('تفاصيل الرحلة'), findsOneWidget);
    expect(find.text('التاريخ'), findsOneWidget);
    expect(find.text('الاستلام'), findsOneWidget);
    expect(find.text('الوجهة'), findsOneWidget);
    expect(find.text('قيمة الرحلة'), findsOneWidget);
    expect(find.text('ميدان التحرير'), findsOneWidget);
    expect(find.text('مدينة نصر'), findsOneWidget);
    expect(find.text('عمولة المنصة'), findsNothing);
    expect(find.text('بيانات العميل'), findsNothing);
  });
}
