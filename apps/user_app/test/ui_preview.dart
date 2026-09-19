// Development-only runtime target. Run with: flutter run -t test/ui_preview.dart --dart-define=PREVIEW=login
import 'dart:async';

import 'package:app_core/app_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user_app/app/user_theme.dart';
import 'package:user_app/app/user_shell.dart';
import 'package:user_app/features/maps/location_picker_page.dart';
import 'package:user_app/features/maps/map_gateway.dart';
import 'package:user_app/features/onboarding/user_auth_entry.dart';
import 'package:user_app/features/orders/create_order_page.dart';
import 'package:user_app/features/orders/order_models.dart';
import 'package:user_app/features/orders/order_providers.dart';
import 'package:user_app/features/orders/order_service.dart';
import 'package:user_app/features/orders/order_status_page.dart';
import 'package:user_app/features/profile/profile_model.dart';
import 'package:user_app/features/profile/profile_provider.dart';

const _preview = String.fromEnvironment('PREVIEW', defaultValue: 'login');
const _selectorEnabled = bool.fromEnvironment('PREVIEW_SELECTOR');
const _previewLabels = {
  'login': 'Login',
  'auth-choice': 'Auth Choice',
  'onboarding': 'Onboarding',
  'home-empty': 'Home Empty',
  'home-content': 'Home Recent',
  'home-active': 'Home Active',
  'shell': 'User Shell',
  'ride-booking': 'Ride Booking',
  'delivery-booking': 'Delivery Booking',
  'location-picker': 'Location Picker',
  'quote': 'Quote',
  'bidding-empty': 'Bidding Empty',
  'bidding-multiple': 'Bidding Multiple Offers',
  'assigned-driver': 'Assigned Driver',
  'ride-on-way': 'Ride On Way',
  'ride-arrived': 'Ride Arrived',
  'ride-in-progress': 'Ride In Progress',
  'delivery-active': 'Delivery Active',
  'delivery-code': 'Delivery Confirmation Code',
  'completed': 'Completed',
  'cancelled': 'Cancelled',
  'expired': 'Expired',
  'bidding-error': 'Bidding Error',
};
const _pickup = LocationSelection(
  displayAddress:
      'شارع طويل جدًا في مدينة نصر بجوار الحديقة الدولية وميدان الساعة',
  latitude: 30.0566,
  longitude: 31.3301,
);
const _destination = LocationSelection(
  displayAddress:
      'التجمع الخامس، القاهرة الجديدة، أمام البوابة الرئيسية للمجمع',
  latitude: 30.0074,
  longitude: 31.4913,
);

void main() {
  if (!kDebugMode) {
    throw StateError('UI preview is test-only.');
  }
  // This entrypoint is never imported by lib/main.dart. The in-memory store
  // keeps onboarding deterministic without touching device preferences.
  SharedPreferences.setMockInitialValues({
    'user_onboarding_seen_v1': _preview != 'onboarding',
  });
  final service = _PreviewOrderService();
  runApp(
    ProviderScope(
      overrides: [
        authServiceProvider.overrideWithValue(AuthService(_previewClient())),
        orderServiceProvider.overrideWithValue(service),
        mapGatewayProvider.overrideWithValue(_PreviewMapGateway()),
        profileProvider.overrideWith(
          (_) async => const CustomerProfile(
            fullName: 'عميلة بيكو باسم طويل للاختبار',
            email: 'customer@example.com',
            phone: '01000000000',
          ),
        ),
        orderHistoryProvider.overrideWith((_) async => _history),
      ],
      child: _PreviewApp(service: service),
    ),
  );
}

class _PreviewApp extends StatefulWidget {
  const _PreviewApp({required this.service});
  final _PreviewOrderService service;

  @override
  State<_PreviewApp> createState() => _PreviewAppState();
}

class _PreviewAppState extends State<_PreviewApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  void _openPreview(String selection) {
    SharedPreferences.setMockInitialValues({
      'user_onboarding_seen_v1': selection != 'onboarding',
    });
    _navigatorKey.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => KeyedSubtree(
          key: ValueKey(selection),
          child: _screen(widget.service, selection),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    navigatorKey: _navigatorKey,
    theme: buildUserTheme(),
    builder: (context, child) =>
        Directionality(textDirection: TextDirection.rtl, child: child!),
    home: _selectorEnabled
        ? _PreviewControls(onSelected: _openPreview)
        : _screen(widget.service, _preview),
  );

  Widget _screen(_PreviewOrderService service, String selected) {
    final delivery = _order(
      id: 'delivery-active',
      service: ServiceType.delivery,
      status: OrderStatus.inProgress,
      delivery: const DeliveryDetails(
        recipientName: 'منى السيد',
        recipientPhone: '01000000000',
        parcelWeightKg: 2.5,
        declaredValue: 2500,
      ),
    );
    switch (selected) {
      case 'login':
        return const EmailPasswordAuthPage(
          appName: 'بيكو',
          description: 'سجل دخولك لإدارة رحلاتك وطلبات التوصيل.',
        );
      case 'auth-choice':
      case 'onboarding':
        return const UserAuthEntry();
      case 'home-empty':
        return ProviderScope(
          overrides: [orderHistoryProvider.overrideWith((_) async => const [])],
          child: const UserShell(),
        );
      case 'home-active':
        service.configure(
          order: _order(id: 'home-active'),
          offers: _offers,
          driver: _driver,
        );
        return ProviderScope(
          overrides: [
            activeOrderProvider.overrideWith(
              (_) async => _order(id: 'home-active'),
            ),
          ],
          child: const UserRootPage(),
        );
      case 'shell':
        return const UserShell();
      case 'home-content':
        return const UserShell();
      case 'ride-booking':
        return const CreateOrderPage(service: ServiceType.ride);
      case 'delivery-booking':
        return const CreateOrderPage(service: ServiceType.delivery);
      case 'location-picker':
        return const LocationPickerPage(
          title: 'اختر نقطة الاستلام',
          initial: _pickup,
        );
      case 'quote':
        return CreateOrderPage(
          service: ServiceType.ride,
          prefill: _order().bookAgainDraft(),
        );
      case 'bidding-empty':
        return _status(
          service,
          order: _order(id: 'bidding-empty'),
          offers: const [],
        );
      case 'bidding-multiple':
        return _status(
          service,
          order: _order(id: 'bidding-multiple'),
          offers: _offers,
        );
      case 'bidding-error':
        return _status(
          service,
          order: _order(id: 'bidding-error'),
          offersError: TimeoutException('preview offers error'),
        );
      case 'assigned-driver':
        return _status(
          service,
          order: _order(
            id: 'assigned-driver',
            status: OrderStatus.driverAssigned,
          ),
          driver: _driver,
        );
      case 'ride-on-way':
        return _status(
          service,
          order: _order(id: 'ride-on-way', status: OrderStatus.driverOnWay),
          driver: _driver,
        );
      case 'ride-arrived':
        return _status(
          service,
          order: _order(id: 'ride-arrived', status: OrderStatus.driverArrived),
          driver: _driver,
        );
      case 'ride-in-progress':
        return _status(
          service,
          order: _order(id: 'ride-in-progress', status: OrderStatus.inProgress),
          driver: _driver,
        );
      case 'delivery-active':
        return _status(service, order: delivery, driver: _driver);
      case 'delivery-code':
        return _status(
          service,
          order: _order(
            id: 'delivery-code',
            service: ServiceType.delivery,
            status: OrderStatus.inProgress,
            delivery: delivery.delivery,
          ),
          driver: _driver,
          deliveryCode: '4821',
        );
      case 'completed':
        return _status(
          service,
          order: _order(id: 'completed', status: OrderStatus.completed),
        );
      case 'cancelled':
        return _status(
          service,
          order: _order(id: 'cancelled', status: OrderStatus.cancelled),
        );
      case 'expired':
        return _status(
          service,
          order: _order(id: 'expired', status: OrderStatus.expired),
        );
      default:
        return const Scaffold(
          body: Center(child: Text('حالة معاينة غير معروفة')),
        );
    }
  }

  Widget _status(
    _PreviewOrderService service, {
    required CustomerOrder order,
    List<DriverOffer> offers = const [],
    DriverSummary? driver,
    String? deliveryCode,
    Object? offersError,
  }) {
    service.configure(
      order: order,
      offers: offers,
      driver: driver,
      deliveryCode: deliveryCode,
      offersError: offersError,
    );
    return OrderStatusPage(initialOrder: order);
  }
}

class _PreviewControls extends StatelessWidget {
  const _PreviewControls({required this.onSelected});

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('حالات معاينة بيكو')),
    body: ListView.separated(
      padding: const EdgeInsets.all(BikoSpace.md),
      itemCount: _previewLabels.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final entry = _previewLabels.entries.elementAt(index);
        return ListTile(
          title: Text(entry.value),
          trailing: const Icon(Icons.arrow_back_rounded),
          onTap: () => onSelected(entry.key),
        );
      },
    ),
  );
}

class _PreviewOrderService extends OrderService {
  _PreviewOrderService() : super(_previewClient());
  CustomerOrder _currentOrder = _order();
  List<DriverOffer> _offers = const [];
  DriverSummary? _driver;
  String? _deliveryCode;
  Object? _offersError;

  void configure({
    required CustomerOrder order,
    List<DriverOffer> offers = const [],
    DriverSummary? driver,
    String? deliveryCode,
    Object? offersError,
  }) {
    _currentOrder = order;
    _offers = offers;
    _driver = driver;
    _deliveryCode = deliveryCode;
    _offersError = offersError;
  }

  @override
  Future<RouteQuote> createRouteQuote(
    ServiceType service,
    LocationSelection pickup,
    LocationSelection destination,
  ) async => _quote;

  @override
  Future<CustomerOrder> loadOrder(String orderId) => _respond(() {
    _assertCurrentOrder(orderId);
    return _currentOrder;
  });

  @override
  Future<List<DriverOffer>> loadOffers(String orderId) => _respond(() {
    _assertCurrentOrder(orderId);
    return _offers;
  }, error: _offersError);

  @override
  Future<DriverSummary?> loadAssignedDriver(String orderId) => _respond(() {
    _assertCurrentOrder(orderId);
    return _driver;
  });

  @override
  Future<String?> loadDeliveryConfirmationCode(String orderId) => _respond(() {
    _assertCurrentOrder(orderId);
    return _deliveryCode;
  });

  Future<T> _respond<T>(T Function() value, {Object? error}) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (error != null) throw error;
    return value();
  }

  void _assertCurrentOrder(String orderId) {
    if (orderId != _currentOrder.id) {
      throw StateError('Preview requested a non-current order: $orderId');
    }
  }
}

class _PreviewMapGateway extends MapGateway {
  _PreviewMapGateway() : super(_previewClient());

  @override
  Future<List<PlaceSuggestion>> search(
    String input,
    String sessionToken,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (input.trim() == 'لا نتائج') return const [];
    if (input.trim() == 'خطأ البحث') {
      throw TimeoutException('preview places error');
    }
    return const [
      PlaceSuggestion(id: 'nasr-city', label: 'مدينة نصر، القاهرة'),
      PlaceSuggestion(id: 'new-cairo', label: 'القاهرة الجديدة، التجمع الخامس'),
    ];
  }

  @override
  Future<LocationSelection> resolve(
    PlaceSuggestion suggestion,
    String sessionToken,
  ) async => _pickup;
}

SupabaseClient _previewClient() => SupabaseClient(
  'http://localhost',
  'preview-anon-key',
  authOptions: const AuthClientOptions(autoRefreshToken: false),
);

RouteQuote get _quote => RouteQuote(
  id: 'preview-quote',
  pickup: _pickup,
  destination: _destination,
  distanceMeters: 5800,
  durationSeconds: 1200,
  encodedPolyline: '_p~iF~ps|U_ulLnnqC_mqNvxq`@',
  suggestedPrice: 125,
  minimumCustomerPrice: 87.5,
  expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 5)),
);

CustomerOrder _order({
  String id = '10000000-0000-4000-8000-000000000001',
  ServiceType service = ServiceType.ride,
  OrderStatus status = OrderStatus.bidding,
  DeliveryDetails? delivery,
}) => CustomerOrder(
  id: id,
  service: service,
  pickup: _pickup,
  destination: _destination,
  proposedPrice: 120,
  agreedPrice: status == OrderStatus.bidding ? null : 130,
  driverId: status == OrderStatus.bidding ? null : 'driver-preview',
  status: status,
  createdAt: DateTime.utc(2026, 9, 7),
  biddingExpiresAt: DateTime.now().toUtc().add(const Duration(seconds: 74)),
  delivery: delivery,
);

const _driver = DriverSummary(
  driverPublicId: 'driver-preview',
  driverFirstName: 'أحمد عبدالرحمن الطويل للاختبار',
  driverType: DriverType.officeDriver,
  officeDisplayName: 'مكتب النخبة للدراجات والتنقل',
  completedTripCount: 172,
  driverVerified: true,
  motorcycleBrand: 'Honda',
  motorcycleModel: 'CBR 150R إصدار المدينة',
  motorcyclePlateNumber: 'أ ب ج ١٢٣٤',
);

const _offers = [
  DriverOffer(
    id: 'offer-1',
    price: 120,
    driverPublicId: 'driver-1',
    driverFirstName: 'أحمد عبدالرحمن الطويل للاختبار',
    driverType: DriverType.officeDriver,
    officeDisplayName: 'مكتب النخبة للدراجات والتنقل',
    completedTripCount: 172,
  ),
  DriverOffer(
    id: 'offer-2',
    price: 145,
    driverPublicId: 'driver-2',
    driverFirstName: 'محمد',
    driverType: DriverType.independent,
    completedTripCount: 42,
  ),
  DriverOffer(
    id: 'offer-3',
    price: 99999,
    driverPublicId: 'driver-3',
    driverFirstName: 'سارة',
    driverType: DriverType.independent,
    completedTripCount: 6,
  ),
];

final _history = List<CustomerOrder>.generate(
  8,
  (index) => _order(
    id: 'history-${index + 1}',
    service: index.isEven ? ServiceType.ride : ServiceType.delivery,
    status: index == 1 ? OrderStatus.cancelled : OrderStatus.completed,
  ),
  growable: false,
);
