import 'package:biko/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Row of ChoiceChips for selecting a report type:
/// Revenue, Driver Payout, Transaction, Custom.
class ReportTypeSelector extends StatelessWidget {
  const ReportTypeSelector({
    required this.selectedType,
    required this.onChanged,
    super.key,
  });

  final String selectedType;
  final Function(String) onChanged;

  static const List<String> _reportTypes = [
    'revenue',
    'driver_payout',
    'transaction',
    'custom',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _reportTypes.map((type) {
        final isSelected = type == selectedType;
        return ChoiceChip(
          label: Text('finance.report_$type'.tr),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) onChanged(type);
          },
          selectedColor: theme.colorScheme.primary.withValues(alpha: 0.15),
          labelStyle: TextStyle(
            color: isSelected
                ? theme.colorScheme.primary
                : colors.textMuted,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            side: BorderSide(
              color: isSelected
                  ? theme.colorScheme.primary
                  : colors.border,
            ),
          ),
        );
      }).toList(),
    );
  }
}
