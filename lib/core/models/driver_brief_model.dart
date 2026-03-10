import 'package:biko/core/models/enums.dart';

/// Lightweight driver info model for bid cards and trip displays
class DriverBriefModel {
  const DriverBriefModel({
    required this.uid,
    required this.name,
    required this.vehicleType,
    required this.rating,
    this.photoUrl,
    this.plateNumber,
    this.distanceKm,
    this.totalTrips = 0,
  });

  factory DriverBriefModel.fromMap(Map<String, dynamic> map) {
    return DriverBriefModel(
      uid: map['uid'] as String? ?? '',
      name: map['name'] as String? ?? '',
      photoUrl: map['avatar_url'] as String? ?? map['photo_url'] as String?,
      vehicleType: VehicleType.fromJson(
        map['vehicle_type'] as String? ?? 'motorcycle',
      ),
      plateNumber: map['plate_number'] as String?,
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      distanceKm: (map['distance_km'] as num?)?.toDouble(),
      totalTrips: (map['total_trips'] as num?)?.toInt() ?? 0,
    );
  }

  final String uid;
  final String name;
  final String? photoUrl;
  final VehicleType vehicleType;
  final String? plateNumber;
  final double rating;
  final double? distanceKm;
  final int totalTrips;

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'photo_url': photoUrl,
      'vehicle_type': vehicleType.toJson(),
      'plate_number': plateNumber,
      'rating': rating,
      'distance_km': distanceKm,
      'total_trips': totalTrips,
    };
  }

  DriverBriefModel copyWith({
    String? uid,
    String? name,
    String? photoUrl,
    VehicleType? vehicleType,
    String? plateNumber,
    double? rating,
    double? distanceKm,
    int? totalTrips,
  }) {
    return DriverBriefModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      vehicleType: vehicleType ?? this.vehicleType,
      plateNumber: plateNumber ?? this.plateNumber,
      rating: rating ?? this.rating,
      distanceKm: distanceKm ?? this.distanceKm,
      totalTrips: totalTrips ?? this.totalTrips,
    );
  }

  @override
  String toString() =>
      'DriverBriefModel(uid: $uid, name: $name, rating: $rating)';
}
