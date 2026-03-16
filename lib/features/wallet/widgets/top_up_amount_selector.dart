import 'package:biko/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Grid selector for top-up amount presets with styled cards
class TopUpAmountSelector extends StatelessWidget {
  const TopUpAmountSelector({
    required this.selectedAmount,
    required this.onAmountSelected,
    super.key,
  });

  final double? selectedAmount;
  final ValueChanged<double?> onAmountSelected;

  static const List<double> _presets = [50, 100, 200, 500];

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppColorsExtension>()!;
    final theme = Theme.of(context);

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: _presets.map((amount) {
        final isSelected = selectedAmount == amount;
        return GestureDetector(
          onTap: () => onAmountSelected(amount),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primary.withValues(alpha: 0.1)
                  : ext.surfaceElevated,
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              border: Border.all(
                color: isSelected ? AppTheme.primary : ext.borderSubtle,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                '${amount.toInt()} ${'common.egp'.tr}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: isSelected ? AppTheme.primary : null,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
