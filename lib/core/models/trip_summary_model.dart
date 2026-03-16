import 'package:biko/core/models/driver_brief_model.dart';

/// Summary model for a completed trip — used in the trip completion screen
class TripSummaryModel {
  const TripSummaryModel({
    required this.tripId,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.distanceKm,
    required this.durationMinutes,
    required this.baseFare,
    required this.distanceFare,
    required this.timeFare,
    required this.totalFare,
    required this.paymentMethod,
    required this.driver,
    this.discount = 0.0,
  });

  factory TripSummaryModel.fromMap(Map<String, dynamic> map) {
    return TripSummaryModel(
      tripId: map['trip_id'] as String? ?? '',
      pickupAddress: map['pickup_address'] as String? ?? '',
      dropoffAddress: map['dropoff_address'] as String? ?? '',
      distanceKm: (map['distance_km'] as num?)?.toDouble() ?? 0.0,
      durationMinutes: (map['duration_minutes'] as num?)?.toInt() ?? 0,
      baseFare: (map['base_fare'] as num?)?.toDouble() ?? 0.0,
      distanceFare: (map['distance_fare'] as num?)?.toDouble() ?? 0.0,
      timeFare: (map['time_fare'] as num?)?.toDouble() ?? 0.0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      totalFare: (map['total_fare'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: map['payment_method'] as String? ?? 'cash',
      driver: DriverBriefModel.fromMap(
        map['driver'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  final String tripId;
  final String pickupAddress;
  final String dropoffAddress;
  final double distanceKm;
  final int durationMinutes;
  final double baseFare;
  final double distanceFare;
  final double timeFare;
  final double discount;
  final double totalFare;
  final String paymentMethod;
  final DriverBriefModel driver;

  /// Formatted total with EGP
  String get formattedTotal => '${totalFare.toStringAsFixed(2)} EGP';

  /// Formatted distance
  String get formattedDistance => '${distanceKm.toStringAsFixed(1)} km';

  /// Formatted duration
  String get formattedDuration => '$durationMinutes min';

  Map<String, dynamic> toMap() {
    return {
      'trip_id': tripId,
      'pickup_address': pickupAddress,
      'dropoff_address': dropoffAddress,
      'distance_km': distanceKm,
      'duration_minutes': durationMinutes,
      'base_fare': baseFare,
      'distance_fare': distanceFare,
      'time_fare': timeFare,
      'discount': discount,
      'total_fare': totalFare,
      'payment_method': paymentMethod,
      'driver': driver.toMap(),
    };
  }

  TripSummaryModel copyWith({
    String? tripId,
    String? pickupAddress,
    String? dropoffAddress,
    double? distanceKm,
    int? durationMinutes,
    double? baseFare,
    double? distanceFare,
    double? timeFare,
    double? discount,
    double? totalFare,
    String? paymentMethod,
    DriverBriefModel? driver,
  }) {
    return TripSummaryModel(
      tripId: tripId ?? this.tripId,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      dropoffAddress: dropoffAddress ?? this.dropoffAddress,
      distanceKm: distanceKm ?? this.distanceKm,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      baseFare: baseFare ?? this.baseFare,
      distanceFare: distanceFare ?? this.distanceFare,
      timeFare: timeFare ?? this.timeFare,
      discount: discount ?? this.discount,
      totalFare: totalFare ?? this.totalFare,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      driver: driver ?? this.driver,
    );
  }

  @override
  String toString() =>
      'TripSummaryModel(tripId: $tripId, total: $formattedTotal)';
}
