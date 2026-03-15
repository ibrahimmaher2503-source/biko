import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/features/pickup/controllers/pickup_controller.dart';
import 'package:biko/features/pickup/widgets/center_pin_widget.dart';
import 'package:biko/features/pickup/widgets/pickup_bottom_sheet.dart';
import 'package:biko/features/pickup/widgets/pickup_results_list.dart';
import 'package:biko/features/pickup/widgets/pickup_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Full-screen interactive map screen for setting the pickup location.
///
/// Uses a center-pin pattern: the pin stays fixed at the map center
/// while the map pans underneath. Includes a floating search bar,
/// autocomplete results overlay, bottom sheet with address + confirm,
/// back button, and my-location FAB.
class SetPickupScreen extends GetView<PickupController> {
  const SetPickupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;

    return Scaffold(
      body: Stack(
        children: [
          // Full-screen Google Map
          Obx(
            () => GoogleMap(
              initialCameraPosition: CameraPosition(
                target: controller.mapCenter.value,
                zoom: 16,
              ),
              onMapCreated: controller.onMapCreated,
              onCameraMove: controller.onCameraMove,
              onCameraIdle: controller.onCameraIdle,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
            ),
          ),

          // Center pin overlay
          const CenterPinWidget(),

          // Back button (top-start)
          PositionedDirectional(
            top: MediaQuery.of(context).padding.top + 12,
            start: 16,
            child: _FloatingCircleButton(
              icon: Icons.arrow_back,
              colors: colors,
              onTap: Get.back,
            ),
          ),

          // My-location FAB (bottom-end, above bottom sheet)
          PositionedDirectional(
            bottom: 200,
            end: 16,
            child: _FloatingCircleButton(
              icon: Icons.my_location,
              colors: colors,
              onTap: controller.goToMyLocation,
            ),
          ),

          // Search bar (below status bar area)
          PositionedDirectional(
            top: MediaQuery.of(context).padding.top + 12,
            start: 68,
            end: 16,
            child: const PickupSearchBar(),
          ),

          // Autocomplete results overlay
          Obx(
            () => controller.isSearchActive.value
                ? PositionedDirectional(
                    top: MediaQuery.of(context).padding.top + 68,
                    start: 16,
                    end: 16,
                    bottom: 0,
                    child: const PickupResultsList(),
                  )
                : const SizedBox.shrink(),
          ),

          // Poor GPS accuracy banner
          Obx(
            () =>
                controller.isPoorGpsAccuracy.value &&
                    !controller.isSearchActive.value
                ? Positioned(
                    bottom: 230,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: colors.warningBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.gps_off, size: 16, color: colors.warning),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'pickup.poor_gps'.tr,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: colors.warning),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // Bottom sheet with address + confirm
          Obx(
            () => !controller.isSearchActive.value
                ? const PickupBottomSheet()
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

/// Small circular elevated button used for back and my-location.
class _FloatingCircleButton extends StatelessWidget {
  const _FloatingCircleButton({
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  final IconData icon;
  final AppColorsExtension colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colors.surfaceElevated,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}
