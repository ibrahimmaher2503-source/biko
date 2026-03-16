import 'package:biko/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Radio-style card selector for payment methods
class PaymentMethodSelector extends StatelessWidget {
  const PaymentMethodSelector({
    required this.selectedMethod,
    required this.onMethodSelected,
    super.key,
  });

  final String selectedMethod;
  final ValueChanged<String> onMethodSelected;

  static const List<_PaymentOption> _options = [
    _PaymentOption(
      key: 'card',
      labelKey: 'wallet.credit_card',
      icon: Icons.credit_card_rounded,
    ),
    _PaymentOption(
      key: 'vodafone_cash',
      labelKey: 'wallet.vodafone_cash',
      icon: Icons.phone_android_rounded,
    ),
    _PaymentOption(
      key: 'fawry',
      labelKey: 'wallet.fawry',
      icon: Icons.store_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppColorsExtension>()!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _options.map((option) {
        final isSelected = selectedMethod == option.key;
        return GestureDetector(
          onTap: () => onMethodSelected(option.key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primary.withValues(alpha: 0.05)
                  : ext.surfaceElevated,
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              border: Border.all(
                color: isSelected ? AppTheme.primary : ext.borderSubtle,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                // Tinted icon container
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primary.withValues(alpha: 0.1)
                        : ext.surfaceContainer,
                    borderRadius: BorderRadius.circular(
                      AppTheme.radiusDefault,
                    ),
                  ),
                  child: Icon(
                    option.icon,
                    color: isSelected ? AppTheme.primary : ext.textMuted,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  option.labelKey.tr,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: isSelected ? AppTheme.primary : ext.textMuted,
                  size: 22,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _PaymentOption {
  const _PaymentOption({
    required this.key,
    required this.labelKey,
    required this.icon,
  });

  final String key;
  final String labelKey;
  final IconData icon;
}
