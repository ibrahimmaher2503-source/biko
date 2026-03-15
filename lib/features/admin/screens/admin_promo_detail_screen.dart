import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_button.dart';
import 'package:biko/core/widgets/app_card.dart';
import 'package:biko/core/widgets/app_empty_state.dart';
import 'package:biko/core/widgets/app_snackbar.dart';
import 'package:biko/features/admin/controllers/admin_promos_controller.dart';
import 'package:biko/features/admin/utils/admin_status_colors.dart';
import 'package:biko/features/admin/widgets/status_badge.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' hide TextDirection;

/// Admin screen showing detailed information about a single promo code,
/// including usage history and stats.
class AdminPromoDetailScreen extends StatelessWidget {
  const AdminPromoDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminPromosController>();
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    final theme = Theme.of(context);
    final numberFormat = NumberFormat.currency(
      symbol: 'EGP ',
      decimalDigits: 2,
    );

    // Get promo from route arguments
    final promo = Get.arguments as Map<String, dynamic>?;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: promo == null
          ? Center(
              child: AppEmptyState(
                icon: Icons.discount_outlined,
                title: 'admin.promos.not_found'.tr,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with back button
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Directionality.of(context) == TextDirection.rtl
                              ? Icons.arrow_forward
                              : Icons.arrow_back,
                        ),
                        onPressed: () => Get.back<void>(),
                        tooltip: 'common.back'.tr,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'admin.promos.detail_title'.tr,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      AppButton(
                        text: 'admin.promos.actions.edit'.tr,
                        variant: ButtonVariant.outline,
                        leadingIcon: Icons.edit,
                        onPressed: () => _showEditPromoDialog(
                          context,
                          promo,
                          controller,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Promo info card
                  _buildPromoInfoCard(
                    context,
                    promo,
                    colors,
                    theme,
                    numberFormat,
                    controller,
                  ),
                  const SizedBox(height: 24),

                  // Usage stats
                  _buildUsageStats(context, promo, colors, theme),
                  const SizedBox(height: 24),

                  // Usage history table
                  _buildUsageHistory(
                    context,
                    promo,
                    colors,
                    theme,
                    numberFormat,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPromoInfoCard(
    BuildContext context,
    Map<String, dynamic> promo,
    AppColorsExtension colors,
    ThemeData theme,
    NumberFormat numberFormat,
    AdminPromosController controller,
  ) {
    final expiryDate = (promo['expiry_date'] as Timestamp?)?.toDate();
    final type = promo['type'] as String? ?? '';
    final value = promo['value'] as num? ?? 0;
    final statusLabel = controller.getStatusLabel(promo);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(
                    AppTheme.radiusDefault,
                  ),
                ),
                child: Text(
                  promo['code'] as String? ?? '',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              StatusBadge(
                label: 'admin.promos.status.$statusLabel'.tr,
                color: _getStatusColor(statusLabel),
              ),
            ],
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;
              final items = [
                _buildDetailItem(
                  'admin.promos.columns.type'.tr,
                  'admin.promos.type.$type'.tr,
                  colors,
                  theme,
                ),
                _buildDetailItem(
                  'admin.promos.columns.value'.tr,
                  type == 'percentage'
                      ? '${value.toStringAsFixed(0)}%'
                      : numberFormat.format(value),
                  colors,
                  theme,
                ),
                _buildDetailItem(
                  'admin.promos.columns.min_trip_value'.tr,
                  '${promo['min_trip_value'] ?? 0} ${'currency.egp'.tr}',
                  colors,
                  theme,
                ),
                _buildDetailItem(
                  'admin.promos.columns.expiry_date'.tr,
                  expiryDate != null
                      ? DateFormat('yyyy-MM-dd').format(expiryDate)
                      : '-',
                  colors,
                  theme,
                ),
              ];

              if (isWide) {
                return Row(
                  children: items
                      .map(
                        (item) => Expanded(child: item),
                      )
                      .toList(),
                );
              }

              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: items,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(
    String label,
    String value,
    AppColorsExtension colors,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageStats(
    BuildContext context,
    Map<String, dynamic> promo,
    AppColorsExtension colors,
    ThemeData theme,
  ) {
    final usedCount = promo['used_count'] as int? ?? 0;
    final maxUses = promo['max_uses'] as int? ?? 0;
    final percentage = maxUses > 0 ? (usedCount / maxUses) : 0.0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'admin.promos.usage_stats'.tr,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'admin.promos.columns.used_count'.tr,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$usedCount / $maxUses',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'admin.promos.usage_rate'.tr,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.textMuted,
                          ),
                        ),
                        Text(
                          '${(percentage * 100).toStringAsFixed(1)}%',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(
                        AppTheme.radiusFull,
                      ),
                      child: LinearProgressIndicator(
                        value: percentage.clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: colors.surfaceContainer,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          percentage > 0.8
                              ? colors.warning
                              : colors.success,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUsageHistory(
    BuildContext context,
    Map<String, dynamic> promo,
    AppColorsExtension colors,
    ThemeData theme,
    NumberFormat numberFormat,
  ) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'admin.promos.usage_history'.tr,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // Placeholder table showing usage history pattern
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: colors.borderSubtle),
              borderRadius: BorderRadius.circular(AppTheme.radiusDefault),
            ),
            child: Column(
              children: [
                // Table header
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
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          'admin.promos.history.user'.tr,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colors.textMuted,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'admin.promos.history.discount'.tr,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colors.textMuted,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'admin.promos.history.trip_value'.tr,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colors.textMuted,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'admin.promos.history.date'.tr,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Empty state
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'admin.promos.no_usage_history'.tr,
                      style: TextStyle(color: colors.textMuted),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditPromoDialog(
    BuildContext context,
    Map<String, dynamic> promo,
    AdminPromosController controller,
  ) {
    final valueController = TextEditingController(
      text: (promo['value'] as num?)?.toString() ?? '',
    );
    final maxUsesController = TextEditingController(
      text: (promo['max_uses'] as int?)?.toString() ?? '',
    );
    final minTripValueController = TextEditingController(
      text: (promo['min_trip_value'] as num?)?.toString() ?? '',
    );
    final expiryDateNotifier = ValueNotifier<DateTime?>(
      (promo['expiry_date'] as Timestamp?)?.toDate(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('admin.promos.dialog.edit_title'.tr),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: valueController,
                  decoration: InputDecoration(
                    labelText: 'admin.promos.dialog.value'.tr,
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: maxUsesController,
                  decoration: InputDecoration(
                    labelText: 'admin.promos.dialog.max_uses'.tr,
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: minTripValueController,
                  decoration: InputDecoration(
                    labelText: 'admin.promos.dialog.min_trip_value'.tr,
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                ValueListenableBuilder<DateTime?>(
                  valueListenable: expiryDateNotifier,
                  builder: (context, date, _) => InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate:
                            date ??
                            DateTime.now().add(const Duration(days: 30)),
                        firstDate: DateTime.now(),
                        lastDate:
                            DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        expiryDateNotifier.value = picked;
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'admin.promos.dialog.expiry_date'.tr,
                        border: const OutlineInputBorder(),
                      ),
                      child: Text(
                        date != null
                            ? DateFormat('yyyy-MM-dd').format(date)
                            : 'admin.promos.dialog.select_date'.tr,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          AppButton(
            text: 'admin.common.cancel'.tr,
            onPressed: Get.back,
            variant: ButtonVariant.text,
          ),
          AppButton(
            text: 'admin.common.save'.tr,
            onPressed: () async {
              final updates = <String, dynamic>{};

              if (valueController.text.isNotEmpty) {
                final parsedValue =
                    double.tryParse(valueController.text);
                if (parsedValue == null) {
                  AppSnackbar.warning(
                    'admin.promos.dialog.invalid_numeric_values'.tr,
                  );
                  return;
                }
                updates['value'] = parsedValue;
              }
              if (maxUsesController.text.isNotEmpty) {
                final parsedMaxUses =
                    int.tryParse(maxUsesController.text);
                if (parsedMaxUses == null) {
                  AppSnackbar.warning(
                    'admin.promos.dialog.invalid_numeric_values'.tr,
                  );
                  return;
                }
                updates['max_uses'] = parsedMaxUses;
              }
              if (minTripValueController.text.isNotEmpty) {
                final parsedMinTripValue =
                    double.tryParse(minTripValueController.text);
                if (parsedMinTripValue == null) {
                  AppSnackbar.warning(
                    'admin.promos.dialog.invalid_numeric_values'.tr,
                  );
                  return;
                }
                updates['min_trip_value'] = parsedMinTripValue;
              }
              if (expiryDateNotifier.value != null) {
                updates['expiry_date'] = expiryDateNotifier.value;
              }

              if (updates.isNotEmpty) {
                await controller.editPromo(
                  promo['code'] as String,
                  updates,
                );
              }

              Get.back();
            },
          ),
        ],
      ),
    ).then((_) {
      valueController.dispose();
      maxUsesController.dispose();
      minTripValueController.dispose();
      expiryDateNotifier.dispose();
    });
  }

  Color _getStatusColor(String status) {
    return AdminStatusColors.statusColor(status);
  }
}
