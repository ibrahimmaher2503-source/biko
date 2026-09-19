import 'package:driver_app/features/driver/driver_location.dart';
import 'package:driver_app/features/driver/driver_models.dart';
import 'package:driver_app/features/driver/driver_providers.dart';
import 'package:driver_app/features/driver/driver_screens.dart';
import 'package:driver_app/features/driver/driver_service.dart';
import 'package:driver_app/features/driver/driver_ui.dart';
import 'package:app_core/app_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _ResilienceDriverService extends DriverService {
  _ResilienceDriverService(this.order)
    : super(
        SupabaseClient(
          'http://localhost',
          'test-only',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
      );

  final DriverOrder order;

  @override
  Future<DriverOrder> loadOrder(String orderId) async => order;

  @override
  Future<DriverOffer?> loadOffer(String orderId) async => null;
}

DriverOrder _longOrder({OrderStatus status = OrderStatus.bidding}) =>
    DriverOrder(
      id: 'resilience-order',
      serviceCode: 'RIDE',
      serviceName: 'رحلة',
      pickupAddress: 'عنوان استلام عربي طويل جدًا ' * 24,
      destinationAddress: 'عنوان وجهة عربي طويل جدًا ' * 24,
      proposedPrice: 999999.99,
      status: status,
      createdAt: DateTime(2026, 9, 13),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('denied location permission gives a recoverable Arabic action', () {
    expect(
      driverLocationErrorMessage(const PermissionDeniedException('denied')),
      'اسمح بالوصول إلى الموقع من إعدادات الجهاز ثم حاول مرة أخرى.',
    );
    const failure = DriverLocationFailure(
      'اسمح بالوصول إلى الموقع من إعدادات التطبيق ثم حاول مرة أخرى.',
      DriverLocationRecovery.appSettings,
    );
    expect(failure.recovery, DriverLocationRecovery.appSettings);
  });

  testWidgets('error state exposes reconnect copy and one retry action', (
    tester,
  ) async {
    var retries = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildDriverTheme(),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: DriverErrorState(
            message: 'تعذر الاتصال. تحقق من الشبكة وأعد المحاولة.',
            onRetry: () => retries++,
          ),
        ),
      ),
    );

    expect(
      find.text('تعذر الاتصال. تحقق من الشبكة وأعد المحاولة.'),
      findsOneWidget,
    );
    expect(find.text('إعادة التحقق'), findsOneWidget);
    await tester.tap(find.text('إعادة التحقق'));
    expect(retries, 1);
  });

  testWidgets('long Arabic routes and large prices survive text scaling', (
    tester,
  ) async {
    final service = _ResilienceDriverService(_longOrder());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [driverServiceProvider.overrideWithValue(service)],
        child: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: MaterialApp(
            theme: buildDriverTheme(),
            home: const Directionality(
              textDirection: TextDirection.rtl,
              child: RequestDetailsScreen(orderId: 'resilience-order'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('999999.99 ج.م'), findsOneWidget);
    expect(find.textContaining('عنوان استلام عربي طويل جدًا'), findsOneWidget);
    expect(find.textContaining('عنوان وجهة عربي طويل جدًا'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('active-order restoration chooses the operational route only', () {
    final active = _longOrder(status: OrderStatus.inProgress);

    expect(driverStartupLocation(active), '/active-order/resilience-order');
    expect(driverStartupLocation(null), '/home');
  });
}
