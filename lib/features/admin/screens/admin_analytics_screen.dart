import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_loading.dart';
import '../controllers/admin_analytics_controller.dart';

class AdminAnalyticsScreen extends GetView<AdminAnalyticsController> {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;
    final currencyFormat = NumberFormat.currency(
      symbol: 'EGP ',
      decimalDigits: 2,
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('admin.analytics.title'.tr),
        backgroundColor: colors.surfaceContainer,
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 16),
            child: AppButton(
              text: 'admin.analytics.export_report'.tr,
              onPressed: controller.exportReport,
              variant: ButtonVariant.outline,
            ),
          ),
        ],
      ),
      body: Obx(
        () => controller.isLoading.value
            ? const Center(child: AppLoading())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Period Selector
                    Center(
                      child: ToggleButtons(
                        isSelected: [
                          controller.selectedPeriod.value == 7,
                          controller.selectedPeriod.value == 30,
                          controller.selectedPeriod.value == 90,
                        ],
                        onPressed: (index) {
                          final periods = [7, 30, 90];
                          controller.loadAllCharts(periods[index]);
                        },
                        borderRadius: BorderRadius.circular(8),
                        selectedColor: theme.colorScheme.onPrimary,
                        fillColor: theme.colorScheme.primary,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            child: Text('admin.analytics.7_days'.tr),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            child: Text('admin.analytics.30_days'.tr),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            child: Text('admin.analytics.90_days'.tr),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Trip Volume Chart
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'admin.analytics.trip_volume'.tr,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 300,
                            child: controller.tripVolumeData.isEmpty
                                ? Center(
                                    child: Text('admin.analytics.no_data'.tr),
                                  )
                                : BarChart(
                                    BarChartData(
                                      alignment: BarChartAlignment.spaceAround,
                                      maxY: controller.tripVolumeData
                                          .map((e) => e.value)
                                          .reduce((a, b) => a > b ? a : b)
                                          .ceilToDouble(),
                                      barTouchData: const BarTouchData(
                                        enabled: true,
                                      ),
                                      titlesData: FlTitlesData(
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            getTitlesWidget: (value, meta) {
                                              if (value.toInt() >= 0 &&
                                                  value.toInt() <
                                                      controller
                                                          .tripVolumeData
                                                          .length) {
                                                final date = DateTime.parse(
                                                  controller
                                                      .tripVolumeData[value
                                                          .toInt()]
                                                      .label!,
                                                );
                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 8,
                                                      ),
                                                  child: Text(
                                                    DateFormat(
                                                      'MM/dd',
                                                    ).format(date),
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                );
                                              }
                                              return const Text('');
                                            },
                                          ),
                                        ),
                                        leftTitles: const AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: 40,
                                          ),
                                        ),
                                        topTitles: const AxisTitles(),
                                        rightTitles: const AxisTitles(),
                                      ),
                                      borderData: FlBorderData(show: false),
                                      barGroups: controller.tripVolumeData
                                          .asMap()
                                          .entries
                                          .map((entry) {
                                            final index = entry.key;
                                            final data = entry.value;
                                            final ride =
                                                data.extraData?['ride'] ?? 0.0;
                                            final c2c =
                                                data.extraData?['c2c_delivery'] ??
                                                0.0;
                                            final b2b =
                                                data.extraData?['b2b_delivery'] ??
                                                0.0;

                                            return BarChartGroupData(
                                              x: index,
                                              barRods: [
                                                BarChartRodData(
                                                  toY: data.value,
                                                  rodStackItems: [
                                                    BarChartRodStackItem(
                                                      0,
                                                      ride,
                                                      theme.colorScheme.primary,
                                                    ),
                                                    BarChartRodStackItem(
                                                      ride,
                                                      ride + c2c,
                                                      theme
                                                          .colorScheme
                                                          .secondary,
                                                    ),
                                                    BarChartRodStackItem(
                                                      ride + c2c,
                                                      ride + c2c + b2b,
                                                      theme
                                                          .colorScheme
                                                          .tertiary,
                                                    ),
                                                  ],
                                                  borderRadius:
                                                      const BorderRadius.vertical(
                                                        top: Radius.circular(4),
                                                      ),
                                                ),
                                              ],
                                            );
                                          })
                                          .toList(),
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 16),
                          // Legend
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildLegendItem(
                                theme.colorScheme.primary,
                                'admin.analytics.ride'.tr,
                              ),
                              const SizedBox(width: 16),
                              _buildLegendItem(
                                theme.colorScheme.secondary,
                                'admin.analytics.c2c_delivery'.tr,
                              ),
                              const SizedBox(width: 16),
                              _buildLegendItem(
                                theme.colorScheme.tertiary,
                                'admin.analytics.b2b_delivery'.tr,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Payment Method Breakdown
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'admin.analytics.payment_breakdown'.tr,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 300,
                            child: controller.paymentBreakdown.isEmpty
                                ? Center(
                                    child: Text('admin.analytics.no_data'.tr),
                                  )
                                : Row(
                                    children: [
                                      Expanded(
                                        child: PieChart(
                                          PieChartData(
                                            sections: _buildPieChartSections(
                                              theme,
                                              colors,
                                            ),
                                            sectionsSpace: 2,
                                            centerSpaceRadius: 60,
                                            borderData: FlBorderData(
                                              show: false,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 24),
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: _buildPaymentLegend(
                                          theme,
                                          colors,
                                          currencyFormat,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Cancellation Rate Trend
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'admin.analytics.cancellation_trend'.tr,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 250,
                            child: controller.cancellationTrend.isEmpty
                                ? Center(
                                    child: Text('admin.analytics.no_data'.tr),
                                  )
                                : LineChart(
                                    LineChartData(
                                      titlesData: FlTitlesData(
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            getTitlesWidget: (value, meta) {
                                              if (value.toInt() >= 0 &&
                                                  value.toInt() <
                                                      controller
                                                          .cancellationTrend
                                                          .length) {
                                                final date = DateTime.parse(
                                                  controller
                                                      .cancellationTrend[value
                                                          .toInt()]
                                                      .label!,
                                                );
                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 8,
                                                      ),
                                                  child: Text(
                                                    DateFormat(
                                                      'MM/dd',
                                                    ).format(date),
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                );
                                              }
                                              return const Text('');
                                            },
                                          ),
                                        ),
                                        leftTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: 40,
                                            getTitlesWidget: (value, meta) {
                                              return Text('${value.toInt()}%');
                                            },
                                          ),
                                        ),
                                        topTitles: const AxisTitles(),
                                        rightTitles: const AxisTitles(),
                                      ),
                                      borderData: FlBorderData(show: true),
                                      lineBarsData: [
                                        LineChartBarData(
                                          spots: controller.cancellationTrend
                                              .asMap()
                                              .entries
                                              .map(
                                                (e) => FlSpot(
                                                  e.key.toDouble(),
                                                  e.value.value,
                                                ),
                                              )
                                              .toList(),
                                          isCurved: true,
                                          color: theme.colorScheme.error,
                                          barWidth: 3,
                                          belowBarData: BarAreaData(
                                            show: true,
                                            color: theme.colorScheme.error
                                                .withValues(alpha: 0.1),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Top Drivers
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'admin.analytics.top_drivers'.tr,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (controller.topDrivers.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text('admin.analytics.no_data'.tr),
                              ),
                            )
                          else
                            DataTable(
                              columns: [
                                DataColumn(
                                  label: Text('admin.analytics.rank'.tr),
                                ),
                                DataColumn(
                                  label: Text('admin.analytics.driver_name'.tr),
                                ),
                                DataColumn(
                                  label: Text('admin.analytics.trips'.tr),
                                ),
                                DataColumn(
                                  label: Text('admin.analytics.earnings'.tr),
                                ),
                                DataColumn(
                                  label: Text('admin.analytics.rating'.tr),
                                ),
                              ],
                              rows: controller.topDrivers.asMap().entries.map((
                                entry,
                              ) {
                                final index = entry.key;
                                final driver = entry.value;

                                return DataRow(
                                  onSelectChanged: (_) {
                                    Get.toNamed(
                                      AppRoutes.adminDriverDetail,
                                      arguments: {'uid': driver['uid']},
                                    );
                                  },
                                  cells: [
                                    DataCell(Text('${index + 1}')),
                                    DataCell(Text(driver['name'] as String)),
                                    DataCell(Text('${driver['trips']}')),
                                    DataCell(
                                      Text(
                                        currencyFormat.format(
                                          driver['earnings'] as double,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.star,
                                            color: Colors.amber,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            (driver['rating'] as double)
                                                .toStringAsFixed(1),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }

  List<PieChartSectionData> _buildPieChartSections(
    ThemeData theme,
    AppColorsExtension colors,
  ) {
    final total = controller.paymentBreakdown.values.fold<double>(
      0.0,
      (a, b) => a + b,
    );
    if (total == 0) return [];

    final colorMap = {
      'cash': theme.colorScheme.primary,
      'wallet': theme.colorScheme.secondary,
      'card': theme.colorScheme.tertiary,
      'vodafone_cash': colors.success,
      'fawry': colors.warning,
    };

    return controller.paymentBreakdown.entries.map((entry) {
      final percentage = (entry.value / total) * 100;
      return PieChartSectionData(
        value: entry.value,
        title: '${percentage.toStringAsFixed(1)}%',
        color: colorMap[entry.key] ?? theme.colorScheme.primary,
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  List<Widget> _buildPaymentLegend(
    ThemeData theme,
    AppColorsExtension colors,
    NumberFormat currencyFormat,
  ) {
    final colorMap = {
      'cash': theme.colorScheme.primary,
      'wallet': theme.colorScheme.secondary,
      'card': theme.colorScheme.tertiary,
      'vodafone_cash': colors.success,
      'fawry': colors.warning,
    };

    final labelMap = {
      'cash': 'admin.analytics.cash'.tr,
      'wallet': 'admin.analytics.wallet'.tr,
      'card': 'admin.analytics.card'.tr,
      'vodafone_cash': 'admin.analytics.vodafone_cash'.tr,
      'fawry': 'admin.analytics.fawry'.tr,
    };

    return controller.paymentBreakdown.entries.map((entry) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: colorMap[entry.key] ?? theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${labelMap[entry.key]}: ${currencyFormat.format(entry.value)}',
            ),
          ],
        ),
      );
    }).toList();
  }
}
