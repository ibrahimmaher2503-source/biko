import 'package:biko/core/models/enums.dart';
import 'package:biko/core/models/place_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for a trip/ride request
class TripModel {
  const TripModel({
    required this.id,
    required this.customerUid,
    required this.pickup,
    required this.dropoff,
    required this.status,
    required this.type,
    required this.paymentMethod,
    required this.customerPrice,
    required this.createdAt,
    this.driverUid,
    this.acceptedPrice,
    this.distanceKm,
    this.durationMinutes,
    this.cancelledBy,
    this.cancellationReason,
    this.acceptedAt,
    this.completedAt,
    this.cancelledAt,
  });

  factory TripModel.fromMap(Map<String, dynamic> map) {
    return TripModel(
      id: map['id'] as String? ?? '',
      customerUid: map['customer_uid'] as String? ?? '',
      driverUid: map['driver_uid'] as String?,
      pickup: PlaceModel.fromMap(
        map['pickup'] as Map<String, dynamic>? ?? {},
      ),
      dropoff: PlaceModel.fromMap(
        map['dropoff'] as Map<String, dynamic>? ?? {},
      ),
      status: TripStatus.fromJson(map['status'] as String? ?? 'searching'),
      type: TripType.fromJson(map['type'] as String? ?? 'ride'),
      paymentMethod: PaymentMethod.fromJson(
        map['payment_method'] as String? ?? 'cash',
      ),
      customerPrice: (map['customer_price'] as num?)?.toDouble() ?? 0.0,
      acceptedPrice: (map['accepted_price'] as num?)?.toDouble(),
      distanceKm: (map['distance_km'] as num?)?.toDouble(),
      durationMinutes: (map['duration_minutes'] as num?)?.toInt(),
      cancelledBy: map['cancelled_by'] as String?,
      cancellationReason: map['cancellation_reason'] as String?,
      createdAt: map['created_at'] is Timestamp
          ? (map['created_at'] as Timestamp).toDate()
          : DateTime.now(),
      acceptedAt: map['accepted_at'] is Timestamp
          ? (map['accepted_at'] as Timestamp).toDate()
          : null,
      completedAt: map['completed_at'] is Timestamp
          ? (map['completed_at'] as Timestamp).toDate()
          : null,
      cancelledAt: map['cancelled_at'] is Timestamp
          ? (map['cancelled_at'] as Timestamp).toDate()
          : null,
    );
  }

  final String id;
  final String customerUid;
  final String? driverUid;
  final PlaceModel pickup;
  final PlaceModel dropoff;
  final TripStatus status;
  final TripType type;
  final PaymentMethod paymentMethod;
  final double customerPrice;
  final double? acceptedPrice;
  final double? distanceKm;
  final int? durationMinutes;
  final String? cancelledBy;
  final String? cancellationReason;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;

  /// Formatted total fare string
  String get formattedPrice {
    final price = acceptedPrice ?? customerPrice;
    return '${price.toStringAsFixed(0)} EGP';
  }

  /// Whether the trip is currently active (not completed/cancelled)
  bool get isActive =>
      status != TripStatus.completed && status != TripStatus.cancelled;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_uid': customerUid,
      'driver_uid': driverUid,
      'pickup': pickup.toMap(),
      'dropoff': dropoff.toMap(),
      'status': status.toJson(),
      'type': type.toJson(),
      'payment_method': paymentMethod.toJson(),
      'customer_price': customerPrice,
      'accepted_price': acceptedPrice,
      'distance_km': distanceKm,
      'duration_minutes': durationMinutes,
      'cancelled_by': cancelledBy,
      'cancellation_reason': cancellationReason,
      'created_at': FieldValue.serverTimestamp(),
      'accepted_at': acceptedAt != null
          ? Timestamp.fromDate(acceptedAt!)
          : null,
      'completed_at': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
      'cancelled_at': cancelledAt != null
          ? Timestamp.fromDate(cancelledAt!)
          : null,
    };
  }

  TripModel copyWith({
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
    double? distanceKm,
    int? durationMinutes,
    String? cancelledBy,
    String? cancellationReason,
    DateTime? createdAt,
    DateTime? acceptedAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
  }) {
    return TripModel(
      id: id ?? this.id,
      customerUid: customerUid ?? this.customerUid,
      driverUid: driverUid ?? this.driverUid,
      pickup: pickup ?? this.pickup,
      dropoff: dropoff ?? this.dropoff,
      status: status ?? this.status,
      type: type ?? this.type,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      customerPrice: customerPrice ?? this.customerPrice,
      acceptedPrice: acceptedPrice ?? this.acceptedPrice,
      distanceKm: distanceKm ?? this.distanceKm,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      cancelledBy: cancelledBy ?? this.cancelledBy,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      createdAt: createdAt ?? this.createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
    );
  }

  @override
  String toString() =>
      'TripModel(id: $id, status: $status, price: $formattedPrice)';
}
