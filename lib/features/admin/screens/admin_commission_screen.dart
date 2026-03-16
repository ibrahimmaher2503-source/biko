import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_button.dart';
import 'package:biko/core/widgets/app_card.dart';
import 'package:biko/core/widgets/app_loading.dart';
import 'package:biko/core/widgets/app_text_field.dart';
import 'package:biko/features/admin/controllers/admin_commission_controller.dart';
import 'package:biko/features/admin/models/finance/commission_rates_model.dart';
import 'package:biko/features/admin/widgets/stat_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Admin commission management screen with rate editor,
/// breakdown card, and collection history table.
class AdminCommissionScreen extends StatelessWidget {
  const AdminCommissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminCommissionController>();
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    final theme = Theme.of(context);
    final numberFormat = NumberFormat.currency(
      symbol: 'EGP ',
      decimalDigits: 2,
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Obx(() {
        if (controller.isLoading.value && controller.rates.value == null) {
          return const Center(child: AppLoading());
        }

        return RefreshIndicator(
          onRefresh: controller.loadData,
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
                      'admin.finance.commission_title'.tr,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: controller.loadData,
                      tooltip: 'admin.common.refresh'.tr,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Commission rates editor
                _buildRatesEditor(context, controller, colors, theme),
                const SizedBox(height: 24),

                // Commission breakdown
                _buildBreakdownCard(
                  context,
                  controller,
                  colors,
                  theme,
                  numberFormat,
                ),
                const SizedBox(height: 24),

                // Collection table
                _buildCollectionTable(
                  context,
                  controller,
                  colors,
                  theme,
                  numberFormat,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildRatesEditor(
    BuildContext context,
    AdminCommissionController controller,
    AppColorsExtension colors,
    ThemeData theme,
  ) {
    return Obx(() {
      final rates = controller.rates.value;
      if (rates == null) return const SizedBox.shrink();

      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.tune,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'admin.finance.commission_rates'.tr,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'admin.finance.rates_description'.tr,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.textMuted,
              ),
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 600;

                final items = [
                  _RateItem(
                    label: 'admin.finance.ride_rate'.tr,
                    value: rates.rideRate,
                    icon: Icons.directions_bike,
                    color: theme.colorScheme.primary,
                  ),
                  _RateItem(
                    label: 'admin.finance.c2c_rate'.tr,
                    value: rates.c2cRate,
                    icon: Icons.local_shipping,
                    color: colors.info,
                  ),
                  _RateItem(
                    label: 'admin.finance.b2b_rate'.tr,
                    value: rates.b2bDefaultRate,
                    icon: Icons.business,
                    color: colors.success,
                  ),
                ];

                if (isWide) {
                  return Row(
                    children: items
                        .map(
                          (item) => Expanded(
                            child: _buildRateDisplay(
                              item,
                              colors,
                              theme,
                            ),
                          ),
                        )
                        .toList(),
                  );
                }

                return Column(
                  children: items
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildRateDisplay(
                            item,
                            colors,
                            theme,
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 16),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: AppButton(
                text: 'admin.finance.edit_rates'.tr,
                leadingIcon: Icons.edit,
                onPressed: () =>
                    _showEditRatesDialog(context, controller, rates),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildRateDisplay(
    _RateItem item,
    AppColorsExtension colors,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusDefault),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusDefault),
            ),
            child: Icon(item.icon, size: 20, color: item.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(item.value * 100).toStringAsFixed(1)}%',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownCard(
    BuildContext context,
    AdminCommissionController controller,
    AppColorsExtension colors,
    ThemeData theme,
    NumberFormat numberFormat,
  ) {
    return Obx(() {
      final breakdown = controller.breakdown.value;
      if (breakdown == null) return const SizedBox.shrink();

      return LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount = 1;
          if (constraints.maxWidth > 800) {
            crossAxisCount = 3;
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
                titleKey: 'admin.finance.ride_commission',
                value: numberFormat.format(breakdown.rideCommission),
                iconColor: theme.colorScheme.primary,
              ),
              StatCard(
                icon: Icons.local_shipping,
                titleKey: 'admin.finance.c2c_commission',
                value: numberFormat.format(breakdown.c2cCommission),
                iconColor: colors.info,
              ),
              StatCard(
                icon: Icons.business,
                titleKey: 'admin.finance.b2b_commission',
                value: numberFormat.format(breakdown.b2bCommission),
                iconColor: colors.success,
              ),
            ],
          );
        },
      );
    });
  }

  Widget _buildCollectionTable(
    BuildContext context,
    AdminCommissionController controller,
    AppColorsExtension colors,
    ThemeData theme,
    NumberFormat numberFormat,
  ) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'admin.finance.commission_collection'.tr,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Obx(() {
            if (controller.collection.isEmpty) {
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

            return Column(
              children: [
                // Table header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainer,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppTheme.radiusDefault),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          'admin.finance.driver_name'.tr,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colors.textMuted,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'admin.finance.trip_count_label'.tr,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colors.textMuted,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'admin.finance.total_fare'.tr,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colors.textMuted,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'admin.finance.commission_collected'.tr,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ...controller.collection.map((item) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: colors.borderSubtle),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            item['driver_name'] as String? ?? '',
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${item['trip_count'] ?? 0}',
                          ),
                        ),
                        Expanded(
                          child: Text(
                            numberFormat.format(
                              (item['total_fare'] as num?)?.toDouble() ?? 0,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            numberFormat.format(
                              (item['commission'] as num?)?.toDouble() ?? 0,
                            ),
                            style: TextStyle(
                              color: colors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            );
          }),
        ],
      ),
    );
  }

  void _showEditRatesDialog(
    BuildContext context,
    AdminCommissionController controller,
    CommissionRatesModel currentRates,
  ) {
    final rideController = TextEditingController(
      text: (currentRates.rideRate * 100).toStringAsFixed(1),
    );
    final c2cController = TextEditingController(
      text: (currentRates.c2cRate * 100).toStringAsFixed(1),
    );
    final b2bController = TextEditingController(
      text: (currentRates.b2bDefaultRate * 100).toStringAsFixed(1),
    );

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
                  'admin.finance.edit_rates'.tr,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 24),
                AppTextField(
                  label: 'admin.finance.ride_rate_percent'.tr,
                  controller: rideController,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'admin.finance.c2c_rate_percent'.tr,
                  controller: c2cController,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'admin.finance.b2b_rate_percent'.tr,
                  controller: b2bController,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      width: 100,
                      child: AppButton(
                        text: 'common.cancel'.tr,
                        variant: ButtonVariant.text,
                        onPressed: () => Get.back<void>(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 120,
                      child: AppButton(
                        text: 'admin.common.save'.tr,
                        onPressed: () {
                          final newRates = CommissionRatesModel(
                            rideRate:
                                (double.tryParse(rideController.text) ?? 0) /
                                    100,
                            c2cRate:
                                (double.tryParse(c2cController.text) ?? 0) /
                                    100,
                            b2bDefaultRate:
                                (double.tryParse(b2bController.text) ?? 0) /
                                    100,
                          );
                          controller.updateRates(newRates);
                          Get.back<void>();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).then((_) {
      rideController.dispose();
      c2cController.dispose();
      b2bController.dispose();
    });
  }
}

class _RateItem {
  const _RateItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final double value;
  final IconData icon;
  final Color color;
}
