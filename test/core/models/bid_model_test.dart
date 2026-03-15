import 'package:biko/core/models/bid_model.dart';
import 'package:biko/core/models/enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BidModel', () {
    final testCreatedAt = DateTime(2026, 3, 10, 12);

    final testBid = BidModel(
      bidId: 'bid_001',
      tripId: 'trip_001',
      driverUid: 'driver_001',
      driverName: 'أحمد محمد',
      driverPhotoUrl: 'https://example.com/photo.jpg',
      driverRating: 4.8,
      vehicleType: VehicleType.motorcycle,
      amount: 75.0,
      status: BidStatus.pending,
      etaMinutes: 5,
      createdAt: testCreatedAt,
    );

    // ===== fromMap =====

    group('fromMap', () {
      test('parses all fields from a complete map', () {
        final map = {
          'bid_id': 'bid_001',
          'trip_id': 'trip_001',
          'driver_uid': 'driver_001',
          'driver_name': 'أحمد محمد',
          'driver_photo_url': 'https://example.com/photo.jpg',
          'driver_rating': 4.8,
          'vehicle_type': 'motorcycle',
          'amount': 75.0,
          'status': 'pending',
          'eta_minutes': 5,
          // no created_at — falls back to DateTime.now()
        };

        final bid = BidModel.fromMap(map);

        expect(bid.bidId, equals('bid_001'));
        expect(bid.tripId, equals('trip_001'));
        expect(bid.driverUid, equals('driver_001'));
        expect(bid.driverName, equals('أحمد محمد'));
        expect(bid.driverPhotoUrl, equals('https://example.com/photo.jpg'));
        expect(bid.driverRating, equals(4.8));
        expect(bid.vehicleType, equals(VehicleType.motorcycle));
        expect(bid.amount, equals(75.0));
        expect(bid.status, equals(BidStatus.pending));
        expect(bid.etaMinutes, equals(5));
      });

      test('uses defaults for missing fields', () {
        final bid = BidModel.fromMap({});

        expect(bid.bidId, equals(''));
        expect(bid.tripId, equals(''));
        expect(bid.driverUid, equals(''));
        expect(bid.driverName, equals(''));
        expect(bid.driverPhotoUrl, isNull);
        expect(bid.driverRating, equals(0.0));
        expect(bid.vehicleType, equals(VehicleType.motorcycle));
        expect(bid.amount, equals(0.0));
        expect(bid.status, equals(BidStatus.pending));
        expect(bid.etaMinutes, equals(0));
      });

      test('parses scooter vehicle type', () {
        final map = {'bid_id': 'b1', 'trip_id': 't1', 'driver_uid': 'd1',
            'driver_name': 'Test', 'driver_rating': 4.0, 'vehicle_type': 'scooter',
            'amount': 50.0, 'status': 'pending', 'eta_minutes': 3};
        final bid = BidModel.fromMap(map);
        expect(bid.vehicleType, equals(VehicleType.scooter));
      });

      test('parses accepted status', () {
        final map = {'bid_id': 'b1', 'trip_id': 't1', 'driver_uid': 'd1',
            'driver_name': 'Test', 'driver_rating': 4.0, 'vehicle_type': 'motorcycle',
            'amount': 50.0, 'status': 'accepted', 'eta_minutes': 3};
        final bid = BidModel.fromMap(map);
        expect(bid.status, equals(BidStatus.accepted));
      });

      test('handles integer amount', () {
        final map = {'bid_id': 'b1', 'trip_id': 't1', 'driver_uid': 'd1',
            'driver_name': 'T', 'driver_rating': 4.0, 'vehicle_type': 'motorcycle',
            'amount': 80, 'status': 'pending', 'eta_minutes': 5};
        final bid = BidModel.fromMap(map);
        expect(bid.amount, equals(80.0));
      });
    });

    // ===== copyWith =====

    group('copyWith', () {
      test('returns identical model when no fields changed', () {
        final copy = testBid.copyWith();

        expect(copy.bidId, equals(testBid.bidId));
        expect(copy.amount, equals(testBid.amount));
        expect(copy.status, equals(testBid.status));
      });

      test('updates only the specified field', () {
        final updated = testBid.copyWith(amount: 90.0);

        expect(updated.amount, equals(90.0));
        expect(updated.bidId, equals(testBid.bidId));
        expect(updated.driverName, equals(testBid.driverName));
      });

      test('updates status correctly', () {
        final updated = testBid.copyWith(status: BidStatus.accepted);
        expect(updated.status, equals(BidStatus.accepted));
      });

      test('updates etaMinutes correctly', () {
        final updated = testBid.copyWith(etaMinutes: 10);
        expect(updated.etaMinutes, equals(10));
      });

      test('updates driverRating correctly', () {
        final updated = testBid.copyWith(driverRating: 5.0);
        expect(updated.driverRating, equals(5.0));
      });

      test('can update all fields simultaneously', () {
        final newDate = DateTime(2026, 6);
        final updated = testBid.copyWith(
          bidId: 'new_bid',
          tripId: 'new_trip',
          driverUid: 'new_driver',
          driverName: 'كريم',
          driverPhotoUrl: 'https://new.com/img.jpg',
          driverRating: 4.9,
          vehicleType: VehicleType.ebike,
          amount: 100.0,
          status: BidStatus.rejected,
          etaMinutes: 8,
          createdAt: newDate,
        );

        expect(updated.bidId, equals('new_bid'));
        expect(updated.vehicleType, equals(VehicleType.ebike));
        expect(updated.status, equals(BidStatus.rejected));
        expect(updated.amount, equals(100.0));
        expect(updated.createdAt, equals(newDate));
      });
    });

    // ===== toString =====

    group('toString', () {
      test('includes bidId, driverName, and amount', () {
        final str = testBid.toString();
        expect(str, contains('bid_001'));
        expect(str, contains('أحمد محمد'));
        expect(str, contains('75.0'));
      });
    });
  });

  // ===== BidStatus enum =====

  group('BidStatus enum', () {
    test('toJson returns correct string for each status', () {
      expect(BidStatus.pending.toJson(), equals('pending'));
      expect(BidStatus.accepted.toJson(), equals('accepted'));
      expect(BidStatus.rejected.toJson(), equals('rejected'));
      expect(BidStatus.expired.toJson(), equals('expired'));
    });

    test('fromJson parses each status correctly', () {
      expect(BidStatus.fromJson('pending'), equals(BidStatus.pending));
      expect(BidStatus.fromJson('accepted'), equals(BidStatus.accepted));
      expect(BidStatus.fromJson('rejected'), equals(BidStatus.rejected));
      expect(BidStatus.fromJson('expired'), equals(BidStatus.expired));
    });

    test('fromJson defaults to pending for unknown string', () {
      expect(BidStatus.fromJson('unknown'), equals(BidStatus.pending));
    });
  });

  // ===== VehicleType enum =====

  group('VehicleType enum', () {
    test('toJson returns correct string for each type', () {
      expect(VehicleType.motorcycle.toJson(), equals('motorcycle'));
      expect(VehicleType.scooter.toJson(), equals('scooter'));
      expect(VehicleType.ebike.toJson(), equals('ebike'));
    });

    test('fromJson parses each type correctly', () {
      expect(VehicleType.fromJson('motorcycle'), equals(VehicleType.motorcycle));
      expect(VehicleType.fromJson('scooter'), equals(VehicleType.scooter));
      expect(VehicleType.fromJson('ebike'), equals(VehicleType.ebike));
    });

    test('fromJson defaults to motorcycle for unknown string', () {
      expect(VehicleType.fromJson('unknown'), equals(VehicleType.motorcycle));
    });
  });
}
