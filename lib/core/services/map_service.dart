import 'dart:convert';
import 'dart:math' show atan2, cos, pi, sin, sqrt;

import 'package:biko/core/models/directions_result.dart';
import 'package:biko/core/models/place_model.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Static utility class for Google Maps/Places API interactions.
///
/// Wraps reverse-geocoding, Places Autocomplete, and Place Details
/// into typed model responses. Shared across pickup, dropoff, and
/// trip features.
class MapService {
  MapService._();

  static const String _apiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');

  static const String _placesBaseUrl =
      'https://maps.googleapis.com/maps/api/place';

  static const String _directionsBaseUrl =
      'https://maps.googleapis.com/maps/api/directions/json';

  /// Fetch route directions between [origin] and [destination].
  ///
  /// Calls the Google Maps Directions API, decodes the overview polyline,
  /// and returns a [DirectionsResult]. Falls back to Haversine estimation
  /// with a 1.3x road factor if the API call fails.
  static Future<DirectionsResult> getDirections(
    LatLng origin,
    LatLng destination,
  ) async {
    try {
      final uri = Uri.parse(_directionsBaseUrl).replace(
        queryParameters: {
          'origin': '${origin.latitude},${origin.longitude}',
          'destination': '${destination.latitude},${destination.longitude}',
          'key': _apiKey,
        },
      );

      final response = await http.get(uri);
      if (response.statusCode != 200) {
        return _haversineFallback(origin, destination);
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final routes = data['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) {
        return _haversineFallback(origin, destination);
      }

      final route = routes.first as Map<String, dynamic>;
      final legs = route['legs'] as List<dynamic>;
      final leg = legs.first as Map<String, dynamic>;

      final distanceMeters =
          ((leg['distance'] as Map<String, dynamic>)['value'] as num)
              .toDouble();
      final durationSeconds =
          ((leg['duration'] as Map<String, dynamic>)['value'] as num)
              .toDouble();

      final encodedPolyline =
          (route['overview_polyline'] as Map<String, dynamic>)['points']
              as String;

      final decoded = PolylinePoints().decodePolyline(encodedPolyline);
      final points = decoded
          .map((p) => LatLng(p.latitude, p.longitude))
          .toList();

      final bounds = route['bounds'] as Map<String, dynamic>;
      final ne = bounds['northeast'] as Map<String, dynamic>;
      final sw = bounds['southwest'] as Map<String, dynamic>;

      return DirectionsResult(
        polylinePoints: points,
        encodedPolyline: encodedPolyline,
        distanceKm: distanceMeters / 1000,
        durationMins: durationSeconds / 60,
        boundsNE: LatLng(
          (ne['lat'] as num).toDouble(),
          (ne['lng'] as num).toDouble(),
        ),
        boundsSW: LatLng(
          (sw['lat'] as num).toDouble(),
          (sw['lng'] as num).toDouble(),
        ),
      );
    } catch (_) {
      return _haversineFallback(origin, destination);
    }
  }

  /// Haversine fallback when Directions API fails.
  ///
  /// Uses a 1.3x road factor to estimate road distance from
  /// straight-line distance, and assumes 30 km/h average urban speed.
  static DirectionsResult _haversineFallback(
    LatLng origin,
    LatLng destination,
  ) {
    const roadFactor = 1.3;
    const avgSpeedKmh = 30.0;

    final straightLineKm = _haversineDistance(origin, destination);
    final distanceKm = straightLineKm * roadFactor;
    final durationMins = (distanceKm / avgSpeedKmh) * 60;

    return DirectionsResult(
      polylinePoints: [origin, destination],
      encodedPolyline: '',
      distanceKm: distanceKm,
      durationMins: durationMins,
      boundsNE: LatLng(
        origin.latitude > destination.latitude
            ? origin.latitude
            : destination.latitude,
        origin.longitude > destination.longitude
            ? origin.longitude
            : destination.longitude,
      ),
      boundsSW: LatLng(
        origin.latitude < destination.latitude
            ? origin.latitude
            : destination.latitude,
        origin.longitude < destination.longitude
            ? origin.longitude
            : destination.longitude,
      ),
    );
  }

  /// Haversine formula for straight-line distance in km.
  static double _haversineDistance(LatLng a, LatLng b) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRadians(b.latitude - a.latitude);
    final dLng = _toRadians(b.longitude - a.longitude);
    final aVal =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(a.latitude)) *
            cos(_toRadians(b.latitude)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(aVal), sqrt(1 - aVal));
    return earthRadiusKm * c;
  }

  static double _toRadians(double degrees) => degrees * pi / 180;

  /// Reverse-geocode a lat/lng to a [PlaceModel].
  ///
  /// Returns `null` if no results are found.
  static Future<PlaceModel?> reverseGeocode(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return null;
      return PlaceModel.fromGeocode(placemarks.first, lat, lng);
    } catch (_) {
      return null;
    }
  }

  /// Search for places matching [query] using Google Places Autocomplete API.
  ///
  /// Results are biased to Egypt (`components=country:eg`) and optionally
  /// biased to [biasLocation] within a 50 km radius.
  static Future<List<PlaceAutocompleteResult>> searchPlaces(
    String query, {
    LatLng? biasLocation,
  }) async {
    try {
      final locale = Get.locale?.languageCode ?? 'ar';
      final params = <String, String>{
        'input': query,
        'components': 'country:eg',
        'language': locale,
        'key': _apiKey,
      };

      if (biasLocation != null) {
        params['location'] =
            '${biasLocation.latitude},${biasLocation.longitude}';
        params['radius'] = '50000';
      }

      final uri = Uri.parse(
        '$_placesBaseUrl/autocomplete/json',
      ).replace(queryParameters: params);

      final response = await http.get(uri);
      if (response.statusCode != 200) return [];

      final data = json.decode(response.body) as Map<String, dynamic>;
      final predictions = data['predictions'] as List<dynamic>? ?? [];

      return predictions
          .map(
            (p) => PlaceAutocompleteResult.fromJson(p as Map<String, dynamic>),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ==================== Recent Dropoffs ====================

  static const String _recentDropoffsKey = 'recent_dropoffs';
  static const int _maxRecentDropoffs = 5;

  /// Save a dropoff location to recent dropoffs in SharedPreferences.
  ///
  /// Keeps at most [_maxRecentDropoffs] items, newest first.
  /// Deduplicates by comparing lat/lng within ~50m threshold.
  static Future<void> saveRecentDropoff(PlaceModel place) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = await getRecentDropoffs();

      // Remove duplicate if exists (within ~50m)
      existing.removeWhere(
        (p) =>
            (p.lat - place.lat).abs() < 0.0005 &&
            (p.lng - place.lng).abs() < 0.0005,
      );

      // Insert at front
      existing.insert(0, place);

      // Trim to max
      if (existing.length > _maxRecentDropoffs) {
        existing.removeRange(_maxRecentDropoffs, existing.length);
      }

      final jsonList = existing.map((p) => json.encode(p.toMap())).toList();
      await prefs.setStringList(_recentDropoffsKey, jsonList);
    } catch (_) {
      // Non-critical — silently fail
    }
  }

  /// Retrieve recent dropoff locations from SharedPreferences.
  static Future<List<PlaceModel>> getRecentDropoffs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_recentDropoffsKey);
      if (jsonList == null || jsonList.isEmpty) return [];

      return jsonList
          .map(
            (s) => PlaceModel.fromMap(json.decode(s) as Map<String, dynamic>),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ==================== Place Details ====================

  /// Fetch full place details (lat/lng, name, address) for a [placeId].
  ///
  /// Returns `null` if the API call fails or the place is not found.
  static Future<PlaceModel?> getPlaceDetails(String placeId) async {
    try {
      final locale = Get.locale?.languageCode ?? 'ar';
      final uri = Uri.parse('$_placesBaseUrl/details/json').replace(
        queryParameters: {
          'place_id': placeId,
          'fields': 'geometry,formatted_address,name',
          'language': locale,
          'key': _apiKey,
        },
      );

      final response = await http.get(uri);
      if (response.statusCode != 200) return null;

      final data = json.decode(response.body) as Map<String, dynamic>;
      final result = data['result'] as Map<String, dynamic>?;
      if (result == null) return null;

      return PlaceModel.fromGooglePlaces(result);
    } catch (_) {
      return null;
    }
  }
}
