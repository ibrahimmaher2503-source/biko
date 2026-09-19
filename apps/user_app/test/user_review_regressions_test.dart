import 'dart:async';
import 'dart:convert';

import 'package:app_core/app_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
// Test-only access to already-installed SDK boundaries; no extra dependency.
// ignore: depend_on_referenced_packages
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' show Response;
// ignore: depend_on_referenced_packages
import 'package:http/testing.dart' show MockClient;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user_app/features/maps/location_picker_page.dart';
import 'package:user_app/features/orders/create_order_page.dart';
import 'package:user_app/features/orders/order_models.dart';
import 'package:user_app/features/orders/order_providers.dart';
import 'package:user_app/features/orders/order_service.dart';
import 'package:user_app/features/orders/order_status_page.dart';

import 'user_core_test.dart' show orderJson;
import 'widget_test.dart' show FakeOrderService, testApp, testOrder, testQuote;

void main() {
  for (final status in [
    'BIDDING',
    'DRIVER_ASSIGNED',
    'EXPIRED',
    'CANCELLED',
    'COMPLETED',
  ]) {
    test('active order uses server expiry result $status', () async {
      final user = {
        'id': 'aabbccdd-0000-4000-8000-000000000001',
        'aud': 'authenticated',
        'email': 'review@example.invalid',
        'created_at': '2026-09-08T00:00:00Z',
      };
      String encode(Object value) =>
          base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
      var expiryCalls = 0;
      final client = SupabaseClient(
        'https://review.invalid',
        'fixture-only',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((request) async {
          Object result;
          if (request.url.path.endsWith('/token')) {
            result = {
              'access_token':
                  '${encode({'alg': 'HS256'})}.${encode({'sub': user['id'], 'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600})}.fixture',
              'refresh_token': 'fixture-only',
              'token_type': 'bearer',
              'expires_in': 3600,
              'user': user,
            };
          } else if (request.url.path.endsWith('/orders')) {
            expect(
              request.url.queryParameters['customer_id'],
              'eq.${user['id']}',
            );
            result = [
              orderJson(
                expiresAt: DateTime.now().toUtc().subtract(
                  const Duration(seconds: 1),
                ),
              ),
            ];
          } else {
            expect(request.url.path, '/rest/v1/rpc/expire_customer_order');
            expiryCalls++;
            result = orderJson(status: status);
          }
          return Response(
            jsonEncode(result),
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(client.dispose);
      await client.auth.signInWithPassword(
        email: 'review@example.invalid',
        password: 'fixture-password',
      );
      final result = await OrderService(client).loadActiveOrder();
      expect(expiryCalls, 1);
      if (status == 'BIDDING' || status == 'DRIVER_ASSIGNED') {
        expect(
          result?.status,
          status == 'BIDDING'
              ? OrderStatus.bidding
              : OrderStatus.driverAssigned,
        );
      } else {
        expect(result, isNull);
      }
    });
  }

  testWidgets(
    'invalid new route rejects a pending old quote and clears loading',
    (tester) async {
      final service = _DeferredQuoteService();
      final draft = testOrder().bookAgainDraft();
      await tester.pumpWidget(
        testApp(
          CreateOrderPage(service: ServiceType.ride, prefill: draft),
          overrides: [orderServiceProvider.overrideWithValue(service)],
        ),
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('pickup-location')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      Navigator.of(
        tester.element(find.byType(LocationPickerPage)),
      ).pop(draft.destination);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      service.quote.complete(testQuote());
      await tester.pumpAndSettle();
      expect(find.text(draft.pickup.displayAddress), findsNothing);
      expect(find.text(draft.destination.displayAddress), findsNWidgets(2));
      expect(find.text('جاري حساب المسار والسعر...'), findsNothing);
      expect(
        tester
            .widget<PrimaryButton>(find.byKey(const Key('create-order')))
            .onPressed,
        isNull,
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final fail in [false, true]) {
    testWidgets(
      'older refresh ${fail ? 'failure' : 'result'} cannot replace newer state',
      (tester) async {
        final service = _DeferredRefreshService();
        final initial = testOrder();
        Widget page(CustomerOrder order) => testApp(
          OrderStatusPage(
            key: const ValueKey('same-order'),
            initialOrder: order,
          ),
          overrides: [orderServiceProvider.overrideWithValue(service)],
        );
        await tester.pumpWidget(page(initial));
        await tester.pump();
        await tester.tap(find.byTooltip('تحديث الحالة'));
        await tester.pump();
        await tester.pumpWidget(
          page(testOrder(status: OrderStatus.driverOnWay)),
        );
        await tester.pump();
        if (fail) {
          service.read.completeError(TimeoutException('old read'));
        } else {
          service.read.complete(initial);
        }
        await tester.pump();
        expect(find.text('السائق في الطريق'), findsOneWidget);
        expect(find.text('نبحث عن عروض السائقين'), findsNothing);
        expect(
          find.text(const ReadFailure(ReadFailureKind.connection).message),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('newer state also wins while old refresh is loading offers', (
    tester,
  ) async {
    final service = _DeferredRefreshService();
    final initial = testOrder();
    Widget page(CustomerOrder order) => testApp(
      OrderStatusPage(key: const ValueKey('same-order'), initialOrder: order),
      overrides: [orderServiceProvider.overrideWithValue(service)],
    );
    await tester.pumpWidget(page(initial));
    await tester.pump();
    service.holdOffers = true;
    service.read.complete(initial);
    await tester.tap(find.byTooltip('تحديث الحالة'));
    await tester.pump();
    await tester.pumpWidget(page(testOrder(status: OrderStatus.driverOnWay)));
    await tester.pump();
    service.offers.complete(const []);
    await tester.pump();
    expect(find.text('السائق في الطريق'), findsOneWidget);
    expect(find.text('نبحث عن عروض السائقين'), findsNothing);
  });

  for (final detail in ['driver', 'delivery-code']) {
    testWidgets('$detail failure preserves the authoritative active state', (
      tester,
    ) async {
      final service = _DeferredRefreshService(failingDetail: detail);
      await tester.pumpWidget(
        testApp(
          OrderStatusPage(
            initialOrder: testOrder(service: ServiceType.delivery),
          ),
          overrides: [orderServiceProvider.overrideWithValue(service)],
        ),
      );
      await tester.pump();
      service.read.complete(
        testOrder(
          status: OrderStatus.inProgress,
          service: ServiceType.delivery,
        ),
      );
      await tester.tap(find.byTooltip('تحديث الحالة'));
      await tester.pump();
      expect(find.text('التوصيل جارٍ'), findsOneWidget);
      expect(find.text('نبحث عن عروض السائقين'), findsNothing);
      expect(find.byKey(const Key('show-cancellation')), findsNothing);
      expect(
        find.text(const ReadFailure(ReadFailureKind.connection).message),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('denied location permission retains its actionable message', (
    tester,
  ) async {
    final original = GeolocatorPlatform.instance;
    GeolocatorPlatform.instance = _DeniedLocation();
    addTearDown(() => GeolocatorPlatform.instance = original);
    await tester.pumpWidget(
      testApp(const LocationPickerPage(title: 'اختر الموقع')),
    );
    await tester.tap(find.byTooltip('استخدم موقعي الحالي'));
    await tester.pump();
    expect(
      find.text('إذن الموقع مطلوب لاستخدام موقعك الحالي.'),
      findsOneWidget,
    );
    expect(find.text('تعذر تحديد موقعك الآن.'), findsNothing);
  });

  testWidgets(
    'repeated elapsed snapshots do not loop expiry when server retains bidding',
    (tester) async {
      final deadline = DateTime.now().toUtc().subtract(
        const Duration(seconds: 1),
      );
      final service = _ServerBiddingService(deadline);
      Widget page() => testApp(
        OrderStatusPage(
          key: const ValueKey('same-order'),
          initialOrder: testOrder(expiresAt: deadline),
        ),
        overrides: [orderServiceProvider.overrideWithValue(service)],
      );
      await tester.pumpWidget(page());
      await tester.pumpAndSettle();
      expect(service.expiryCalls, 1);
      await tester.pumpWidget(page());
      await tester.pumpAndSettle();
      expect(service.expiryCalls, 1);
      expect(find.text('نبحث عن عروض السائقين'), findsOneWidget);
    },
  );
}

class _ServerBiddingService extends FakeOrderService {
  _ServerBiddingService(this.deadline);
  final DateTime deadline;
  int expiryCalls = 0;
  @override
  Future<CustomerOrder> loadOrder(String orderId) async =>
      testOrder(expiresAt: deadline);
  @override
  Future<CustomerOrder> expireElapsedOrder(CustomerOrder current) async {
    expiryCalls++;
    return testOrder(expiresAt: deadline);
  }
}

class _DeferredQuoteService extends FakeOrderService {
  final quote = Completer<RouteQuote>();
  @override
  Future<RouteQuote> createRouteQuote(
    ServiceType service,
    LocationSelection pickup,
    LocationSelection destination,
  ) => quote.future;
}

class _DeferredRefreshService extends FakeOrderService {
  _DeferredRefreshService({this.failingDetail});
  final String? failingDetail;
  final read = Completer<CustomerOrder>();
  final offers = Completer<List<DriverOffer>>();
  bool holdOffers = false;
  @override
  Future<CustomerOrder> loadOrder(String orderId) => read.future;
  @override
  Future<List<DriverOffer>> loadOffers(String orderId) async =>
      holdOffers ? offers.future : const [];
  @override
  Future<DriverSummary?> loadAssignedDriver(String orderId) async {
    if (failingDetail == 'driver') throw TimeoutException('driver unavailable');
    return null;
  }

  @override
  Future<String?> loadDeliveryConfirmationCode(String orderId) async {
    if (failingDetail == 'delivery-code') {
      throw TimeoutException('code unavailable');
    }
    return null;
  }
}

class _DeniedLocation extends GeolocatorPlatform {
  @override
  Future<bool> isLocationServiceEnabled() async => true;
  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.denied;
  @override
  Future<LocationPermission> requestPermission() async =>
      LocationPermission.denied;
}
