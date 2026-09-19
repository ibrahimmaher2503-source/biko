import 'package:app_core/app_core.dart';
import 'package:driver_app/features/driver/driver_models.dart';
import 'package:driver_app/features/driver/driver_providers.dart';
import 'package:driver_app/features/driver/driver_screens.dart';
import 'package:driver_app/features/driver/driver_service.dart';
import 'package:driver_app/features/driver/driver_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _DriverService extends DriverService {
  _DriverService({required this.order, required this.offer})
    : super(
        SupabaseClient(
          'http://localhost',
          'test-only',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
      );

  final DriverOrder order;
  final DriverOffer? offer;

  @override
  Future<DriverOrder> loadOrder(String orderId) async => order;

  @override
  Future<DriverOffer?> loadOffer(String orderId) async => offer;
}

GoRouter _router(String initialLocation) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(
      path: '/request/:orderId',
      builder: (_, state) =>
          RequestDetailsScreen(orderId: state.pathParameters['orderId']!),
    ),
    GoRoute(
      path: '/waiting/:orderId',
      builder: (_, state) =>
          OfferWaitingScreen(orderId: state.pathParameters['orderId']!),
    ),
    GoRoute(path: '/home', builder: (_, _) => const SizedBox.shrink()),
  ],
);

Future<void> _mount(
  WidgetTester tester,
  _DriverService service,
  GoRouter router,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [driverServiceProvider.overrideWithValue(service)],
      child: MaterialApp.router(
        theme: buildDriverTheme(),
        routerConfig: router,
        builder: (_, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: DriverRecoveryBoundary(child: child!),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

DriverOrder _request() => DriverOrder(
  id: 'request-1',
  serviceCode: ServiceType.delivery.databaseValue,
  serviceName: 'توصيل',
  pickupAddress: 'شارع طويل جدًا ' * 20,
  destinationAddress: 'وجهة طويلة جدًا ' * 20,
  proposedPrice: 80,
  status: OrderStatus.bidding,
  createdAt: DateTime.now(),
  biddingDeadline: DateTime.now().add(const Duration(minutes: 2)),
  dispatchRadiusMeters: 8000,
);

void main() {
  test('request deadline is adjusted from the database clock', () {
    final serverNow = DateTime.now().toUtc().add(const Duration(hours: 2));
    final order = DriverOrder.fromJson({
      'id': 'request-clock',
      'service_code': 'RIDE',
      'service_name': 'رحلة',
      'pickup_address': 'أ',
      'destination_address': 'ب',
      'proposed_price': 50,
      'status': 'BIDDING',
      'created_at': serverNow.toIso8601String(),
      'bidding_expires_at': serverNow
          .add(const Duration(seconds: 90))
          .toIso8601String(),
      'server_now': serverNow.toIso8601String(),
    });

    final remaining = order.biddingDeadline!.difference(DateTime.now());
    expect(remaining.inSeconds, inInclusiveRange(88, 90));
  });

  testWidgets(
    'request details keeps long routes safe, hides dispatch radius, and counts down',
    (tester) async {
      final router = _router('/request/request-1');
      addTearDown(router.dispose);
      await _mount(
        tester,
        _DriverService(order: _request(), offer: null),
        router,
      );

      expect(find.text('الوقت المتبقي'), findsOneWidget);
      expect(find.textContaining('نطاق'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'waiting state compares prices and refreshes from a server deadline',
    (tester) async {
      final order = _request();
      final router = _router('/waiting/request-1');
      addTearDown(router.dispose);
      await _mount(
        tester,
        _DriverService(
          order: order,
          offer: DriverOffer(
            id: 'offer-1',
            orderId: order.id,
            price: 95,
            customerPrice: order.proposedPrice,
            status: OfferStatus.active,
            orderStatus: OrderStatus.bidding,
            biddingDeadline: order.biddingDeadline,
            pickupAddress: order.pickupAddress,
            destinationAddress: order.destinationAddress,
          ),
        ),
        router,
      );
      expect(
        find.byKey(const ValueKey('offer-price-comparison')),
        findsOneWidget,
      );
      expect(find.text('سعر العميل'), findsOneWidget);
      expect(find.text('الوقت المتبقي'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('سحب العرض'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('سحب العرض'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
