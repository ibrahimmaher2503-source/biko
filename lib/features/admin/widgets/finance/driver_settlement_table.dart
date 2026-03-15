import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/features/admin/models/finance/driver_settlement_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// DataTable with checkboxes for selecting drivers for settlement.
/// Shows driver name, pending amount, bank details, and status.
class DriverSettlementTable extends StatelessWidget {
  const DriverSettlementTable({
    required this.data,
    required this.selectedUids,
    required this.onToggle,
    super.key,
  });

  final List<DriverSettlementModel> data;
  final List<String> selectedUids;
  final Function(String) onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;

    if (data.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'finance.no_settlements'.tr,
            style: TextStyle(color: colors.textMuted),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(colors.surfaceContainer),
        columnSpacing: 20,
        columns: [
          const DataColumn(label: SizedBox(width: 32)),
          DataColumn(label: Text('finance.driver'.tr)),
          DataColumn(label: Text('finance.amount'.tr), numeric: true),
          DataColumn(label: Text('finance.bank_details'.tr)),
          DataColumn(label: Text('finance.status'.tr)),
        ],
        rows: data.map((settlement) {
          final isSelected = selectedUids.contains(settlement.driverUid);

          return DataRow(
            selected: isSelected,
            onSelectChanged: (_) => onToggle(settlement.driverUid),
            cells: [
              DataCell(
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => onToggle(settlement.driverUid),
                  activeColor: theme.colorScheme.primary,
                ),
              ),
              DataCell(
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 160),
                  child: Text(
                    settlement.driverName,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataCell(
                Text(
                  '${settlement.pendingAmount.toStringAsFixed(0)} '
                  '${'common.egp'.tr}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              DataCell(
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 180),
                  child: Text(
                    settlement.bankDetails ?? 'finance.no_bank_details'.tr,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: settlement.bankDetails != null
                          ? null
                          : colors.textMuted,
                    ),
                  ),
                ),
              ),
              DataCell(_buildStatusBadge(settlement.status, colors)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatusBadge(String status, AppColorsExtension colors) {
    Color bg;
    Color fg;
    switch (status.toLowerCase()) {
      case 'completed':
      case 'paid':
        bg = colors.successBg;
        fg = colors.success;
      case 'pending':
        bg = colors.warningBg;
        fg = colors.warning;
      case 'processing':
        bg = colors.infoBg;
        fg = colors.info;
      default:
        bg = colors.surfaceContainer;
        fg = colors.textMuted;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Text(
        status,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}
