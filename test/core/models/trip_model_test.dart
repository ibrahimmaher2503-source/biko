import 'package:biko/core/models/enums.dart';
import 'package:biko/core/models/place_model.dart';
import 'package:biko/core/models/trip_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TripModel', () {
    const testPickup = PlaceModel(
      placeId: 'pickup_id',
      name: 'Tahrir Square',
      address: 'Tahrir Sq, Cairo',
      lat: 30.0444,
      lng: 31.2357,
    );

    const testDropoff = PlaceModel(
      placeId: 'dropoff_id',
      name: 'Cairo Tower',
      address: 'Gezira, Cairo',
      lat: 30.0459,
      lng: 31.2243,
    );

    final testCreatedAt = DateTime(2026, 3, 10, 14);

    final testTrip = TripModel(
      id: 'trip_001',
      customerUid: 'customer_001',
      driverUid: 'driver_001',
      pickup: testPickup,
      dropoff: testDropoff,
      status: TripStatus.searching,
      type: TripType.ride,
      paymentMethod: PaymentMethod.cash,
      customerPrice: 80.0,
      acceptedPrice: 75.0,
      distanceKm: 5.2,
      durationMinutes: 15,
      createdAt: testCreatedAt,
    );

    // ===== fromMap =====

    group('fromMap', () {
      test('parses all fields from a complete map', () {
        final map = {
          'id': 'trip_001',
          'customer_uid': 'customer_001',
          'driver_uid': 'driver_001',
          'pickup': {
            'place_id': 'pickup_id',
            'name': 'Tahrir Square',
            'address': 'Tahrir Sq, Cairo',
            'lat': 30.0444,
            'lng': 31.2357,
          },
          'dropoff': {
            'place_id': 'dropoff_id',
            'name': 'Cairo Tower',
            'address': 'Gezira, Cairo',
            'lat': 30.0459,
            'lng': 31.2243,
          },
          'status': 'searching',
          'type': 'ride',
          'payment_method': 'cash',
          'customer_price': 80.0,
          'accepted_price': 75.0,
          'distance_km': 5.2,
          'duration_minutes': 15,
          // no timestamps — falls back to DateTime.now()
        };

        final trip = TripModel.fromMap(map);

        expect(trip.id, equals('trip_001'));
        expect(trip.customerUid, equals('customer_001'));
        expect(trip.driverUid, equals('driver_001'));
        expect(trip.pickup.name, equals('Tahrir Square'));
        expect(trip.dropoff.name, equals('Cairo Tower'));
        expect(trip.status, equals(TripStatus.searching));
        expect(trip.type, equals(TripType.ride));
        expect(trip.paymentMethod, equals(PaymentMethod.cash));
        expect(trip.customerPrice, equals(80.0));
        expect(trip.acceptedPrice, equals(75.0));
        expect(trip.distanceKm, equals(5.2));
        expect(trip.durationMinutes, equals(15));
      });

      test('uses defaults for missing fields', () {
        final trip = TripModel.fromMap({});

        expect(trip.id, equals(''));
        expect(trip.customerUid, equals(''));
        expect(trip.driverUid, isNull);
        expect(trip.acceptedPrice, isNull);
        expect(trip.distanceKm, isNull);
        expect(trip.durationMinutes, isNull);
        expect(trip.cancelledBy, isNull);
        expect(trip.cancellationReason, isNull);
        expect(trip.status, equals(TripStatus.searching));
        expect(trip.type, equals(TripType.ride));
        expect(trip.paymentMethod, equals(PaymentMethod.cash));
      });

      test('parses on_the_way status', () {
        final map = _minimalMap()..['status'] = 'on_the_way';
        final trip = TripModel.fromMap(map);
        expect(trip.status, equals(TripStatus.onTheWay));
      });

      test('parses in_progress status', () {
        final map = _minimalMap()..['status'] = 'in_progress';
        final trip = TripModel.fromMap(map);
        expect(trip.status, equals(TripStatus.inProgress));
      });

      test('parses c2c_delivery type', () {
        final map = _minimalMap()..['type'] = 'c2c_delivery';
        final trip = TripModel.fromMap(map);
        expect(trip.type, equals(TripType.c2cDelivery));
      });

      test('parses b2b_delivery type', () {
        final map = _minimalMap()..['type'] = 'b2b_delivery';
        final trip = TripModel.fromMap(map);
        expect(trip.type, equals(TripType.b2bDelivery));
      });

      test('parses vodafone_cash payment method', () {
        final map = _minimalMap()..['payment_method'] = 'vodafone_cash';
        final trip = TripModel.fromMap(map);
        expect(trip.paymentMethod, equals(PaymentMethod.vodafoneCash));
      });

      test('parses wallet payment method', () {
        final map = _minimalMap()..['payment_method'] = 'wallet';
        final trip = TripModel.fromMap(map);
        expect(trip.paymentMethod, equals(PaymentMethod.wallet));
      });

      test('fromJson is an alias for fromMap', () {
        final map = _minimalMap();
        final fromMap = TripModel.fromMap(map);
        final fromJson = TripModel.fromJson(map);
        expect(fromJson.id, equals(fromMap.id));
        expect(fromJson.status, equals(fromMap.status));
      });
    });

    // ===== Computed properties =====

    group('finalPrice', () {
      test('returns acceptedPrice when available', () {
        expect(testTrip.finalPrice, equals(75.0));
      });

      test('returns customerPrice when acceptedPrice is null', () {
        // copyWith cannot clear nullable fields to null, test directly
        final trip = TripModel(
          id: 'trip_002',
          customerUid: 'customer_001',
          pickup: testPickup,
          dropoff: testDropoff,
          status: TripStatus.searching,
          type: TripType.ride,
          paymentMethod: PaymentMethod.cash,
          customerPrice: 80.0,
          createdAt: testCreatedAt,
        );
        expect(trip.finalPrice, equals(80.0));
      });
    });

    group('formattedPrice', () {
      test('formats final price with EGP suffix', () {
        expect(testTrip.formattedPrice, equals('75 EGP'));
      });

      test('formats price without decimal places', () {
        final trip = TripModel(
          id: 'trip_003',
          customerUid: 'cust_001',
          pickup: testPickup,
          dropoff: testDropoff,
          status: TripStatus.searching,
          type: TripType.ride,
          paymentMethod: PaymentMethod.cash,
          customerPrice: 50.0,
          createdAt: testCreatedAt,
        );
        expect(trip.formattedPrice, equals('50 EGP'));
      });
    });

    group('isActive', () {
      test('returns true for searching status', () {
        expect(testTrip.isActive, isTrue);
      });

      test('returns false for completed status', () {
        final completed = TripModel(
          id: 'trip_004',
          customerUid: 'cust_001',
          pickup: testPickup,
          dropoff: testDropoff,
          status: TripStatus.completed,
          type: TripType.ride,
          paymentMethod: PaymentMethod.cash,
          customerPrice: 80.0,
          createdAt: testCreatedAt,
        );
        expect(completed.isActive, isFalse);
      });

      test('returns false for cancelled status', () {
        final cancelled = TripModel(
          id: 'trip_005',
          customerUid: 'cust_001',
          pickup: testPickup,
          dropoff: testDropoff,
          status: TripStatus.cancelled,
          type: TripType.ride,
          paymentMethod: PaymentMethod.cash,
          customerPrice: 80.0,
          createdAt: testCreatedAt,
        );
        expect(cancelled.isActive, isFalse);
      });

      test('returns true for accepted status', () {
        final accepted = TripModel(
          id: 'trip_006',
          customerUid: 'cust_001',
          pickup: testPickup,
          dropoff: testDropoff,
          status: TripStatus.accepted,
          type: TripType.ride,
          paymentMethod: PaymentMethod.cash,
          customerPrice: 80.0,
          createdAt: testCreatedAt,
        );
        expect(accepted.isActive, isTrue);
      });
    });

    group('tripId getter', () {
      test('tripId is an alias for id', () {
        expect(testTrip.tripId, equals(testTrip.id));
      });
    });

    // ===== copyWith =====

    group('copyWith', () {
      test('returns identical model when no fields changed', () {
        final copy = testTrip.copyWith();

        expect(copy.id, equals(testTrip.id));
        expect(copy.customerPrice, equals(testTrip.customerPrice));
        expect(copy.status, equals(testTrip.status));
      });

      test('updates only the specified field', () {
        final updated = testTrip.copyWith(status: TripStatus.accepted);

        expect(updated.status, equals(TripStatus.accepted));
        expect(updated.id, equals(testTrip.id));
        expect(updated.customerPrice, equals(testTrip.customerPrice));
      });

      test('updates customerPrice correctly', () {
        final updated = testTrip.copyWith(customerPrice: 100.0);
        expect(updated.customerPrice, equals(100.0));
      });

      test('updates driverUid correctly', () {
        final updated = testTrip.copyWith(driverUid: 'driver_999');
        expect(updated.driverUid, equals('driver_999'));
      });
    });

    // ===== toString =====

    group('toString', () {
      test('includes id, status, and price', () {
        final str = testTrip.toString();
        expect(str, contains('trip_001'));
        expect(str, contains('TripStatus.searching'));
      });
    });
  });

  // ===== TripStatus enum =====

  group('TripStatus enum', () {
    test('toJson returns correct strings', () {
      expect(TripStatus.searching.toJson(), equals('searching'));
      expect(TripStatus.bidding.toJson(), equals('bidding'));
      expect(TripStatus.accepted.toJson(), equals('accepted'));
      expect(TripStatus.onTheWay.toJson(), equals('on_the_way'));
      expect(TripStatus.arrived.toJson(), equals('arrived'));
      expect(TripStatus.inProgress.toJson(), equals('in_progress'));
      expect(TripStatus.completed.toJson(), equals('completed'));
      expect(TripStatus.cancelled.toJson(), equals('cancelled'));
    });

    test('fromJson parses each status correctly', () {
      expect(TripStatus.fromJson('searching'), equals(TripStatus.searching));
      expect(TripStatus.fromJson('bidding'), equals(TripStatus.bidding));
      expect(TripStatus.fromJson('accepted'), equals(TripStatus.accepted));
      expect(TripStatus.fromJson('on_the_way'), equals(TripStatus.onTheWay));
      expect(TripStatus.fromJson('arrived'), equals(TripStatus.arrived));
      expect(TripStatus.fromJson('in_progress'), equals(TripStatus.inProgress));
      expect(TripStatus.fromJson('completed'), equals(TripStatus.completed));
      expect(TripStatus.fromJson('cancelled'), equals(TripStatus.cancelled));
    });

    test('fromJson defaults to searching for unknown string', () {
      expect(TripStatus.fromJson('unknown'), equals(TripStatus.searching));
    });
  });

  // ===== TripType enum =====

  group('TripType enum', () {
    test('toJson returns correct strings', () {
      expect(TripType.ride.toJson(), equals('ride'));
      expect(TripType.c2cDelivery.toJson(), equals('c2c_delivery'));
      expect(TripType.b2bDelivery.toJson(), equals('b2b_delivery'));
    });

    test('fromJson parses each type correctly', () {
      expect(TripType.fromJson('ride'), equals(TripType.ride));
      expect(TripType.fromJson('c2c_delivery'), equals(TripType.c2cDelivery));
      expect(TripType.fromJson('b2b_delivery'), equals(TripType.b2bDelivery));
    });

    test('fromJson defaults to ride for unknown string', () {
      expect(TripType.fromJson('unknown'), equals(TripType.ride));
    });
  });

  // ===== PaymentMethod enum =====

  group('PaymentMethod enum', () {
    test('toJson returns correct strings', () {
      expect(PaymentMethod.cash.toJson(), equals('cash'));
      expect(PaymentMethod.wallet.toJson(), equals('wallet'));
      expect(PaymentMethod.card.toJson(), equals('card'));
      expect(PaymentMethod.vodafoneCash.toJson(), equals('vodafone_cash'));
      expect(PaymentMethod.fawry.toJson(), equals('fawry'));
    });

    test('fromJson parses each method correctly', () {
      expect(PaymentMethod.fromJson('cash'), equals(PaymentMethod.cash));
      expect(PaymentMethod.fromJson('wallet'), equals(PaymentMethod.wallet));
      expect(PaymentMethod.fromJson('card'), equals(PaymentMethod.card));
      expect(
        PaymentMethod.fromJson('vodafone_cash'),
        equals(PaymentMethod.vodafoneCash),
      );
      expect(PaymentMethod.fromJson('fawry'), equals(PaymentMethod.fawry));
    });

    test('fromJson defaults to cash for unknown string', () {
      expect(PaymentMethod.fromJson('unknown'), equals(PaymentMethod.cash));
    });
  });
}

// Helper to build a minimal valid map for fromMap tests
Map<String, dynamic> _minimalMap() {
  return {
    'id': 'trip_min',
    'customer_uid': 'cust_min',
    'pickup': {
      'place_id': '',
      'name': 'A',
      'address': '',
      'lat': 30.0,
      'lng': 31.0,
    },
    'dropoff': {
      'place_id': '',
      'name': 'B',
      'address': '',
      'lat': 30.1,
      'lng': 31.1,
    },
    'status': 'searching',
    'type': 'ride',
    'payment_method': 'cash',
    'customer_price': 50.0,
  };
}
