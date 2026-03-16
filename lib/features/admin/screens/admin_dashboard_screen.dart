import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_card.dart';
import 'package:biko/core/widgets/app_loading.dart';
import 'package:biko/features/admin/controllers/admin_dashboard_controller.dart';
import 'package:biko/features/admin/widgets/stat_card.dart';
import 'package:biko/features/admin/widgets/status_badge.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class AdminDashboardScreen extends GetView<AdminDashboardController> {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Obx(() {
        if (controller.isLoading.value &&
            controller.stats.value.tripsToday == 0) {
          return const Center(child: AppLoading());
        }

        return RefreshIndicator(
          onRefresh: controller.refreshDashboard,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Refresh button row
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Obx(
                    () => controller.isLoading.value
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: controller.refreshDashboard,
                            tooltip: 'admin.dashboard.refresh'.tr,
                          ),
                  ),
                ),

                // Stats Cards Grid
                _buildStatsGrid(context, colors),

                const SizedBox(height: 24),

                // Revenue Chart
                _buildRevenueChart(context, colors),

                const SizedBox(height: 24),

                // Recent Trips
                _buildRecentTrips(context, colors),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStatsGrid(BuildContext context, AppColorsExtension colors) {
    return Obx(() {
      final stats = controller.stats.value;

      return LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount = 1;
          if (constraints.maxWidth > 1200) {
            crossAxisCount = 4;
          } else if (constraints.maxWidth > 800) {
            crossAxisCount = 2;
          }

          return GridView.count(
            crossAxisCount: crossAxisCount,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: crossAxisCount == 1 ? 2.5 : 2.0,
            children: [
              StatCard(
                icon: Icons.directions_bike,
                titleKey: 'admin.dashboard.tripsToday',
                value: stats.tripsToday.toString(),
                iconColor: Theme.of(context).colorScheme.primary,
              ),
              StatCard(
                icon: Icons.attach_money,
                titleKey: 'admin.dashboard.revenueToday',
                value:
                    '${stats.revenueToday.toStringAsFixed(2)} ${'currency.egp'.tr}',
                iconColor: colors.success,
              ),
              StatCard(
                icon: Icons.person,
                titleKey: 'admin.dashboard.driversOnline',
                value: stats.driversOnline.toString(),
                iconColor: colors.info,
              ),
              StatCard(
                icon: Icons.pending_actions,
                titleKey: 'admin.dashboard.pendingReviews',
                value: stats.pendingReviews.toString(),
                iconColor: colors.warning,
              ),
            ],
          );
        },
      );
    });
  }

  Widget _buildRevenueChart(BuildContext context, AppColorsExtension colors) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'admin.dashboard.revenueChart'.tr,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Obx(() {
            if (controller.revenueChartData.isEmpty) {
              return const SizedBox(
                height: 250,
                child: Center(child: AppLoading()),
              );
            }

            return SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: colors.border.withValues(alpha: 0.3),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(),
                    topTitles: const AxisTitles(),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 5,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 &&
                              index < controller.revenueChartData.length) {
                            final date =
                                controller.revenueChartData[index].date;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                DateFormat('MM/dd').format(date),
                                style: TextStyle(
                                  color: colors.textMuted,
                                  fontSize: 10,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              color: colors.textMuted,
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: colors.border.withValues(alpha: 0.3),
                    ),
                  ),
                  minX: 0,
                  maxX: (controller.revenueChartData.length - 1).toDouble(),
                  minY: 0,
                  maxY: _getMaxY(),
                  lineBarsData: [
                    LineChartBarData(
                      spots: controller.revenueChartData
                          .asMap()
                          .entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value.value))
                          .toList(),
                      isCurved: true,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  double _getMaxY() {
    if (controller.revenueChartData.isEmpty) return 100;
    final maxValue = controller.revenueChartData
        .map((e) => e.value)
        .reduce((a, b) => a > b ? a : b);
    return (maxValue * 1.2).ceilToDouble();
  }

  Widget _buildRecentTrips(BuildContext context, AppColorsExtension colors) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'admin.dashboard.recentTrips'.tr,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Obx(() {
            if (controller.recentTrips.isEmpty) {
              return SizedBox(
                height: 200,
                child: Center(
                  child: Text(
                    'admin.dashboard.noTrips'.tr,
                    style: TextStyle(color: colors.textMuted),
                  ),
                ),
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth > 800;

                if (isDesktop) {
                  return Table(
                    columnWidths: const {
                      0: FlexColumnWidth(2),
                      1: FlexColumnWidth(2),
                      2: FlexColumnWidth(),
                      3: FlexColumnWidth(2),
                    },
                    border: TableBorder(
                      horizontalInside: BorderSide(
                        color: colors.border.withValues(alpha: 0.3),
                      ),
                    ),
                    children: [
                      TableRow(
                        decoration: BoxDecoration(
                          color: colors.surfaceContainer,
                        ),
                        children: [
                          _buildTableHeader(
                            'admin.dashboard.tripType'.tr,
                            colors,
                          ),
                          _buildTableHeader(
                            'admin.dashboard.status'.tr,
                            colors,
                          ),
                          _buildTableHeader('admin.dashboard.fare'.tr, colors),
                          _buildTableHeader('admin.dashboard.date'.tr, colors),
                        ],
                      ),
                      ...controller.recentTrips.map((trip) {
                        return TableRow(
                          children: [
                            _buildTableCell(trip.type.name.tr, colors),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 8,
                              ),
                              child: StatusBadge.fromTripStatus(trip.status),
                            ),
                            _buildTableCell(
                              '${(trip.acceptedPrice ?? trip.customerPrice).toStringAsFixed(2)} ${'currency.egp'.tr}',
                              colors,
                            ),
                            _buildTableCell(
                              DateFormat(
                                'yyyy-MM-dd HH:mm',
                              ).format(trip.createdAt),
                              colors,
                            ),
                          ],
                        );
                      }),
                    ],
                  );
                } else {
                  return Column(
                    children: controller.recentTrips.map((trip) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: colors.border.withValues(alpha: 0.3),
                          ),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusDefault,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  trip.type.name.tr,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                ),
                                StatusBadge.fromTripStatus(trip.status),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${(trip.acceptedPrice ?? trip.customerPrice).toStringAsFixed(2)} ${'currency.egp'.tr}',
                                  style: TextStyle(color: colors.textMuted),
                                ),
                                Text(
                                  DateFormat(
                                    'yyyy-MM-dd HH:mm',
                                  ).format(trip.createdAt),
                                  style: TextStyle(
                                    color: colors.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                }
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String text, AppColorsExtension colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildTableCell(String text, AppColorsExtension colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Text(text, style: TextStyle(color: colors.textMuted)),
    );
  }
}
