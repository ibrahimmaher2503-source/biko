import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_button.dart';
import 'package:biko/features/admin/models/finance/settlement_summary_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Confirmation dialog for processing batch settlements.
/// Shows a breakdown of selected drivers and total amount.
/// Returns true if confirmed, false/null otherwise.
class ProcessSettlementDialog extends StatelessWidget {
  const ProcessSettlementDialog({
    required this.summary,
    required this.selectedCount,
    super.key,
  });

  final SettlementSummaryModel summary;
  final int selectedCount;

  /// Show the dialog and return true if confirmed.
  static Future<bool?> show({
    required SettlementSummaryModel summary,
    required int selectedCount,
  }) {
    return Get.dialog<bool?>(
      ProcessSettlementDialog(
        summary: summary,
        selectedCount: selectedCount,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: colors.warning,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'finance.process_settlement'.tr,
                    style: theme.textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'finance.settlement_confirmation_message'.tr,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.textMuted,
                ),
              ),
              const SizedBox(height: 20),
              // Breakdown
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surfaceContainer,
                  borderRadius: BorderRadius.circular(
                    AppTheme.radiusDefault,
                  ),
                ),
                child: Column(
                  children: [
                    _breakdownRow(
                      theme,
                      colors,
                      label: 'finance.selected_drivers'.tr,
                      value: selectedCount.toString(),
                    ),
                    const SizedBox(height: 8),
                    _breakdownRow(
                      theme,
                      colors,
                      label: 'finance.total_amount'.tr,
                      value: '${summary.totalAmount.toStringAsFixed(0)} '
                          '${'common.egp'.tr}',
                      isBold: true,
                    ),
                    const SizedBox(height: 8),
                    _breakdownRow(
                      theme,
                      colors,
                      label: 'finance.pending_settlements'.tr,
                      value: summary.pendingSettlements.toString(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 100,
                    child: AppButton(
                      text: 'common.cancel'.tr,
                      variant: ButtonVariant.text,
                      onPressed: () => Get.back<bool?>(result: false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 160,
                    child: AppButton(
                      text: 'finance.confirm_settlement'.tr,
                      onPressed: () => Get.back<bool?>(result: true),
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

  Widget _breakdownRow(
    ThemeData theme,
    AppColorsExtension colors, {
    required String label,
    required String value,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: colors.textMuted,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
