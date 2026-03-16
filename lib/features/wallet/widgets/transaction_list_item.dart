import 'package:biko/core/models/transaction_model.dart';
import 'package:biko/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// List item for a financial transaction with bordered container
class TransactionListItem extends StatelessWidget {
  const TransactionListItem({required this.transaction, super.key});

  final TransactionModel transaction;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppColorsExtension>()!;
    final theme = Theme.of(context);
    final isCredit = transaction.type == TransactionType.credit;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
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
                color: isCredit
                    ? ext.successBg
                    : AppTheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCredit
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                size: 20,
                color: isCredit ? ext.success : AppTheme.primary,
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
                        : transaction.tripId ?? transaction.txnId,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat(
                      'MMM d, yyyy · HH:mm',
                      Get.locale?.languageCode,
                    ).format(transaction.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: ext.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            // Amount badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isCredit
                    ? ext.successBg
                    : AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
              child: Text(
                transaction.formattedAmount,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: isCredit ? ext.success : AppTheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
