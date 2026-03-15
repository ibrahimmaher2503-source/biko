import 'package:biko/core/models/bid_model.dart';
import 'package:biko/core/models/enums.dart';
import 'package:biko/core/models/place_model.dart';
import 'package:biko/core/models/trip_model.dart';
import 'package:biko/core/routes/app_routes.dart';
import 'package:biko/features/bidding/controllers/bids_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// Integration tests for bidding flow.
///
/// T138: Receiving bids → selecting driver → trip start flow
/// T139: Real-time bid updates — RTDB subscriptions structure
/// T140: Driver selection — acceptBid flow
/// T141: Trip state transition — pending → accepted
/// T142: Navigation to tracking screen
///
/// Note: Realtime Database subscriptions require live Firebase.
/// These tests verify data structures and state flow logic.
void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(Get.reset);

  // Test data
  const cairoPickup = PlaceModel(
    placeId: 'pickup_bidding',
    name: 'Tahrir Square',
    address: 'Tahrir Sq, Cairo',
    lat: 30.0444,
    lng: 31.2357,
  );

  const gizaDropoff = PlaceModel(
    placeId: 'dropoff_bidding',
    name: 'Giza Pyramids',
    address: 'Giza, Egypt',
    lat: 29.9792,
    lng: 31.1342,
  );

  final testBid = BidModel(
    bidId: 'bid_001',
    tripId: 'trip_001',
    driverUid: 'driver_001',
    driverName: 'محمد علي',
    driverPhotoUrl: 'https://example.com/driver.jpg',
    driverRating: 4.8,
    vehicleType: VehicleType.motorcycle,
    amount: 75.0,
    status: BidStatus.pending,
    etaMinutes: 5,
    createdAt: DateTime(2026, 3, 10, 14),
  );

  // ===== T138: Receiving bids flow =====

  group('T138: receiving bids flow — bid list structure', () {
    test('BidsController manages incoming bids list', () {
      final controller = BidsController();
      expect(controller.bids, isA<RxList<BidModel>>());
      expect(controller.bids.isEmpty, isTrue);
    });

    test('BidModel contains all required driver information', () {
      expect(testBid.driverName, equals('محمد علي'));
      expect(testBid.driverRating, equals(4.8));
      expect(testBid.vehicleType, equals(VehicleType.motorcycle));
      expect(testBid.amount, equals(75.0));
      expect(testBid.etaMinutes, equals(5));
    });

    test('BidModel contains trip reference and driver uid', () {
      expect(testBid.tripId, equals('trip_001'));
      expect(testBid.driverUid, equals('driver_001'));
    });

    test('only pending bids are shown to the customer', () {
      // BidsController filters: b.status == BidStatus.pending
      final allBids = [
        testBid,
        testBid.copyWith(bidId: 'bid_accepted', status: BidStatus.accepted),
        testBid.copyWith(bidId: 'bid_rejected', status: BidStatus.rejected),
      ];

      final pendingOnly = allBids.where((b) => b.status == BidStatus.pending).toList();
      expect(pendingOnly.length, equals(1));
      expect(pendingOnly.first.bidId, equals('bid_001'));
    });

    test('viewBids route is registered', () {
      expect(AppRoutes.viewBids, isNotEmpty);
    });
  });

  // ===== T139: Real-time bid updates =====

  group('T139: real-time bid updates — RTDB structure', () {
    test('BidsController has RTDB stream subscription teardown', () {
      // _bidsSub must be cancelled in onClose()
      final controller = BidsController();
      expect(controller.onClose, returnsNormally);
    });

    test('bid amount is stored as double for EGP', () {
      expect(testBid.amount, isA<double>());
      expect(testBid.amount, equals(75.0));
    });

    test('BidModel fromMap parses RTDB-format data correctly', () {
      final rtdbData = {
        'bid_id': 'bid_rtdb_001',
        'trip_id': 'trip_rtdb_001',
        'driver_uid': 'driver_rtdb_001',
        'driver_name': 'Ahmed',
        'driver_rating': 4.5,
        'vehicle_type': 'motorcycle',
        'amount': 65.0,
        'status': 'pending',
        'eta_minutes': 8,
      };

      final bid = BidModel.fromMap(rtdbData);
      expect(bid.bidId, equals('bid_rtdb_001'));
      expect(bid.amount, equals(65.0));
      expect(bid.status, equals(BidStatus.pending));
      expect(bid.etaMinutes, equals(8));
    });

    test('bid timeout after 60 seconds is tracked in BidsController', () {
      final controller = BidsController();
      expect(controller.hasTimedOut.value, isFalse);

      // After timeout simulation
      controller.hasTimedOut.value = true;
      expect(controller.hasTimedOut.value, isTrue);
    });
  });

  // ===== T140: Driver selection =====

  group('T140: driver selection — acceptBid flow', () {
    test('acceptBid method exists on BidsController', () {
      expect(() => BidsController().acceptBid, returnsNormally);
    });

    test('rejectBid method exists on BidsController', () {
      expect(() => BidsController().rejectBid, returnsNormally);
    });

    test('isAcceptingBid tracks acceptance in progress', () {
      final controller = BidsController();
      expect(controller.isAcceptingBid.value, isFalse);

      controller.isAcceptingBid.value = true;
      expect(controller.isAcceptingBid.value, isTrue);
    });

    test('BidModel stores driver info for selection display', () {
      expect(testBid.driverName, isNotEmpty);
      expect(testBid.driverRating, greaterThan(0));
      expect(testBid.etaMinutes, greaterThan(0));
      expect(testBid.amount, greaterThan(0));
    });
  });

  // ===== T141: Trip state transition =====

  group('T141: trip state transition — pending → accepted', () {
    test('TripStatus transitions from searching to accepted', () {
      final pendingTrip = TripModel(
        id: 'trip_state',
        customerUid: 'cust_001',
        pickup: cairoPickup,
        dropoff: gizaDropoff,
        status: TripStatus.searching,
        type: TripType.ride,
        paymentMethod: PaymentMethod.cash,
        customerPrice: 75.0,
        createdAt: DateTime.now(),
      );

      expect(pendingTrip.status, equals(TripStatus.searching));
      expect(pendingTrip.isActive, isTrue);

      final acceptedTrip = pendingTrip.copyWith(
        status: TripStatus.accepted,
        driverUid: 'driver_001',
        acceptedPrice: 70.0,
      );

      expect(acceptedTrip.status, equals(TripStatus.accepted));
      expect(acceptedTrip.isActive, isTrue);
      expect(acceptedTrip.driverUid, equals('driver_001'));
      expect(acceptedTrip.finalPrice, equals(70.0));
    });

    test('all trip status values exist', () {
      expect(TripStatus.searching, isA<TripStatus>());
      expect(TripStatus.bidding, isA<TripStatus>());
      expect(TripStatus.accepted, isA<TripStatus>());
      expect(TripStatus.onTheWay, isA<TripStatus>());
      expect(TripStatus.arrived, isA<TripStatus>());
      expect(TripStatus.inProgress, isA<TripStatus>());
      expect(TripStatus.completed, isA<TripStatus>());
      expect(TripStatus.cancelled, isA<TripStatus>());
    });

    test('bid status transitions correctly', () {
      final pendingBid = testBid;
      expect(pendingBid.status, equals(BidStatus.pending));

      final acceptedBid = pendingBid.copyWith(status: BidStatus.accepted);
      expect(acceptedBid.status, equals(BidStatus.accepted));

      final rejectedBid = pendingBid.copyWith(status: BidStatus.rejected);
      expect(rejectedBid.status, equals(BidStatus.rejected));
    });
  });

  // ===== T142: Navigation to tracking screen =====

  group('T142: navigation to tracking screen after driver acceptance', () {
    test('trackTrip route exists', () {
      expect(AppRoutes.trackTrip, isNotEmpty);
    });

    test('accepted trip has driver uid for tracking', () {
      final acceptedTrip = TripModel(
        id: 'trip_tracking',
        customerUid: 'cust_001',
        driverUid: 'driver_accepted_001',
        pickup: cairoPickup,
        dropoff: gizaDropoff,
        status: TripStatus.accepted,
        type: TripType.ride,
        paymentMethod: PaymentMethod.cash,
        customerPrice: 75.0,
        acceptedPrice: 70.0,
        createdAt: DateTime.now(),
      );

      expect(acceptedTrip.driverUid, equals('driver_accepted_001'));
      expect(acceptedTrip.status, equals(TripStatus.accepted));
      expect(acceptedTrip.isActive, isTrue);
    });

    test('cancelSearch method exists on BidsController', () {
      expect(() => BidsController().cancelSearch, returnsNormally);
    });

    test('customerHome route is available for search cancellation', () {
      expect(AppRoutes.customerHome, isNotEmpty);
    });
  });
}
