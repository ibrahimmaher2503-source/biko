import 'dart:async';

import 'package:biko/core/routes/app_routes.dart';
import 'package:biko/core/services/auth_service.dart';
import 'package:biko/core/services/firestore_service.dart';
import 'package:biko/core/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Controller for the driver bid submission screen.
///
/// Allows driver to submit a counter-bid for a trip request.
/// Listens for bid acceptance/rejection from the customer.
class BidController extends GetxController {
  /// Price input controller
  final priceController = TextEditingController();

  /// Loading state
  final isSubmitting = false.obs;

  /// Waiting for customer response
  final isWaiting = false.obs;

  /// Price validation error
  final priceError = ''.obs;

  /// Trip details from arguments
  late final String tripId;
  late final double customerPrice;
  late final String pickupAddress;
  late final String dropoffAddress;
  late final double distanceKm;
  late final int durationMinutes;

  /// Suggested price (calculated from app_config)
  final suggestedPrice = 0.0.obs;

  /// Floor price from app_config
  final floorPrice = 0.0.obs;

  String? _bidId;
  StreamSubscription<Map<String, dynamic>>? _bidStatusSubscription;

  @override
  void onInit() {
    super.onInit();
    _parseArguments();
    _loadConfig();
  }

  @override
  void onClose() {
    priceController.dispose();
    _bidStatusSubscription?.cancel();
    super.onClose();
  }

  /// Submit the driver's bid.
  Future<void> submitBid() async {
    final price = double.tryParse(priceController.text) ?? 0;

    // Validate floor price
    if (price < floorPrice.value) {
      priceError.value = 'driver_trips.below_floor_price'.tr;
      return;
    }
    priceError.value = '';

    try {
      isSubmitting.value = true;
      final uid = AuthService.currentUser?.uid;
      if (uid == null) return;

      final user = await FirestoreService.getUser(uid);

      _bidId = await FirestoreService.submitDriverBid(tripId, {
        'driver_uid': uid,
        'driver_name': user?.name ?? '',
        'driver_rating': 0, // Will be populated from driver_profiles
        'vehicle_type': 'motorcycle',
        'amount': price,
        'status': 'pending',
      });

      isSubmitting.value = false;
      isWaiting.value = true;

      // Listen for customer response
      _listenToBidStatus();
    } catch (e) {
      debugPrint('❌ BidController.submitBid failed: $e');
      isSubmitting.value = false;
      AppSnackbar.error('driver_trips.bid_failed'.tr);
    }
  }

  /// Cancel the pending bid and go back.
  Future<void> cancelBid() async {
    _bidStatusSubscription?.cancel();
    isWaiting.value = false;

    if (_bidId != null) {
      try {
        await FirestoreService.rejectBid(tripId, _bidId!);
      } catch (e) {
        debugPrint('⚠️ BidController.cancelBid failed: $e');
      }
    }

    Get.back<void>();
  }

  // ==================== Private Methods ====================

  void _parseArguments() {
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    tripId = args['tripId'] as String? ?? '';
    customerPrice = (args['customerPrice'] as num?)?.toDouble() ?? 0.0;
    pickupAddress = args['pickupAddress'] as String? ?? '';
    dropoffAddress = args['dropoffAddress'] as String? ?? '';
    distanceKm = (args['distanceKm'] as num?)?.toDouble() ?? 0.0;
    durationMinutes = (args['durationMinutes'] as num?)?.toInt() ?? 0;
  }

  Future<void> _loadConfig() async {
    try {
      final config = await FirestoreService.getAppConfig();
      if (config != null) {
        final baseFare = (config['base_fare'] as num?)?.toDouble() ?? 10.0;
        final pricePerKm = (config['price_per_km'] as num?)?.toDouble() ?? 3.0;
        final pricePerMin =
            (config['price_per_min'] as num?)?.toDouble() ?? 0.5;
        floorPrice.value = (config['floor_price'] as num?)?.toDouble() ?? 10.0;

        // Calculate suggested price
        final calculated =
            baseFare +
            (pricePerKm * distanceKm) +
            (pricePerMin * durationMinutes);
        suggestedPrice.value = calculated;
        priceController.text = calculated.toStringAsFixed(0);
      }
    } catch (e) {
      debugPrint('⚠️ BidController._loadConfig failed: $e');
      // Use customer price as fallback
      priceController.text = customerPrice.toStringAsFixed(0);
    }
  }

  void _listenToBidStatus() {
    if (_bidId == null) return;

    _bidStatusSubscription = FirestoreService.listenToBidStatus(tripId, _bidId!)
        .listen(
          (data) {
            final status = data['status'] as String? ?? '';

            if (status == 'accepted') {
              _bidStatusSubscription?.cancel();
              isWaiting.value = false;
              AppSnackbar.success('driver_trips.bid_accepted'.tr);
              Get.offNamed(
                AppRoutes.navigateToPickup,
                arguments: {'tripId': tripId},
              );
            } else if (status == 'rejected') {
              _bidStatusSubscription?.cancel();
              isWaiting.value = false;
              AppSnackbar.warning('driver_trips.bid_rejected'.tr);
              Get.back<void>();
            }
          },
          onError: (e) {
            debugPrint('⚠️ BidController bid status stream error: $e');
          },
        );
  }
}
