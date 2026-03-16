import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_button.dart';
import 'package:biko/core/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Dialog for adding a bonus to a driver.
/// Returns a Map with amount, reason, and driverUid, or null if cancelled.
class AddBonusDialog extends StatefulWidget {
  const AddBonusDialog({
    required this.driverName,
    required this.driverUid,
    super.key,
  });

  final String driverName;
  final String driverUid;

  /// Show the dialog and return bonus details or null if cancelled.
  static Future<Map<String, dynamic>?> show({
    required String driverName,
    required String driverUid,
  }) {
    return Get.dialog<Map<String, dynamic>?>(
      AddBonusDialog(
        driverName: driverName,
        driverUid: driverUid,
      ),
    );
  }

  @override
  State<AddBonusDialog> createState() => _AddBonusDialogState();
}

class _AddBonusDialogState extends State<AddBonusDialog> {
  late final TextEditingController _amountController;
  late final TextEditingController _reasonController;
  String? _reasonError;
  String? _amountError;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _reasonController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _confirm() {
    final amount = double.tryParse(_amountController.text);
    final reason = _reasonController.text.trim();

    var hasError = false;

    if (amount == null || amount <= 0) {
      setState(() => _amountError = 'admin.finance.invalid_amount'.tr);
      hasError = true;
    } else {
      setState(() => _amountError = null);
    }

    if (reason.isEmpty) {
      setState(() => _reasonError = 'admin.finance.reason_required'.tr);
      hasError = true;
    } else {
      setState(() => _reasonError = null);
    }

    if (hasError) return;

    Get.back<Map<String, dynamic>>(
      result: {
        'amount': amount,
        'reason': reason,
        'driver_uid': widget.driverUid,
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
                'admin.finance.add_bonus'.tr,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                '${'admin.finance.driver'.tr}: ${widget.driverName}',
                style: TextStyle(color: colors.textMuted),
              ),
              const SizedBox(height: 20),
              AppTextField(
                controller: _amountController,
                label: 'admin.finance.amount'.tr,
                hint: 'admin.finance.enter_amount'.tr,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                suffixIcon: Icons.payments_outlined,
                errorText: _amountError,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _reasonController,
                label: 'admin.finance.reason'.tr,
                hint: 'admin.finance.enter_reason'.tr,
                errorText: _reasonError,
                maxLines: 3,
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
                      text: 'admin.finance.add_bonus'.tr,
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
