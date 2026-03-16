import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Location/place model for pickup and dropoff locations
class PlaceModel {
  const PlaceModel({
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    this.placeId = '',
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

  /// Create from geocoding Placemark result
  factory PlaceModel.fromGeocode(Placemark placemark, double lat, double lng) {
    final name = placemark.name ?? placemark.street ?? '';
    final parts = <String>[
      if (placemark.street != null && placemark.street != placemark.name)
        placemark.street!,
      if (placemark.subLocality?.isNotEmpty ?? false) placemark.subLocality!,
      if (placemark.locality?.isNotEmpty ?? false) placemark.locality!,
      if (placemark.administrativeArea?.isNotEmpty ?? false)
        placemark.administrativeArea!,
    ];
    final address = parts.isNotEmpty ? parts.join(', ') : '';

    return PlaceModel(name: name, address: address, lat: lat, lng: lng);
  }

  /// Create from Google Places API detail result
  factory PlaceModel.fromGooglePlaces(Map<String, dynamic> result) {
    final geometry = result['geometry'] as Map<String, dynamic>?;
    final location = geometry?['location'] as Map<String, dynamic>?;

    return PlaceModel(
      placeId: (result['place_id'] as String?) ?? '',
      name: (result['name'] as String?) ?? '',
      address: (result['formatted_address'] as String?) ?? '',
      lat: (location?['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (location?['lng'] as num?)?.toDouble() ?? 0.0,
    );
  }

  final String placeId;
  final String name;
  final String address;
  final double lat;
  final double lng;

  /// Convenience getter for Google Maps [LatLng].
  LatLng get latLng => LatLng(lat, lng);

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

/// Autocomplete result from Google Places API
class PlaceAutocompleteResult {
  const PlaceAutocompleteResult({
    required this.placeId,
    required this.description,
    this.mainText = '',
    this.secondaryText = '',
  });

  factory PlaceAutocompleteResult.fromJson(Map<String, dynamic> json) {
    final structured =
        json['structured_formatting'] as Map<String, dynamic>? ?? {};
    return PlaceAutocompleteResult(
      placeId: json['place_id'] as String? ?? '',
      description: json['description'] as String? ?? '',
      mainText: structured['main_text'] as String? ?? '',
      secondaryText: structured['secondary_text'] as String? ?? '',
    );
  }

  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;
}
