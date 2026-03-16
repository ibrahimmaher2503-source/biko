import 'package:biko/core/routes/app_routes.dart';
import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_button.dart';
import 'package:biko/core/widgets/app_loading.dart';
import 'package:biko/features/tracking/controllers/tracking_controller.dart';
import 'package:biko/features/tracking/widgets/driver_info_card.dart';
import 'package:biko/features/tracking/widgets/tracking_map_widget.dart';
import 'package:biko/features/tracking/widgets/tracking_status_banner.dart';
import 'package:biko/features/tracking/widgets/trip_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Full-screen trip tracking screen with map and overlaid cards.
///
/// Shows driver location on map, status banner, progress bar,
/// driver info card, and cancel button.
class TrackingScreen extends GetView<TrackingController> {
  const TrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (controller.isLoading.value) {
          return const AppLoading();
        }

        return Stack(
          children: [
            // Full-screen map — uses its own Obx; outer Obx only
            // gates on isLoading, so inner rebuilds are independent.
            TrackingMapWidget(
                driverLocation: controller.driverLocation.value,
                driverHeading: controller.driverHeading.value,
                pickupLocation: controller.pickupLocation.value,
                dropoffLocation: controller.dropoffLocation.value,
              ),

            // Status banner (top)
            PositionedDirectional(
              top: MediaQuery.of(context).padding.top + 12,
              start: 16,
              end: 16,
              child: Obx(
                () => TrackingStatusBanner(
                  status: controller.trackingStatus.value,
                ),
              ),
            ),

            // ETA chip
            Obx(
              () => controller.eta.value.isNotEmpty
                  ? PositionedDirectional(
                      top: MediaQuery.of(context).padding.top + 68,
                      start: 16,
                      child: _EtaChip(eta: controller.eta.value),
                    )
                  : const SizedBox.shrink(),
            ),

            // Bottom section
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Cancel button (only when allowed)
                  Obx(
                    () => controller.canCancel
                        ? Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: AppButton(
                              text: 'tracking.cancel_trip'.tr,
                              variant: ButtonVariant.outline,
                              onPressed: () => _showCancelDialog(context),
                              isLoading: controller.isCancelling.value,
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),

                  // Progress bar
                  Obx(
                    () => TripProgressBar(
                      status: controller.trackingStatus.value,
                    ),
                  ),

                  // Driver info card
                  Obx(
                    () => DriverInfoCard(
                      driverName: controller.driverName.value,
                      vehicleType: controller.vehicleType.value,
                      plateNumber: controller.plateNumber.value,
                      driverRating: controller.driverRating.value,
                      driverPhotoUrl: controller.driverPhotoUrl.value,
                      driverPhone: controller.driverPhone.value,
                      onChatPressed: () {
                        Get.toNamed(
                          AppRoutes.customerChat,
                          arguments: {
                            'tripId': controller.tripId.value,
                            'uid': controller.customerUid.value,
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  void _showCancelDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: Text('tracking.cancel_trip'.tr),
        content: Text('tracking.cancel_trip_confirm'.tr),
        actions: [
          TextButton(onPressed: Get.back, child: Text('common.no'.tr)),
          TextButton(
            onPressed: () {
              Get.back();
              controller.cancelTrip();
            },
            child: Text(
              'common.yes'.tr,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small chip displaying ETA.
class _EtaChip extends StatelessWidget {
  const _EtaChip({required this.eta});

  final String eta;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    final theme = Theme.of(context);
    final etaLabel = 'tracking.eta_label'.tr;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.access_time, size: 14, color: AppTheme.primary),
          const SizedBox(width: 4),
          Text(
            '$etaLabel: $eta',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
