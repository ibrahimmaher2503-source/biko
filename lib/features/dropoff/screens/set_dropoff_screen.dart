import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_button.dart';
import 'package:biko/features/dropoff/controllers/dropoff_controller.dart';
import 'package:biko/features/dropoff/widgets/dropoff_results_list.dart';
import 'package:biko/features/dropoff/widgets/dropoff_search_bar.dart';
import 'package:biko/features/dropoff/widgets/saved_dropoffs_list.dart';
import 'package:biko/features/pickup/widgets/center_pin_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Full-screen interactive map screen for setting the dropoff location.
///
/// Mirrors [SetPickupScreen] layout with dropoff-specific labels.
/// Uses a center-pin pattern: pin stays fixed at map center while
/// the map pans underneath.
class SetDropoffScreen extends GetView<DropoffController> {
  const SetDropoffScreen({super.key});

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

          // Center pin overlay (red for dropoff)
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
            child: const DropoffSearchBar(),
          ),

          // Autocomplete results overlay
          Obx(
            () => controller.isSearchActive.value
                ? PositionedDirectional(
                    top: MediaQuery.of(context).padding.top + 68,
                    start: 16,
                    end: 16,
                    bottom: 0,
                    child: const DropoffResultsList(),
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
                              'dropoff.poor_gps'.tr,
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
                ? _DropoffBottomSheet(colors: colors)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet anchored to the bottom of the dropoff screen.
class _DropoffBottomSheet extends GetView<DropoffController> {
  const _DropoffBottomSheet({required this.colors});

  final AppColorsExtension colors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceElevated,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: colors.borderSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Address row
                Obx(
                  () => _AddressRow(
                    colors: colors,
                    theme: theme,
                    isGeocoding: controller.isGeocoding.value,
                    place: controller.selectedDropoff.value,
                  ),
                ),

                const SizedBox(height: 12),

                // Divider
                Divider(height: 1, color: colors.borderSubtle),

                // Recent dropoffs
                const SavedDropoffsList(),

                const SizedBox(height: 16),

                // Confirm Dropoff button
                Obx(
                  () => AppButton(
                    text: 'dropoff.confirm_dropoff'.tr,
                    onPressed: controller.selectedDropoff.value != null
                        ? controller.confirmDropoff
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Row showing a location icon and the reverse-geocoded address.
class _AddressRow extends StatelessWidget {
  const _AddressRow({
    required this.colors,
    required this.theme,
    required this.isGeocoding,
    required this.place,
  });

  final AppColorsExtension colors;
  final ThemeData theme;
  final bool isGeocoding;
  final dynamic place;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Dropoff icon (red)
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colors.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.flag_outlined,
            color: AppTheme.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),

        // Address text
        Expanded(
          child: isGeocoding
              ? _LoadingAddress(colors: colors)
              : place != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name as String,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      place.address as String,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                )
              : Text(
                  'dropoff.tap_map_dropoff'.tr,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.textMuted,
                  ),
                ),
        ),
      ],
    );
  }
}

/// Animated loading placeholder for the address field.
class _LoadingAddress extends StatelessWidget {
  const _LoadingAddress({required this.colors});

  final AppColorsExtension colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 14,
          width: 160,
          decoration: BoxDecoration(
            color: colors.borderSubtle,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 10,
          width: 100,
          decoration: BoxDecoration(
            color: colors.borderSubtle,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
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
