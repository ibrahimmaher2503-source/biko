import 'package:biko/core/models/enums.dart';

import 'test_factories.dart';

/// Predefined test fixtures for common testing scenarios.
///
/// Fixtures provide complex, realistic test data combinations that are
/// reused across multiple tests. Each fixture returns a complete scenario
/// with all related entities.
class TestFixtures {
  /// Creates a complete trip scenario with multiple bids.
  ///
  /// Returns:
  /// - customer: User who created the trip
  /// - drivers: List of 3 drivers who submitted bids
  /// - trip: Pending trip awaiting bid selection
  /// - bids: List of 3 bids with varying amounts (40, 45, 50 EGP)
  ///
  /// Example:
  /// ```dart
  /// final scenario = TestFixtures.tripWithMultipleBids();
  /// expect(scenario['bids'].length, equals(3));
  /// expect(scenario['trip'].status, equals(TripStatus.pending));
  /// ```
  static Map<String, dynamic> tripWithMultipleBids() {
    final customer = UserFactory.createCustomer();
    final drivers = UserFactory.createList(3, type: UserType.driver);
    final trip = TripFactory.create(customerUid: customer.uid);
    final bids = drivers
        .asMap()
        .entries
        .map(
          (entry) => BidFactory.create(
            tripId: trip.id,
            driverUid: entry.value.uid,
            driverName: entry.value.name,
            amount: 40.0 + (entry.key * 5.0),
          ),
        )
        .toList();

    return {
      'customer': customer,
      'drivers': drivers,
      'trip': trip,
      'bids': bids,
    };
  }

  /// Creates a completed trip with rating.
  ///
  /// Returns:
  /// - customer: User who took the trip
  /// - driver: Driver who completed the trip
  /// - trip: Completed trip with final price
  /// - rating: 5-star rating from customer to driver
  ///
  /// Example:
  /// ```dart
  /// final scenario = TestFixtures.completedTripWithRating();
  /// expect(scenario['trip'].status, equals(TripStatus.completed));
  /// expect(scenario['rating'].rating, equals(5));
  /// ```
  static Map<String, dynamic> completedTripWithRating() {
    final customer = UserFactory.createCustomer();
    final driver = UserFactory.createDriver();
    final trip = TripFactory.createCompleted(
      customerUid: customer.uid,
      driverUid: driver.uid,
    );

    // Note: RatingModel will be created once the model exists
    // For now, returning without rating until RatingModel is available
    final rating = {
      'ratingId': 'rating_${DateTime.now().millisecondsSinceEpoch}',
      'tripId': trip.id,
      'fromUserId': customer.uid,
      'toUserId': driver.uid,
      'rating': 5,
      'comment': 'Excellent service!',
      'createdAt': DateTime.now(),
    };

    return {
      'customer': customer,
      'driver': driver,
      'trip': trip,
      'rating': rating,
    };
  }

  /// Creates a user with wallet and transactions.
  ///
  /// Returns:
  /// - user: Customer user
  /// - wallet: Wallet with 100 EGP balance
  /// - transactions: List of 2 transactions (credit +50, debit -25)
  ///
  /// Example:
  /// ```dart
  /// final scenario = TestFixtures.userWithWallet();
  /// expect(scenario['wallet']['balance'], equals(100.0));
  /// expect(scenario['transactions'].length, equals(2));
  /// ```
  static Map<String, dynamic> userWithWallet() {
    final user = UserFactory.createCustomer();

    // Note: WalletModel and TransactionModel will be created once models exist
    // For now, returning wallet and transactions as maps
    final wallet = {
      'userId': user.uid,
      'balance': 100.0,
      'currency': 'EGP',
      'createdAt': DateTime.now(),
      'updatedAt': DateTime.now(),
    };

    final transactions = [
      {
        'transactionId': 'txn_1',
        'userId': user.uid,
        'amount': 50.0,
        'type': 'credit',
        'description': 'Initial deposit',
        'createdAt': DateTime.now().subtract(const Duration(days: 5)),
      },
      {
        'transactionId': 'txn_2',
        'userId': user.uid,
        'amount': -25.0,
        'type': 'debit',
        'description': 'Trip payment',
        'createdAt': DateTime.now().subtract(const Duration(days: 2)),
      },
    ];

    return {
      'user': user,
      'wallet': wallet,
      'transactions': transactions,
    };
  }

  /// Creates an active trip being tracked in real-time.
  ///
  /// Returns:
  /// - customer: User taking the trip
  /// - driver: Driver performing the trip
  /// - trip: In-progress trip
  /// - pickup: Cairo downtown location
  /// - destination: Giza pyramids location
  /// - currentLocation: Driver's current position (halfway between pickup and destination)
  ///
  /// Example:
  /// ```dart
  /// final scenario = TestFixtures.activeTripInProgress();
  /// expect(scenario['trip'].status, equals(TripStatus.inProgress));
  /// ```
  static Map<String, dynamic> activeTripInProgress() {
    final customer = UserFactory.createCustomer();
    final driver = UserFactory.createDriver();
    final pickup = PlaceFactory.createCairoLocation();
    final dropoff = PlaceFactory.createGizaLocation();

    final trip = TripFactory.create(
      customerUid: customer.uid,
      driverUid: driver.uid,
      pickup: pickup,
      dropoff: dropoff,
      status: TripStatus.inProgress,
    );

    // Driver's current location (halfway between pickup and dropoff)
    final currentLocation = PlaceFactory.create(
      name: 'Current Location',
      lat: (pickup.lat + dropoff.lat) / 2,
      lng: (pickup.lng + dropoff.lng) / 2,
    );

    return {
      'customer': customer,
      'driver': driver,
      'trip': trip,
      'pickup': pickup,
      'destination': dropoff,
      'currentLocation': currentLocation,
    };
  }

  /// Creates a cancelled trip scenario.
  ///
  /// Returns:
  /// - customer: User who cancelled the trip
  /// - trip: Cancelled trip
  /// - bids: List of bids that were submitted before cancellation
  ///
  /// Example:
  /// ```dart
  /// final scenario = TestFixtures.cancelledTrip();
  /// expect(scenario['trip'].status, equals(TripStatus.cancelled));
  /// ```
  static Map<String, dynamic> cancelledTrip() {
    final customer = UserFactory.createCustomer();
    final trip = TripFactory.create(
      customerUid: customer.uid,
      status: TripStatus.cancelled,
    );
    final bids = BidFactory.createMultipleBids(trip.id, 2);

    return {
      'customer': customer,
      'trip': trip,
      'bids': bids,
    };
  }
}
