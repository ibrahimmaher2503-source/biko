import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_card.dart';
import 'package:biko/core/widgets/app_empty_state.dart';
import 'package:biko/core/widgets/app_loading.dart';
import 'package:biko/features/driver_earnings/controllers/earnings_controller.dart';
import 'package:biko/features/driver_earnings/widgets/earnings_chart.dart';
import 'package:biko/features/driver_earnings/widgets/trip_earning_tile.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Screen showing driver earnings by period with chart and trip list.
///
/// Matches stitch design: tinted total earnings card with icon header,
/// styled bar chart, and clean trip earnings list.
class EarningsScreen extends GetView<EarningsController> {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = theme.extension<AppColorsExtension>()!;

    return Scaffold(
      appBar: AppBar(
        title: Text('earnings.title'.tr),
        centerTitle: false,
        bottom: TabBar(
          controller: controller.tabController,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: ext.textMuted,
          labelStyle: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          tabs: [
            Tab(text: 'earnings.today'.tr),
            Tab(text: 'earnings.this_week'.tr),
            Tab(text: 'earnings.this_month'.tr),
          ],
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: AppLoading());
        }

        return RefreshIndicator(
          onRefresh: controller.refresh,
          color: AppTheme.primary,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Total earnings card with icon header
              AppCard(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Icon header
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: ext.success.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.payments_rounded,
                          color: ext.success,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'earnings.total'.tr,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: ext.textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Obx(
                        () => Text(
                          '${controller.totalEarnings.value.toStringAsFixed(0)} ${'common.egp'.tr}',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: ext.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Chart
              Obx(
                () => controller.chartData.isNotEmpty
                    ? EarningsChart(
                        data: controller.chartData.toList(),
                        labels: controller.chartLabels.toList(),
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),

              // Trip list header with icon
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        AppTheme.radiusLarge,
                      ),
                    ),
                    child: const Icon(
                      Icons.list_alt_rounded,
                      color: AppTheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'earnings.trip_list'.tr,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Trip earnings list
              Obx(() {
                if (controller.transactions.isEmpty) {
                  return AppEmptyState(
                    icon: Icons.receipt_long,
                    title: 'earnings.no_earnings'.tr,
                    subtitle: 'earnings.no_earnings'.tr,
                  );
                }

                return Column(
                  children: controller.transactions
                      .map((txn) => TripEarningTile(transaction: txn))
                      .toList(),
                );
              }),
            ],
          ),
        );
      }),
    );
  }
}
