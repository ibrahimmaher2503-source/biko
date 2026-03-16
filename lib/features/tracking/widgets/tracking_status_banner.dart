import 'package:biko/core/models/enums.dart';
import 'package:biko/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Animated banner at top of tracking screen showing current status.
///
/// Cross-fades between status states with color-coded backgrounds.
class TrackingStatusBanner extends StatelessWidget {
  const TrackingStatusBanner({required this.status, super.key});

  final TrackingStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(status),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _backgroundColor(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(_statusIcon, size: 20, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                status.translationKey.tr,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _backgroundColor(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    switch (status) {
      case TrackingStatus.driverEnRoute:
        return AppTheme.orange;
      case TrackingStatus.driverArrived:
        return colors.success;
      case TrackingStatus.tripInProgress:
        return AppTheme.primary;
      case TrackingStatus.arrivingSoon:
        return colors.warning;
      case TrackingStatus.completed:
        return colors.success;
    }
  }

  IconData get _statusIcon {
    switch (status) {
      case TrackingStatus.driverEnRoute:
        return Icons.two_wheeler;
      case TrackingStatus.driverArrived:
        return Icons.check_circle;
      case TrackingStatus.tripInProgress:
        return Icons.route;
      case TrackingStatus.arrivingSoon:
        return Icons.flag;
      case TrackingStatus.completed:
        return Icons.done_all;
    }
  }
}
