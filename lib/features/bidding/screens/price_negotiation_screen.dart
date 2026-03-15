import 'package:biko/core/models/directions_result.dart';
import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_button.dart';
import 'package:biko/core/widgets/app_loading.dart';
import 'package:biko/features/bidding/controllers/bidding_controller.dart';
import 'package:biko/features/bidding/widgets/fare_badge.dart';
import 'package:biko/features/bidding/widgets/offer_adjuster.dart';
import 'package:biko/features/bidding/widgets/route_address_bar.dart';
import 'package:biko/features/bidding/widgets/trip_options_chips.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Price Negotiation screen where the customer sees the route on a map,
/// the system-suggested fare, and can adjust their offer before
/// submitting a ride request.
///
/// Layout: full-screen Google Map (top) + DraggableScrollableSheet (bottom).
class PriceNegotiationScreen extends GetView<BiddingController> {
  const PriceNegotiationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Google Map
          Obx(_buildMap),

          // Back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: const _BackButton(),
          ),

          // Bottom sheet
          _buildBottomSheet(context),
        ],
      ),
    );
  }

  /// Build the Google Map with route polyline and markers.
  Widget _buildMap() {
    final directions = controller.directionsResult.value;
    final pickup = controller.pickup.value;
    final dropoff = controller.dropoff.value;

    // Default camera: Cairo
    CameraPosition initialCamera = const CameraPosition(
      target: LatLng(30.0444, 31.2357),
      zoom: 12,
    );

    if (pickup != null) {
      initialCamera = CameraPosition(target: pickup.latLng, zoom: 14);
    }

    // Markers
    final markers = <Marker>{};
    if (pickup != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: pickup.latLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }
    if (dropoff != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('dropoff'),
          position: dropoff.latLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }

    // Polyline
    final polylines = <Polyline>{};
    if (directions != null && directions.polylinePoints.length > 1) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: directions.polylinePoints,
          color: AppTheme.primary,
          width: 5,
        ),
      );
    }

    return GoogleMap(
      initialCameraPosition: initialCamera,
      markers: markers,
      polylines: polylines,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      onMapCreated: (mapController) {
        _fitRouteBounds(mapController, directions);
      },
    );
  }

  /// Fit the camera to show the full route.
  void _fitRouteBounds(
    GoogleMapController mapController,
    DirectionsResult? directions,
  ) {
    if (directions == null) return;

    final bounds = LatLngBounds(
      southwest: directions.boundsSW,
      northeast: directions.boundsNE,
    );

    // Delay to ensure map is rendered
    Future.delayed(const Duration(milliseconds: 300), () {
      mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
    });
  }

  /// Build the bottom DraggableScrollableSheet.
  Widget _buildBottomSheet(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.45,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Obx(() {
            if (controller.isLoadingRoute.value) {
              return _buildLoadingState();
            }
            return _buildSheetContent(context, scrollController);
          }),
        );
      },
    );
  }

  /// Loading state while route is being fetched.
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppLoading(),
          const SizedBox(height: 16),
          Text(
            'trip.loading_route'.tr,
            style: Get.textTheme.bodyMedium?.copyWith(
              color: Get.theme.extension<AppColorsExtension>()!.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  /// Main sheet content with all bidding widgets.
  Widget _buildSheetContent(
    BuildContext context,
    ScrollController scrollController,
  ) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;

    return ListView(
      controller: scrollController,
      padding: EdgeInsets.zero,
      children: [
        // Drag handle
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),

        // Route addresses
        RouteAddressBar(
          pickupAddress: controller.pickup.value?.address ?? '',
          dropoffAddress: controller.dropoff.value?.address ?? '',
        ),

        const SizedBox(height: 8),

        // Fair price badge
        Obx(() => FareBadge(price: controller.suggestedPrice.value)),

        const SizedBox(height: 16),

        // YOUR OFFER label
        Center(
          child: Text(
            'trip.your_offer'.tr.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.textMuted,
              letterSpacing: 1.2,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Offer adjuster
        const OfferAdjuster(),

        const SizedBox(height: 8),

        // Bid hint
        Center(
          child: Text(
            'trip.bid_hint'.tr,
            style: theme.textTheme.bodySmall?.copyWith(color: colors.textMuted),
          ),
        ),

        const SizedBox(height: 16),

        // Trip options chips (payment, passengers, note)
        const TripOptionsChips(),

        const SizedBox(height: 20),

        // Request Ride button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Obx(
            () => AppButton(
              text: 'trip.request_ride'.tr,
              onPressed: controller.isSubmitting.value
                  ? null
                  : controller.submitTrip,
              isLoading: controller.isSubmitting.value,
            ),
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }
}

/// Back button overlay for the map.
class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: Get.back,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.arrow_back,
          size: 20,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}
