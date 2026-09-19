import 'package:app_core/app_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:user_app/features/home/home_view.dart';
import 'package:user_app/features/orders/create_order_page.dart';
import 'package:user_app/features/orders/order_models.dart';
import 'package:user_app/features/orders/order_providers.dart';

import 'widget_test.dart' show FakeOrderService, testApp;

void main() {
  testWidgets('Home keeps real location entry separate from service fallback', (
    tester,
  ) async {
    var rideCalls = 0;
    await tester.pumpWidget(
      testApp(
        HomeView(
          onRide: () => rideCalls++,
          onDelivery: () {},
          onHistory: () {},
          onBookAgain: (_) {},
        ),
        overrides: [orderHistoryProvider.overrideWith((_) async => const [])],
      ),
    );

    expect(find.byKey(const Key('home-pickup-location')), findsOneWidget);
    expect(find.byKey(const Key('home-destination-location')), findsOneWidget);
    await tester.tap(find.byKey(const Key('ride-service')));
    expect(rideCalls, 1);
  });

  testWidgets('location-only client draft waits for the trusted quote', (
    tester,
  ) async {
    final service = FakeOrderService();
    final draft = OrderDraft(
      service: ServiceType.ride,
      pickup: developmentLocations.first,
      destination: developmentLocations[1],
      proposedPrice: 0,
    );
    await tester.pumpWidget(
      testApp(
        CreateOrderPage(service: ServiceType.ride, prefill: draft),
        overrides: [orderServiceProvider.overrideWithValue(service)],
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('proposed-price')),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('proposed-price')))
          .controller!
          .text,
      '80',
    );
    expect(find.text('السعر المقترح من بيكو'), findsOneWidget);
    expect(find.text('سعرك المقترح'), findsOneWidget);
  });

  testWidgets('Home completes a partial route without dropping its pickup', (
    tester,
  ) async {
    OrderDraft? draft;
    await tester.pumpWidget(
      testApp(
        HomeView(
          onRide: () {},
          onDelivery: () {},
          onHistory: () {},
          onBookAgain: (_) {},
          onCreateDraft: (value) => draft = value,
        ),
        overrides: [orderHistoryProvider.overrideWith((_) async => const [])],
      ),
    );

    await tester.tap(find.byKey(const Key('home-pickup-location')));
    await tester.pumpAndSettle();
    tester.widget<GoogleMap>(find.byType(GoogleMap)).onTap!(
      const LatLng(30.12345, 31.54321),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('confirm-map-location')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('ride-service')));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(draft, isNull);

    await tester.tap(find.byKey(const Key('ride-service')));
    await tester.pumpAndSettle();
    tester.widget<GoogleMap>(find.byType(GoogleMap)).onTap!(
      const LatLng(30.23456, 31.65432),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('confirm-map-location')));
    await tester.pumpAndSettle();

    expect(draft?.service, ServiceType.ride);
    expect(draft?.pickup.latitude, 30.12345);
    expect(draft?.pickup.longitude, 31.54321);
    expect(draft?.destination.latitude, 30.23456);
    expect(draft?.destination.longitude, 31.65432);
  });
}
