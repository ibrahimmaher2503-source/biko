import 'dart:async';

import 'package:app_core/app_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user_app/app/user_theme.dart';
import 'package:user_app/features/orders/order_models.dart';
import 'package:user_app/features/orders/order_providers.dart';
import 'package:user_app/features/orders/order_service.dart';
import 'package:user_app/features/orders/order_status_page.dart';
import 'package:user_app/features/orders/order_tracking.dart';
import 'package:user_app/features/orders/widgets/assigned_driver_widgets.dart';
import 'package:user_app/features/orders/widgets/offer_widgets.dart';

void main() {
  testWidgets(
    'late supporting-data failure does not leak into a terminal order',
    (tester) async {
      final service = _DelayedDriverService();
      const key = ValueKey('same-order');

      await tester.pumpWidget(
        _app(
          OrderStatusPage(
            key: key,
            initialOrder: _order(OrderStatus.driverOnWay),
          ),
          service,
        ),
      );
      await tester.pump();

      await tester.pumpWidget(
        _app(
          OrderStatusPage(
            key: key,
            initialOrder: _order(OrderStatus.completed),
          ),
          service,
        ),
      );
      service.driver.completeError(TimeoutException('late driver request'));
      await tester.pumpAndSettle();

      expect(find.text('اكتمل طلبك'), findsOneWidget);
      expect(
        find.text(const ReadFailure(ReadFailureKind.connection).message),
        findsNothing,
      );
      expect(find.byIcon(Icons.cloud_off_outlined), findsNothing);
    },
  );

  testWidgets('offers keep a prominent price and the approved اختيار CTA', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _app(
        DriverOfferCard(
          offer: const DriverOffer(
            id: 'offer-1',
            price: 145,
            driverPublicId: 'driver-1',
            driverFirstName: 'أحمد عبدالرحمن الطويل للاختبار',
            driverType: DriverType.officeDriver,
            officeDisplayName: 'مكتب النخبة للدراجات والتنقل داخل القاهرة',
            completedTripCount: 172,
          ),
        ),
        _DelayedDriverService(),
      ),
    );

    expect(find.text('اختيار'), findsOneWidget);
    expect(find.text('اختيار هذا السائق'), findsNothing);
    expect(find.text('145 ج.م'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('assigned identity keeps long names, model, and plate readable', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const DriverSummaryCard(
          driver: DriverSummary(
            driverPublicId: 'driver-1',
            driverFirstName: 'أحمد عبدالرحمن الطويل للاختبار',
            driverType: DriverType.officeDriver,
            officeDisplayName: 'مكتب النخبة للدراجات والتنقل',
            completedTripCount: 172,
            driverVerified: true,
            motorcycleBrand: 'Honda',
            motorcycleModel: 'CBR 150R إصدار المدينة الطويل',
            motorcyclePlateNumber: 'أ ب ج ١٢٣٤',
          ),
        ),
        _DelayedDriverService(),
      ),
    );

    expect(find.text('أحمد عبدالرحمن الطويل للاختبار'), findsOneWidget);
    expect(find.byKey(const Key('driver-plate')), findsOneWidget);
    expect(find.textContaining('Honda CBR 150R'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('active and delivery states retain their human hierarchy', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        OrderStatusPage(initialOrder: _order(OrderStatus.driverOnWay)),
        _DelayedDriverService(),
      ),
    );
    await tester.pump();
    expect(find.text('السائق في الطريق'), findsOneWidget);

    await tester.pumpWidget(
      _app(
        const DeliveryConfirmationCodeCard(code: '4821'),
        _DelayedDriverService(),
      ),
    );
    final code = tester.widget<SelectableText>(
      find.byKey(const Key('delivery-confirmation-code')),
    );
    expect(code.textDirection, TextDirection.ltr);
    expect(find.textContaining('تسليم الشحنة'), findsOneWidget);
  });
}

Widget _app(Widget child, OrderService service) => ProviderScope(
  overrides: [
    orderServiceProvider.overrideWithValue(service),
    orderTrackingServiceProvider.overrideWithValue(
      OrderTrackingService(_client()),
    ),
  ],
  child: MaterialApp(
    theme: buildUserTheme(),
    builder: (context, child) =>
        Directionality(textDirection: TextDirection.rtl, child: child!),
    home: child,
  ),
);

CustomerOrder _order(OrderStatus status) => CustomerOrder(
  id: '10000000-0000-4000-8000-000000000001',
  service: ServiceType.ride,
  pickup: const LocationSelection(
    displayAddress: 'شارع النزهة، مدينة نصر',
    latitude: 30.07,
    longitude: 31.34,
  ),
  destination: const LocationSelection(
    displayAddress: 'التجمع الخامس، القاهرة الجديدة',
    latitude: 30.01,
    longitude: 31.48,
  ),
  proposedPrice: 80,
  agreedPrice: 90,
  driverId: status == OrderStatus.completed ? null : 'driver-1',
  status: status,
  createdAt: DateTime.utc(2026, 9, 8),
);

class _DelayedDriverService extends OrderService {
  _DelayedDriverService() : super(_client());

  final driver = Completer<DriverSummary?>();

  @override
  Future<DriverSummary?> loadAssignedDriver(String orderId) => driver.future;
}

SupabaseClient _client() => SupabaseClient(
  'http://localhost',
  'test-anon-key',
  authOptions: const AuthClientOptions(autoRefreshToken: false),
);
