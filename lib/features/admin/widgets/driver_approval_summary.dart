import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_card.dart';
import 'package:biko/features/admin/models/approval_stats_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DriverApprovalSummary extends StatelessWidget {
  const DriverApprovalSummary({
    required this.stats,
    super.key,
  });

  final ApprovalStatsModel stats;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _StatItem(
          label: 'admin.approvals.pending_count'.tr,
          value: '${stats.pendingCount}',
          color: stats.pendingCount > 5
              ? Theme.of(context).colorScheme.error
              : colors.warning,
          icon: Icons.hourglass_empty,
        ),
        _StatItem(
          label: 'admin.approvals.approved_today'.tr,
          value: '${stats.approvedTodayCount}',
          color: colors.success,
          icon: Icons.check_circle_outline,
        ),
        _StatItem(
          label: 'admin.approvals.rejected_today'.tr,
          value: '${stats.rejectedTodayCount}',
          color: Theme.of(context).colorScheme.error,
          icon: Icons.cancel_outlined,
        ),
        _StatItem(
          label: 'admin.approvals.avg_wait_time'.tr,
          value: '${stats.avgApprovalTimeHours.toStringAsFixed(1)}h',
          color: colors.info,
          icon: Icons.timer_outlined,
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    return AppCard(
      child: SizedBox(
        width: 180,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(color: color),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
