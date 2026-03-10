/// Location/place model for pickup and dropoff locations
class PlaceModel {
  const PlaceModel({
    required this.placeId,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
  });

  factory PlaceModel.fromMap(Map<String, dynamic> map) {
    return PlaceModel(
      placeId: map['place_id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      address: map['address'] as String? ?? '',
      lat: (map['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (map['lng'] as num?)?.toDouble() ?? 0.0,
    );
  }

  final String placeId;
  final String name;
  final String address;
  final double lat;
  final double lng;

  Map<String, dynamic> toMap() {
    return {
      'place_id': placeId,
      'name': name,
      'address': address,
      'lat': lat,
      'lng': lng,
    };
  }

  PlaceModel copyWith({
    String? placeId,
    String? name,
    String? address,
    double? lat,
    double? lng,
  }) {
    return PlaceModel(
      placeId: placeId ?? this.placeId,
      name: name ?? this.name,
      address: address ?? this.address,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
    );
  }

  @override
  String toString() => 'PlaceModel(name: $name, lat: $lat, lng: $lng)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlaceModel && other.placeId == placeId;
  }

  @override
  int get hashCode => placeId.hashCode;
}
