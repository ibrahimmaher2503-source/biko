import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_button.dart';
import 'package:biko/core/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Dialog for adjusting a user's wallet balance (add or subtract).
/// Returns a Map with userUid, amount (signed), and reason, or null.
class WalletAdjustmentDialog extends StatefulWidget {
  const WalletAdjustmentDialog({
    super.key,
    this.preselectedUserUid,
    this.preselectedUserName,
  });

  final String? preselectedUserUid;
  final String? preselectedUserName;

  /// Show the dialog and return adjustment details or null if cancelled.
  static Future<Map<String, dynamic>?> show({
    String? preselectedUserUid,
    String? preselectedUserName,
  }) {
    return Get.dialog<Map<String, dynamic>?>(
      WalletAdjustmentDialog(
        preselectedUserUid: preselectedUserUid,
        preselectedUserName: preselectedUserName,
      ),
    );
  }

  @override
  State<WalletAdjustmentDialog> createState() =>
      _WalletAdjustmentDialogState();
}

class _WalletAdjustmentDialogState extends State<WalletAdjustmentDialog> {
  late final TextEditingController _userController;
  late final TextEditingController _amountController;
  late final TextEditingController _reasonController;
  bool _isAddition = true;

  @override
  void initState() {
    super.initState();
    _userController = TextEditingController(
      text: widget.preselectedUserName ?? '',
    );
    _amountController = TextEditingController();
    _reasonController = TextEditingController();
  }

  @override
  void dispose() {
    _userController.dispose();
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _confirm() {
    final amount = double.tryParse(_amountController.text);
    final reason = _reasonController.text.trim();
    if (amount == null || amount <= 0 || reason.isEmpty) return;

    final signedAmount = _isAddition ? amount : -amount;

    Get.back<Map<String, dynamic>>(
      result: {
        'user_uid': widget.preselectedUserUid ?? _userController.text.trim(),
        'user_name': _userController.text.trim(),
        'amount': signedAmount,
        'reason': reason,
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
                'finance.wallet_adjustment'.tr,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              AppTextField(
                controller: _userController,
                label: 'finance.user'.tr,
                hint: 'finance.enter_user'.tr,
                enabled: widget.preselectedUserUid == null,
                prefixIcon: Icons.person_outline,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: Text('finance.add_funds'.tr),
                      selected: _isAddition,
                      onSelected: (selected) {
                        if (selected) setState(() => _isAddition = true);
                      },
                      selectedColor: colors.successBg,
                      labelStyle: TextStyle(
                        color: _isAddition
                            ? colors.success
                            : colors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: Text('finance.deduct_funds'.tr),
                      selected: !_isAddition,
                      onSelected: (selected) {
                        if (selected) setState(() => _isAddition = false);
                      },
                      selectedColor: const Color(0xFFFEE2E2),
                      labelStyle: TextStyle(
                        color: !_isAddition
                            ? theme.colorScheme.error
                            : colors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _amountController,
                label: 'finance.amount'.tr,
                hint: 'finance.enter_amount'.tr,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                suffixIcon: Icons.payments_outlined,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _reasonController,
                label: 'finance.reason'.tr,
                hint: 'finance.enter_reason'.tr,
                maxLines: 2,
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
                      text: 'common.confirm'.tr,
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
