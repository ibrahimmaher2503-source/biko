import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Horizontal filter row with type dropdown, status dropdown,
/// date range, amount range, and search field.
class TransactionFilterPanel extends StatefulWidget {
  const TransactionFilterPanel({
    super.key,
    this.onTypeChanged,
    this.onStatusChanged,
    this.onDateRangeChanged,
    this.onAmountRangeChanged,
    this.onSearchChanged,
  });

  final Function(String?)? onTypeChanged;
  final Function(String?)? onStatusChanged;
  final Function(DateTimeRange?)? onDateRangeChanged;
  final Function(double?, double?)? onAmountRangeChanged;
  final Function(String)? onSearchChanged;

  @override
  State<TransactionFilterPanel> createState() =>
      _TransactionFilterPanelState();
}

class _TransactionFilterPanelState extends State<TransactionFilterPanel> {
  String? _selectedType;
  String? _selectedStatus;
  DateTimeRange? _dateRange;
  late final TextEditingController _searchController;
  late final TextEditingController _minAmountController;
  late final TextEditingController _maxAmountController;

  static const List<String> _types = [
    'all',
    'trip_payment',
    'top_up',
    'withdrawal',
    'commission',
    'bonus',
    'refund',
  ];

  static const List<String> _statuses = [
    'all',
    'completed',
    'pending',
    'failed',
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _minAmountController = TextEditingController();
    _maxAmountController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _dateRange,
    );
    if (result != null) {
      setState(() => _dateRange = result);
      widget.onDateRangeChanged?.call(result);
    }
  }

  void _applyAmountFilter() {
    final min = double.tryParse(_minAmountController.text);
    final max = double.tryParse(_maxAmountController.text);
    widget.onAmountRangeChanged?.call(min, max);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Type dropdown
        SizedBox(
          width: 160,
          child: DropdownButtonFormField<String>(
            initialValue: _selectedType,
            decoration: InputDecoration(
              labelText: 'finance.type'.tr,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusDefault),
              ),
            ),
            isExpanded: true,
            items: _types.map((type) {
              return DropdownMenuItem(
                value: type == 'all' ? null : type,
                child: Text(
                  type == 'all'
                      ? 'common.all'.tr
                      : 'finance.type_$type'.tr,
                  style: const TextStyle(fontSize: 13),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedType = value);
              widget.onTypeChanged?.call(value);
            },
          ),
        ),
        // Status dropdown
        SizedBox(
          width: 140,
          child: DropdownButtonFormField<String>(
            initialValue: _selectedStatus,
            decoration: InputDecoration(
              labelText: 'finance.status'.tr,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusDefault),
              ),
            ),
            isExpanded: true,
            items: _statuses.map((status) {
              return DropdownMenuItem(
                value: status == 'all' ? null : status,
                child: Text(
                  status == 'all'
                      ? 'common.all'.tr
                      : 'finance.status_$status'.tr,
                  style: const TextStyle(fontSize: 13),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedStatus = value);
              widget.onStatusChanged?.call(value);
            },
          ),
        ),
        // Date range button
        SizedBox(
          width: 200,
          child: OutlinedButton.icon(
            onPressed: _pickDateRange,
            icon: const Icon(Icons.date_range, size: 18),
            label: Text(
              _dateRange != null
                  ? '${_dateRange!.start.day}/${_dateRange!.start.month} - '
                      '${_dateRange!.end.day}/${_dateRange!.end.month}'
                  : 'finance.date_range'.tr,
              style: const TextStyle(fontSize: 13),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              side: BorderSide(color: colors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusDefault),
              ),
            ),
          ),
        ),
        // Min amount
        SizedBox(
          width: 110,
          child: TextField(
            controller: _minAmountController,
            decoration: InputDecoration(
              labelText: 'finance.min'.tr,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusDefault),
              ),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 13),
            onSubmitted: (_) => _applyAmountFilter(),
          ),
        ),
        // Max amount
        SizedBox(
          width: 110,
          child: TextField(
            controller: _maxAmountController,
            decoration: InputDecoration(
              labelText: 'finance.max'.tr,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusDefault),
              ),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 13),
            onSubmitted: (_) => _applyAmountFilter(),
          ),
        ),
        // Search field
        SizedBox(
          width: 220,
          child: AppTextField(
            controller: _searchController,
            hint: 'common.search'.tr,
            prefixIcon: Icons.search,
            onChanged: widget.onSearchChanged,
          ),
        ),
      ],
    );
  }
}
