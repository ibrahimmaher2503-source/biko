import 'package:app_core/app_core.dart';
import 'package:driver_app/features/driver/driver_models.dart';
import 'package:driver_app/features/driver/driver_providers.dart';
import 'package:driver_app/features/driver/driver_screens.dart';
import 'package:driver_app/features/driver/driver_service.dart';
import 'package:driver_app/features/driver/driver_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FreshContactService extends DriverService {
  _FreshContactService(this.responses)
    : super(
        SupabaseClient(
          'http://localhost',
          'test-only',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
      );

  final List<DriverCustomerContact?> responses;
  var reads = 0;

  @override
  Future<DriverCustomerContact?> loadCustomerContact(String orderId) async {
    final index = reads++;
    return responses[index.clamp(0, responses.length - 1)];
  }
}

DriverOrder _order(OrderStatus status) => DriverOrder(
  id: 'order-1',
  serviceCode: 'RIDE',
  serviceName: 'رحلة',
  pickupAddress: 'نقطة الاستلام',
  destinationAddress: 'الوجهة',
  proposedPrice: 100,
  status: status,
  createdAt: DateTime(2026, 9, 12),
);

void main() {
  testWidgets('contact is active-only and rechecks before dialing', (
    tester,
  ) async {
    for (final status in const [
      OrderStatus.driverAssigned,
      OrderStatus.driverOnWay,
      OrderStatus.driverArrived,
      OrderStatus.inProgress,
    ]) {
      expect(canDriverContactCustomer(status), isTrue);
    }
    expect(canDriverContactCustomer(OrderStatus.completed), isFalse);

    final service = _FreshContactService([
      const DriverCustomerContact(
        name: 'عميل الاختبار',
        phone: '+201011111111',
      ),
      null,
    ]);
    Uri? launched;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [driverServiceProvider.overrideWithValue(service)],
        child: MaterialApp(
          theme: buildDriverTheme(),
          home: Scaffold(
            body: DriverCustomerContactActions(
              order: _order(OrderStatus.driverAssigned),
              launcher: (uri) async {
                launched = uri;
                return true;
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('call-customer')), findsOneWidget);
    await tester.tap(find.byKey(const Key('call-customer')));
    await tester.pumpAndSettle();

    expect(service.reads, 2);
    expect(launched, isNull);
    expect(find.text('بيانات الاتصال لم تعد متاحة الآن.'), findsOneWidget);
  });
}
