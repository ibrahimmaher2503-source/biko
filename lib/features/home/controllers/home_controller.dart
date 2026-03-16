import 'dart:async';
import 'dart:ui';

import 'package:biko/core/routes/app_routes.dart';
import 'package:biko/core/services/auth_service.dart';
import 'package:biko/core/services/firestore_service.dart';
import 'package:biko/core/services/location_service.dart';
import 'package:biko/core/widgets/app_snackbar.dart';
import 'package:biko/features/home/models/recent_location.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeController extends GetxController {
  // User data
  final userName = ''.obs;
  final avatarUrl = Rxn<String>();

  // Wallet
  final walletBalance = 0.0.obs;
  final walletLoaded = false.obs;

  // Location
  final locationName = ''.obs;
  final locationLoaded = false.obs;

  // Recent locations
  final recentLocations = <RecentLocation>[].obs;

  // Bottom navigation
  final currentTabIndex = 0.obs;

  // Loading
  final isLoading = true.obs;

  // Nearby driver markers on map
  final driverMarkers = RxSet<Marker>();

  // Internal subscriptions
  StreamSubscription<dynamic>? _driversSub;
  StreamSubscription<dynamic>? _walletSub;

  @override
  void onInit() {
    super.onInit();
    _loadUserData();
    _loadLocation();
    _loadRecentLocations();
  }

  @override
  void onClose() {
    _driversSub?.cancel();
    _walletSub?.cancel();
    super.onClose();
  }

  // ==================== Data Loading ====================

  Future<void> _loadUserData() async {
    final uid = AuthService.currentUid;
    if (uid == null) {
      isLoading.value = false;
      return;
    }

    try {
      final userModel = await FirestoreService.getUser(uid);
      if (userModel != null) {
        userName.value = userModel.name;
        avatarUrl.value = userModel.avatarUrl;
      }
      // Keep wallet balance up-to-date via a real-time stream
      _listenToWalletBalance(uid);
    } catch (e) {
      debugPrint('[HomeController] Failed to load user data: $e');
      walletLoaded.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  void _listenToWalletBalance(String uid) {
    _walletSub?.cancel();
    _walletSub = FirestoreService.listenToWallet(uid).listen(
      (walletModel) {
        walletBalance.value = walletModel?.balance ?? 0.0;
        walletLoaded.value = true;
      },
      onError: (Object e) =>
          debugPrint('[HomeController] wallet stream error: $e'),
    );
  }

  Future<void> _loadLocation() async {
    try {
      // Try cached location first for fast display
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('last_location_name');
      if (cached != null && cached.isNotEmpty) {
        locationName.value = cached;
        locationLoaded.value = true;
      }

      // Use global LocationService for permission and position
      final locationService = Get.find<LocationService>();
      final hasPermission =
          await locationService.checkAndRequestPermission();
      if (!hasPermission) {
        if (!locationLoaded.value) {
          locationLoaded.value = false;
        }
        return;
      }

      // Get position via LocationService
      final position = await locationService.getCurrentPosition();
      if (position == null) {
        if (!locationLoaded.value) {
          locationLoaded.value = false;
        }
        return;
      }

      // Subscribe to nearby drivers around current position
      _subscribeToNearbyDrivers(LatLng(position.latitude, position.longitude));

      // Reverse geocode
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final city = place.locality ?? place.subAdministrativeArea ?? '';
        final area = place.administrativeArea ?? '';
        final name = city.isNotEmpty && area.isNotEmpty
            ? '$city, $area'
            : city + area;

        if (name.isNotEmpty) {
          locationName.value = name;
          locationLoaded.value = true;
          // Cache for offline use
          await prefs.setString('last_location_name', name);
        }
      }
    } catch (e) {
      debugPrint('[HomeController] Failed to load location: $e');
      // Keep cached value if available
      if (locationName.value.isEmpty) {
        locationLoaded.value = false;
      }
    }
  }

  Future<void> _loadRecentLocations() async {
    final uid = AuthService.currentUid;
    if (uid == null) return;

    try {
      final result = await FirestoreService.getTripHistoryPaginated(uid);
      final seen = <String>{};
      final locations = <RecentLocation>[];

      for (final trip in result.items) {
        final key = '${trip.dropoff.lat},${trip.dropoff.lng}';
        if (!seen.contains(key)) {
          seen.add(key);
          locations.add(
            RecentLocation(
              name: trip.dropoff.name,
              address: trip.dropoff.address,
              lat: trip.dropoff.lat,
              lng: trip.dropoff.lng,
            ),
          );
          if (locations.length >= 5) break;
        }
      }
      recentLocations.value = locations;
    } catch (e) {
      debugPrint('[HomeController] Failed to load recent locations: $e');
      // Failure is silent — section is simply hidden when list is empty
    }
  }

  // ==================== Nearby Drivers ====================

  /// Subscribe to nearby driver locations and convert to map markers.
  void _subscribeToNearbyDrivers(LatLng center) {
    _driversSub?.cancel();
    _driversSub = FirestoreService.getNearbyDrivers(center).listen(
      (drivers) {
        final markers = <Marker>{};
        for (final driver in drivers) {
          markers.add(
            Marker(
              markerId: MarkerId('driver_${driver.uid}'),
              position: LatLng(driver.lat, driver.lng),
              rotation: driver.heading,
              anchor: const Offset(0.5, 0.5),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueOrange,
              ),
            ),
          );
        }
        driverMarkers
          ..clear()
          ..addAll(markers);
      },
      onError: (e) {
        debugPrint('[HomeController] Nearby drivers error: $e');
      },
    );
  }

  // ==================== Bottom Navigation ====================

  void changeTab(int index) {
    // Index 2 is the center button — not a tab
    if (index == 2) return;
    currentTabIndex.value = index;
  }

  // ==================== Navigation Methods ====================

  void navigateToRideBooking() {
    Get.toNamed(AppRoutes.setPickup);
  }

  void navigateToDeliveryBooking() {
    Get.toNamed(AppRoutes.setPickup, arguments: {'type': 'delivery'});
  }

  void navigateToWallet() {
    Get.toNamed(AppRoutes.customerWallet);
  }

  void navigateToSearch() {
    Get.toNamed(AppRoutes.setPickup);
  }

  void navigateToLocationHistory() {
    Get.toNamed(AppRoutes.tripHistory);
  }

  /// When user taps a recent location, go to pickup screen with the
  /// recent location pre-filled as the intended dropoff. After pickup
  /// is confirmed, PickupController forwards to dropoff (pre-filled),
  /// then to price negotiation.
  void onRecentLocationTap(RecentLocation location) {
    Get.toNamed(
      AppRoutes.setPickup,
      arguments: {
        'intended_dropoff_name': location.name,
        'intended_dropoff_address': location.address,
        'intended_dropoff_lat': location.lat,
        'intended_dropoff_lng': location.lng,
      },
    );
  }

  void onMerchantTap() {
    AppSnackbar.info('home.coming_soon'.tr);
  }
}
