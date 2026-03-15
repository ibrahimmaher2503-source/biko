import 'package:biko/core/routes/app_routes.dart';
import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/features/admin/controllers/admin_auth_controller.dart';
import 'package:biko/features/admin/controllers/admin_layout_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Top bar with section title, search placeholder, admin info, and logout.
class AdminTopbar extends StatelessWidget {
  const AdminTopbar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;
    final layout = Get.find<AdminLayoutController>();
    final auth = Get.find<AdminAuthController>();

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        border: Border(bottom: BorderSide(color: colors.borderSubtle)),
      ),
      child: Row(
        children: [
          // Hamburger menu for mobile
          Obx(() {
            if (!layout.isMobile) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            );
          }),

          // Section title
          Obx(() {
            final route = layout.currentRoute.value;
            final titleKey = _routeToTitle(route);
            return Text(titleKey.tr, style: theme.textTheme.titleLarge);
          }),

          Expanded(
            child: Obx(() {
              if (layout.isMobile) return const SizedBox.shrink();
              return Align(
                alignment: AlignmentDirectional.centerEnd,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 280),
                  child: SizedBox(
                    height: 40,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'admin.search.placeholder'.tr,
                        prefixIcon: const Icon(Icons.search, size: 20),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusFull,
                          ),
                          borderSide: BorderSide(color: colors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusFull,
                          ),
                          borderSide: BorderSide(color: colors.border),
                        ),
                        filled: true,
                        fillColor: colors.surfaceContainer,
                      ),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(width: 16),

          // Language toggle
          IconButton(
            icon: Text(
              Get.locale?.languageCode == 'ar' ? 'EN' : 'AR',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            tooltip: 'admin.topbar.toggle_language'.tr,
            onPressed: () {
              final newLocale = Get.locale?.languageCode == 'ar'
                  ? const Locale('en')
                  : const Locale('ar');
              Get.updateLocale(newLocale);
            },
          ),

          const SizedBox(width: 8),

          // Admin info + logout
          Obx(() {
            final admin = auth.adminUser.value;
            if (admin == null) return const SizedBox.shrink();

            final displayLabel =
                (admin.displayName?.isNotEmpty ?? false)
                    ? admin.displayName!
                    : admin.email;
            final initial =
                displayLabel.isNotEmpty
                    ? displayLabel.substring(0, 1).toUpperCase()
                    : '?';

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: theme.colorScheme.primary,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (!layout.isMobile) ...[
                  const SizedBox(width: 8),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayLabel,
                        style: theme.textTheme.labelSmall,
                      ),
                      Text(
                        admin.role.toJson(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.logout, size: 20),
                  tooltip: 'admin.sidebar.logout'.tr,
                  onPressed: auth.signOut,
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  String _routeToTitle(String route) {
    final map = {
      // Main sections
      AppRoutes.adminDashboard: 'admin.dashboard.title',
      AppRoutes.adminCustomers: 'admin.users.customers',
      AppRoutes.adminCustomerDetail: 'admin.users.customers',
      AppRoutes.adminDrivers: 'admin.users.drivers',
      AppRoutes.adminDriverDetail: 'admin.users.drivers',
      AppRoutes.adminDriverDocuments: 'admin.documents.title',
      AppRoutes.adminUsers: 'admin.users.title',
      AppRoutes.adminUserDetail: 'admin.users.title',
      AppRoutes.adminTrips: 'admin.trips.title',
      AppRoutes.adminTripDetail: 'admin.trips.title',
      AppRoutes.adminFinancial: 'admin.financial.title',
      AppRoutes.adminTransactions: 'admin.transactions.title',
      AppRoutes.adminConfig: 'admin.config.title',
      AppRoutes.adminCommission: 'admin.config.title',
      AppRoutes.adminPromos: 'admin.promos.title',
      AppRoutes.adminPromoDetail: 'admin.promos.detail_title',
      AppRoutes.adminNotifications: 'admin.notifications.title',
      AppRoutes.adminReferralConfig: 'admin.referrals.title',
      AppRoutes.adminAnalytics: 'admin.analytics.title',
      AppRoutes.adminNotFound: 'admin.dashboard.title',
      // Approval queue
      AppRoutes.adminApprovalQueue: 'admin.approvals.title',
      AppRoutes.adminDriverReview: 'admin.approvals.title',
      // Finance sub-screens
      AppRoutes.adminFinancialDashboard: 'admin.sidebar.finance_dashboard',
      AppRoutes.adminRevenue: 'admin.sidebar.revenue',
      AppRoutes.adminCommissions: 'admin.sidebar.commissions',
      AppRoutes.adminDriverEarnings: 'admin.sidebar.driver_earnings',
      AppRoutes.adminDriverEarningsDetail: 'admin.sidebar.driver_earnings',
      AppRoutes.adminWalletMonitoring: 'admin.sidebar.wallets',
      AppRoutes.adminPaymentAnalytics: 'admin.sidebar.payment_analytics',
      AppRoutes.adminTransactionMonitor: 'admin.sidebar.transactions',
      AppRoutes.adminReports: 'admin.sidebar.reports',
      AppRoutes.adminSettlement: 'admin.sidebar.settlement',
    };
    return map[route] ?? 'admin.dashboard.title';
  }
}
