import 'package:biko/core/models/enums.dart';
import 'package:biko/core/models/trip_model.dart';
import 'package:biko/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Single trip history list item with bordered container
class TripHistoryItem extends StatelessWidget {
  const TripHistoryItem({required this.trip, required this.onTap, super.key});

  final TripModel trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = Theme.of(context).extension<AppColorsExtension>()!;
    final isCancelled = trip.status == TripStatus.cancelled;
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: ext.surfaceElevated,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(color: ext.borderSubtle),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status icon in tinted circle
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isCancelled
                      ? theme.colorScheme.error.withValues(alpha: 0.1)
                      : ext.successBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCancelled
                      ? Icons.cancel_outlined
                      : Icons.check_circle_outline_rounded,
                  color: isCancelled
                      ? theme.colorScheme.error
                      : ext.success,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),

              // Trip details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pickup → Dropoff
                    Text(
                      '${trip.pickup.name} → ${trip.dropoff.name}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Date
                    Text(
                      dateFormat.format(trip.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: ext.textMuted,
                      ),
                    ),
                    if (isCancelled) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusFull,
                          ),
                        ),
                        child: Text(
                          'history.cancelled'.tr,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Price badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isCancelled
                      ? ext.surfaceContainer
                      : ext.successBg,
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: Text(
                  trip.formattedPrice,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isCancelled ? ext.textMuted : ext.success,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
