import 'dart:async';

import 'package:biko/core/models/place_model.dart';
import 'package:biko/core/routes/app_routes.dart';
import 'package:biko/core/services/map_service.dart';
import 'package:biko/core/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Controller for the Set Dropoff Location screen.
///
/// Manages map camera, address search (Places API), reverse-geocoding,
/// recent dropoffs, and navigation to price negotiation.
class DropoffController extends GetxController {
  // ==================== Observables ====================

  /// Currently selected dropoff location
  final selectedDropoff = Rxn<PlaceModel>();

  /// Search input text
  final searchQuery = ''.obs;

  /// Autocomplete results from Places API
  final searchResults = <PlaceAutocompleteResult>[].obs;

  /// Recent dropoff locations
  final recentDropoffs = <PlaceModel>[].obs;

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

  /// GPS position for search bias
  final currentPosition = Rxn<LatLng>();

  /// Whether GPS accuracy is poor (>50m)
  final isPoorGpsAccuracy = false.obs;

  // ==================== Pickup reference ====================

  /// Pickup location passed via route arguments
  PlaceModel? pickupPlace;

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

  // ==================== Lifecycle ====================

  @override
  void onInit() {
    super.onInit();
    _extractArguments();
    _loadRecentDropoffs();
    _detectCurrentPosition();
  }

  @override
  void onClose() {
    _debounceTimer?.cancel();
    searchTextController.dispose();
    searchFocusNode.dispose();
    super.onClose();
  }

  // ==================== Initialization ====================

  /// Extract pickup and optional intended dropoff from route arguments.
  void _extractArguments() {
    final args = Get.arguments;
    if (args is Map<String, dynamic>) {
      pickupPlace = args['pickup'] as PlaceModel?;

      // Pre-fill dropoff if intended dropoff was forwarded (e.g. recent location)
      if (args.containsKey('intended_dropoff_lat')) {
        final place = PlaceModel(
          name: (args['intended_dropoff_name'] as String?) ?? '',
          address: (args['intended_dropoff_address'] as String?) ?? '',
          lat: (args['intended_dropoff_lat'] as num).toDouble(),
          lng: (args['intended_dropoff_lng'] as num).toDouble(),
        );
        selectedDropoff.value = place;
        mapCenter.value = place.latLng;
        _animateCameraTo(place.latLng);
      }
    }
  }

  /// Load recent dropoffs from SharedPreferences.
  Future<void> _loadRecentDropoffs() async {
    final recents = await MapService.getRecentDropoffs();
    recentDropoffs.assignAll(recents);
  }

  /// Detect current GPS position for search bias.
  Future<void> _detectCurrentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
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
    } catch (_) {
      // Non-critical — keep default Cairo position
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

  /// Reverse-geocode a position and set [selectedDropoff].
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
        selectedDropoff.value = result;
      } else {
        selectedDropoff.value = PlaceModel(
          name: 'dropoff.selected_location'.tr,
          address:
              '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}',
          lat: position.latitude,
          lng: position.longitude,
        );
      }
    } catch (_) {
      selectedDropoff.value = PlaceModel(
        name: 'dropoff.selected_location'.tr,
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
      AppSnackbar.error('dropoff.could_not_search'.tr);
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
        selectedDropoff.value = place;
        mapCenter.value = place.latLng;
        _animateCameraTo(place.latLng);
      }
    } catch (_) {
      AppSnackbar.error('dropoff.could_not_search'.tr);
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

  // ==================== Dropoff Selection ====================

  /// Select a dropoff from recent/saved locations.
  void selectDropoff(PlaceModel place) {
    selectedDropoff.value = place;
    mapCenter.value = place.latLng;
    _animateCameraTo(place.latLng);
    deactivateSearch();
  }

  /// Confirm the selected dropoff and navigate to price negotiation.
  void confirmDropoff() {
    if (selectedDropoff.value == null) {
      AppSnackbar.error('dropoff.select_prompt'.tr);
      return;
    }

    // Save to recent dropoffs
    MapService.saveRecentDropoff(selectedDropoff.value!);

    Get.toNamed(
      AppRoutes.createTrip,
      arguments: {'pickup': pickupPlace, 'dropoff': selectedDropoff.value},
    );
  }

  /// Re-center map on current GPS position.
  Future<void> goToMyLocation() async {
    if (currentPosition.value != null) {
      _animateCameraTo(currentPosition.value!);
    } else {
      await _detectCurrentPosition();
    }
  }

  // ==================== Camera Helpers ====================

  /// Animate the Google Map camera to [target].
  ///
  /// Times out after 5 seconds if the map controller never initializes.
  Future<void> _animateCameraTo(LatLng target) async {
    try {
      final controller = await mapControllerCompleter.future
          .timeout(const Duration(seconds: 5));
      await controller.animateCamera(CameraUpdate.newLatLngZoom(target, 16));
    } catch (_) {
      // Map not ready or timed out — will center via initialCameraPosition
    }
  }
}
