import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_card.dart';
import 'package:biko/core/widgets/app_loading.dart';
import 'package:biko/features/admin/controllers/admin_revenue_controller.dart';
import 'package:biko/features/admin/widgets/date_range_picker.dart';
import 'package:biko/features/admin/widgets/finance/revenue_chart.dart';
import 'package:biko/features/admin/widgets/stat_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Admin revenue analysis screen with charts for revenue by type,
/// hourly heatmap, zone breakdown, and forecast.
class AdminRevenueScreen extends StatelessWidget {
  const AdminRevenueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminRevenueController>();
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    final theme = Theme.of(context);
    final numberFormat = NumberFormat.currency(
      symbol: 'EGP ',
      decimalDigits: 2,
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Obx(() {
        if (controller.isLoading.value && controller.revenueData.isEmpty) {
          return const Center(child: AppLoading());
        }

        return RefreshIndicator(
          onRefresh: controller.loadRevenueData,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'admin.finance.revenue_title'.tr,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Obx(
                      () => AdminDateRangePicker(
                        selectedRange: controller.dateRange,
                        onRangeSelected: controller.filterByDate,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Revenue trend chart
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'admin.finance.revenue_trend'.tr,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Obx(() {
                        if (controller.revenueData.isEmpty) {
                          return SizedBox(
                            height: 300,
                            child: Center(
                              child: Text(
                                'admin.finance.no_data'.tr,
                                style: TextStyle(color: colors.textMuted),
                              ),
                            ),
                          );
                        }

                        return SizedBox(
                          height: 300,
                          child: RevenueChart(
                            data: controller.revenueData,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Revenue by type
                _buildRevenueByType(
                  context,
                  controller,
                  colors,
                  theme,
                  numberFormat,
                ),
                const SizedBox(height: 24),

                // Hourly heatmap
                _buildHourlyHeatmap(context, controller, colors, theme),
                const SizedBox(height: 24),

                // Revenue forecast placeholder
                _buildForecastCard(context, colors, theme),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildRevenueByType(
    BuildContext context,
    AdminRevenueController controller,
    AppColorsExtension colors,
    ThemeData theme,
    NumberFormat numberFormat,
  ) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'admin.finance.revenue_by_type'.tr,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Obx(() {
            if (controller.revenueByType.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'admin.finance.no_data'.tr,
                    style: TextStyle(color: colors.textMuted),
                  ),
                ),
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = 1;
                if (constraints.maxWidth > 800) {
                  crossAxisCount = 3;
                } else if (constraints.maxWidth > 500) {
                  crossAxisCount = 2;
                }

                final entries = controller.revenueByType.entries.toList();

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: crossAxisCount == 1 ? 2.5 : 2.0,
                  ),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return StatCard(
                      icon: _getServiceTypeIcon(entry.key),
                      titleKey: 'trip_type.${entry.key}',
                      value: numberFormat.format(entry.value),
                      iconColor: _getServiceTypeColor(
                        entry.key,
                        theme,
                        colors,
                      ),
                    );
                  },
                );
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHourlyHeatmap(
    BuildContext context,
    AdminRevenueController controller,
    AppColorsExtension colors,
    ThemeData theme,
  ) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'admin.finance.hourly_revenue'.tr,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Obx(() {
            if (controller.hourlyPattern.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'admin.finance.no_data'.tr,
                    style: TextStyle(color: colors.textMuted),
                  ),
                ),
              );
            }

            final maxValue = controller.hourlyPattern.values.isEmpty
                ? 1.0
                : controller.hourlyPattern.values
                    .reduce((a, b) => a > b ? a : b);

            return SizedBox(
              height: 200,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(24, (hour) {
                  final value =
                      controller.hourlyPattern[hour] ?? 0.0;
                  final ratio = maxValue > 0 ? value / maxValue : 0.0;

                  return Expanded(
                    child: Tooltip(
                      message: '$hour:00 - ${value.toStringAsFixed(0)} '
                          '${'currency.egp'.tr}',
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        height: (ratio * 180).clamp(4.0, 180.0),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.3 + (ratio * 0.7),
                          ),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
          const SizedBox(height: 8),
          // Hour labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '0:00',
                style: TextStyle(fontSize: 10, color: colors.textMuted),
              ),
              Text(
                '6:00',
                style: TextStyle(fontSize: 10, color: colors.textMuted),
              ),
              Text(
                '12:00',
                style: TextStyle(fontSize: 10, color: colors.textMuted),
              ),
              Text(
                '18:00',
                style: TextStyle(fontSize: 10, color: colors.textMuted),
              ),
              Text(
                '23:00',
                style: TextStyle(fontSize: 10, color: colors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildForecastCard(
    BuildContext context,
    AppColorsExtension colors,
    ThemeData theme,
  ) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights, color: colors.info, size: 24),
              const SizedBox(width: 8),
              Text(
                'admin.finance.revenue_forecast'.tr,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colors.infoBg,
              borderRadius: BorderRadius.circular(AppTheme.radiusDefault),
              border: Border.all(color: colors.infoBorder),
            ),
            child: Column(
              children: [
                Icon(Icons.auto_graph, size: 48, color: colors.info),
                const SizedBox(height: 12),
                Text(
                  'admin.finance.forecast_coming_soon'.tr,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colors.info,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'admin.finance.forecast_description'.tr,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getServiceTypeIcon(String type) {
    switch (type) {
      case 'ride':
        return Icons.directions_bike;
      case 'c2c':
        return Icons.local_shipping;
      case 'b2b':
        return Icons.business;
      default:
        return Icons.receipt;
    }
  }

  Color _getServiceTypeColor(
    String type,
    ThemeData theme,
    AppColorsExtension colors,
  ) {
    switch (type) {
      case 'ride':
        return theme.colorScheme.primary;
      case 'c2c':
        return colors.info;
      case 'b2b':
        return colors.success;
      default:
        return colors.warning;
    }
  }
}
