import 'package:biko/core/models/trip_summary_model.dart';
import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Card showing trip route summary and fare breakdown
class TripSummaryCard extends StatelessWidget {
  const TripSummaryCard({required this.summary, super.key});

  final TripSummaryModel summary;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppColorsExtension>()!;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AppCard(
        child: Column(
          children: [
            // Route row with timeline
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Pickup/dropoff timeline
                  Column(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: ext.success,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: ext.success.withValues(alpha: 0.3),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 2,
                        height: 28,
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        decoration: BoxDecoration(
                          color: ext.borderSubtle,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.3),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  // Addresses column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          summary.pickupAddress,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          summary.dropoffAddress,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Metrics row with tinted background
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: ext.surfaceContainer,
                border: Border.symmetric(
                  horizontal: BorderSide(color: ext.borderSubtle),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _MetricItem(
                    icon: Icons.straighten_rounded,
                    label: summary.formattedDistance,
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    color: ext.borderSubtle,
                  ),
                  _MetricItem(
                    icon: Icons.timer_outlined,
                    label: summary.formattedDuration,
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    color: ext.borderSubtle,
                  ),
                  _MetricItem(
                    icon: Icons.payment_rounded,
                    label: summary.paymentMethod,
                  ),
                ],
              ),
            ),

            // Fare breakdown (expandable)
            Theme(
              data: theme.copyWith(
                dividerTheme: const DividerThemeData(
                  color: Colors.transparent,
                ),
              ),
              child: ExpansionTile(
                title: Text(
                  'completion.fare_breakdown'.tr,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                iconColor: ext.textMuted,
                collapsedIconColor: ext.textMuted,
                children: [
                  _FareRow(
                    label: 'completion.base_fare'.tr,
                    amount: summary.baseFare,
                  ),
                  _FareRow(
                    label: 'completion.distance_fare'.tr,
                    amount: summary.distanceFare,
                  ),
                  _FareRow(
                    label: 'completion.time_fare'.tr,
                    amount: summary.timeFare,
                  ),
                  if (summary.discount > 0)
                    _FareRow(
                      label: 'completion.discount'.tr,
                      amount: -summary.discount,
                      isDiscount: true,
                    ),
                  const SizedBox(height: 8),
                  Container(
                    height: 1,
                    color: ext.borderSubtle,
                  ),
                  const SizedBox(height: 8),
                  _FareRow(
                    label: 'completion.total_fare'.tr,
                    amount: summary.totalFare,
                    isTotal: true,
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

class _MetricItem extends StatelessWidget {
  const _MetricItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppColorsExtension>()!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusDefault),
          ),
          child: Icon(icon, size: 14, color: AppTheme.primary),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(
            color: ext.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _FareRow extends StatelessWidget {
  const _FareRow({
    required this.label,
    required this.amount,
    this.isDiscount = false,
    this.isTotal = false,
  });

  final String label;
  final double amount;
  final bool isDiscount;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppColorsExtension>()!;
    final theme = Theme.of(context);

    final amountText = isDiscount
        ? '-${amount.abs().toStringAsFixed(2)}'
        : amount.toStringAsFixed(2);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isTotal
                ? theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  )
                : theme.textTheme.bodySmall?.copyWith(color: ext.textMuted),
          ),
          Text(
            '$amountText ${'common.egp'.tr}',
            style: isTotal
                ? theme.textTheme.titleSmall?.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w700,
                  )
                : theme.textTheme.bodySmall?.copyWith(
                    color: isDiscount ? ext.success : null,
                    fontWeight: FontWeight.w600,
                  ),
          ),
        ],
      ),
    );
  }
}
