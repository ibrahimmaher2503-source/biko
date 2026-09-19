import 'dart:async';

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

DriverOrder order(
  String id,
  OrderStatus status, {
  int? driverDistanceMeters,
  int? routeDistanceMeters,
  int? routeDurationSeconds,
}) => DriverOrder(
  id: id,
  serviceCode: 'RIDE',
  serviceName: 'رحلة',
  pickupAddress: 'استلام $id',
  destinationAddress: 'وجهة $id',
  proposedPrice: 80,
  agreedPrice: status == OrderStatus.bidding ? null : 90,
  status: status,
  createdAt: DateTime(2026, 8, 30),
  driverDistanceMeters: driverDistanceMeters,
  routeDistanceMeters: routeDistanceMeters,
  routeDurationSeconds: routeDurationSeconds,
);

class FakeDriverService extends DriverService {
  FakeDriverService()
    : super(
        SupabaseClient(
          'http://localhost',
          'test-only',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
      );
  final offers = <DriverOffer>[];
  DriverOrder currentOrder = order('A', OrderStatus.bidding);
  DriverOrder? active;
  var writes = 0;
  bool isOnline = true;
  DriverVerificationOverview verification = const DriverVerificationOverview(
    driverStatus: DriverStatus.active,
    safetyEquipmentConfirmed: true,
    driverDocuments: [],
    motorcycleDocuments: [],
  );
  String? withdrawn;
  bool loseResponse = false;
  bool failRead = false;
  bool failOptional = false;
  ReadFailureKind? failAccount;
  var optionalReads = 0;
  Completer<void>? readGate;

  @override
  Future<DriverAccount?> loadAccount() async {
    if (readGate != null) await readGate!.future;
    if (failAccount case final kind?) throw ReadFailure(kind);
    if (failRead) throw const ReadFailure(ReadFailureKind.connection);
    return DriverAccount(
      id: 'driver',
      type: DriverType.independent,
      status: DriverStatus.active,
      isOnline: isOnline,
    );
  }

  @override
  Future<DriverVerificationOverview> loadVerificationOverview() async =>
      verification;

  @override
  Future<DriverOrder?> loadActiveOrder(String driverId) async => active;
  @override
  Future<List<DriverOrder>> loadAvailableRequests() async {
    optionalReads++;
    if (failOptional) throw const ReadFailure(ReadFailureKind.connection);
    return active == null ? [currentOrder] : [];
  }

  @override
  Future<List<DriverOffer>> loadWaitingOffers({DriverOffer? after}) async {
    optionalReads++;
    if (failOptional) throw const ReadFailure(ReadFailureKind.connection);
    final offset = after == null
        ? 0
        : offers.indexWhere((offer) => offer.id == after.id) + 1;
    return offers
        .where((o) => o.status == OfferStatus.active)
        .skip(offset)
        .take(50)
        .toList();
  }

  @override
  Future<DriverOrder> loadOrder(String orderId) async => currentOrder;
  @override
  Future<DriverOffer?> loadOffer(String orderId) async {
    final matches = offers.where((o) => o.orderId == orderId);
    return matches.isEmpty ? null : matches.last;
  }

  @override
  Future<DriverOffer> submitOffer(String orderId, double price) async {
    writes++;
    final offer = DriverOffer(
      id: 'offer-$orderId',
      orderId: orderId,
      price: price,
      status: OfferStatus.active,
      orderStatus: OrderStatus.bidding,
      biddingDeadline: DateTime.now().add(const Duration(seconds: 90)),
    );
    offers.add(offer);
    if (loseResponse) throw TimeoutException('commit succeeded, response lost');
    return offer;
  }

  @override
  Future<void> withdrawOffer(String offerId) async {
    writes++;
    withdrawn = offerId;
    final index = offers.indexWhere((o) => o.id == offerId);
    final old = offers[index];
    offers[index] = DriverOffer(
      id: old.id,
      orderId: old.orderId,
      price: old.price,
      status: OfferStatus.withdrawn,
    );
  }

  @override
  Future<DriverOrder> advanceOrder(
    String orderId,
    DriverTripAction action,
  ) async {
    writes++;
    currentOrder = order(orderId, OrderStatus.driverOnWay);
    active = currentOrder;
    if (loseResponse) throw TimeoutException('response lost');
    return currentOrder;
  }
}

GoRouter router(String initial) => GoRouter(
  initialLocation: initial,
  routes: [
    GoRoute(path: '/restore', builder: (_, _) => const DriverBootstrapScreen()),
    GoRoute(path: '/home', builder: (_, _) => const DriverHomeScreen()),
    GoRoute(path: '/profile', builder: (_, _) => const DriverProfileScreen()),
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
    GoRoute(
      path: '/active-order/:orderId',
      builder: (_, state) =>
          ActiveOrderScreen(orderId: state.pathParameters['orderId']!),
    ),
  ],
);

Future<void> mount(
  WidgetTester tester,
  FakeDriverService service,
  GoRouter routes,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [driverServiceProvider.overrideWithValue(service)],
      child: MaterialApp.router(
        theme: buildDriverTheme(),
        routerConfig: routes,
        builder: (_, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: DriverRecoveryBoundary(child: child!),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'F three waiting offers retain order identity and withdraw only chosen offer',
    (tester) async {
      final service = FakeDriverService();
      for (final id in ['A', 'B', 'C']) {
        service.offers.add(
          DriverOffer.fromJson({
            'id': 'offer-$id',
            'order_id': id,
            'offered_price': 90,
            'status': 'ACTIVE',
            'order_status': 'BIDDING',
            'bidding_expires_at': DateTime.now()
                .add(const Duration(seconds: 90))
                .toIso8601String(),
            'server_now': DateTime.now().toIso8601String(),
            'pickup_address': 'استلام $id',
            'destination_address': 'وجهة $id',
          }),
        );
      }
      final routes = router('/home');
      addTearDown(routes.dispose);
      await mount(tester, service, routes);
      expect(find.byKey(const ValueKey('offer-A')), findsOneWidget);
      expect(find.byKey(const ValueKey('offer-B')), findsOneWidget);
      expect(find.byKey(const ValueKey('offer-C')), findsOneWidget);
      final target = find.descendant(
        of: find.byKey(const ValueKey('offer-B')),
        matching: find.byType(TextButton),
      );
      await tester.ensureVisible(target);
      await tester.pumpAndSettle();
      await tester.tap(target);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<OfferWaitingScreen>(find.byType(OfferWaitingScreen))
            .orderId,
        'B',
      );
      await tester.scrollUntilVisible(
        find.text('سحب العرض'),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('سحب العرض'));
      await tester.pumpAndSettle();
      expect(service.withdrawn, 'offer-B');
      expect(
        service.offers
            .where((o) => o.status == OfferStatus.active)
            .map((o) => o.orderId),
        ['A', 'C'],
      );
      expect(find.text('تم سحب العرض'), findsOneWidget);
    },
  );

  testWidgets(
    'G/I lost submit response reconciles, offline retry never resubmits',
    (tester) async {
      final service = FakeDriverService()..loseResponse = true;
      final routes = router('/request/A');
      addTearDown(routes.dispose);
      await mount(tester, service, routes);
      service.failRead = true;
      await tester.tap(find.text('قبول سعر العميل'));
      await tester.pumpAndSettle();
      expect(find.textContaining('تعذر الاتصال'), findsOneWidget);
      expect(service.writes, 1);
      service.failRead = false;
      await tester.tap(find.text('إعادة التحقق'));
      await tester.pumpAndSettle();
      expect(service.writes, 1);
      expect(find.text('لديك عرض لهذا الطلب'), findsOneWidget);
      expect(find.text('قبول سعر العميل'), findsNothing);
      await tester.tap(find.text('فتح العرض'));
      await tester.pumpAndSettle();
      expect(routes.routeInformationProvider.value.uri.path, '/waiting/A');
      expect(find.text('تم إرسال عرضك'), findsOneWidget);
    },
  );

  testWidgets(
    'H lost lifecycle response renders next server CTA without retry',
    (tester) async {
      final service = FakeDriverService()
        ..currentOrder = order('A', OrderStatus.driverAssigned)
        ..loseResponse = true;
      service.active = service.currentOrder;
      final routes = router('/active-order/A');
      addTearDown(routes.dispose);
      await mount(tester, service, routes);
      service.readGate = Completer<void>();
      await tester.tap(find.text('ابدأ التحرك'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      expect(find.text('جاري التحقق من الحالة...'), findsOneWidget);
      service.readGate!.complete();
      await tester.pumpAndSettle();
      expect(service.writes, 1);
      final button = tester.widget<FilledButton>(
        find.byType(FilledButton).first,
      );
      expect((button.child as Text).data, 'وصلت');
      expect(
        find.text('في الطريق للعميل'),
        findsOneWidget,
      ); // status, not the old CTA
    },
  );

  for (final status in [
    OrderStatus.driverAssigned,
    OrderStatus.driverOnWay,
    OrderStatus.driverArrived,
    OrderStatus.inProgress,
    null,
    OrderStatus.completed,
  ]) {
    testWidgets('K authenticated bootstrap restores $status without loops', (
      tester,
    ) async {
      final service = FakeDriverService();
      final active =
          status == OrderStatus.driverAssigned ||
          status == OrderStatus.driverOnWay ||
          status == OrderStatus.driverArrived ||
          status == OrderStatus.inProgress;
      if (status != null) service.active = order('A', status);
      if (active) {
        service.currentOrder = service.active!;
      }
      final routes = router('/restore');
      addTearDown(routes.dispose);
      await mount(tester, service, routes);
      expect(
        routes.routeInformationProvider.value.uri.path,
        active ? '/active-order/A' : '/home',
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'F assignment refresh shows active trip and zero waiting offers',
    (tester) async {
      final service = FakeDriverService()
        ..currentOrder = order('A', OrderStatus.driverAssigned);
      service.active = service.currentOrder;
      final routes = router('/home');
      addTearDown(routes.dispose);
      await mount(tester, service, routes);
      expect(find.text('الرحلة النشطة'), findsOneWidget);
      expect(
        tester.getTopLeft(find.byKey(const Key('active-order-priority'))).dy,
        lessThan(
          tester.getTopLeft(find.byKey(const Key('online-status-card'))).dy,
        ),
      );
      expect(find.byType(WaitingOffersList), findsNothing);
      expect(
        find.text('استقبال الطلبات متوقف حتى انتهاء الرحلة الحالية.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Driver Home explains a verification block before online', (
    tester,
  ) async {
    final service = FakeDriverService()
      ..isOnline = false
      ..verification = const DriverVerificationOverview(
        driverStatus: DriverStatus.active,
        safetyEquipmentConfirmed: false,
        safetyReason: 'انتهت صلاحية رخصة القيادة.',
        driverDocuments: [],
        motorcycleDocuments: [],
      );
    final routes = router('/home');
    addTearDown(routes.dispose);
    await mount(tester, service, routes);
    expect(find.text('انتهت صلاحية رخصة القيادة.'), findsOneWidget);
    expect(find.text('استكمال التحقق'), findsOneWidget);
    expect(find.text('فعّل الاتصال لاستقبال الطلبات المناسبة.'), findsNothing);
  });

  testWidgets('Driver request card exposes available route facts only', (
    tester,
  ) async {
    final service = FakeDriverService()
      ..currentOrder = order(
        'A',
        OrderStatus.bidding,
        driverDistanceMeters: 1800,
        routeDistanceMeters: 5000,
        routeDurationSeconds: 901,
      );
    final routes = router('/home');
    addTearDown(routes.dispose);
    await mount(tester, service, routes);
    expect(find.text('يبعد عنك 1.8 كم'), findsOneWidget);
    expect(find.text('المسافة 5 كم'), findsOneWidget);
    expect(find.text('حوالي 16 دقيقة'), findsOneWidget);
    expect(find.textContaining('نطاق'), findsNothing);
  });

  for (final state in <(OrderStatus, String)>[
    (OrderStatus.expired, 'انتهت مهلة الطلب'),
    (OrderStatus.cancelled, 'تم إلغاء الطلب'),
  ]) {
    testWidgets('CR-011 active offer with ${state.$1.name} order is terminal', (
      tester,
    ) async {
      final service = FakeDriverService();
      service.offers.add(
        DriverOffer(
          id: 'offer-A',
          orderId: 'A',
          price: 90,
          status: OfferStatus.active,
          orderStatus: state.$1,
          biddingDeadline: DateTime.now().subtract(const Duration(seconds: 1)),
        ),
      );
      final routes = router('/waiting/A');
      addTearDown(routes.dispose);
      await mount(tester, service, routes);
      expect(find.text(state.$2), findsOneWidget);
      expect(find.text('سحب العرض'), findsNothing);
    });
  }

  testWidgets('CR-011 selected assigned offer restores Active Trip action', (
    tester,
  ) async {
    final service = FakeDriverService();
    service.offers.add(
      DriverOffer(
        id: 'offer-A',
        orderId: 'A',
        price: 90,
        status: OfferStatus.selected,
        orderStatus: OrderStatus.driverAssigned,
        assignedToMe: true,
      ),
    );
    final routes = router('/waiting/A');
    addTearDown(routes.dispose);
    await mount(tester, service, routes);
    expect(find.text('تم اختيارك للرحلة'), findsOneWidget);
    expect(find.text('فتح الرحلة'), findsOneWidget);
    expect(find.text('سحب العرض'), findsNothing);
  });

  testWidgets('CR-011 withdrawn offer stays terminal', (tester) async {
    final service = FakeDriverService();
    service.offers.add(
      const DriverOffer(
        id: 'offer-A',
        orderId: 'A',
        price: 90,
        status: OfferStatus.withdrawn,
        orderStatus: OrderStatus.bidding,
      ),
    );
    final routes = router('/waiting/A');
    addTearDown(routes.dispose);
    await mount(tester, service, routes);
    expect(find.text('تم سحب العرض'), findsOneWidget);
    expect(find.text('سحب العرض'), findsNothing);
  });

  testWidgets('CR-012 active bootstrap ignores failed optional feeds', (
    tester,
  ) async {
    final service = FakeDriverService()..failOptional = true;
    service.active = order('A', OrderStatus.driverAssigned);
    service.currentOrder = service.active!;
    final routes = router('/restore');
    addTearDown(routes.dispose);
    await mount(tester, service, routes);
    expect(routes.routeInformationProvider.value.uri.path, '/active-order/A');
    expect(service.optionalReads, 0);
  });

  testWidgets('CR-012 Profile and Sign Out ignore failed optional feeds', (
    tester,
  ) async {
    final service = FakeDriverService()..failOptional = true;
    final routes = router('/profile');
    addTearDown(routes.dispose);
    await mount(tester, service, routes);
    await tester.scrollUntilVisible(
      find.text('تسجيل الخروج'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('تسجيل الخروج'), findsOneWidget);
    expect(service.optionalReads, 0);
  });

  testWidgets('CR-013 forbidden read preserves safe message and Sign Out', (
    tester,
  ) async {
    final service = FakeDriverService()
      ..failAccount = ReadFailureKind.forbidden;
    final routes = router('/profile');
    addTearDown(routes.dispose);
    await mount(tester, service, routes);
    expect(find.text('ليس لديك صلاحية لعرض هذه البيانات.'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('تسجيل الخروج'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('تسجيل الخروج'), findsOneWidget);
    expect(find.textContaining('private'), findsNothing);
  });

  testWidgets('CR-019 fractional fares remain exact in offer and trip UI', (
    tester,
  ) async {
    final service = FakeDriverService()
      ..currentOrder = DriverOrder(
        id: 'A',
        serviceCode: 'RIDE',
        serviceName: 'رحلة',
        pickupAddress: 'استلام A',
        destinationAddress: 'وجهة A',
        proposedPrice: 105.50,
        status: OrderStatus.bidding,
        createdAt: DateTime(2026, 8, 30),
      );
    final routes = router('/request/A');
    addTearDown(routes.dispose);
    await mount(tester, service, routes);

    await tester.ensureVisible(find.text('تقديم سعر آخر'));
    await tester.tap(find.text('تقديم سعر آخر'));
    await tester.pumpAndSettle();
    expect(find.text('سعر العميل: 105.50 ج.م'), findsOneWidget);
    expect(find.text('سعر العميل: 105 ج.م'), findsNothing);

    Navigator.of(tester.element(find.byType(TextField))).pop();
    await tester.pumpAndSettle();
    service.currentOrder = DriverOrder(
      id: 'B',
      serviceCode: 'RIDE',
      serviceName: 'رحلة',
      pickupAddress: 'استلام B',
      destinationAddress: 'وجهة B',
      proposedPrice: 100,
      agreedPrice: 105.50,
      status: OrderStatus.completed,
      createdAt: DateTime(2026, 8, 30),
      completedAt: DateTime(2026, 8, 30, 1),
    );
    routes.go('/active-order/B');
    await tester.pumpAndSettle();
    expect(find.text('استلام B ← وجهة B\n105.50 ج.م'), findsOneWidget);
    expect(find.text('استلام B ← وجهة B\n105 ج.م'), findsNothing);
  });
}
