import 'dart:async';

import 'package:biko/core/models/place_model.dart';
import 'package:biko/core/routes/app_routes.dart';
import 'package:biko/core/services/map_service.dart';
import 'package:biko/core/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controller for the Set Pickup Location screen.
///
/// Manages map camera, GPS detection, address search (Places API),
/// reverse-geocoding, and navigation to the dropoff screen.
class PickupController extends GetxController {
  // ==================== Observables ====================

  /// Currently selected pickup location
  final selectedPlace = Rxn<PlaceModel>();

  /// Search input text
  final searchQuery = ''.obs;

  /// Autocomplete results from Places API
  final searchResults = <PlaceAutocompleteResult>[].obs;

  /// Whether an autocomplete API call is in flight
  final isSearching = false.obs;

  /// Whether a reverse-geocode is in progress
  final isGeocoding = false.obs;

  /// Whether the GoogleMap controller is initialized
  final isMapReady = false.obs;

  /// Whether the search overlay is visible
  final isSearchActive = false.obs;

  /// Current map camera center (default: Cairo)
  final mapCenter = const LatLng(30.0444, 31.2357).obs;

  /// GPS position (null if unavailable)
  final currentPosition = Rxn<LatLng>();

  /// Whether GPS accuracy is poor (>50m)
  final isPoorGpsAccuracy = false.obs;

  // ==================== Controllers ====================

  /// Completer for GoogleMap controller
  final Completer<GoogleMapController> mapControllerCompleter = Completer();

  /// Text editing controller for search field
  final searchTextController = TextEditingController();

  /// Focus node for search field
  final searchFocusNode = FocusNode();

  /// Debounce timer for search input
  Timer? _debounceTimer;

  /// Counter to skip stale reverse-geocode results
  int _geocodeRequestId = 0;

  // ==================== Cached location keys ====================

  static const String _cachedLatKey = 'last_pickup_lat';
  static const String _cachedLngKey = 'last_pickup_lng';

  // ==================== Lifecycle ====================

  @override
  void onInit() {
    super.onInit();
    _handleRouteArguments();
  }

  @override
  void onClose() {
    _debounceTimer?.cancel();
    searchTextController.dispose();
    searchFocusNode.dispose();
    super.onClose();
  }

  // ==================== Initialization ====================

  /// Intended dropoff forwarded from home (e.g. recent location tap).
  /// Passed through to DropoffController when confirming pickup.
  Map<String, dynamic>? _intendedDropoff;

  /// Check if route arguments contain a pre-filled location.
  /// If so, use it; otherwise, detect GPS.
  void _handleRouteArguments() {
    final args = Get.arguments;
    if (args is Map<String, dynamic>) {
      // Store intended dropoff for forwarding
      if (args.containsKey('intended_dropoff_lat')) {
        _intendedDropoff = {
          'intended_dropoff_name': args['intended_dropoff_name'],
          'intended_dropoff_address': args['intended_dropoff_address'],
          'intended_dropoff_lat': args['intended_dropoff_lat'],
          'intended_dropoff_lng': args['intended_dropoff_lng'],
        };
      }

      // Pre-fill pickup if coordinates provided
      if (args.containsKey('pickup_lat') && args.containsKey('pickup_lng')) {
        final place = PlaceModel(
          name: (args['pickup_name'] as String?) ?? '',
          address: (args['pickup_address'] as String?) ?? '',
          lat: (args['pickup_lat'] as num).toDouble(),
          lng: (args['pickup_lng'] as num).toDouble(),
        );
        selectedPlace.value = place;
        mapCenter.value = place.latLng;
        _animateCameraTo(place.latLng);
        return;
      }
    }
    _detectGpsLocation();
  }

  /// Detect GPS position, request permission, reverse-geocode.
  Future<void> _detectGpsLocation() async {
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _handleGpsUnavailable();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          _handleGpsUnavailable();
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _handleGpsUnavailable();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final latLng = LatLng(position.latitude, position.longitude);
      currentPosition.value = latLng;
      mapCenter.value = latLng;
      _animateCameraTo(latLng);

      // Check GPS accuracy
      if (position.accuracy > 50) {
        isPoorGpsAccuracy.value = true;
      }

      // Reverse-geocode to get address
      await _reverseGeocodePosition(latLng);

      // Cache for fallback
      _cacheLastLocation(latLng);
    } catch (_) {
      _handleGpsUnavailable();
    }
  }

  /// Handle GPS unavailable: try cached location, then Cairo default.
  Future<void> _handleGpsUnavailable() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedLat = prefs.getDouble(_cachedLatKey);
      final cachedLng = prefs.getDouble(_cachedLngKey);

      if (cachedLat != null && cachedLng != null) {
        final latLng = LatLng(cachedLat, cachedLng);
        mapCenter.value = latLng;
        _animateCameraTo(latLng);
        return;
      }
    } catch (_) {
      // Fall through to default
    }

    // Cairo default — no selected place, prompt manual search
    mapCenter.value = const LatLng(30.0444, 31.2357);
    _animateCameraTo(mapCenter.value);
  }

  /// Cache last known location for fallback.
  Future<void> _cacheLastLocation(LatLng latLng) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_cachedLatKey, latLng.latitude);
      await prefs.setDouble(_cachedLngKey, latLng.longitude);
    } catch (_) {
      // Non-critical
    }
  }

  // ==================== Map Callbacks ====================

  /// Called when the GoogleMap is created.
  void onMapCreated(GoogleMapController controller) {
    if (!mapControllerCompleter.isCompleted) {
      mapControllerCompleter.complete(controller);
    }
    isMapReady.value = true;
  }

  /// Called on every camera move frame.
  void onCameraMove(CameraPosition position) {
    mapCenter.value = position.target;
    isGeocoding.value = true;
  }

  /// Called when camera movement settles.
  void onCameraIdle() {
    final requestId = ++_geocodeRequestId;
    _reverseGeocodePosition(mapCenter.value, requestId: requestId);
  }

  // ==================== Reverse Geocoding ====================

  /// Reverse-geocode a position and set [selectedPlace].
  Future<void> _reverseGeocodePosition(
    LatLng position, {
    int? requestId,
  }) async {
    isGeocoding.value = true;
    try {
      final result = await MapService.reverseGeocode(
        position.latitude,
        position.longitude,
      );

      // Skip if a newer request has been issued
      if (requestId != null && requestId != _geocodeRequestId) return;

      if (result != null) {
        selectedPlace.value = result;
      } else {
        // Fallback with coordinates
        selectedPlace.value = PlaceModel(
          name: 'pickup.selected_location'.tr,
          address:
              '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}',
          lat: position.latitude,
          lng: position.longitude,
        );
      }
    } catch (_) {
      selectedPlace.value = PlaceModel(
        name: 'pickup.selected_location'.tr,
        address:
            '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}',
        lat: position.latitude,
        lng: position.longitude,
      );
    } finally {
      if (requestId == null || requestId == _geocodeRequestId) {
        isGeocoding.value = false;
      }
    }
  }

  // ==================== Search ====================

  /// Called when search text changes. Debounces by 300ms.
  void onSearchChanged(String query) {
    searchQuery.value = query;
    _debounceTimer?.cancel();

    if (query.length < 2) {
      searchResults.clear();
      isSearching.value = false;
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _searchPlaces(query);
    });
  }

  /// Perform Places Autocomplete search.
  Future<void> _searchPlaces(String query) async {
    isSearching.value = true;
    try {
      final results = await MapService.searchPlaces(
        query,
        biasLocation: currentPosition.value,
      );
      searchResults.assignAll(results);
    } catch (_) {
      searchResults.clear();
      AppSnackbar.error('pickup.could_not_search'.tr);
    } finally {
      isSearching.value = false;
    }
  }

  /// Called when user taps an autocomplete result.
  Future<void> onResultTap(PlaceAutocompleteResult result) async {
    isGeocoding.value = true;
    try {
      final place = await MapService.getPlaceDetails(result.placeId);
      if (place != null) {
        selectedPlace.value = place;
        mapCenter.value = place.latLng;
        _animateCameraTo(place.latLng);
      }
    } catch (_) {
      AppSnackbar.error('pickup.could_not_search'.tr);
    } finally {
      isGeocoding.value = false;
      deactivateSearch();
    }
  }

  /// Activate search overlay.
  void activateSearch() {
    isSearchActive.value = true;
    searchFocusNode.requestFocus();
  }

  /// Deactivate search overlay and clear state.
  void deactivateSearch() {
    isSearchActive.value = false;
    searchQuery.value = '';
    searchResults.clear();
    searchTextController.clear();
    searchFocusNode.unfocus();
  }

  // ==================== Saved / Recent Locations ====================

  /// Called when user taps a saved or recent location.
  void onSavedLocationTap({
    required String name,
    required String address,
    required double lat,
    required double lng,
  }) {
    final place = PlaceModel(name: name, address: address, lat: lat, lng: lng);
    selectedPlace.value = place;
    mapCenter.value = place.latLng;
    _animateCameraTo(place.latLng);
    deactivateSearch();
  }

  // ==================== Navigation ====================

  /// Confirm the selected pickup and navigate to the dropoff screen.
  void confirmPickup() {
    if (selectedPlace.value == null) {
      AppSnackbar.error('pickup.select_prompt'.tr);
      return;
    }

    // Cache this location for future fallback
    _cacheLastLocation(selectedPlace.value!.latLng);

    final dropoffArgs = <String, dynamic>{
      'pickup': selectedPlace.value,
    };

    // Forward intended dropoff if present (from recent location tap)
    if (_intendedDropoff != null) {
      dropoffArgs.addAll(_intendedDropoff!);
    }

    Get.toNamed(AppRoutes.setDropoff, arguments: dropoffArgs);
  }

  /// Re-center map on current GPS position.
  Future<void> goToMyLocation() async {
    if (currentPosition.value != null) {
      _animateCameraTo(currentPosition.value!);
    } else {
      await _detectGpsLocation();
    }
  }

  // ==================== Camera Helpers ====================

  /// Animate the Google Map camera to [target].
  Future<void> _animateCameraTo(LatLng target) async {
    try {
      final controller = await mapControllerCompleter.future;
      await controller.animateCamera(CameraUpdate.newLatLngZoom(target, 16));
    } catch (_) {
      // Map not ready yet — will center via initialCameraPosition
    }
  }
}
