import 'package:biko/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Date range filter widget with preset ranges and custom picker.
class AdminDateRangePicker extends StatelessWidget {
  const AdminDateRangePicker({
    required this.selectedRange,
    required this.onRangeSelected,
    super.key,
  });

  final DateTimeRange? selectedRange;
  final ValueChanged<DateTimeRange> onRangeSelected;

  static final _presets = <String, int>{
    'admin.common.today': 0,
    'admin.common.last_7_days': 7,
    'admin.common.last_30_days': 30,
    'admin.common.last_90_days': 90,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ..._presets.entries.map((entry) {
          final isSelected = _isPresetSelected(entry.value);
          return ChoiceChip(
            label: Text(entry.key.tr),
            selected: isSelected,
            onSelected: (_) => _selectPreset(entry.value),
            selectedColor: theme.colorScheme.primary.withValues(alpha: 0.15),
            labelStyle: TextStyle(
              color: isSelected ? theme.colorScheme.primary : colors.textMuted,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              fontSize: 13,
            ),
          );
        }),
        ActionChip(
          label: Text('admin.common.custom_range'.tr),
          avatar: const Icon(Icons.calendar_today, size: 16),
          onPressed: () => _showCustomPicker(context),
        ),
      ],
    );
  }

  bool _isPresetSelected(int days) {
    if (selectedRange == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (days == 0) {
      return selectedRange!.start == today &&
          selectedRange!.end.day == today.day;
    }

    final presetStart = today.subtract(Duration(days: days));
    return selectedRange!.start.year == presetStart.year &&
        selectedRange!.start.month == presetStart.month &&
        selectedRange!.start.day == presetStart.day;
  }

  void _selectPreset(int days) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final end = today.add(const Duration(hours: 23, minutes: 59, seconds: 59));

    if (days == 0) {
      onRangeSelected(DateTimeRange(start: today, end: end));
    } else {
      onRangeSelected(
        DateTimeRange(
          start: today.subtract(Duration(days: days)),
          end: end,
        ),
      );
    }
  }

  Future<void> _showCustomPicker(BuildContext context) async {
    final now = DateTime.now();
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: now,
      initialDateRange:
          selectedRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 30)),
            end: now,
          ),
    );
    if (result != null) {
      onRangeSelected(result);
    }
  }
}
