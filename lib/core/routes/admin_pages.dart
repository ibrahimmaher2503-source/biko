import 'package:biko/core/routes/app_routes.dart';
import 'package:biko/features/admin/bindings/admin_analytics_binding.dart';
import 'package:biko/features/admin/bindings/admin_approval_binding.dart';
import 'package:biko/features/admin/bindings/admin_commission_binding.dart';
import 'package:biko/features/admin/bindings/admin_config_binding.dart';
import 'package:biko/features/admin/bindings/admin_dashboard_binding.dart';
import 'package:biko/features/admin/bindings/admin_documents_binding.dart';
import 'package:biko/features/admin/bindings/admin_driver_earnings_binding.dart';
import 'package:biko/features/admin/bindings/admin_drivers_binding.dart';
import 'package:biko/features/admin/bindings/admin_financial_binding.dart';
import 'package:biko/features/admin/bindings/admin_financial_dashboard_binding.dart';
import 'package:biko/features/admin/bindings/admin_notifications_binding.dart';
import 'package:biko/features/admin/bindings/admin_payment_analytics_binding.dart';
import 'package:biko/features/admin/bindings/admin_promos_binding.dart';
import 'package:biko/features/admin/bindings/admin_referral_binding.dart';
import 'package:biko/features/admin/bindings/admin_reports_binding.dart';
import 'package:biko/features/admin/bindings/admin_revenue_binding.dart';
import 'package:biko/features/admin/bindings/admin_settlement_binding.dart';
import 'package:biko/features/admin/bindings/admin_transaction_monitor_binding.dart';
import 'package:biko/features/admin/bindings/admin_trips_binding.dart';
import 'package:biko/features/admin/bindings/admin_users_binding.dart';
import 'package:biko/features/admin/bindings/admin_wallet_binding.dart';
import 'package:biko/features/admin/controllers/admin_auth_controller.dart';
import 'package:biko/features/admin/screens/admin_analytics_screen.dart';
import 'package:biko/features/admin/screens/admin_approval_queue_screen.dart';
import 'package:biko/features/admin/screens/admin_commission_screen.dart';
import 'package:biko/features/admin/screens/admin_config_screen.dart';
import 'package:biko/features/admin/screens/admin_customer_detail_screen.dart';
import 'package:biko/features/admin/screens/admin_customers_screen.dart';
import 'package:biko/features/admin/screens/admin_dashboard_screen.dart';
import 'package:biko/features/admin/screens/admin_documents_screen.dart';
import 'package:biko/features/admin/screens/admin_driver_detail_screen.dart';
import 'package:biko/features/admin/screens/admin_driver_earnings_detail_screen.dart';
import 'package:biko/features/admin/screens/admin_driver_earnings_screen.dart';
import 'package:biko/features/admin/screens/admin_driver_review_screen.dart';
import 'package:biko/features/admin/screens/admin_drivers_screen.dart';
import 'package:biko/features/admin/screens/admin_financial_dashboard_screen.dart';
import 'package:biko/features/admin/screens/admin_financial_screen.dart';
import 'package:biko/features/admin/screens/admin_layout_shell.dart';
import 'package:biko/features/admin/screens/admin_login_screen.dart';
import 'package:biko/features/admin/screens/admin_notifications_screen.dart';
import 'package:biko/features/admin/screens/admin_payment_analytics_screen.dart';
import 'package:biko/features/admin/screens/admin_promo_detail_screen.dart';
import 'package:biko/features/admin/screens/admin_promos_screen.dart';
import 'package:biko/features/admin/screens/admin_referral_screen.dart';
import 'package:biko/features/admin/screens/admin_reports_screen.dart';
import 'package:biko/features/admin/screens/admin_revenue_screen.dart';
import 'package:biko/features/admin/screens/admin_settlement_screen.dart';
import 'package:biko/features/admin/screens/admin_transaction_monitor_screen.dart';
import 'package:biko/features/admin/screens/admin_trip_detail_screen.dart';
import 'package:biko/features/admin/screens/admin_trips_screen.dart';
import 'package:biko/features/admin/screens/admin_wallet_monitoring_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Admin panel page registry
///
/// Returns the list of [GetPage] entries for the admin web panel.
/// Admin routes use [AdminAuthGuard] middleware and wrap content
/// in [AdminLayoutShell] for sidebar navigation.
class AdminPages {
  AdminPages._();

  static List<GetPage> get pages => [
    // ==================== Auth (no layout shell, no guard) ====================
    GetPage(
      name: AppRoutes.adminLogin,
      page: () => const AdminLoginScreen(),
    ),

    // ==================== Dashboard ====================
    GetPage(
      name: AppRoutes.adminDashboard,
      page: () => const AdminLayoutShell(child: AdminDashboardScreen()),
      binding: AdminDashboardBinding(),
      middlewares: [AdminAuthGuard()],
    ),

    // ==================== Customer Management ====================
    GetPage(
      name: AppRoutes.adminCustomers,
      page: () => const AdminLayoutShell(child: AdminCustomersScreen()),
      binding: AdminUsersBinding(),
      middlewares: [AdminAuthGuard()],
    ),
    GetPage(
      name: AppRoutes.adminCustomerDetail,
      page: () => const AdminLayoutShell(child: AdminCustomerDetailScreen()),
      binding: AdminUsersBinding(),
      middlewares: [AdminAuthGuard()],
    ),

    // ==================== Driver Management ====================
    GetPage(
      name: AppRoutes.adminDrivers,
      page: () => const AdminLayoutShell(child: AdminDriversScreen()),
      binding: AdminDriversBinding(),
      middlewares: [AdminAuthGuard()],
    ),
    GetPage(
      name: AppRoutes.adminDriverDetail,
      page: () => const AdminLayoutShell(child: AdminDriverDetailScreen()),
      binding: AdminDriversBinding(),
      middlewares: [AdminAuthGuard()],
    ),

    // ==================== Document Review ====================
    GetPage(
      name: AppRoutes.adminDriverDocuments,
      page: () => const AdminLayoutShell(child: AdminDocumentsScreen()),
      binding: AdminDocumentsBinding(),
      middlewares: [AdminAuthGuard()],
    ),

    // ==================== Trip Management ====================
    GetPage(
      name: AppRoutes.adminTrips,
      page: () => const AdminLayoutShell(child: AdminTripsScreen()),
      binding: AdminTripsBinding(),
      middlewares: [AdminAuthGuard()],
    ),
    GetPage(
      name: AppRoutes.adminTripDetail,
      page: () => const AdminLayoutShell(child: AdminTripDetailScreen()),
      binding: AdminTripsBinding(),
      middlewares: [AdminAuthGuard()],
    ),

    // ==================== Financial ====================
    GetPage(
      name: AppRoutes.adminFinancial,
      page: () => const AdminLayoutShell(child: AdminFinancialScreen()),
      binding: AdminFinancialBinding(),
      middlewares: [AdminAuthGuard()],
    ),

    // ==================== App Config (super admin only) ====================
    GetPage(
      name: AppRoutes.adminConfig,
      page: () => const AdminLayoutShell(child: AdminConfigScreen()),
      binding: AdminConfigBinding(),
      middlewares: [AdminAuthGuard()],
    ),

    // ==================== Promos ====================
    GetPage(
      name: AppRoutes.adminPromos,
      page: () => const AdminLayoutShell(child: AdminPromosScreen()),
      binding: AdminPromosBinding(),
      middlewares: [AdminAuthGuard()],
    ),

    // ==================== Notifications ====================
    GetPage(
      name: AppRoutes.adminNotifications,
      page: () => const AdminLayoutShell(child: AdminNotificationsScreen()),
      binding: AdminNotificationsBinding(),
      middlewares: [AdminAuthGuard()],
    ),

    // ==================== Referral ====================
    GetPage(
      name: AppRoutes.adminReferralConfig,
      page: () => const AdminLayoutShell(child: AdminReferralScreen()),
      binding: AdminReferralBinding(),
      middlewares: [AdminAuthGuard()],
    ),

    // ==================== Analytics ====================
    GetPage(
      name: AppRoutes.adminAnalytics,
      page: () => const AdminLayoutShell(child: AdminAnalyticsScreen()),
      binding: AdminAnalyticsBinding(),
      middlewares: [AdminAuthGuard()],
    ),

    // ==================== Driver Approval Queue ====================
    GetPage(
      name: AppRoutes.adminApprovalQueue,
      page: () => const AdminLayoutShell(child: AdminApprovalQueueScreen()),
      binding: AdminApprovalBinding(),
      middlewares: [AdminAuthGuard()],
    ),
    GetPage(
      name: AppRoutes.adminDriverReview,
      page: () => const AdminLayoutShell(child: AdminDriverReviewScreen()),
      binding: AdminApprovalBinding(),
      middlewares: [AdminAuthGuard()],
    ),

    // ==================== Promo Detail ====================
    GetPage(
      name: AppRoutes.adminPromoDetail,
      page: () => const AdminLayoutShell(child: AdminPromoDetailScreen()),
      binding: AdminPromosBinding(),
      middlewares: [AdminAuthGuard()],
    ),

    // ==================== Financial Dashboard ====================
    GetPage(
      name: AppRoutes.adminFinancialDashboard,
      page: () => const AdminLayoutShell(
        child: AdminFinancialDashboardScreen(),
      ),
      binding: AdminFinancialDashboardBinding(),
      middlewares: [AdminAuthGuard()],
    ),

    // ==================== Revenue ====================
    GetPage(
      name: AppRoutes.adminRevenue,
      page: () => const AdminLayoutShell(child: AdminRevenueScreen()),
      binding: AdminRevenueBinding(),
      middlewares: [AdminAuthGuard()],
    ),

    // ==================== Commission ====================
    GetPage(
      name: AppRoutes.adminCommissions,
      page: () => const AdminLayoutShell(child: AdminCommissionScreen()),
      binding: AdminCommissionBinding(),
      middlewares: [AdminAuthGuard()],
    ),

    // ==================== Driver Earnings ====================
    GetPage(
      name: AppRoutes.adminDriverEarnings,
      page: () => const AdminLayoutShell(child: AdminDriverEarningsScreen()),
      binding: AdminDriverEarningsBinding(),
      middlewares: [AdminAuthGuard()],
    ),
    GetPage(
      name: AppRoutes.adminDriverEarningsDetail,
      page: () => const AdminLayoutShell(
        child: AdminDriverEarningsDetailScreen(),
      ),
      binding: AdminDriverEarningsBinding(),
      middlewares: [AdminAuthGuard()],
    ),

    // ==================== Wallet Monitoring ====================
    GetPage(
      name: AppRoutes.adminWalletMonitoring,
      page: () => const AdminLayoutShell(
        child: AdminWalletMonitoringScreen(),
      ),
      binding: AdminWalletBinding(),
      middlewares: [AdminAuthGuard()],
    ),

    // ==================== Payment Analytics ====================
    GetPage(
      name: AppRoutes.adminPaymentAnalytics,
      page: () => const AdminLayoutShell(
        child: AdminPaymentAnalyticsScreen(),
      ),
      binding: AdminPaymentAnalyticsBinding(),
      middlewares: [AdminAuthGuard()],
    ),

    // ==================== Transaction Monitor ====================
    GetPage(
      name: AppRoutes.adminTransactionMonitor,
      page: () => const AdminLayoutShell(
        child: AdminTransactionMonitorScreen(),
      ),
      binding: AdminTransactionMonitorBinding(),
      middlewares: [AdminAuthGuard()],
    ),

    // ==================== Reports ====================
    GetPage(
      name: AppRoutes.adminReports,
      page: () => const AdminLayoutShell(child: AdminReportsScreen()),
      binding: AdminReportsBinding(),
      middlewares: [AdminAuthGuard()],
    ),

    // ==================== Settlement ====================
    GetPage(
      name: AppRoutes.adminSettlement,
      page: () => const AdminLayoutShell(child: AdminSettlementScreen()),
      binding: AdminSettlementBinding(),
      middlewares: [AdminAuthGuard()],
    ),
  ];
}

/// Middleware that redirects to admin login if not authenticated.
class AdminAuthGuard extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final auth = Get.find<AdminAuthController>();
    if (!auth.isAuthenticated.value) {
      return const RouteSettings(name: AppRoutes.adminLogin);
    }
    return null;
  }
}
