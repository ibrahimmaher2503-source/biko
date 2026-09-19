import 'dart:async';

import 'package:app_core/app_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user_app/app/user_app.dart';
import 'package:user_app/app/user_shell.dart';
import 'package:user_app/app/user_theme.dart';
import 'package:user_app/features/orders/order_status_page.dart';
import 'package:user_app/features/orders/widgets/offer_widgets.dart';
import 'package:user_app/features/orders/order_providers.dart';
import 'package:user_app/features/orders/order_service.dart';
import 'package:user_app/features/orders/order_models.dart';
import 'package:user_app/features/orders/create_order_page.dart';
import 'package:user_app/features/home/home_view.dart';
import 'package:user_app/features/orders/order_history_view.dart';
import 'package:user_app/features/maps/map_gateway.dart';
import 'package:user_app/features/profile/profile_model.dart';
import 'package:user_app/features/profile/profile_provider.dart';
import 'package:user_app/features/profile/profile_view.dart';

RouteQuote testQuote() => RouteQuote(
  id: 'quote-1',
  pickup: LocationSelection(
    displayAddress: '',
    latitude: developmentLocations[0].latitude,
    longitude: developmentLocations[0].longitude,
  ),
  destination: LocationSelection(
    displayAddress: '',
    latitude: developmentLocations[1].latitude,
    longitude: developmentLocations[1].longitude,
  ),
  distanceMeters: 5000,
  durationSeconds: 900,
  encodedPolyline: '_p~iF~ps|U_ulLnnqC_mqNvxq`@',
  suggestedPrice: 80,
  minimumCustomerPrice: 56,
  expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 5)),
);

CustomerOrder testOrder({
  OrderStatus status = OrderStatus.bidding,
  ServiceType service = ServiceType.ride,
  DateTime? expiresAt,
  DeliveryDetails? delivery,
}) => CustomerOrder(
  id: '10000000-0000-4000-8000-000000000001',
  service: service,
  pickup: developmentLocations[0],
  destination: developmentLocations[1],
  proposedPrice: 80,
  agreedPrice: status == OrderStatus.bidding ? null : 90,
  driverId: status == OrderStatus.bidding ? null : 'driver-1',
  status: status,
  createdAt: DateTime.utc(2026, 8, 30),
  biddingExpiresAt:
      expiresAt ?? DateTime.now().toUtc().add(const Duration(minutes: 1)),
  delivery: delivery,
);

DriverOffer testOffer(String id, String name, double price) => DriverOffer(
  id: id,
  price: price,
  driverPublicId: 'driver-$id',
  driverFirstName: name,
  driverType: DriverType.independent,
  completedTripCount: 12,
);

Widget testApp(Widget child, {dynamic overrides = const []}) => ProviderScope(
  overrides: [...overrides],
  child: MaterialApp(
    theme: buildUserTheme(),
    builder: (context, child) =>
        Directionality(textDirection: TextDirection.rtl, child: child!),
    home: child,
  ),
);

class FakeOrderService extends OrderService {
  FakeOrderService() : super(testClient());

  int createCalls = 0;
  final intents = <String>[];
  CustomerOrder? recovered;
  DriverSummary? assignedDriver;
  String? deliveryCode;
  List<CustomerOrder> history = const [];

  @override
  Future<CustomerOrder> createOrder(OrderDraft draft, String intentId) {
    createCalls++;
    intents.add(intentId);
    throw TimeoutException('uncertain');
  }

  @override
  Future<RouteQuote> createRouteQuote(
    ServiceType service,
    LocationSelection pickup,
    LocationSelection destination,
  ) async => testQuote();

  @override
  Future<CustomerOrder?> findByCreationIntent(String intentId) async {
    expect(intentId, intents.single);
    return recovered;
  }

  @override
  Future<DriverSummary?> loadAssignedDriver(String orderId) async =>
      assignedDriver;

  @override
  Future<String?> loadDeliveryConfirmationCode(String orderId) async =>
      deliveryCode;

  @override
  Future<List<DriverOffer>> loadOffers(String orderId) async => const [];

  @override
  Future<List<CustomerOrder>> loadHistory() async => history;
}

class FakeMapGateway extends MapGateway {
  FakeMapGateway() : super(testClient());
  int searches = 0;

  @override
  Future<List<PlaceSuggestion>> search(
    String input,
    String sessionToken,
  ) async {
    searches++;
    return const [PlaceSuggestion(id: 'place-1', label: 'مدينة نصر')];
  }
}

SupabaseClient testClient() => SupabaseClient(
  'http://localhost',
  'test-anon-key',
  authOptions: const AuthClientOptions(autoRefreshToken: false),
);

void main() {
  testWidgets('shows the safe setup state without credentials', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: UserApp(configured: false)),
    );

    expect(find.textContaining('أضف إعدادات Supabase'), findsOneWidget);
  });

  testWidgets('Home exposes Ride, Delivery, history, and empty recent state', (
    tester,
  ) async {
    await tester.pumpWidget(
      testApp(
        HomeView(
          onRide: () {},
          onDelivery: () {},
          onHistory: () {},
          onBookAgain: (_) {},
        ),
        overrides: [orderHistoryProvider.overrideWith((_) async => const [])],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ride-service')), findsOneWidget);
    expect(find.byKey(const Key('delivery-service')), findsOneWidget);
    expect(find.text('كل الطلبات'), findsOneWidget);
    expect(find.textContaining('لا توجد طلبات سابقة'), findsOneWidget);
  });

  for (final state in <(OrderStatus, String)>[
    (OrderStatus.bidding, 'بانتظار العروض'),
    (OrderStatus.driverAssigned, 'تم الإسناد'),
    (OrderStatus.driverOnWay, 'في الطريق للعميل'),
    (OrderStatus.driverArrived, 'وصل السائق'),
    (OrderStatus.inProgress, 'الرحلة جارية'),
  ]) {
    testWidgets('Gate 7B customer bootstrap restores ${state.$1.name}', (
      tester,
    ) async {
      final service = FakeOrderService();
      await tester.pumpWidget(
        testApp(
          const UserRootPage(),
          overrides: [
            orderServiceProvider.overrideWithValue(service),
            activeOrderProvider.overrideWith(
              (_) async => testOrder(status: state.$1),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(StatusChip),
          matching: find.text(state.$2),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Ride form keeps Delivery-only fields out', (tester) async {
    await tester.pumpWidget(
      testApp(const CreateOrderPage(service: ServiceType.ride)),
    );
    expect(find.byKey(const Key('pickup-location')), findsOneWidget);
    expect(find.byKey(const Key('destination-location')), findsOneWidget);
    expect(find.byKey(const Key('proposed-price')), findsOneWidget);
    expect(find.byKey(const Key('recipient-name')), findsNothing);
    expect(find.byKey(const Key('parcel-weight')), findsNothing);
  });

  testWidgets('Places search waits for the bounded debounce', (tester) async {
    final maps = FakeMapGateway();
    await tester.pumpWidget(
      testApp(
        const CreateOrderPage(service: ServiceType.ride),
        overrides: [mapGatewayProvider.overrideWithValue(maps)],
      ),
    );
    await tester.tap(find.byKey(const Key('pickup-location')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('places-search')), 'مدينة');
    await tester.pump(const Duration(milliseconds: 349));
    expect(maps.searches, 0);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    expect(maps.searches, 1);
    expect(find.text('مدينة نصر'), findsOneWidget);
  });

  testWidgets('Delivery form exposes the complete hosted 7A contract', (
    tester,
  ) async {
    await tester.pumpWidget(
      testApp(const CreateOrderPage(service: ServiceType.delivery)),
    );
    expect(find.byKey(const Key('recipient-name')), findsOneWidget);
    expect(find.byKey(const Key('recipient-phone')), findsOneWidget);
    expect(find.byKey(const Key('parcel-weight')), findsOneWidget);
    expect(find.byKey(const Key('declared-value')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('proposed-price')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const Key('proposed-price')), findsOneWidget);
  });

  testWidgets('zero and multiple offer states are explicit and comparable', (
    tester,
  ) async {
    await tester.pumpWidget(
      testApp(
        DriverOffersSection(
          offers: const [],
          disabled: false,
          onSelect: (_) {},
        ),
      ),
    );
    expect(find.textContaining('لم يصل أي عرض'), findsOneWidget);

    await tester.pumpWidget(
      testApp(
        DriverOffersSection(
          offers: [testOffer('1', 'أحمد', 80), testOffer('2', 'محمد', 90)],
          disabled: false,
          onSelect: (_) {},
        ),
      ),
    );
    expect(find.text('أحمد'), findsOneWidget);
    expect(find.text('محمد'), findsOneWidget);
    expect(find.text('اختيار'), findsNWidgets(2));
  });

  testWidgets('countdown performs exactly one authoritative action at zero', (
    tester,
  ) async {
    var elapsedCalls = 0;
    await tester.pumpWidget(
      testApp(
        BiddingCountdown(
          expiresAt: DateTime.now().toUtc().subtract(
            const Duration(seconds: 1),
          ),
          onElapsed: () => elapsedCalls++,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('00:00'), findsOneWidget);
    expect(elapsedCalls, 1);
  });

  testWidgets('uncertain create reconciles original intent without replay', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final service = FakeOrderService();
    final authClient = testClient();
    final auth = AuthService(authClient);
    CustomerOrder? created;
    await tester.pumpWidget(
      testApp(
        CreateOrderPage(
          service: ServiceType.ride,
          prefill: testOrder().bookAgainDraft(),
          onCreated: (value) => created = value,
        ),
        overrides: [
          orderServiceProvider.overrideWithValue(service),
          authServiceProvider.overrideWithValue(auth),
        ],
      ),
    );

    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('proposed-price')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(find.byKey(const Key('proposed-price')), '80');
    await tester.ensureVisible(find.byKey(const Key('create-order')));
    await tester.tap(find.byKey(const Key('create-order')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(service.createCalls, 1);
    expect(service.intents, hasLength(1));
    expect(find.text('إعادة التحقق'), findsOneWidget);

    service.recovered = testOrder();
    await tester.scrollUntilVisible(
      find.text('إعادة التحقق'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('إعادة التحقق'));
    await tester.pumpAndSettle();
    expect(service.createCalls, 1);
    expect(created?.id, service.recovered?.id);
    auth.dispose();
  });

  testWidgets(
    'assigned order renders public Driver summary and no bidding CTA',
    (tester) async {
      final service = FakeOrderService()
        ..assignedDriver = const DriverSummary(
          driverPublicId: 'driver-1',
          driverFirstName: 'أحمد',
          driverType: DriverType.independent,
          completedTripCount: 20,
        );
      await tester.pumpWidget(
        testApp(
          OrderStatusPage(
            initialOrder: testOrder(status: OrderStatus.driverAssigned),
          ),
          overrides: [orderServiceProvider.overrideWithValue(service)],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('أحمد'), findsOneWidget);
      expect(find.text('20 رحلة مكتملة'), findsOneWidget);
      expect(find.text('اختيار'), findsNothing);
      expect(find.byKey(const Key('show-cancellation')), findsOneWidget);
    },
  );

  testWidgets('active Delivery shows one final code and Ride shows none', (
    tester,
  ) async {
    final service = FakeOrderService()
      ..assignedDriver = const DriverSummary(
        driverPublicId: 'driver-1',
        driverFirstName: 'أحمد',
        driverType: DriverType.independent,
        completedTripCount: 20,
        driverVerified: true,
        motorcyclePlateNumber: 'ا ب ج 123',
      )
      ..deliveryCode = '4821';
    final delivery = testOrder(
      status: OrderStatus.inProgress,
      service: ServiceType.delivery,
      delivery: const DeliveryDetails(
        recipientName: 'منى',
        recipientPhone: '01000000000',
        parcelWeightKg: 2,
        declaredValue: 500,
      ),
    );
    await tester.pumpWidget(
      testApp(
        OrderStatusPage(initialOrder: delivery),
        overrides: [orderServiceProvider.overrideWithValue(service)],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('delivery-confirmation-code')), findsOneWidget);
    expect(find.text('4821'), findsOneWidget);
    expect(find.text('هوية معتمدة'), findsOneWidget);
    expect(find.byKey(const Key('driver-plate')), findsOneWidget);
    expect(find.textContaining('ا ب ج 123'), findsOneWidget);

    await tester.pumpWidget(
      testApp(
        OrderStatusPage(
          key: UniqueKey(),
          initialOrder: testOrder(status: OrderStatus.inProgress),
        ),
        overrides: [orderServiceProvider.overrideWithValue(service)],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('delivery-confirmation-code')), findsNothing);
  });

  testWidgets('terminal state removes stale actions and offers Book Again', (
    tester,
  ) async {
    final terminal = CustomerOrder(
      id: 'terminal-1',
      service: ServiceType.ride,
      pickup: developmentLocations[0],
      destination: developmentLocations[1],
      proposedPrice: 80,
      status: OrderStatus.expired,
      createdAt: DateTime.utc(2026, 8, 30),
    );
    await tester.pumpWidget(testApp(OrderStatusPage(initialOrder: terminal)));
    await tester.pump();
    expect(find.byKey(const Key('book-again')), findsOneWidget);
    expect(find.byKey(const Key('show-cancellation')), findsNothing);
    expect(find.text('اختيار'), findsNothing);
  });

  testWidgets('active detail replaces stale state when resume data changes', (
    tester,
  ) async {
    final service = FakeOrderService();
    const key = ValueKey('same-order');
    await tester.pumpWidget(
      testApp(
        OrderStatusPage(key: key, initialOrder: testOrder()),
        overrides: [orderServiceProvider.overrideWithValue(service)],
      ),
    );
    await tester.pump();
    expect(find.text('بانتظار العروض'), findsOneWidget);
    await tester.pumpWidget(
      testApp(
        OrderStatusPage(
          key: key,
          initialOrder: testOrder(status: OrderStatus.inProgress),
        ),
        overrides: [orderServiceProvider.overrideWithValue(service)],
      ),
    );
    await tester.pump();
    expect(
      find.descendant(
        of: find.byType(StatusChip),
        matching: find.text('الرحلة جارية'),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'cancellation controls follow Bidding, assigned, and in-progress states',
    (tester) async {
      final service = FakeOrderService();
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        testApp(
          OrderStatusPage(key: UniqueKey(), initialOrder: testOrder()),
          overrides: [orderServiceProvider.overrideWithValue(service)],
        ),
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('show-cancellation')));
      await tester.pump();
      expect(find.textContaining('اختياري'), findsNWidgets(2));

      await tester.pumpWidget(
        testApp(
          OrderStatusPage(
            key: UniqueKey(),
            initialOrder: testOrder(status: OrderStatus.driverAssigned),
          ),
          overrides: [orderServiceProvider.overrideWithValue(service)],
        ),
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('show-cancellation')));
      await tester.pump();
      expect(find.textContaining('مطلوب'), findsOneWidget);

      await tester.pumpWidget(
        testApp(
          OrderStatusPage(
            key: UniqueKey(),
            initialOrder: testOrder(status: OrderStatus.inProgress),
          ),
          overrides: [orderServiceProvider.overrideWithValue(service)],
        ),
      );
      await tester.pump();
      expect(find.byKey(const Key('show-cancellation')), findsNothing);
      expect(find.textContaining('الإلغاء المباشر غير متاح'), findsOneWidget);
    },
  );

  testWidgets('history and profile remain usable as independent shell feeds', (
    tester,
  ) async {
    final service = FakeOrderService()
      ..history = [testOrder(status: OrderStatus.completed)];
    final profileOverride = profileProvider.overrideWith(
      (_) async => const CustomerProfile(
        email: 'customer@example.com',
        fullName: 'عميل بيكو',
      ),
    );
    await tester.pumpWidget(
      testApp(
        const OrderHistoryView(),
        overrides: [
          orderServiceProvider.overrideWithValue(service),
          profileOverride,
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('رحلة'), findsOneWidget);
    expect(find.text('احجز مرة أخرى'), findsOneWidget);

    await tester.pumpWidget(
      testApp(
        const ProfileView(),
        overrides: [
          orderServiceProvider.overrideWithValue(service),
          profileOverride,
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('عميل بيكو'), findsOneWidget);
    expect(find.text('customer@example.com'), findsOneWidget);
    expect(find.text('تسجيل الخروج'), findsOneWidget);
  });
}
