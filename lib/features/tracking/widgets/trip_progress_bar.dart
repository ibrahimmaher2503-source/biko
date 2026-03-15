import 'package:biko/core/models/enums.dart';
import 'package:biko/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Linear step indicator: Pickup ─── Driver ─── Dropoff
///
/// Visually shows progress through the trip stages.
class TripProgressBar extends StatelessWidget {
  const TripProgressBar({required this.status, super.key});

  final TrackingStatus status;

  double get _progress {
    switch (status) {
      case TrackingStatus.driverEnRoute:
        return 0.15;
      case TrackingStatus.driverArrived:
        return 0.35;
      case TrackingStatus.tripInProgress:
        return 0.6;
      case TrackingStatus.arrivingSoon:
        return 0.85;
      case TrackingStatus.completed:
        return 1.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 6,
              backgroundColor: colors.borderSubtle,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
            ),
          ),
          const SizedBox(height: 8),

          // Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'pickup.select_prompt'.tr,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.textMuted,
                  fontSize: 10,
                ),
              ),
              Text(
                'dropoff.confirm_dropoff'.tr,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.textMuted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
