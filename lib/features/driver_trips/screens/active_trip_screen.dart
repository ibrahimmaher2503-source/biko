import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_button.dart';
import 'package:biko/core/widgets/app_dialog.dart';
import 'package:biko/core/widgets/app_loading.dart';
import 'package:biko/core/widgets/app_map_widget.dart';
import 'package:biko/features/driver_trips/controllers/active_trip_controller.dart';
import 'package:biko/features/driver_trips/widgets/trip_status_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Screen for managing an active trip in progress.
///
/// Matches stitch: full-bleed map, customer info with call/chat,
/// dropoff address with notes, fare amount, status bar, action buttons.
class ActiveTripScreen extends GetView<ActiveTripController> {
  const ActiveTripScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _showExitConfirmation(context);
      },
      child: Scaffold(
        body: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: AppLoading());
          }

          final trip = controller.trip.value;
          if (trip == null) {
            return Center(child: Text('active_trip.error_no_trip'.tr));
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

              // Top overlay: back button
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
                        _CircleIconButton(
                          icon: Icons.arrow_back,
                          onTap: () => _showExitConfirmation(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // FAB: chat
              Positioned(
                right: 16,
                bottom: 320,
                child: FloatingActionButton(
                  onPressed: controller.openChat,
                  backgroundColor: AppTheme.primary,
                  elevation: 4,
                  child: const Icon(
                    Icons.chat_bubble,
                    color: Colors.white,
                  ),
                ),
              ),

              // Bottom panel
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildBottomPanel(context, trip),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildBottomPanel(BuildContext context, dynamic trip) {
    final theme = Theme.of(context);
    final ext = theme.extension<AppColorsExtension>()!;

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
          padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 16),
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
              const SizedBox(height: 12),

              // Status bar
              Obx(
                () => TripStatusBar(
                  isStarted: controller.isTripStarted.value,
                ),
              ),
              const SizedBox(height: 16),

              // Customer info row
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: ext.surfaceContainer,
                    child: Icon(
                      Icons.person,
                      color: ext.textMuted,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.customerName ??
                              'driver_trips.customer'.tr,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: ext.warning,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '4.9',
                              style:
                                  theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '• ${'driver_trips.customer'.tr}',
                              style:
                                  theme.textTheme.bodySmall?.copyWith(
                                color: ext.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Call
                  _CircleActionButton(
                    icon: Icons.phone,
                    color: ext.success,
                    onTap: () {},
                  ),
                  const SizedBox(width: 8),
                  // Chat
                  _CircleActionButton(
                    icon: Icons.chat_bubble,
                    color: ext.textMuted,
                    onTap: controller.openChat,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Dropoff address card
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
                          color: AppTheme.primary.withValues(
                            alpha: 0.3,
                          ),
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
                            'active_trip.dropoff'.tr,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: ext.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            trip.dropoff.address,
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
              const SizedBox(height: 12),

              // Fare info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'active_trip.fare'.tr,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: ext.textMuted,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(
                        AppTheme.radiusDefault,
                      ),
                    ),
                    child: Text(
                      '${trip.finalPrice.toStringAsFixed(0)} ${'common.egp'.tr}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Action button
              Obx(() {
                if (!controller.isTripStarted.value) {
                  return AppButton(
                    text: 'active_trip.start_trip'.tr,
                    onPressed: controller.startTrip,
                    trailingIcon: Icons.arrow_forward,
                  );
                }

                return AppButton(
                  text: 'active_trip.complete_trip'.tr,
                  onPressed: controller.completeTrip,
                  isLoading: controller.isCompleting.value,
                  leadingIcon: Icons.check_circle,
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showExitConfirmation(BuildContext context) async {
    await AppDialog.info(
      title: 'active_trip.exit_title'.tr,
      content: 'active_trip.exit_message'.tr,
    );
  }
}

/// Small circle icon button for overlays.
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

/// Circle action button with tinted background.
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
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}
