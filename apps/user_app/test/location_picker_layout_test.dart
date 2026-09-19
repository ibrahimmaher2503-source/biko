import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:user_app/features/maps/location_picker_page.dart';
import 'package:user_app/features/maps/map_gateway.dart';
import 'package:user_app/features/orders/order_models.dart';

import 'widget_test.dart' show FakeMapGateway, testApp, testClient;

class _DeferredMapGateway extends MapGateway {
  _DeferredMapGateway() : super(testClient());

  final searches = <Completer<List<PlaceSuggestion>>>[];
  final resolves = <Completer<LocationSelection>>[];

  @override
  Future<List<PlaceSuggestion>> search(String input, String sessionToken) {
    final result = Completer<List<PlaceSuggestion>>();
    searches.add(result);
    return result.future;
  }

  @override
  Future<LocationSelection> resolve(
    PlaceSuggestion suggestion,
    String sessionToken,
  ) {
    final result = Completer<LocationSelection>();
    resolves.add(result);
    return result.future;
  }
}

void main() {
  testWidgets(
    'small phone keeps Places results and confirmation above keyboard',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        testApp(
          const LocationPickerPage(
            title: 'اختر نقطة الاستلام',
            initial: LocationSelection(
              displayAddress:
                  'عنوان طويل في مدينة نصر بجوار الحديقة الدولية وميدان الساعة',
              latitude: 30.05,
              longitude: 31.33,
            ),
          ),
          overrides: [mapGatewayProvider.overrideWithValue(FakeMapGateway())],
        ),
      );
      await tester.enterText(find.byKey(const Key('places-search')), 'مدينة');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('مدينة نصر'), findsOneWidget);
      expect(
        tester.getBottomRight(find.byKey(const Key('confirm-map-location'))).dy,
        lessThanOrEqualTo(340),
      );
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('late Places responses cannot replace the completed query', (
    tester,
  ) async {
    final maps = _DeferredMapGateway();
    await tester.pumpWidget(
      testApp(
        const LocationPickerPage(title: 'اختر نقطة الاستلام'),
        overrides: [mapGatewayProvider.overrideWithValue(maps)],
      ),
    );
    await tester.enterText(find.byKey(const Key('places-search')), 'مدينة');
    await tester.pump(const Duration(milliseconds: 350));
    expect(maps.searches, hasLength(1));

    await tester.enterText(find.byKey(const Key('places-search')), 'عباسية');
    await tester.pump(const Duration(milliseconds: 350));
    expect(maps.searches, hasLength(2));

    maps.searches.first.complete(const [
      PlaceSuggestion(id: 'old', label: 'مدينة نصر'),
    ]);
    await tester.pump();
    expect(find.text('مدينة نصر'), findsNothing);

    maps.searches.last.complete(const []);
    await tester.pump();
    expect(find.textContaining('لا توجد نتائج مطابقة'), findsOneWidget);
  });

  testWidgets('late Place details cannot replace a newer map selection', (
    tester,
  ) async {
    final maps = _DeferredMapGateway();
    await tester.pumpWidget(
      testApp(
        const LocationPickerPage(title: 'اختر نقطة الاستلام'),
        overrides: [mapGatewayProvider.overrideWithValue(maps)],
      ),
    );
    await tester.enterText(find.byKey(const Key('places-search')), 'مدينة');
    await tester.pump(const Duration(milliseconds: 350));
    maps.searches.single.complete(const [
      PlaceSuggestion(id: 'place-1', label: 'مدينة نصر'),
    ]);
    await tester.pump();
    await tester.tap(find.text('مدينة نصر'));
    await tester.pump();
    expect(maps.resolves, hasLength(1));

    final map = tester.widget<GoogleMap>(find.byType(GoogleMap));
    map.onTap!(const LatLng(30.12345, 31.54321));
    await tester.pump();
    maps.resolves.single.complete(
      const LocationSelection(
        displayAddress: 'نتيجة قديمة',
        latitude: 30,
        longitude: 31,
      ),
    );
    await tester.pump();

    expect(find.text('30.12345, 31.54321'), findsOneWidget);
    expect(find.text('نتيجة قديمة'), findsNothing);
  });
}
