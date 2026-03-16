import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Bottom sheet showing full transaction details with a flag button.
class TransactionDetailSheet extends StatelessWidget {
  const TransactionDetailSheet({
    required this.transaction,
    super.key,
  });

  final Map<String, dynamic> transaction;

  /// Show the detail sheet as a modal bottom sheet.
  static Future<void> show({
    required Map<String, dynamic> transaction,
  }) {
    return Get.bottomSheet<void>(
      TransactionDetailSheet(transaction: transaction),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;

    final id = transaction['id'] as String? ?? '';
    final type = transaction['type'] as String? ?? '';
    final user = transaction['user'] as String? ?? '';
    final amount = transaction['amount'] as num? ?? 0;
    final status = transaction['status'] as String? ?? '';
    final timestamp = transaction['timestamp'];
    final timeStr = timestamp is DateTime
        ? DateFormat('dd/MM/yyyy HH:mm:ss').format(timestamp)
        : (timestamp?.toString() ?? '');
    final method = transaction['method'] as String? ?? '';
    final tripId = transaction['trip_id'] as String? ?? '';
    final notes = transaction['notes'] as String? ?? '';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'finance.transaction_details'.tr,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              _detailRow(theme, colors, 'ID', id),
              _detailRow(theme, colors, 'finance.type'.tr, type),
              _detailRow(theme, colors, 'finance.user'.tr, user),
              _detailRow(
                theme,
                colors,
                'finance.amount'.tr,
                '${amount.toStringAsFixed(2)} ${'common.egp'.tr}',
                valueColor: amount >= 0
                    ? colors.success
                    : theme.colorScheme.error,
              ),
              _detailRow(theme, colors, 'finance.status'.tr, status),
              _detailRow(theme, colors, 'finance.timestamp'.tr, timeStr),
              if (method.isNotEmpty)
                _detailRow(theme, colors, 'finance.method'.tr, method),
              if (tripId.isNotEmpty)
                _detailRow(theme, colors, 'finance.trip'.tr, tripId),
              if (notes.isNotEmpty)
                _detailRow(theme, colors, 'finance.notes'.tr, notes),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: 'finance.flag_transaction'.tr,
                      variant: ButtonVariant.outline,
                      leadingIcon: Icons.flag_outlined,
                      onPressed: Get.back,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      text: 'common.close'.tr,
                      onPressed: Get.back,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(
    ThemeData theme,
    AppColorsExtension colors,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: colors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
