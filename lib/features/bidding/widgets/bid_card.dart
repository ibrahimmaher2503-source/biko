import 'package:biko/core/models/bid_model.dart';
import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Card displaying a single driver bid with accept/reject actions.
class BidCard extends StatelessWidget {
  const BidCard({
    required this.bid,
    required this.onAccept,
    required this.onReject,
    this.isAccepting = false,
    super.key,
  });

  final BidModel bid;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final bool isAccepting;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Driver avatar
          CircleAvatar(
            radius: 24,
            backgroundImage: bid.driverPhotoUrl != null
                ? NetworkImage(bid.driverPhotoUrl!)
                : null,
            backgroundColor: colors.surfaceContainer,
            child: bid.driverPhotoUrl == null
                ? Icon(Icons.person, color: colors.textMuted, size: 24)
                : null,
          ),
          const SizedBox(width: 12),

          // Driver info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bid.driverName,
                  style: theme.textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // Rating stars
                Row(
                  children: [
                    ...List.generate(5, (i) {
                      return Icon(
                        i < bid.driverRating.round()
                            ? Icons.star
                            : Icons.star_border,
                        size: 14,
                        color: AppTheme.orange,
                      );
                    }),
                    const SizedBox(width: 4),
                    Text(
                      bid.driverRating.toStringAsFixed(1),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Vehicle + ETA
                Row(
                  children: [
                    Icon(Icons.two_wheeler, size: 14, color: colors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      bid.vehicleType.name.tr,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.textMuted,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '\u00b7',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.textMuted,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'bids.eta_minutes'.trParams({
                        'minutes': bid.etaMinutes.toString(),
                      }),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Price + Accept
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${bid.amount.toStringAsFixed(0)} ${'bids.egp'.tr}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 80,
                height: 36,
                child: AppButton(
                  text: 'bids.accept_bid'.tr,
                  onPressed: isAccepting ? null : onAccept,
                  isLoading: isAccepting,
                  height: 36,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
