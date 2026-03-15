import 'package:biko/core/models/bid_model.dart';
import 'package:biko/core/models/enums.dart';
import 'package:biko/core/models/place_model.dart';
import 'package:biko/core/models/trip_model.dart';
import 'package:biko/core/models/user_model.dart';

/// Test data factories for generating realistic test data.
///
/// These factories provide:
/// - Sensible defaults for all model fields
/// - Realistic Egyptian market data (+20 phone numbers, Arabic names, EGP currency)
/// - Unique IDs across test runs (timestamp-based)
/// - Easy customization via overrides

/// Factory for creating User model test data.
///
/// Generates users with realistic Egyptian data:
/// - Phone numbers: +20 prefix, 11 digits
/// - Names: Realistic Arabic names
/// - Unique UIDs: Timestamp-based for test isolation
class UserFactory {
  /// Creates a single user with optional field overrides.
  ///
  /// Example:
  /// ```dart
  /// final user = UserFactory.create();
  /// final customUser = UserFactory.create(phone: '+201111111111', name: 'Custom Name');
  /// ```
  static UserModel create({
    String? uid,
    String? phone,
    String? name,
    UserType? type,
    String? email,
    String? avatarUrl,
    DateTime? createdAt,
    UserStatus? status,
    double? walletBalance,
  }) {
    return UserModel(
      uid: uid ?? 'test_user_${DateTime.now().millisecondsSinceEpoch}',
      phone: phone ?? '+201234567890',
      name: name ?? 'أحمد محمد',
      type: type ?? UserType.customer,
      email: email,
      avatarUrl: avatarUrl,
      createdAt: createdAt ?? DateTime.now(),
      status: status ?? UserStatus.active,
      walletBalance: walletBalance ?? 0.0,
    );
  }

  /// Creates a customer user (type: UserType.customer).
  static UserModel createCustomer({Map<String, dynamic>? overrides}) {
    return create(
      type: UserType.customer,
      uid: overrides?['uid'] as String?,
      phone: overrides?['phone'] as String?,
      name: overrides?['name'] as String?,
    );
  }

  /// Creates a driver user (type: UserType.driver).
  static UserModel createDriver({Map<String, dynamic>? overrides}) {
    return create(
      type: UserType.driver,
      uid: overrides?['uid'] as String?,
      phone: overrides?['phone'] as String?,
      name: overrides?['name'] as String? ?? 'محمد علي',
    );
  }

  /// Creates a list of users with shared overrides.
  ///
  /// Example:
  /// ```dart
  /// final drivers = UserFactory.createList(5);
  /// ```
  static List<UserModel> createList(int count, {UserType? type}) {
    return List.generate(
      count,
      (index) => create(
        type: type ?? UserType.customer,
      ),
    );
  }
}

/// Factory for creating Trip model test data.
class TripFactory {
  /// Creates a single trip with optional field overrides.
  ///
  /// Example:
  /// ```dart
  /// final trip = TripFactory.create();
  /// final customTrip = TripFactory.create(status: TripStatus.completed);
  /// ```
  static TripModel create({
    String? id,
    String? customerUid,
    String? driverUid,
    PlaceModel? pickup,
    PlaceModel? dropoff,
    TripStatus? status,
    TripType? type,
    PaymentMethod? paymentMethod,
    double? customerPrice,
    double? acceptedPrice,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return TripModel(
      id: id ?? 'trip_${DateTime.now().millisecondsSinceEpoch}',
      customerUid: customerUid ?? UserFactory.createCustomer().uid,
      driverUid: driverUid,
      pickup: pickup ?? PlaceFactory.createCairoLocation(),
      dropoff: dropoff ?? PlaceFactory.createGizaLocation(),
      status: status ?? TripStatus.searching,
      type: type ?? TripType.ride,
      paymentMethod: paymentMethod ?? PaymentMethod.cash,
      customerPrice: customerPrice ?? 50.0,
      acceptedPrice: acceptedPrice,
      createdAt: createdAt ?? DateTime.now(),
      completedAt: completedAt,
    );
  }

  /// Creates a pending trip (status: TripStatus.searching).
  static TripModel createPending({String? id, String? customerUid}) {
    return create(
      status: TripStatus.searching,
      id: id,
      customerUid: customerUid,
    );
  }

  /// Creates an accepted trip (status: TripStatus.accepted) with driver assigned.
  static TripModel createAccepted({String? id, String? customerUid, String? driverUid}) {
    return create(
      status: TripStatus.accepted,
      driverUid: driverUid ?? 'driver_${DateTime.now().millisecondsSinceEpoch}',
      id: id,
      customerUid: customerUid,
    );
  }

  /// Creates a completed trip (status: TripStatus.completed) with accepted price.
  static TripModel createCompleted({String? id, String? customerUid, String? driverUid}) {
    return create(
      status: TripStatus.completed,
      driverUid: driverUid ?? 'driver_${DateTime.now().millisecondsSinceEpoch}',
      acceptedPrice: 55.0,
      completedAt: DateTime.now(),
      id: id,
      customerUid: customerUid,
    );
  }
}

/// Factory for creating Bid model test data.
class BidFactory {
  /// Creates a single bid with optional field overrides.
  ///
  /// Example:
  /// ```dart
  /// final bid = BidFactory.create();
  /// final customBid = BidFactory.create(amount: 45.0);
  /// ```
  static BidModel create({
    String? bidId,
    String? tripId,
    String? driverUid,
    String? driverName,
    double? driverRating,
    VehicleType? vehicleType,
    double? amount,
    BidStatus? status,
    int? etaMinutes,
    DateTime? createdAt,
  }) {
    return BidModel(
      bidId: bidId ?? 'bid_${DateTime.now().millisecondsSinceEpoch}',
      tripId: tripId ?? TripFactory.create().id,
      driverUid: driverUid ?? UserFactory.createDriver().uid,
      driverName: driverName ?? 'محمد علي',
      driverRating: driverRating ?? 4.5,
      vehicleType: vehicleType ?? VehicleType.motorcycle,
      amount: amount ?? 45.0,
      status: status ?? BidStatus.pending,
      etaMinutes: etaMinutes ?? 10,
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  /// Creates multiple bids for a trip with varying amounts.
  ///
  /// Example:
  /// ```dart
  /// final bids = BidFactory.createMultipleBids('trip123', 3);
  /// // Creates 3 bids with amounts: 40.0, 45.0, 50.0
  /// ```
  static List<BidModel> createMultipleBids(String tripId, int count) {
    return List.generate(
      count,
      (index) => create(
        tripId: tripId,
        amount: 40.0 + (index * 5.0), // Varying bid amounts
        driverUid: 'driver_${DateTime.now().millisecondsSinceEpoch}_$index',
        driverName: 'سائق ${index + 1}',
        etaMinutes: 10 + (index * 2),
      ),
    );
  }
}

/// Factory for creating Place model test data.
class PlaceFactory {
  /// Creates Cairo downtown location (Tahrir Square).
  static PlaceModel createCairoLocation() {
    return const PlaceModel(
      name: 'Downtown Cairo',
      address: 'Tahrir Square, Cairo Governorate, Egypt',
      lat: 30.0444,
      lng: 31.2357,
      placeId: 'ChIJEcc4BIHnWBQRv2W5eSY2SkY',
    );
  }

  /// Creates Giza Pyramids location.
  static PlaceModel createGizaLocation() {
    return const PlaceModel(
      name: 'Giza Pyramids',
      address: 'Al Haram, Nazlet El-Semman, Giza Governorate, Egypt',
      lat: 29.9792,
      lng: 31.1342,
      placeId: 'ChIJv7MqnJTJWBQRv-Pjxwck7wM',
    );
  }

  /// Creates a custom location with specified coordinates.
  ///
  /// Example:
  /// ```dart
  /// final place = PlaceFactory.create(
  ///   name: 'Cairo Airport',
  ///   lat: 30.1219,
  ///   lng: 31.4056,
  /// );
  /// ```
  static PlaceModel create({
    String? name,
    String? address,
    double? lat,
    double? lng,
    String? placeId,
  }) {
    return PlaceModel(
      name: name ?? 'Custom Location',
      address: address ?? 'Cairo, Egypt',
      lat: lat ?? 30.0444,
      lng: lng ?? 31.2357,
      placeId: placeId ?? 'custom_${DateTime.now().millisecondsSinceEpoch}',
    );
  }
}
