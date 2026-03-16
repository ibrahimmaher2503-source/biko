import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_button.dart';
import 'package:biko/core/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Dialog for processing a payout to a driver.
/// Returns a Map with method, amount, and confirmed flag, or null if cancelled.
class ProcessPayoutDialog extends StatefulWidget {
  const ProcessPayoutDialog({
    required this.driverName,
    required this.pendingAmount,
    super.key,
  });

  final String driverName;
  final double pendingAmount;

  /// Show the dialog and return payout details or null if cancelled.
  static Future<Map<String, dynamic>?> show({
    required String driverName,
    required double pendingAmount,
  }) {
    return Get.dialog<Map<String, dynamic>?>(
      ProcessPayoutDialog(
        driverName: driverName,
        pendingAmount: pendingAmount,
      ),
    );
  }

  @override
  State<ProcessPayoutDialog> createState() => _ProcessPayoutDialogState();
}

class _ProcessPayoutDialogState extends State<ProcessPayoutDialog> {
  late final TextEditingController _amountController;
  String _selectedMethod = 'bank';

  static const List<String> _methods = ['bank', 'cash', 'wallet'];

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.pendingAmount.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _confirm() {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return;

    Get.back<Map<String, dynamic>>(
      result: {
        'method': _selectedMethod,
        'amount': amount,
        'confirmed': true,
      },
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
              Text(
                'finance.process_payout'.tr,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                '${'finance.driver'.tr}: ${widget.driverName}',
                style: TextStyle(color: colors.textMuted),
              ),
              Text(
                '${'finance.pending'.tr}: '
                '${widget.pendingAmount.toStringAsFixed(2)} '
                '${'common.egp'.tr}',
                style: TextStyle(color: colors.textMuted),
              ),
              const SizedBox(height: 20),
              Text(
                'finance.payout_method'.tr,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedMethod,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                items: _methods.map((method) {
                  return DropdownMenuItem(
                    value: method,
                    child: Text('finance.method_$method'.tr),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedMethod = value);
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _amountController,
                label: 'finance.amount'.tr,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                suffixIcon: Icons.payments_outlined,
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
                      onPressed: () => Get.back<Map<String, dynamic>?>(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 140,
                    child: AppButton(
                      text: 'finance.confirm_payout'.tr,
                      onPressed: _confirm,
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
}
