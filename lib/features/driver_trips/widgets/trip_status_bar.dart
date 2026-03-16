import 'package:biko/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Visual status bar showing trip progress: Arrived → In Progress → Completed.
class TripStatusBar extends StatelessWidget {
  const TripStatusBar({required this.isStarted, super.key});

  final bool isStarted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = theme.extension<AppColorsExtension>()!;

    return Row(
      children: [
        _StatusStep(
          label: 'active_trip.status_arrived'.tr,
          isActive: true,
          isCompleted: isStarted,
          color: ext.success,
        ),
        Expanded(
          child: Container(
            height: 2,
            color: isStarted ? ext.success : ext.border,
          ),
        ),
        _StatusStep(
          label: 'active_trip.status_in_progress'.tr,
          isActive: isStarted,
          isCompleted: false,
          color: isStarted ? AppTheme.primary : ext.border,
        ),
        Expanded(child: Container(height: 2, color: ext.border)),
        _StatusStep(
          label: 'active_trip.status_completed'.tr,
          isActive: false,
          isCompleted: false,
          color: ext.border,
        ),
      ],
    );
  }
}

class _StatusStep extends StatelessWidget {
  const _StatusStep({
    required this.label,
    required this.isActive,
    required this.isCompleted,
    required this.color,
  });

  final String label;
  final bool isActive;
  final bool isCompleted;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive || isCompleted ? color : Colors.transparent,
            border: Border.all(color: color, width: 2),
          ),
          child: isCompleted
              ? const Icon(Icons.check, size: 8, color: Colors.white)
              : null,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: isActive
                ? color
                : theme.extension<AppColorsExtension>()!.textMuted,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
