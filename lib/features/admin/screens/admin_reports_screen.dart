import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_button.dart';
import 'package:biko/core/widgets/app_card.dart';
import 'package:biko/core/widgets/app_empty_state.dart';
import 'package:biko/core/widgets/app_loading.dart';
import 'package:biko/features/admin/controllers/admin_reports_controller.dart';
import 'package:biko/features/admin/utils/admin_status_colors.dart';
import 'package:biko/features/admin/widgets/date_range_picker.dart';
import 'package:biko/features/admin/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Admin reports screen with report type selector, parameter form,
/// generation controls, scheduled reports, and download history.
class AdminReportsScreen extends StatelessWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminReportsController>();
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Obx(() {
        if (controller.isLoading.value &&
            controller.reportHistory.isEmpty) {
          return const Center(child: AppLoading());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'admin.finance.reports_title'.tr,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      AppButton(
                        text: 'admin.finance.schedule_report'.tr,
                        variant: ButtonVariant.outline,
                        leadingIcon: Icons.schedule,
                        onPressed: () => _showScheduleDialog(context),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Report type selector + parameters
              _buildReportGenerator(context, controller, colors, theme),
              const SizedBox(height: 24),

              // Scheduled reports
              _buildScheduledReports(
                context,
                controller,
                colors,
                theme,
              ),
              const SizedBox(height: 24),

              // Report history
              _buildReportHistory(context, controller, colors, theme),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildReportGenerator(
    BuildContext context,
    AdminReportsController controller,
    AppColorsExtension colors,
    ThemeData theme,
  ) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'admin.finance.generate_report'.tr,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Report type selector
          Text(
            'admin.finance.report_type'.tr,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Obx(
            () => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTypeChip(
                  'admin.finance.type_revenue'.tr,
                  'revenue',
                  Icons.attach_money,
                  controller,
                  theme,
                  colors,
                ),
                _buildTypeChip(
                  'admin.finance.type_commission'.tr,
                  'commission',
                  Icons.percent,
                  controller,
                  theme,
                  colors,
                ),
                _buildTypeChip(
                  'admin.finance.type_earnings'.tr,
                  'earnings',
                  Icons.payments,
                  controller,
                  theme,
                  colors,
                ),
                _buildTypeChip(
                  'admin.finance.type_transactions'.tr,
                  'transactions',
                  Icons.receipt_long,
                  controller,
                  theme,
                  colors,
                ),
                _buildTypeChip(
                  'admin.finance.type_settlements'.tr,
                  'settlements',
                  Icons.account_balance,
                  controller,
                  theme,
                  colors,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Date range
          Text(
            'admin.finance.date_range'.tr,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Obx(
            () => AdminDateRangePicker(
              selectedRange: controller.dateRange,
              onRangeSelected: (range) {
                controller.startDate.value = range.start;
                controller.endDate.value = range.end;
              },
            ),
          ),
          const SizedBox(height: 24),

          // Generate buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AppButton(
                text: 'admin.finance.generate_csv'.tr,
                variant: ButtonVariant.outline,
                leadingIcon: Icons.table_chart,
                onPressed: () => controller.generateReport(format: 'csv'),
              ),
              const SizedBox(width: 12),
              Obx(
                () => AppButton(
                  text: controller.isGenerating.value
                      ? 'admin.finance.generating'.tr
                      : 'admin.finance.generate_pdf'.tr,
                  leadingIcon: Icons.picture_as_pdf,
                  onPressed: controller.isGenerating.value
                      ? null
                      : () => controller.generateReport(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(
    String label,
    String type,
    IconData icon,
    AdminReportsController controller,
    ThemeData theme,
    AppColorsExtension colors,
  ) {
    final isSelected = controller.selectedType.value == type;

    return ChoiceChip(
      avatar: Icon(
        icon,
        size: 18,
        color: isSelected ? theme.colorScheme.primary : colors.textMuted,
      ),
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => controller.selectedType.value = type,
      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: isSelected ? theme.colorScheme.primary : colors.textMuted,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        fontSize: 13,
      ),
    );
  }

  Widget _buildScheduledReports(
    BuildContext context,
    AdminReportsController controller,
    AppColorsExtension colors,
    ThemeData theme,
  ) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'admin.finance.scheduled_reports'.tr,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Obx(() {
            if (controller.scheduledReports.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'admin.finance.no_scheduled_reports'.tr,
                    style: TextStyle(color: colors.textMuted),
                  ),
                ),
              );
            }

            return Column(
              children: controller.scheduledReports.map((schedule) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainer,
                    borderRadius: BorderRadius.circular(
                      AppTheme.radiusDefault,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 20,
                        color: colors.info,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'admin.finance.type_${schedule.reportType}'.tr,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${'admin.finance.frequency'.tr}: ${schedule.frequency}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      StatusBadge(
                        label: schedule.isActive
                            ? 'admin.finance.active'.tr
                            : 'admin.finance.inactive'.tr,
                        color: schedule.isActive
                            ? AdminStatusColors.success
                            : AdminStatusColors.neutral,
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildReportHistory(
    BuildContext context,
    AdminReportsController controller,
    AppColorsExtension colors,
    ThemeData theme,
  ) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'admin.finance.report_history'.tr,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Obx(() {
            if (controller.reportHistory.isEmpty) {
              return AppEmptyState(
                icon: Icons.description_outlined,
                title: 'admin.finance.no_reports'.tr,
              );
            }

            return Column(
              children: controller.reportHistory.map((report) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: colors.borderSubtle),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusDefault,
                          ),
                        ),
                        child: Icon(
                          _getReportIcon(report.type),
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              report.name,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${'admin.finance.generated_by'.tr}: '
                              '${report.generatedBy} - '
                              '${dateFormat.format(report.generatedAt)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.download, size: 20),
                        tooltip: 'admin.finance.download'.tr,
                        onPressed: () => controller.downloadReport(report),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }

  IconData _getReportIcon(String type) {
    switch (type) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'csv':
        return Icons.table_chart;
      default:
        return Icons.description;
    }
  }

  void _showScheduleDialog(BuildContext context) {
    // Placeholder for schedule report dialog
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'admin.finance.schedule_report'.tr,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .extension<AppColorsExtension>()!
                        .infoBg,
                    borderRadius: BorderRadius.circular(
                      AppTheme.radiusDefault,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.construction,
                        size: 48,
                        color: Theme.of(context)
                            .extension<AppColorsExtension>()!
                            .info,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'admin.finance.schedule_coming_soon'.tr,
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                          color: Theme.of(context)
                              .extension<AppColorsExtension>()!
                              .info,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: SizedBox(
                    width: 100,
                    child: AppButton(
                      text: 'common.close'.tr,
                      onPressed: () => Get.back<void>(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
