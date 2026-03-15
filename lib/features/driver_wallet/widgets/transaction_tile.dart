import 'package:biko/core/models/transaction_model.dart';
import 'package:biko/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Tile showing a single transaction in the wallet history.
///
/// Matches stitch design: tinted icon container,
/// clean typography, and colored amount indicator.
class TransactionTile extends StatelessWidget {
  const TransactionTile({required this.transaction, super.key});

  final TransactionModel transaction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = theme.extension<AppColorsExtension>()!;
    final isCredit = transaction.type == TransactionType.credit;
    final dateFormat = DateFormat('dd MMM, hh:mm a');

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
                color: isCredit
                    ? ext.successBg
                    : theme.colorScheme.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCredit
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                color: isCredit ? ext.success : theme.colorScheme.error,
                size: 20,
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
                        : isCredit
                            ? 'wallet.credit'.tr
                            : 'wallet.debit'.tr,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateFormat.format(transaction.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: ext.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            // Amount
            Text(
              '${isCredit ? '+' : '-'}${transaction.amount.toStringAsFixed(0)} ${'common.egp'.tr}',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: isCredit ? ext.success : theme.colorScheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
