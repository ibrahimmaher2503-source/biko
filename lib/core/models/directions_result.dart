import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Result from Google Maps Directions API call.
///
/// Contains the decoded polyline points for map display,
/// route distance/duration for fare calculation, and
/// bounding box for camera fitting.
class DirectionsResult {
  const DirectionsResult({
    required this.polylinePoints,
    required this.encodedPolyline,
    required this.distanceKm,
    required this.durationMins,
    required this.boundsNE,
    required this.boundsSW,
  });

  /// Creates a [DirectionsResult] from a map (e.g. Firestore document).
  factory DirectionsResult.fromMap(Map<String, dynamic> map) {
    final polylineData = map['polyline_points'] as List<dynamic>? ?? [];
    final polylinePoints = polylineData
        .map(
          (p) => LatLng(
            (p['lat'] as num).toDouble(),
            (p['lng'] as num).toDouble(),
          ),
        )
        .toList();

    final ne = map['bounds_ne'] as Map<String, dynamic>? ?? {};
    final sw = map['bounds_sw'] as Map<String, dynamic>? ?? {};

    return DirectionsResult(
      polylinePoints: polylinePoints,
      encodedPolyline: map['encoded_polyline'] as String? ?? '',
      distanceKm: (map['distance_km'] as num?)?.toDouble() ?? 0.0,
      durationMins: (map['duration_mins'] as num?)?.toDouble() ?? 0.0,
      boundsNE: LatLng(
        (ne['lat'] as num?)?.toDouble() ?? 0.0,
        (ne['lng'] as num?)?.toDouble() ?? 0.0,
      ),
      boundsSW: LatLng(
        (sw['lat'] as num?)?.toDouble() ?? 0.0,
        (sw['lng'] as num?)?.toDouble() ?? 0.0,
      ),
    );
  }

  /// Decoded route points for drawing a Polyline on the map
  final List<LatLng> polylinePoints;

  /// Raw encoded polyline string from the API
  final String encodedPolyline;

  /// Route distance in kilometers
  final double distanceKm;

  /// Estimated trip duration in minutes
  final double durationMins;

  /// Northeast corner of the route bounding box
  final LatLng boundsNE;

  /// Southwest corner of the route bounding box
  final LatLng boundsSW;

  /// Converts this result to a map for Firestore storage.
  Map<String, dynamic> toMap() {
    return {
      'polyline_points': polylinePoints
          .map((p) => {'lat': p.latitude, 'lng': p.longitude})
          .toList(),
      'encoded_polyline': encodedPolyline,
      'distance_km': distanceKm,
      'duration_mins': durationMins,
      'bounds_ne': {
        'lat': boundsNE.latitude,
        'lng': boundsNE.longitude,
      },
      'bounds_sw': {
        'lat': boundsSW.latitude,
        'lng': boundsSW.longitude,
      },
    };
  }

  /// Creates a copy with optional field overrides.
  DirectionsResult copyWith({
    List<LatLng>? polylinePoints,
    String? encodedPolyline,
    double? distanceKm,
    double? durationMins,
    LatLng? boundsNE,
    LatLng? boundsSW,
  }) {
    return DirectionsResult(
      polylinePoints: polylinePoints ?? this.polylinePoints,
      encodedPolyline: encodedPolyline ?? this.encodedPolyline,
      distanceKm: distanceKm ?? this.distanceKm,
      durationMins: durationMins ?? this.durationMins,
      boundsNE: boundsNE ?? this.boundsNE,
      boundsSW: boundsSW ?? this.boundsSW,
    );
  }
}
