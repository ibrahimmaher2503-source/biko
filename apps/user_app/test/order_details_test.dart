import 'package:app_core/app_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/features/orders/order_details_page.dart';
import 'package:user_app/features/orders/order_models.dart';
import 'package:user_app/features/orders/order_providers.dart';

import 'widget_test.dart' show testApp;

CustomerOrder _order(OrderStatus status) => CustomerOrder(
  id: 'order-1',
  service: ServiceType.delivery,
  pickup: const LocationSelection(
    displayAddress: 'مدينة نصر',
    latitude: 30.05,
    longitude: 31.33,
  ),
  destination: const LocationSelection(
    displayAddress: 'مصر الجديدة',
    latitude: 30.11,
    longitude: 31.34,
  ),
  proposedPrice: 80,
  agreedPrice: status == OrderStatus.completed ? 90 : null,
  status: status,
  createdAt: DateTime.utc(2026, 9, 1),
  cancelledAt: status == OrderStatus.cancelled
      ? DateTime.utc(2026, 9, 1, 1)
      : null,
);

void main() {
  testWidgets('cancelled receipt does not imply a cash payment', (
    tester,
  ) async {
    await tester.pumpWidget(
      testApp(
        const OrderDetailsPage(orderId: 'order-1'),
        overrides: [
          orderDetailsProvider(
            'order-1',
          ).overrideWith((_) async => _order(OrderStatus.cancelled)),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('طريقة الدفع'), findsOneWidget);
    expect(find.text('نقدي'), findsOneWidget);
    expect(find.text('لم يكتمل الطلب. لا تُفرض رسوم إلغاء.'), findsOneWidget);
    expect(find.textContaining('مدفوع'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
