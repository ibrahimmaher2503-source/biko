import 'package:biko/core/models/enums.dart';

class DriverProfileModel {
  const DriverProfileModel({
    required this.uid,
    this.nationalId = '',
    this.licenseNumber = '',
    this.vehicleType = VehicleType.motorcycle,
    this.plateNumber = '',
    this.vehicleModel = '',
    this.isOnline = false,
    this.isApproved = false,
    this.currentLat,
    this.currentLng,
    this.ratingAvg = 0.0,
    this.totalTrips = 0,
    this.totalEarnings = 0.0,
  });

  factory DriverProfileModel.fromJson(Map<String, dynamic> json) {
    return DriverProfileModel(
      uid: json['uid'] as String? ?? '',
      nationalId: json['national_id'] as String? ?? '',
      licenseNumber: json['license_number'] as String? ?? '',
      vehicleType: VehicleType.fromJson(
        json['vehicle_type'] as String? ?? 'motorcycle',
      ),
      plateNumber: json['plate_number'] as String? ?? '',
      vehicleModel: json['vehicle_model'] as String? ?? '',
      isOnline: json['is_online'] as bool? ?? false,
      isApproved: json['is_approved'] as bool? ?? false,
      currentLat: (json['current_lat'] as num?)?.toDouble(),
      currentLng: (json['current_lng'] as num?)?.toDouble(),
      ratingAvg: (json['rating_avg'] as num?)?.toDouble() ?? 0.0,
      totalTrips: json['total_trips'] as int? ?? 0,
      totalEarnings: (json['total_earnings'] as num?)?.toDouble() ?? 0.0,
    );
  }

  final String uid;
  final String nationalId;
  final String licenseNumber;
  final VehicleType vehicleType;
  final String plateNumber;
  final String vehicleModel;
  final bool isOnline;
  final bool isApproved;
  final double? currentLat;
  final double? currentLng;
  final double ratingAvg;
  final int totalTrips;
  final double totalEarnings;

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'national_id': nationalId,
      'license_number': licenseNumber,
      'vehicle_type': vehicleType.toJson(),
      'plate_number': plateNumber,
      'vehicle_model': vehicleModel,
      'is_online': isOnline,
      'is_approved': isApproved,
      'current_lat': currentLat,
      'current_lng': currentLng,
      'rating_avg': ratingAvg,
      'total_trips': totalTrips,
      'total_earnings': totalEarnings,
    };
  }

  DriverProfileModel copyWith({
    String? uid,
    String? nationalId,
    String? licenseNumber,
    VehicleType? vehicleType,
    String? plateNumber,
    String? vehicleModel,
    bool? isOnline,
    bool? isApproved,
    double? currentLat,
    double? currentLng,
    double? ratingAvg,
    int? totalTrips,
    double? totalEarnings,
  }) {
    return DriverProfileModel(
      uid: uid ?? this.uid,
      nationalId: nationalId ?? this.nationalId,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      vehicleType: vehicleType ?? this.vehicleType,
      plateNumber: plateNumber ?? this.plateNumber,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      isOnline: isOnline ?? this.isOnline,
      isApproved: isApproved ?? this.isApproved,
      currentLat: currentLat ?? this.currentLat,
      currentLng: currentLng ?? this.currentLng,
      ratingAvg: ratingAvg ?? this.ratingAvg,
      totalTrips: totalTrips ?? this.totalTrips,
      totalEarnings: totalEarnings ?? this.totalEarnings,
    );
  }
}
