import 'package:biko/core/models/transaction_model.dart';
import 'package:biko/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Tile showing a single trip earning entry.
///
/// Matches stitch design: tinted circle icon, clean layout,
/// bordered container with rounded corners.
class TripEarningTile extends StatelessWidget {
  const TripEarningTile({required this.transaction, super.key});

  final TransactionModel transaction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = theme.extension<AppColorsExtension>()!;
    final timeFormat = DateFormat('hh:mm a');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ext.surfaceElevated,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(color: ext.borderSubtle),
        ),
        child: Row(
          children: [
            // Icon in tinted circle
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: ext.successBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.two_wheeler_rounded,
                color: ext.success,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.method.isNotEmpty
                        ? transaction.method
                        : 'earnings.trip_earning'.tr,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    timeFormat.format(transaction.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: ext.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            // Amount badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: ext.successBg,
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
              child: Text(
                '+${transaction.amount.toStringAsFixed(0)} ${'common.egp'.tr}',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: ext.success,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
