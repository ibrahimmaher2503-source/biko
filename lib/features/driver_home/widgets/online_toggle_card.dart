import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Large online/offline toggle card for driver home screen.
///
/// Prominent card with accent bar when online,
/// pulsing status dot, and scaled toggle switch.
class OnlineToggleCard extends StatelessWidget {
  const OnlineToggleCard({
    required this.isOnline,
    required this.onToggle,
    required this.hasDebt,
    super.key,
  });

  final bool isOnline;
  final VoidCallback onToggle;
  final bool hasDebt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = theme.extension<AppColorsExtension>()!;

    final statusColor = isOnline ? ext.success : ext.textMuted;

    return AppCard(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: Stack(
          children: [
            // Accent bar at start edge when online
            if (isOnline)
              PositionedDirectional(
                start: 0,
                top: 0,
                bottom: 0,
                width: 4,
                child: ColoredBox(color: ext.success),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Status icon in tinted circle
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          isOnline ? Icons.wifi : Icons.wifi_off,
                          color: statusColor,
                          size: 28,
                        ),
                        // Active dot when online
                        if (isOnline)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: ext.success,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: ext.surfaceElevated,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Status text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isOnline
                              ? 'driver_home.status_online'.tr
                              : 'driver_home.status_offline'.tr,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isOnline
                              ? 'driver_home.accepting_trips'.tr
                              : 'driver_home.go_online_hint'.tr,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: ext.textMuted,
                          ),
                        ),
                        if (hasDebt)
                          Padding(
                            padding: const EdgeInsetsDirectional.only(top: 6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusFull,
                                ),
                              ),
                              child: Text(
                                'driver_home.top_up_required'.tr,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Toggle switch
                  Transform.scale(
                    scale: 1.3,
                    child: Switch(
                      value: isOnline,
                      onChanged:
                          hasDebt && !isOnline ? null : (_) => onToggle(),
                      activeThumbColor: ext.success,
                      activeTrackColor: ext.success.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
