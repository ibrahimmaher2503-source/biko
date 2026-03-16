import 'package:biko/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Multi-select comment chips for rating feedback
class CommentChips extends StatelessWidget {
  const CommentChips({
    required this.selectedChips,
    required this.onChipToggled,
    super.key,
  });

  final List<String> selectedChips;
  final ValueChanged<String> onChipToggled;

  static const List<String> _chipKeys = [
    'completion.great_ride',
    'completion.clean_vehicle',
    'completion.punctual',
    'completion.friendly_driver',
    'completion.safe_driving',
  ];

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppColorsExtension>()!;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: _chipKeys.map((key) {
        final isSelected = selectedChips.contains(key);
        return GestureDetector(
          onTap: () => onChipToggled(key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected) ...[
                  const Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  key.tr,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isSelected ? AppTheme.primary : null,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
