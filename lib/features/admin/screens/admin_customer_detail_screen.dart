import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_button.dart';
import 'package:biko/core/widgets/app_card.dart';
import 'package:biko/core/widgets/app_loading.dart';
import 'package:biko/core/widgets/app_text_field.dart';
import 'package:biko/features/admin/controllers/admin_users_controller.dart';
import 'package:biko/features/admin/widgets/confirm_dialog.dart';
import 'package:biko/features/admin/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' hide TextDirection;

/// Admin Customer Detail Screen (US5)
///
/// Displays customer profile, wallet, recent trips, and actions.
class AdminCustomerDetailScreen extends GetView<AdminUsersController> {
  const AdminCustomerDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;
    final uid = Get.arguments as String;

    // Load user detail on screen init
    controller.loadUserDetail(uid);

    return Scaffold(
      appBar: AppBar(
        title: Text('admin.users.customer_detail_title'.tr),
        leading: IconButton(
          icon: Icon(
            Directionality.of(context) == TextDirection.rtl
                ? Icons.arrow_forward
                : Icons.arrow_back,
          ),
          onPressed: Get.back,
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value &&
            controller.selectedUser.value == null) {
          return const Center(child: AppLoading());
        }

        final user = controller.selectedUser.value;
        if (user == null) {
          return Center(
            child: Text(
              'admin.users.user_not_found'.tr,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colors.textMuted,
              ),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Card
              _buildProfileCard(context, theme, colors, user),
              const SizedBox(height: 24),

              // Wallet Card
              _buildWalletCard(context, theme, colors, user),
              const SizedBox(height: 24),

              // Recent Trips Card
              _buildRecentTripsCard(context, theme, colors),
              const SizedBox(height: 24),

              // Actions Card
              _buildActionsCard(context, theme, colors, user),
            ],
          ),
        );
      }),
    );
  }

  /// Build profile card
  Widget _buildProfileCard(
    BuildContext context,
    ThemeData theme,
    AppColorsExtension colors,
    user,
  ) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 40,
                backgroundColor: colors.surfaceContainer,
                backgroundImage: user.avatarUrl != null
                    ? NetworkImage(user.avatarUrl!)
                    : null,
                child: user.avatarUrl == null
                    ? Icon(Icons.person, size: 40, color: colors.textMuted)
                    : null,
              ),
              const SizedBox(width: 16),

              // Name and status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 4),
                    StatusBadge.fromUserStatus(user.status),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),

          // Details
          _buildDetailRow(
            theme,
            colors,
            'admin.users.detail_phone'.tr,
            user.phone,
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            theme,
            colors,
            'admin.users.detail_email'.tr,
            user.email ?? 'admin.users.detail_no_email'.tr,
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            theme,
            colors,
            'admin.users.detail_created'.tr,
            DateFormat('dd MMM yyyy, HH:mm').format(user.createdAt),
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            theme,
            colors,
            'admin.users.detail_referral_code'.tr,
            user.referralCode.isEmpty
                ? 'admin.users.detail_no_referral'.tr
                : user.referralCode,
          ),
        ],
      ),
    );
  }

  /// Build wallet card
  Widget _buildWalletCard(
    BuildContext context,
    ThemeData theme,
    AppColorsExtension colors,
    user,
  ) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'admin.users.wallet_title'.tr,
                style: theme.textTheme.titleMedium,
              ),
              AppButton(
                text: 'admin.users.wallet_adjust_button'.tr,
                onPressed: () => _showAdjustWalletDialog(context),
                variant: ButtonVariant.outline,
                width: 150,
                height: 40,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          _buildDetailRow(
            theme,
            colors,
            'admin.users.wallet_balance'.tr,
            '${user.walletBalance.toStringAsFixed(2)} ${'currency.egp'.tr}',
            valueColor: user.walletBalance >= 0
                ? colors.success
                : theme.colorScheme.error,
          ),
        ],
      ),
    );
  }

  /// Build recent trips card
  Widget _buildRecentTripsCard(
    BuildContext context,
    ThemeData theme,
    AppColorsExtension colors,
  ) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'admin.users.recent_trips_title'.tr,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          if (controller.selectedUserTrips.isEmpty)
            Text(
              'admin.users.no_trips'.tr,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.textMuted,
              ),
            )
          else
            ...controller.selectedUserTrips
                .take(10)
                .map((trip) => _buildTripRow(theme, colors, trip)),
        ],
      ),
    );
  }

  /// Build trip row
  Widget _buildTripRow(ThemeData theme, AppColorsExtension colors, trip) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.borderSubtle)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trip.type.toJson().replaceAll('_', ' ').toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd MMM yyyy').format(trip.createdAt),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Expanded(child: StatusBadge.fromTripStatus(trip.status)),
          Expanded(
            child: Text(
              '${trip.finalPrice.toStringAsFixed(2)} ${'currency.egp'.tr}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  /// Build actions card
  Widget _buildActionsCard(
    BuildContext context,
    ThemeData theme,
    AppColorsExtension colors,
    user,
  ) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'admin.users.actions_title'.tr,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          if (user.status.toJson() == 'suspended')
            AppButton(
              text: 'admin.users.action_activate'.tr,
              onPressed: () => _handleActivateUser(context, user.uid),
            )
          else
            AppButton(
              text: 'admin.users.action_suspend'.tr,
              onPressed: () => _handleSuspendUser(context, user.uid),
              variant: ButtonVariant.outline,
            ),
        ],
      ),
    );
  }

  /// Build detail row
  Widget _buildDetailRow(
    ThemeData theme,
    AppColorsExtension colors,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 150,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.textMuted,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }

  /// Show adjust wallet dialog
  void _showAdjustWalletDialog(BuildContext context) {
    final theme = Theme.of(context);
    final amountController = TextEditingController();
    final reasonController = TextEditingController();

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'admin.users.wallet_adjust_title'.tr,
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 24),
                AppTextField(
                  controller: amountController,
                  label: 'admin.users.wallet_amount_label'.tr,
                  hint: 'admin.users.wallet_amount_hint'.tr,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  prefixIcon: Icons.attach_money,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: reasonController,
                  label: 'admin.users.wallet_reason_label'.tr,
                  hint: 'admin.users.wallet_reason_hint'.tr,
                  maxLines: 3,
                  prefixIcon: Icons.notes,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      width: 100,
                      child: AppButton(
                        text: 'common.cancel'.tr,
                        onPressed: Get.back,
                        variant: ButtonVariant.text,
                        height: 40,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 120,
                      child: AppButton(
                        text: 'common.confirm'.tr,
                        onPressed: () {
                          final amount = double.tryParse(amountController.text);
                          final reason = reasonController.text.trim();

                          if (amount == null || reason.isEmpty) {
                            return;
                          }

                          Get.back();
                          controller.adjustWallet(
                            controller.selectedUser.value!.uid,
                            amount,
                            reason,
                          );
                        },
                        height: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Handle suspend user
  Future<void> _handleSuspendUser(BuildContext context, String uid) async {
    final reasonController = TextEditingController();

    final confirmed = await Get.dialog<dynamic>(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'admin.users.suspend_confirm_title'.tr,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: reasonController,
                  label: 'admin.users.suspend_reason_label'.tr,
                  hint: 'admin.users.suspend_reason_hint'.tr,
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      width: 100,
                      child: AppButton(
                        text: 'common.cancel'.tr,
                        onPressed: () => Get.back(result: false),
                        variant: ButtonVariant.text,
                        height: 40,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 120,
                      child: AppButton(
                        text: 'admin.users.action_suspend'.tr,
                        onPressed: () {
                          final reason = reasonController.text.trim();
                          if (reason.isNotEmpty) {
                            Get.back(result: reason);
                          }
                        },
                        height: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (confirmed is String && confirmed.isNotEmpty) {
      await controller.suspendUser(uid, confirmed);
    }
  }

  /// Handle activate user
  Future<void> _handleActivateUser(BuildContext context, String uid) async {
    final confirmed = await ConfirmDialog.show(
      title: 'admin.users.activate_confirm_title'.tr,
      message: 'admin.users.activate_confirm_message'.tr,
      confirmLabel: 'admin.users.action_activate'.tr,
    );

    if (confirmed) {
      await controller.activateUser(uid);
    }
  }
}
