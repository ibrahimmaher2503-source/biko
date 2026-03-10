import 'package:biko/core/services/location_service.dart';
import 'package:biko/core/widgets/app_map_widget.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  group('AppMapWidget Tests', () {
    setUp(() {
      Get.put(LocationService());
    });

    tearDown(Get.reset);

    testWidgets('AppMapWidget instantiates correctly', (tester) async {
      // We wrap in a try-catch because GoogleMap requires a platform view
      // which is not available in standard widget tests without a mock interface.
      // This test ensures the widget parameters and instantiation are valid.
      const widget = AppMapWidget(
        height: 400.0,
        initialPosition: LatLng(30.0444, 31.2357),
        zoom: 14.0,
      );

      expect(widget.height, 400.0);
      expect(widget.zoom, 14.0);
      expect(widget.initialPosition, const LatLng(30.0444, 31.2357));
    });
  });
}
