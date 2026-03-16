import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_button.dart';
import 'package:biko/core/widgets/app_loading.dart';
import 'package:biko/core/widgets/app_map_widget.dart';
import 'package:biko/features/driver_trips/controllers/navigate_pickup_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

/// Screen showing navigation to pickup location.
///
/// Matches the stitch design: map with route, dark turn-by-turn banner
/// at top, customer info panel, and "I Have Arrived" button.
class NavigateToPickupScreen extends GetView<NavigatePickupController> {
  const NavigateToPickupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: AppLoading());
        }

        final trip = controller.trip.value;
        if (trip == null) {
          return Center(child: Text('navigate.error_no_trip'.tr));
        }

        return Stack(
          children: [
            // Full-bleed map
            Positioned.fill(
              child: Obx(
                () => AppMapWidget(
                  height: double.infinity,
                  markers: controller.markers.toSet(),
                  polylines: controller.polylines.toSet(),
                ),
              ),
            ),

            // Dark turn-by-turn direction banner (top)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      // Back button
                      _CircleIconButton(
                        icon: Icons.arrow_back,
                        onTap: () => Get.back<void>(),
                      ),
                      const SizedBox(width: 12),
                      // Turn direction banner
                      Expanded(child: _TurnByTurnBanner()),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom sheet panel
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomPanel(context, trip),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildBottomPanel(BuildContext context, dynamic trip) {
    final theme = Theme.of(context);
    final ext = theme.extension<AppColorsExtension>()!;
    final directions = controller.directions.value;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: ext.surfaceElevated,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ext.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Customer info row
              Row(
                children: [
                  // Avatar placeholder
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: ext.surfaceContainer,
                    child: Icon(
                      Icons.person,
                      color: ext.textMuted,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Name + label
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.customerName ?? 'driver_trips.customer'.tr,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'driver_trips.customer'.tr,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: ext.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Call button
                  _CircleActionButton(
                    icon: Icons.phone,
                    color: ext.success,
                    onTap: _callCustomer,
                  ),
                  const SizedBox(width: 8),
                  // Chat button
                  _CircleActionButton(
                    icon: Icons.chat_bubble,
                    color: ext.textMuted,
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Pickup address card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: ext.surfaceContainer,
                  borderRadius: BorderRadius.circular(
                    AppTheme.radiusLarge,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'navigate.pickup_location'.tr,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: ext.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            trip.pickup.address,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Distance + ETA
              if (directions != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    _MetricChip(
                      icon: Icons.straighten,
                      label: 'driver_trips.distance'.tr,
                      value:
                          '${directions.distanceKm.toStringAsFixed(1)} ${'driver_trips.km'.tr}',
                    ),
                    const SizedBox(width: 12),
                    _MetricChip(
                      icon: Icons.schedule,
                      label: 'driver_trips.duration'.tr,
                      value:
                          '${directions.durationMins.toStringAsFixed(0)} ${'driver_trips.min'.tr}',
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),

              // I Have Arrived button
              AppButton(
                text: 'navigate.arrived'.tr,
                onPressed: controller.markArrived,
                trailingIcon: Icons.check_circle,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _callCustomer() async {
    final trip = controller.trip.value;
    if (trip == null) return;

    final uri = Uri.parse('tel:+201000000000');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

/// Dark turn-by-turn direction banner (matches stitch).
class _TurnByTurnBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.turn_right, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'driver_trips.turn_direction'.tr,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'navigate.follow_route'.tr,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.close,
              color: Colors.white.withValues(alpha: 0.6),
              size: 20,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

/// Small circle icon button for top overlays.
class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppColorsExtension>()!;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: ext.surfaceElevated,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
            ),
          ],
        ),
        child: Icon(icon, size: 22),
      ),
    );
  }
}

/// Circle action button for call/chat (colored icon in circle).
class _CircleActionButton extends StatelessWidget {
  const _CircleActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}

/// Small metric chip showing icon + label + value.
class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = theme.extension<AppColorsExtension>()!;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: ext.surfaceContainer,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: ext.textMuted),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: ext.textMuted,
                    fontSize: 10,
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
