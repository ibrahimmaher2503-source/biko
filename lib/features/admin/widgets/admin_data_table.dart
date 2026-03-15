import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_loading.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Column definition for [AdminDataTable].
class AdminColumn {
  const AdminColumn({
    required this.label,
    this.flex = 1,
    this.alignment = AlignmentDirectional.centerStart,
  });

  final String label;
  final int flex;
  final AlignmentDirectional alignment;
}

/// Reusable paginated data table with search, filter, and row tap support.
class AdminDataTable<T> extends StatelessWidget {
  const AdminDataTable({
    required this.columns,
    required this.rows,
    required this.cellBuilder,
    super.key,
    this.searchHint,
    this.onSearch,
    this.filterWidgets = const [],
    this.onRowTap,
    this.isLoading = false,
    this.emptyMessage,
    this.hasNextPage = false,
    this.hasPreviousPage = false,
    this.onNextPage,
    this.onPreviousPage,
    this.currentPage = 1,
    this.totalLabel,
  });

  final List<AdminColumn> columns;
  final List<T> rows;
  final Widget Function(T row, int columnIndex) cellBuilder;
  final String? searchHint;
  final ValueChanged<String>? onSearch;
  final List<Widget> filterWidgets;
  final ValueChanged<T>? onRowTap;
  final bool isLoading;
  final String? emptyMessage;
  final bool hasNextPage;
  final bool hasPreviousPage;
  final VoidCallback? onNextPage;
  final VoidCallback? onPreviousPage;
  final int currentPage;
  final String? totalLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Search and filter row
        if (onSearch != null || filterWidgets.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (onSearch != null)
                  SizedBox(
                    width: 300,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: searchHint ?? 'common.search'.tr,
                        prefixIcon: const Icon(Icons.search, size: 20),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                      ),
                      onChanged: onSearch,
                    ),
                  ),
                ...filterWidgets,
              ],
            ),
          ),

        // Table content
        Expanded(
          child: isLoading
              ? const Center(child: AppLoading())
              : rows.isEmpty
              ? Center(
                  child: Text(
                    emptyMessage ?? 'admin.common.no_data'.tr,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colors.textMuted,
                    ),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      // Header row
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainer,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(AppTheme.radiusDefault),
                          ),
                        ),
                        child: Row(
                          children: columns.map((col) {
                            return Expanded(
                              flex: col.flex,
                              child: Align(
                                alignment: col.alignment,
                                child: Text(
                                  col.label,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: colors.textMuted,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      // Data rows
                      ...rows.asMap().entries.map((entry) {
                        final index = entry.key;
                        final row = entry.value;
                        return InkWell(
                          onTap: onRowTap != null ? () => onRowTap!(row) : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: index.isEven
                                  ? colors.surfaceElevated
                                  : null,
                              border: Border(
                                bottom: BorderSide(color: colors.borderSubtle),
                              ),
                            ),
                            child: Row(
                              children: List.generate(
                                columns.length,
                                (colIndex) => Expanded(
                                  flex: columns[colIndex].flex,
                                  child: Align(
                                    alignment: columns[colIndex].alignment,
                                    child: cellBuilder(row, colIndex),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
        ),

        // Pagination
        if (hasPreviousPage || hasNextPage)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (totalLabel != null)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 16),
                    child: Text(
                      totalLabel!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.textMuted,
                      ),
                    ),
                  ),
                Builder(
                  builder: (context) {
                    final isRtl =
                        Directionality.of(context) == TextDirection.rtl;
                    return IconButton(
                      onPressed: hasPreviousPage ? onPreviousPage : null,
                      icon: Icon(
                        isRtl ? Icons.chevron_right : Icons.chevron_left,
                      ),
                      tooltip: 'admin.common.previous'.tr,
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '$currentPage',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                Builder(
                  builder: (context) {
                    final isRtl =
                        Directionality.of(context) == TextDirection.rtl;
                    return IconButton(
                      onPressed: hasNextPage ? onNextPage : null,
                      icon: Icon(
                        isRtl ? Icons.chevron_left : Icons.chevron_right,
                      ),
                      tooltip: 'admin.common.next_page'.tr,
                    );
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }
}
