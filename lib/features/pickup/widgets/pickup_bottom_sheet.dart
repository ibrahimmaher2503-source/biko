import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_button.dart';
import 'package:biko/features/pickup/controllers/pickup_controller.dart';
import 'package:biko/features/pickup/widgets/saved_locations_list.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Bottom sheet anchored to the bottom of the pickup screen.
///
/// Shows the reverse-geocoded address (or loading indicator),
/// saved/recent locations, and a "Confirm Pickup" button.
class PickupBottomSheet extends GetView<PickupController> {
  const PickupBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
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
                    place: controller.selectedPlace.value,
                  ),
                ),

                const SizedBox(height: 12),

                // Divider
                Divider(height: 1, color: colors.borderSubtle),

                // Saved / Recent locations
                const SavedLocationsList(),

                const SizedBox(height: 16),

                // Confirm Pickup button
                Obx(
                  () => AppButton(
                    text: 'pickup.confirm'.tr,
                    onPressed: controller.selectedPlace.value != null
                        ? controller.confirmPickup
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

/// Row showing a location icon and the reverse-geocoded address,
/// or a loading indicator.
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
        // Location icon
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colors.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.location_on_outlined,
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
                      place.name,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      place.address,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                )
              : Text(
                  'pickup.select_prompt'.tr,
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
