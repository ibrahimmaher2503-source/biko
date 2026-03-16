/// Model for a driver's real-time location from Realtime Database.
///
/// Used to display nearby driver markers on the customer home screen map.
class DriverLocationModel {
  const DriverLocationModel({
    required this.uid,
    required this.lat,
    required this.lng,
    required this.heading,
    required this.isOnline,
    this.vehicleType = 'motorcycle',
  });

  factory DriverLocationModel.fromMap(String uid, Map<String, dynamic> map) {
    return DriverLocationModel(
      uid: uid,
      lat: (map['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (map['lng'] as num?)?.toDouble() ?? 0.0,
      heading: (map['heading'] as num?)?.toDouble() ?? 0.0,
      isOnline: map['is_online'] as bool? ?? false,
      vehicleType: map['vehicle_type'] as String? ?? 'motorcycle',
    );
  }

  final String uid;
  final double lat;
  final double lng;
  final double heading;
  final bool isOnline;
  final String vehicleType;

  Map<String, dynamic> toMap() {
    return {
      'lat': lat,
      'lng': lng,
      'heading': heading,
      'is_online': isOnline,
      'vehicle_type': vehicleType,
    };
  }

  DriverLocationModel copyWith({
    String? uid,
    double? lat,
    double? lng,
    double? heading,
    bool? isOnline,
    String? vehicleType,
  }) {
    return DriverLocationModel(
      uid: uid ?? this.uid,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      heading: heading ?? this.heading,
      isOnline: isOnline ?? this.isOnline,
      vehicleType: vehicleType ?? this.vehicleType,
    );
  }

  @override
  String toString() => 'DriverLocationModel(uid: $uid, lat: $lat, lng: $lng)';
}
