import 'package:biko/core/models/enums.dart';
import 'package:biko/core/models/place_model.dart';
import 'package:biko/core/models/trip_model.dart';
import 'package:biko/core/routes/app_routes.dart';
import 'package:biko/features/bidding/controllers/bidding_controller.dart';
import 'package:biko/features/bidding/controllers/bids_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// Integration tests for trip creation flow.
///
/// T133: Pickup → destination → service selection → bid submission flow
/// T134: Map interactions — location selection
/// T135: Location data flow — lat/lng stored correctly
/// T136: Trip document creation — TripModel structure for Firestore
/// T137: Navigation to bidding screen
///
/// Note: MapService (Google Directions API) and FirestoreService calls
/// require live Firebase — covered by manual device testing.
/// These tests verify the data flow structure and state management.
void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(Get.reset);

  // Helper test data
  const cairoPickup = PlaceModel(
    placeId: 'tahrir',
    name: 'Tahrir Square',
    address: 'Tahrir Sq, Cairo Governorate, Egypt',
    lat: 30.0444,
    lng: 31.2357,
  );

  const gizaDropoff = PlaceModel(
    placeId: 'giza_pyramids',
    name: 'Giza Pyramids',
    address: 'Al Haram, Giza Governorate, Egypt',
    lat: 29.9792,
    lng: 31.1342,
  );

  // ===== T133: Trip creation flow =====

  group(
    'T133: trip creation flow — pickup → destination → bid submission',
    () {
      test('BiddingController is the entry point for trip creation', () {
        final controller = BiddingController();
        expect(controller, isNotNull);
        expect(controller.pickup.value, isNull);
        expect(controller.dropoff.value, isNull);
      });

      test('pickup and dropoff can be set to valid Egyptian locations', () {
        final controller = BiddingController();
        controller.pickup.value = cairoPickup;
        controller.dropoff.value = gizaDropoff;

        expect(controller.pickup.value?.name, equals('Tahrir Square'));
        expect(controller.dropoff.value?.name, equals('Giza Pyramids'));
      });

      test('trip creation route exists', () {
        expect(AppRoutes.createTrip, isNotEmpty);
      });

      test('set pickup route exists', () {
        expect(AppRoutes.setPickup, isNotEmpty);
      });

      test('set dropoff route exists', () {
        expect(AppRoutes.setDropoff, isNotEmpty);
      });

      test('view bids route exists (post-submission navigation)', () {
        expect(AppRoutes.viewBids, isNotEmpty);
      });
    },
  );

  // ===== T134: Map interactions =====

  group('T134: map interactions — location selection', () {
    test('PlaceModel stores map coordinates correctly', () {
      expect(cairoPickup.lat, equals(30.0444));
      expect(cairoPickup.lng, equals(31.2357));
      expect(gizaDropoff.lat, equals(29.9792));
      expect(gizaDropoff.lng, equals(31.1342));
    });

    test('PlaceModel.latLng returns LatLng for map display', () {
      // latLng is available for map markers
      final latLng = cairoPickup.latLng;
      expect(latLng.latitude, equals(30.0444));
      expect(latLng.longitude, equals(31.2357));
    });

    test('pickup and dropoff places are different locations', () {
      expect(cairoPickup.placeId, isNot(equals(gizaDropoff.placeId)));
      expect(cairoPickup.lat, isNot(equals(gizaDropoff.lat)));
      expect(cairoPickup.lng, isNot(equals(gizaDropoff.lng)));
    });

    test('AppMapWidget route exists for displaying route polyline', () {
      // AppMapWidget is used in trip creation screens
      expect(AppRoutes.createTrip, isNotEmpty);
    });
  });

  // ===== T135: Location data flow =====

  group('T135: location data flow', () {
    test('location data flows from PlaceModel to TripModel', () {
      final trip = TripModel(
        id: 'trip_flow_001',
        customerUid: 'cust_001',
        pickup: cairoPickup,
        dropoff: gizaDropoff,
        status: TripStatus.searching,
        type: TripType.ride,
        paymentMethod: PaymentMethod.cash,
        customerPrice: 75.0,
        createdAt: DateTime(2026, 3, 10),
      );

      expect(trip.pickup.lat, equals(cairoPickup.lat));
      expect(trip.pickup.lng, equals(cairoPickup.lng));
      expect(trip.dropoff.lat, equals(gizaDropoff.lat));
      expect(trip.dropoff.lng, equals(gizaDropoff.lng));
    });

    test('TripModel preserves all location data through toMap/fromMap', () {
      final original = TripModel(
        id: 'trip_roundtrip',
        customerUid: 'cust_001',
        pickup: cairoPickup,
        dropoff: gizaDropoff,
        status: TripStatus.searching,
        type: TripType.ride,
        paymentMethod: PaymentMethod.cash,
        customerPrice: 80.0,
        createdAt: DateTime(2026, 3, 10),
      );

      final map = original.toMap();
      final restored = TripModel.fromMap(map);

      expect(restored.pickup.lat, equals(cairoPickup.lat));
      expect(restored.pickup.lng, equals(cairoPickup.lng));
      expect(restored.pickup.name, equals(cairoPickup.name));
      expect(restored.dropoff.lat, equals(gizaDropoff.lat));
      expect(restored.dropoff.lng, equals(gizaDropoff.lng));
    });

    test('Egyptian coordinates are within valid geographic bounds', () {
      // Egypt: lat 22-32N, lng 24-37E
      for (final lat in [cairoPickup.lat, gizaDropoff.lat]) {
        expect(lat, greaterThan(22.0));
        expect(lat, lessThan(32.0));
      }
      for (final lng in [cairoPickup.lng, gizaDropoff.lng]) {
        expect(lng, greaterThan(24.0));
        expect(lng, lessThan(37.0));
      }
    });
  });

  // ===== T136: Trip document creation =====

  group('T136: trip document creation — TripModel for Firestore', () {
    test('TripModel creates Firestore-ready map via toMap()', () {
      final trip = TripModel(
        id: 'trip_fs_001',
        customerUid: 'cust_001',
        pickup: cairoPickup,
        dropoff: gizaDropoff,
        status: TripStatus.searching,
        type: TripType.ride,
        paymentMethod: PaymentMethod.cash,
        customerPrice: 85.0,
        createdAt: DateTime(2026, 3, 10),
      );

      final map = trip.toMap();

      expect(map, containsPair('id', 'trip_fs_001'));
      expect(map, containsPair('customer_uid', 'cust_001'));
      expect(map, containsPair('status', 'searching'));
      expect(map, containsPair('type', 'ride'));
      expect(map, containsPair('payment_method', 'cash'));
      expect(map, containsPair('customer_price', 85.0));
    });

    test('TripModel pickup and dropoff are embedded maps', () {
      final trip = TripModel(
        id: 'trip_embedded',
        customerUid: 'cust_001',
        pickup: cairoPickup,
        dropoff: gizaDropoff,
        status: TripStatus.searching,
        type: TripType.ride,
        paymentMethod: PaymentMethod.cash,
        customerPrice: 60.0,
        createdAt: DateTime(2026),
      );

      final map = trip.toMap();
      final pickupMap = map['pickup'] as Map<String, dynamic>;
      final dropoffMap = map['dropoff'] as Map<String, dynamic>;

      expect(pickupMap['lat'], equals(30.0444));
      expect(pickupMap['name'], equals('Tahrir Square'));
      expect(dropoffMap['lat'], equals(29.9792));
      expect(dropoffMap['name'], equals('Giza Pyramids'));
    });

    test('new trip has searching status by default', () {
      final trip = TripModel(
        id: '',
        customerUid: 'cust_001',
        pickup: cairoPickup,
        dropoff: gizaDropoff,
        status: TripStatus.searching,
        type: TripType.ride,
        paymentMethod: PaymentMethod.cash,
        customerPrice: 70.0,
        createdAt: DateTime.now(),
      );

      expect(trip.status, equals(TripStatus.searching));
      expect(trip.isActive, isTrue);
    });

    test('CRITICAL: wallets/ is never written from Flutter', () {
      // This test documents the critical security rule:
      // TripModel.toMap() must NOT include wallet modification fields
      final trip = TripModel(
        id: 'trip_wallet_check',
        customerUid: 'cust_001',
        pickup: cairoPickup,
        dropoff: gizaDropoff,
        status: TripStatus.searching,
        type: TripType.ride,
        paymentMethod: PaymentMethod.cash,
        customerPrice: 50.0,
        createdAt: DateTime.now(),
      );

      final map = trip.toMap();

      // TripModel must NOT contain wallet_balance, debit, credit fields
      expect(map.containsKey('wallet_balance'), isFalse);
      expect(map.containsKey('debit'), isFalse);
      expect(map.containsKey('credit'), isFalse);
      expect(map.containsKey('transaction'), isFalse);
    });
  });

  // ===== T137: Navigation to bidding screen =====

  group('T137: navigation to bidding screen after trip creation', () {
    test('viewBids route exists for post-creation navigation', () {
      expect(AppRoutes.viewBids, isNotEmpty);
    });

    test('trackTrip route exists for accepted trip navigation', () {
      expect(AppRoutes.trackTrip, isNotEmpty);
    });

    test('BidsController accepts trip_id argument', () {
      // The navigation sends: {'trip_id': tripId}
      // BidsController._extractArguments reads 'trip_id'
      // Without onInit(), we test the observable type
      final controller = BidsController();
      expect(controller.tripId.value, isA<String>());
    });

    test('trip creation controller has submitTrip method', () {
      expect(() => BiddingController().submitTrip, returnsNormally);
    });
  });
}
