import 'package:biko/core/models/directions_result.dart';
import 'package:biko/core/models/enums.dart';
import 'package:biko/core/models/place_model.dart';
import 'package:biko/core/models/trip_model.dart';
import 'package:biko/core/routes/app_routes.dart';
import 'package:biko/core/services/firestore_service.dart';
import 'package:biko/core/services/map_service.dart';
import 'package:biko/core/widgets/app_snackbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

/// Controller for the Price Negotiation (bidding) screen.
///
/// Manages route fetching, fare calculation, offer adjustment,
/// payment/passenger selection, notes, and trip submission.
class BiddingController extends GetxController {
  // ==================== Observables ====================

  /// Pickup location from navigation arguments
  final pickup = Rxn<PlaceModel>();

  /// Dropoff location from navigation arguments
  final dropoff = Rxn<PlaceModel>();

  /// Route directions result (polyline, distance, duration)
  final directionsResult = Rxn<DirectionsResult>();

  /// System-calculated suggested fare (EGP)
  final suggestedPrice = 0.obs;

  /// Customer's current offer amount (EGP)
  final offerAmount = 0.obs;

  /// Minimum allowed offer (= suggested price)
  final minOffer = 0.obs;

  /// Selected payment method
  final paymentMethod = PaymentMethod.cash.obs;

  /// Number of passengers
  final passengerCount = 1.obs;

  /// Optional note for the driver
  final tripNote = ''.obs;

  /// Whether route is being fetched
  final isLoadingRoute = true.obs;

  /// Whether trip creation is in progress
  final isSubmitting = false.obs;

  // ==================== Pricing config ====================

  double _baseFare = 10.0;
  double _pricePerKm = 3.0;
  double _pricePerMin = 0.5;

  // ==================== Lifecycle ====================

  @override
  void onInit() {
    super.onInit();
    _extractArguments();
    _loadRouteAndPricing();
  }

  // ==================== Initialization ====================

  /// Extract pickup and dropoff PlaceModel from route arguments.
  void _extractArguments() {
    final args = Get.arguments;
    if (args is Map<String, dynamic>) {
      pickup.value = args['pickup'] as PlaceModel?;
      dropoff.value = args['dropoff'] as PlaceModel?;
    }
  }

  /// Fetch app_config pricing and route directions in parallel.
  Future<void> _loadRouteAndPricing() async {
    if (pickup.value == null || dropoff.value == null) {
      isLoadingRoute.value = false;
      return;
    }

    isLoadingRoute.value = true;

    try {
      // Fetch pricing config and directions in parallel
      final results = await Future.wait([
        FirestoreService.getAppConfig(),
        MapService.getDirections(pickup.value!.latLng, dropoff.value!.latLng),
      ]);

      // Apply pricing config
      final config = results[0] as Map<String, dynamic>?;
      if (config != null) {
        _baseFare = (config['base_fare'] as num?)?.toDouble() ?? _baseFare;
        _pricePerKm =
            (config['price_per_km'] as num?)?.toDouble() ?? _pricePerKm;
        _pricePerMin =
            (config['price_per_min'] as num?)?.toDouble() ?? _pricePerMin;
      }

      // Apply directions
      final directions = results[1] as DirectionsResult;
      directionsResult.value = directions;

      // Calculate suggested price
      _calculateSuggestedPrice(directions);
    } catch (_) {
      // If directions fail entirely, try fallback
      try {
        final directions = await MapService.getDirections(
          pickup.value!.latLng,
          dropoff.value!.latLng,
        );
        directionsResult.value = directions;
        _calculateSuggestedPrice(directions);
      } catch (_) {
        AppSnackbar.error('trip.create_failed'.tr);
      }
    } finally {
      isLoadingRoute.value = false;
    }
  }

  /// Calculate the system-suggested fare from route data.
  void _calculateSuggestedPrice(DirectionsResult directions) {
    final rawPrice =
        _baseFare +
        (_pricePerKm * directions.distanceKm) +
        (_pricePerMin * directions.durationMins);

    // Round up to nearest 5
    final rounded = (rawPrice / 5).ceil() * 5;
    suggestedPrice.value = rounded;
    minOffer.value = rounded;
    offerAmount.value = rounded;
  }

  // ==================== Offer Adjustment ====================

  /// Increase offer by 5 EGP (max 999).
  void incrementOffer() {
    if (offerAmount.value < 999) {
      offerAmount.value += 5;
    }
  }

  /// Decrease offer by 5 EGP (min = suggested price).
  void decrementOffer() {
    if (offerAmount.value > minOffer.value) {
      offerAmount.value -= 5;
    }
  }

  // ==================== Payment & Passengers ====================

  /// Set the payment method.
  void setPaymentMethod(PaymentMethod method) {
    paymentMethod.value = method;
  }

  /// Set the passenger count.
  void setPassengerCount(int count) {
    passengerCount.value = count;
  }

  // ==================== Trip Note ====================

  /// Set the trip note.
  void setNote(String note) {
    tripNote.value = note.trim();
  }

  // ==================== Submit Trip ====================

  /// Create a trip document in Firestore and navigate to bids screen.
  Future<void> submitTrip() async {
    if (pickup.value == null || dropoff.value == null) return;

    // Same-location guard
    if (_isSameLocation(pickup.value!, dropoff.value!)) {
      AppSnackbar.error('trip.same_location_error'.tr);
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    isSubmitting.value = true;

    try {
      final trip = TripModel(
        id: '', // Auto-generated by Firestore
        customerUid: uid,
        type: TripType.ride,
        status: TripStatus.searching,
        pickup: pickup.value!,
        dropoff: dropoff.value!,
        customerPrice: offerAmount.value.toDouble(),
        paymentMethod: paymentMethod.value,
        distanceKm: directionsResult.value?.distanceKm,
        durationMinutes: directionsResult.value?.durationMins.toInt(),
        createdAt: DateTime.now(),
      );

      final tripId = await FirestoreService.createTrip(trip);

      Get.toNamed(
        AppRoutes.viewBids,
        arguments: {
          'trip_id': tripId,
          'offered_price': offerAmount.value.toDouble(),
          'pickup_address': pickup.value?.address ?? '',
          'dropoff_address': dropoff.value?.address ?? '',
        },
      );
    } catch (_) {
      AppSnackbar.error('trip.create_failed'.tr);
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Check if pickup and dropoff are essentially the same location.
  bool _isSameLocation(PlaceModel a, PlaceModel b) {
    const threshold = 0.0005; // ~50 meters
    return (a.lat - b.lat).abs() < threshold &&
        (a.lng - b.lng).abs() < threshold;
  }
}
