import 'package:app_core/app_core.dart';

class LocationSelection {
  const LocationSelection({
    required this.displayAddress,
    required this.latitude,
    required this.longitude,
  });

  final String displayAddress;
  final double latitude;
  final double longitude;

  @override
  bool operator ==(Object other) =>
      other is LocationSelection &&
      other.displayAddress == displayAddress &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(displayAddress, latitude, longitude);
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  if (value is List && value.isNotEmpty && value.first is Map) {
    return Map<String, dynamic>.from(value.first as Map);
  }
  return null;
}

const developmentLocations = <LocationSelection>[
  LocationSelection(
    displayAddress: 'ميدان رابعة، مدينة نصر',
    latitude: 30.0566,
    longitude: 31.3301,
  ),
  LocationSelection(
    displayAddress: 'ميدان الحجاز، مصر الجديدة',
    latitude: 30.1133,
    longitude: 31.3460,
  ),
  LocationSelection(
    displayAddress: 'التجمع الخامس، القاهرة الجديدة',
    latitude: 30.0074,
    longitude: 31.4913,
  ),
];

class DeliveryDetails {
  const DeliveryDetails({
    required this.recipientName,
    required this.recipientPhone,
    required this.parcelWeightKg,
    required this.declaredValue,
  });

  final String recipientName;
  final String recipientPhone;
  final double parcelWeightKg;
  final double declaredValue;

  factory DeliveryDetails.fromJson(Map<String, dynamic> json) {
    return DeliveryDetails(
      recipientName: json['recipient_name'] as String,
      recipientPhone: json['recipient_phone'] as String,
      parcelWeightKg: (json['parcel_weight_kg'] as num).toDouble(),
      declaredValue: (json['declared_value'] as num).toDouble(),
    );
  }
}

class OrderDraft {
  const OrderDraft({
    required this.service,
    required this.pickup,
    required this.destination,
    required this.proposedPrice,
    this.delivery,
    this.routeQuote,
  });

  final ServiceType service;
  final LocationSelection pickup;
  final LocationSelection destination;
  final double proposedPrice;
  final DeliveryDetails? delivery;
  final RouteQuote? routeQuote;
}

class RouteQuote {
  const RouteQuote({
    required this.id,
    required this.pickup,
    required this.destination,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.encodedPolyline,
    required this.suggestedPrice,
    required this.minimumCustomerPrice,
    required this.expiresAt,
  });

  factory RouteQuote.fromJson(Map<String, dynamic> json) => RouteQuote(
    id: json['id'] as String,
    pickup: LocationSelection(
      displayAddress: '',
      latitude: (json['pickup_lat'] as num).toDouble(),
      longitude: (json['pickup_lng'] as num).toDouble(),
    ),
    destination: LocationSelection(
      displayAddress: '',
      latitude: (json['destination_lat'] as num).toDouble(),
      longitude: (json['destination_lng'] as num).toDouble(),
    ),
    distanceMeters: json['distance_meters'] as int,
    durationSeconds: json['duration_seconds'] as int,
    encodedPolyline: json['encoded_polyline'] as String,
    suggestedPrice: (json['suggested_price'] as num).toDouble(),
    minimumCustomerPrice: (json['minimum_customer_price'] as num).toDouble(),
    expiresAt: DateTime.parse(json['expires_at'] as String).toUtc(),
  );

  final String id;
  final LocationSelection pickup;
  final LocationSelection destination;
  final int distanceMeters;
  final int durationSeconds;
  final String encodedPolyline;
  final double suggestedPrice;
  final double minimumCustomerPrice;
  final DateTime expiresAt;
}

class CustomerOrder {
  const CustomerOrder({
    required this.id,
    required this.service,
    required this.pickup,
    required this.destination,
    required this.proposedPrice,
    required this.status,
    required this.createdAt,
    this.agreedPrice,
    this.driverId,
    this.biddingExpiresAt,
    this.cancellationReason,
    this.cancellationType,
    this.delivery,
    this.routeDistanceMeters,
    this.routeDurationSeconds,
    this.routePolyline,
    this.suggestedPrice,
    this.minimumCustomerPrice,
    this.completedAt,
    this.cancelledAt,
    this.expiredAt,
  });

  final String id;
  final ServiceType service;
  final LocationSelection pickup;
  final LocationSelection destination;
  final double proposedPrice;
  final double? agreedPrice;
  final String? driverId;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime? biddingExpiresAt;
  final String? cancellationReason;
  final String? cancellationType;
  final DeliveryDetails? delivery;
  final int? routeDistanceMeters;
  final int? routeDurationSeconds;
  final String? routePolyline;
  final double? suggestedPrice;
  final double? minimumCustomerPrice;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final DateTime? expiredAt;

  DateTime? get terminalAt => switch (status) {
    OrderStatus.completed => completedAt,
    OrderStatus.cancelled => cancelledAt,
    OrderStatus.expired => expiredAt,
    _ => null,
  };

  bool biddingElapsed([DateTime? now]) =>
      status == OrderStatus.bidding &&
      biddingExpiresAt != null &&
      !biddingExpiresAt!.isAfter((now ?? DateTime.now()).toUtc());

  OrderDraft bookAgainDraft() => OrderDraft(
    service: service,
    pickup: pickup,
    destination: destination,
    proposedPrice: proposedPrice,
    delivery: delivery,
  );

  factory CustomerOrder.fromJson(Map<String, dynamic> json) {
    final serviceJson = _asMap(json['service']);
    final deliveryJson = _asMap(json['delivery']);
    return CustomerOrder(
      id: json['id'] as String,
      service: ServiceType.values.firstWhere(
        (value) => value.databaseValue == serviceJson?['code'],
      ),
      pickup: LocationSelection(
        displayAddress: json['pickup_address'] as String,
        latitude: (json['pickup_lat'] as num).toDouble(),
        longitude: (json['pickup_lng'] as num).toDouble(),
      ),
      destination: LocationSelection(
        displayAddress: json['destination_address'] as String,
        latitude: (json['destination_lat'] as num).toDouble(),
        longitude: (json['destination_lng'] as num).toDouble(),
      ),
      proposedPrice: (json['proposed_price'] as num).toDouble(),
      agreedPrice: (json['agreed_price'] as num?)?.toDouble(),
      driverId: json['driver_id'] as String?,
      status: OrderStatus.values.firstWhere(
        (value) => value.databaseValue == json['status'],
      ),
      createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
      biddingExpiresAt: json['bidding_expires_at'] == null
          ? null
          : DateTime.parse(json['bidding_expires_at'] as String).toUtc(),
      cancellationReason: json['cancellation_reason'] as String?,
      cancellationType: json['cancellation_type'] as String?,
      delivery: deliveryJson == null
          ? null
          : DeliveryDetails.fromJson(deliveryJson),
      routeDistanceMeters: json['route_distance_meters'] as int?,
      routeDurationSeconds: json['route_duration_seconds'] as int?,
      routePolyline: json['route_polyline'] as String?,
      suggestedPrice: (json['suggested_price'] as num?)?.toDouble(),
      minimumCustomerPrice: (json['minimum_customer_price'] as num?)
          ?.toDouble(),
      completedAt: _dateOrNull(json['completed_at']),
      cancelledAt: _dateOrNull(json['cancelled_at']),
      expiredAt: _dateOrNull(json['expired_at']),
    );
  }
}

DateTime? _dateOrNull(dynamic value) =>
    value == null ? null : DateTime.parse(value as String).toUtc();

class OrderHistoryCursor {
  const OrderHistoryCursor({required this.createdAt, required this.id});

  final DateTime createdAt;
  final String id;
}

class OrderHistoryPage {
  const OrderHistoryPage({required this.orders, required this.nextCursor});

  final List<CustomerOrder> orders;
  final OrderHistoryCursor? nextCursor;

  bool get hasMore => nextCursor != null;
}

class DriverOffer {
  const DriverOffer({
    required this.id,
    required this.price,
    required this.driverPublicId,
    required this.driverFirstName,
    required this.driverType,
    required this.completedTripCount,
    this.driverPhotoUrl,
    this.officeDisplayName,
  });

  final String id;
  final double price;
  final String driverPublicId;
  final String driverFirstName;
  final String? driverPhotoUrl;
  final DriverType driverType;
  final String? officeDisplayName;
  final int completedTripCount;

  DriverSummary toSummary() => DriverSummary(
    driverPublicId: driverPublicId,
    driverFirstName: driverFirstName,
    driverPhotoUrl: driverPhotoUrl,
    driverType: driverType,
    officeDisplayName: officeDisplayName,
    completedTripCount: completedTripCount,
    driverVerified: false,
  );

  factory DriverOffer.fromJson(Map<String, dynamic> json) => DriverOffer(
    id: json['offer_id'] as String,
    price: (json['offered_price'] as num).toDouble(),
    driverPublicId: json['driver_public_id'] as String,
    driverFirstName:
        (json['driver_first_name'] as String?)?.trim().isNotEmpty == true
        ? json['driver_first_name'] as String
        : 'السائق',
    driverPhotoUrl: json['driver_photo_url'] as String?,
    driverType: DriverType.values.firstWhere(
      (value) => value.databaseValue == json['driver_type'],
    ),
    officeDisplayName: json['office_display_name'] as String?,
    completedTripCount: (json['completed_trip_count'] as num?)?.toInt() ?? 0,
  );
}

class DriverSummary {
  const DriverSummary({
    required this.driverPublicId,
    required this.driverFirstName,
    required this.driverType,
    required this.completedTripCount,
    this.driverVerified = false,
    this.driverPhotoUrl,
    this.officeDisplayName,
    this.motorcycleBrand,
    this.motorcycleModel,
    this.motorcyclePlateNumber,
  });

  final String driverPublicId;
  final String driverFirstName;
  final String? driverPhotoUrl;
  final DriverType driverType;
  final String? officeDisplayName;
  final int completedTripCount;
  final bool driverVerified;
  final String? motorcycleBrand;
  final String? motorcycleModel;
  final String? motorcyclePlateNumber;

  factory DriverSummary.fromJson(Map<String, dynamic> json) => DriverSummary(
    driverPublicId: json['driver_public_id'] as String,
    driverFirstName:
        (json['driver_first_name'] as String?)?.trim().isNotEmpty == true
        ? json['driver_first_name'] as String
        : 'السائق',
    driverPhotoUrl: json['driver_photo_url'] as String?,
    driverType: DriverType.values.firstWhere(
      (value) => value.databaseValue == json['driver_type'],
    ),
    officeDisplayName: json['office_display_name'] as String?,
    completedTripCount: (json['completed_trip_count'] as num?)?.toInt() ?? 0,
    driverVerified: json['driver_verified'] as bool? ?? false,
    motorcycleBrand: json['motorcycle_brand'] as String?,
    motorcycleModel: json['motorcycle_model'] as String?,
    motorcyclePlateNumber: json['motorcycle_plate_number'] as String?,
  );
}
