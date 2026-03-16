import 'package:biko/core/models/enums.dart';
import 'package:biko/core/models/user_model.dart';
import 'package:biko/core/routes/app_routes.dart';
import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/features/admin/controllers/admin_users_controller.dart';
import 'package:biko/features/admin/widgets/admin_data_table.dart';
import 'package:biko/features/admin/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Admin Customers List Screen (US5)
///
/// Displays paginated customer list with search and status filter.
class AdminCustomersScreen extends GetView<AdminUsersController> {
  const AdminCustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;

    return Scaffold(
      appBar: AppBar(title: Text('admin.users.customers_title'.tr)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Obx(
          () => AdminDataTable<UserModel>(
            columns: [
              AdminColumn(label: 'admin.users.column_name'.tr, flex: 2),
              AdminColumn(label: 'admin.users.column_phone'.tr, flex: 2),
              AdminColumn(label: 'admin.users.column_status'.tr),
              AdminColumn(
                label: 'admin.users.column_wallet'.tr,
                alignment: AlignmentDirectional.centerEnd,
              ),
              AdminColumn(label: 'admin.users.column_created'.tr, flex: 2),
            ],
            rows: controller.customers,
            cellBuilder: (user, columnIndex) {
              switch (columnIndex) {
                case 0:
                  return Text(
                    user.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  );
                case 1:
                  return Text(user.phone, style: theme.textTheme.bodyMedium);
                case 2:
                  return StatusBadge.fromUserStatus(user.status);
                case 3:
                  return Text(
                    '${user.walletBalance.toStringAsFixed(2)} ${'currency.egp'.tr}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: user.walletBalance >= 0
                          ? colors.success
                          : theme.colorScheme.error,
                    ),
                    textAlign: TextAlign.end,
                  );
                case 4:
                  return Text(
                    DateFormat('dd MMM yyyy, HH:mm').format(user.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.textMuted,
                    ),
                  );
                default:
                  return const SizedBox.shrink();
              }
            },
            searchHint: 'admin.users.search_hint'.tr,
            onSearch: (query) => controller.searchCustomers(query),
            filterWidgets: [_buildStatusFilter(theme, colors)],
            onRowTap: (user) {
              Get.toNamed(AppRoutes.adminCustomerDetail, arguments: user.uid);
            },
            isLoading: controller.isLoading.value,
            emptyMessage: 'admin.users.no_customers'.tr,
            hasNextPage: controller.hasMore.value,
            hasPreviousPage: controller.currentPage.value > 1,
            onNextPage: controller.nextPage,
            onPreviousPage: controller.previousPage,
            currentPage: controller.currentPage.value,
            totalLabel: 'admin.users.total_customers'.tr.replaceAll(
              '{count}',
              controller.customers.length.toString(),
            ),
          ),
        ),
      ),
    );
  }

  /// Build status filter dropdown
  Widget _buildStatusFilter(ThemeData theme, AppColorsExtension colors) {
    return Obx(
      () => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colors.surfaceElevated,
          border: Border.all(color: colors.border),
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        ),
        child: DropdownButton<UserStatus?>(
          value: controller.statusFilter.value,
          underline: const SizedBox.shrink(),
          icon: const Icon(Icons.arrow_drop_down, size: 20),
          items: [
            DropdownMenuItem<UserStatus?>(
              child: Text(
                'admin.users.filter_all'.tr,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            DropdownMenuItem<UserStatus?>(
              value: UserStatus.active,
              child: Text(
                'admin.users.filter_active'.tr,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            DropdownMenuItem<UserStatus?>(
              value: UserStatus.suspended,
              child: Text(
                'admin.users.filter_suspended'.tr,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            DropdownMenuItem<UserStatus?>(
              value: UserStatus.pendingApproval,
              child: Text(
                'admin.users.filter_pending'.tr,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
          onChanged: (status) => controller.filterByStatus(status),
        ),
      ),
    );
  }
}
