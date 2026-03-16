import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../controllers/admin_promos_controller.dart';
import '../utils/admin_status_colors.dart';
import '../widgets/admin_data_table.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/status_badge.dart';

class AdminPromosScreen extends GetView<AdminPromosController> {
  const AdminPromosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Obx(
                  () => DropdownButton<String>(
                    value: controller.statusFilter.value,
                    items: [
                      DropdownMenuItem(
                        value: 'all',
                        child: Text('admin.promos.filters.all'.tr),
                      ),
                      DropdownMenuItem(
                        value: 'active',
                        child: Text('admin.promos.filters.active'.tr),
                      ),
                      DropdownMenuItem(
                        value: 'expired',
                        child: Text('admin.promos.filters.expired'.tr),
                      ),
                      DropdownMenuItem(
                        value: 'inactive',
                        child: Text('admin.promos.filters.inactive'.tr),
                      ),
                      DropdownMenuItem(
                        value: 'exhausted',
                        child: Text('admin.promos.filters.exhausted'.tr),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        controller.statusFilter.value = value;
                        controller.loadPromos();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                AppButton(
                  text: 'admin.promos.create_new'.tr,
                  onPressed: () => _showCreatePromoDialog(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: Obx(
              () => AdminDataTable<Map<String, dynamic>>(
                isLoading: controller.isLoading.value,
                emptyWidget: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'admin.promos.no_promos'.tr,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(
                          context,
                        ).extension<AppColorsExtension>()!.textMuted,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      text: 'admin.promos.create_new'.tr,
                      onPressed: () => _showCreatePromoDialog(context),
                    ),
                  ],
                ),
                columns: [
                  AdminColumn(label: 'admin.promos.columns.code'.tr),
                  AdminColumn(label: 'admin.promos.columns.type'.tr),
                  AdminColumn(label: 'admin.promos.columns.value'.tr),
                  AdminColumn(label: 'admin.promos.columns.max_uses'.tr),
                  AdminColumn(label: 'admin.promos.columns.used_count'.tr),
                  AdminColumn(label: 'admin.promos.columns.min_trip_value'.tr),
                  AdminColumn(label: 'admin.promos.columns.expiry_date'.tr),
                  AdminColumn(label: 'admin.promos.columns.status'.tr),
                  AdminColumn(label: 'admin.promos.columns.actions'.tr),
                ],
                rows: controller.promos,
                cellBuilder: (promo, colIndex) {
                  final expiryDate = (promo['expiry_date'] as Timestamp?)
                      ?.toDate();
                  final type = promo['type'] as String? ?? '';
                  final value = promo['value'] as num? ?? 0;
                  final statusLabel = controller.getStatusLabel(promo);

                  switch (colIndex) {
                    case 0:
                      return Text(
                        promo['code'] as String? ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      );
                    case 1:
                      return _buildTypeBadge(context, type);
                    case 2:
                      return Text(
                        type == 'percentage'
                            ? '${value.toStringAsFixed(0)}%'
                            : '${value.toStringAsFixed(2)} ${'currency.egp'.tr}',
                      );
                    case 3:
                      return Text('${promo['max_uses'] ?? 0}');
                    case 4:
                      return Text('${promo['used_count'] ?? 0}');
                    case 5:
                      return Text('${promo['min_trip_value'] ?? 0} ${'currency.egp'.tr}');
                    case 6:
                      return Text(
                        expiryDate != null
                            ? DateFormat('yyyy-MM-dd').format(expiryDate)
                            : '-',
                      );
                    case 7:
                      return StatusBadge(
                        label: 'admin.promos.status.$statusLabel'.tr,
                        color: _getStatusColor(statusLabel),
                      );
                    case 8:
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: () =>
                                _showEditPromoDialog(context, promo),
                            tooltip: 'admin.promos.actions.edit'.tr,
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.block, size: 20),
                            onPressed: () =>
                                _showDeactivateConfirmDialog(context, promo),
                            tooltip: 'admin.promos.actions.deactivate'.tr,
                          ),
                        ],
                      );
                    default:
                      return const SizedBox.shrink();
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    return AdminStatusColors.statusColor(status);
  }

  Widget _buildTypeBadge(BuildContext context, String type) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    final color = type == 'percentage' ? colors.info : colors.success;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        'admin.promos.type.$type'.tr,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showCreatePromoDialog(BuildContext context) {
    final codeController = TextEditingController();
    final valueController = TextEditingController();
    final maxUsesController = TextEditingController();
    final minTripValueController = TextEditingController();
    final typeNotifier = ValueNotifier<String>('percentage');
    final expiryDateNotifier = ValueNotifier<DateTime?>(null);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('admin.promos.dialog.create_title'.tr),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: codeController,
                  decoration: InputDecoration(
                    labelText: 'admin.promos.dialog.code'.tr,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ValueListenableBuilder<String>(
                  valueListenable: typeNotifier,
                  builder: (context, type, _) =>
                      DropdownButtonFormField<String>(
                        initialValue: type,
                        decoration: InputDecoration(
                          labelText: 'admin.promos.dialog.type'.tr,
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'percentage',
                            child: Text('admin.promos.type.percentage'.tr),
                          ),
                          DropdownMenuItem(
                            value: 'fixed',
                            child: Text('admin.promos.type.fixed'.tr),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            typeNotifier.value = value;
                          }
                        },
                      ),
                ),
                const SizedBox(height: 16),
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
                        initialDate: DateTime.now().add(
                          const Duration(days: 30),
                        ),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
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
            text: 'admin.common.create'.tr,
            onPressed: () async {
              if (codeController.text.isEmpty ||
                  valueController.text.isEmpty ||
                  maxUsesController.text.isEmpty ||
                  minTripValueController.text.isEmpty ||
                  expiryDateNotifier.value == null) {
                Get.snackbar(
                  'admin.promos.error_title'.tr,
                  'admin.promos.dialog.fill_all_fields'.tr,
                  snackPosition: SnackPosition.BOTTOM,
                );
                return;
              }

              final parsedValue =
                  double.tryParse(valueController.text) ?? 0.0;
              final parsedMaxUses =
                  int.tryParse(maxUsesController.text) ?? 0;
              final parsedMinTripValue =
                  double.tryParse(minTripValueController.text) ?? 0.0;

              if (parsedValue == 0.0 ||
                  parsedMaxUses == 0 ||
                  parsedMinTripValue == 0.0) {
                AppSnackbar.warning(
                  'admin.promos.dialog.invalid_numeric_values'.tr,
                );
                return;
              }

              await controller.createPromo(
                code: codeController.text,
                type: typeNotifier.value,
                value: parsedValue,
                maxUses: parsedMaxUses,
                minTripValue: parsedMinTripValue,
                expiryDate: expiryDateNotifier.value!,
              );

              Get.back();
            },
          ),
        ],
      ),
    ).then((_) {
      codeController.dispose();
      valueController.dispose();
      maxUsesController.dispose();
      minTripValueController.dispose();
      typeNotifier.dispose();
      expiryDateNotifier.dispose();
    });
  }

  void _showEditPromoDialog(BuildContext context, Map<String, dynamic> promo) {
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
                        lastDate: DateTime.now().add(const Duration(days: 365)),
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
                await controller.editPromo(promo['code'] as String, updates);
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

  Future<void> _showDeactivateConfirmDialog(
    BuildContext context,
    Map<String, dynamic> promo,
  ) async {
    final confirmed = await ConfirmDialog.show(
      title: 'admin.promos.dialog.deactivate_title'.tr,
      message: 'admin.promos.dialog.deactivate_message'.trParams({
        'code': promo['code'] as String? ?? '',
      }),
      confirmLabel: 'admin.common.deactivate'.tr,
      cancelLabel: 'admin.common.cancel'.tr,
    );

    if (confirmed) {
      await controller.deactivatePromo(promo['code'] as String);
    }
  }
}
