import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_card.dart';
import 'package:biko/features/driver_trips/controllers/trip_requests_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Card displaying an incoming trip request matching the stitch design.
///
/// Layout: countdown badge + dismiss, pickup/dropoff with timeline dots,
/// distance/duration chips, price, and Decline/Accept buttons.
class TripRequestCard extends StatelessWidget {
  const TripRequestCard({
    required this.request,
    required this.onAccept,
    required this.onBid,
    required this.onDismiss,
    this.isBestPrice = false,
    super.key,
  });

  final TripRequest request;
  final VoidCallback onAccept;
  final VoidCallback onBid;
  final VoidCallback onDismiss;
  final bool isBestPrice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = theme.extension<AppColorsExtension>()!;

    return AppCard(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row: countdown + dismiss
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Countdown badge
                      _CountdownBadge(
                        countdown: request.countdown,
                        isUrgent: request.countdown <= 10,
                      ),
                      IconButton(
                        onPressed: onDismiss,
                        icon: Icon(
                          Icons.close,
                          size: 20,
                          color: ext.textMuted,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Route timeline: pickup → dropoff
                  _RouteTimeline(
                    pickupAddress: request.pickupAddress,
                    dropoffAddress: request.dropoffAddress,
                  ),
                  const SizedBox(height: 16),

                  // Trip details row: distance, duration, price
                  Row(
                    children: [
                      _DetailChip(
                        icon: Icons.straighten,
                        text:
                            '${request.distanceKm.toStringAsFixed(1)} ${'driver_trips.km'.tr}',
                      ),
                      const SizedBox(width: 12),
                      _DetailChip(
                        icon: Icons.schedule,
                        text:
                            '${request.durationMinutes} ${'driver_trips.min'.tr}',
                      ),
                      const Spacer(),
                      // Price
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
                          '${request.customerPrice.toStringAsFixed(0)} ${'common.egp'.tr}',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Action buttons: Decline (light) + Accept (primary)
                  Row(
                    children: [
                      // Decline / Counter-bid
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: TextButton(
                            onPressed: onBid,
                            style: TextButton.styleFrom(
                              backgroundColor: ext.surfaceContainer,
                              foregroundColor:
                                  theme.colorScheme.onSurface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusLarge,
                                ),
                              ),
                              textStyle:
                                  theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            child: Text('driver_trips.submit_bid'.tr),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Accept
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 48,
                          child: FilledButton.icon(
                            onPressed: onAccept,
                            icon: const Icon(
                              Icons.check_circle,
                              size: 18,
                            ),
                            label: Text('driver_trips.accept_price'.tr),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusLarge,
                                ),
                              ),
                              elevation: 2,
                              shadowColor: AppTheme.primary.withValues(
                                alpha: 0.3,
                              ),
                              textStyle:
                                  theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // "BEST PRICE" badge (top-right corner)
            if (isBestPrice)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: ext.success,
                    borderRadius: const BorderRadiusDirectional.only(
                      bottomStart: Radius.circular(AppTheme.radiusDefault),
                    ),
                  ),
                  child: Text(
                    'driver_trips.best_price'.tr,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Route timeline showing pickup → dotted line → dropoff.
class _RouteTimeline extends StatelessWidget {
  const _RouteTimeline({
    required this.pickupAddress,
    required this.dropoffAddress,
  });

  final String pickupAddress;
  final String dropoffAddress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = theme.extension<AppColorsExtension>()!;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline dots + connector
          SizedBox(
            width: 24,
            child: Column(
              children: [
                // Green pickup dot
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: ext.success,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: ext.success.withValues(alpha: 0.3),
                      width: 3,
                    ),
                  ),
                ),
                // Connector line
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: ext.border,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
                // Red dropoff dot
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                      width: 3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Addresses
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Pickup
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'driver_trips.pickup'.tr,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: ext.textMuted,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      pickupAddress,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Dropoff
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'driver_trips.dropoff'.tr,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: ext.textMuted,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dropoffAddress,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated countdown badge with timer icon.
class _CountdownBadge extends StatelessWidget {
  const _CountdownBadge({
    required this.countdown,
    required this.isUrgent,
  });

  final int countdown;
  final bool isUrgent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isUrgent ? theme.colorScheme.error : AppTheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            '$countdown${'driver_trips.seconds_short'.tr}',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Small detail chip with icon + text for distance/duration.
class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppColorsExtension>()!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ext.surfaceContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusDefault),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: ext.textMuted),
          const SizedBox(width: 4),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: ext.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
