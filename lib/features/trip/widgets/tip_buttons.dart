import 'package:biko/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Preset tip amount buttons with custom input option
class TipButtons extends StatelessWidget {
  const TipButtons({
    required this.selectedAmount,
    required this.onAmountSelected,
    super.key,
  });

  final double? selectedAmount;
  final ValueChanged<double?> onAmountSelected;

  static const List<double> _presets = [5, 10, 15, 20];

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppColorsExtension>()!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header with tinted icon
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: ext.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              ),
              child: Icon(
                Icons.volunteer_activism_rounded,
                color: ext.success,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'completion.tip_driver'.tr,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            // No tip option
            _TipChip(
              label: 'completion.no_tip'.tr,
              isSelected: selectedAmount == null,
              onTap: () => onAmountSelected(null),
            ),
            // Preset amounts
            ..._presets.map(
              (amount) => _TipChip(
                label: '${amount.toInt()} ${'common.egp'.tr}',
                isSelected: selectedAmount == amount,
                onTap: () => onAmountSelected(amount),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TipChip extends StatelessWidget {
  const _TipChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppColorsExtension>()!;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withValues(alpha: 0.1)
              : ext.surfaceContainer,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(
            color: isSelected ? AppTheme.primary : ext.borderSubtle,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isSelected ? AppTheme.primary : null,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
