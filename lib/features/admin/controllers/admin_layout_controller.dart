import 'package:biko/core/routes/app_routes.dart';
import 'package:biko/features/admin/controllers/admin_auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Sidebar navigation item model
class SidebarItem {
  const SidebarItem({
    required this.route,
    required this.icon,
    required this.labelKey,
    this.badgeCount,
    this.superAdminOnly = false,
  });

  final String route;
  final IconData icon;
  final String labelKey;
  final RxInt? badgeCount;
  final bool superAdminOnly;
}

/// Admin layout controller
///
/// Manages the admin sidebar navigation state, responsive breakpoints,
/// and route-based active highlighting.
/// Registered permanently in the Admin app entry point.
class AdminLayoutController extends GetxController {
  final selectedIndex = 0.obs;
  final isSidebarExpanded = true.obs;
  final currentRoute = AppRoutes.adminDashboard.obs;
  final _screenWidth = 1200.0.obs;

  // ==================== Breakpoints ====================

  static const double _mobileBreakpoint = 768;
  static const double _tabletBreakpoint = 1200;

  /// Whether the current screen is mobile-sized
  bool get isMobile => _screenWidth.value < _mobileBreakpoint;

  /// Whether the current screen is tablet-sized
  bool get isTablet =>
      _screenWidth.value >= _mobileBreakpoint &&
      _screenWidth.value < _tabletBreakpoint;

  // ==================== Sidebar Items ====================

  final List<SidebarItem> _sidebarItems = [
    const SidebarItem(
      route: AppRoutes.adminDashboard,
      icon: Icons.dashboard_rounded,
      labelKey: 'admin.sidebar.dashboard',
    ),
    const SidebarItem(
      route: AppRoutes.adminApprovalQueue,
      icon: Icons.verified_user_rounded,
      labelKey: 'admin.sidebar.approvals',
    ),
    const SidebarItem(
      route: AppRoutes.adminCustomers,
      icon: Icons.people_rounded,
      labelKey: 'admin.sidebar.customers',
    ),
    const SidebarItem(
      route: AppRoutes.adminDrivers,
      icon: Icons.two_wheeler_rounded,
      labelKey: 'admin.sidebar.drivers',
    ),
    const SidebarItem(
      route: AppRoutes.adminDriverDocuments,
      icon: Icons.description_rounded,
      labelKey: 'admin.sidebar.documents',
    ),
    const SidebarItem(
      route: AppRoutes.adminTrips,
      icon: Icons.route_rounded,
      labelKey: 'admin.sidebar.trips',
    ),
    const SidebarItem(
      route: AppRoutes.adminFinancial,
      icon: Icons.account_balance_wallet_rounded,
      labelKey: 'admin.sidebar.financial',
    ),
    const SidebarItem(
      route: AppRoutes.adminFinancialDashboard,
      icon: Icons.bar_chart_rounded,
      labelKey: 'admin.sidebar.finance_dashboard',
    ),
    const SidebarItem(
      route: AppRoutes.adminRevenue,
      icon: Icons.trending_up_rounded,
      labelKey: 'admin.sidebar.revenue',
    ),
    const SidebarItem(
      route: AppRoutes.adminCommissions,
      icon: Icons.percent_rounded,
      labelKey: 'admin.sidebar.commissions',
    ),
    const SidebarItem(
      route: AppRoutes.adminDriverEarnings,
      icon: Icons.payments_rounded,
      labelKey: 'admin.sidebar.driver_earnings',
    ),
    const SidebarItem(
      route: AppRoutes.adminWalletMonitoring,
      icon: Icons.account_balance_rounded,
      labelKey: 'admin.sidebar.wallets',
    ),
    const SidebarItem(
      route: AppRoutes.adminPaymentAnalytics,
      icon: Icons.credit_card_rounded,
      labelKey: 'admin.sidebar.payment_analytics',
    ),
    const SidebarItem(
      route: AppRoutes.adminTransactionMonitor,
      icon: Icons.receipt_long_rounded,
      labelKey: 'admin.sidebar.transactions',
    ),
    const SidebarItem(
      route: AppRoutes.adminReports,
      icon: Icons.summarize_rounded,
      labelKey: 'admin.sidebar.reports',
    ),
    const SidebarItem(
      route: AppRoutes.adminSettlement,
      icon: Icons.handshake_rounded,
      labelKey: 'admin.sidebar.settlement',
    ),
    const SidebarItem(
      route: AppRoutes.adminConfig,
      icon: Icons.settings_rounded,
      labelKey: 'admin.sidebar.config',
      superAdminOnly: true,
    ),
    const SidebarItem(
      route: AppRoutes.adminPromos,
      icon: Icons.local_offer_rounded,
      labelKey: 'admin.sidebar.promos',
    ),
    const SidebarItem(
      route: AppRoutes.adminNotifications,
      icon: Icons.notifications_rounded,
      labelKey: 'admin.sidebar.notifications',
    ),
    const SidebarItem(
      route: AppRoutes.adminReferralConfig,
      icon: Icons.share_rounded,
      labelKey: 'admin.sidebar.referrals',
    ),
    const SidebarItem(
      route: AppRoutes.adminAnalytics,
      icon: Icons.analytics_rounded,
      labelKey: 'admin.sidebar.analytics',
    ),
  ];

  // ==================== Methods ====================

  /// Update screen width from LayoutBuilder
  void updateScreenWidth(double width) {
    _screenWidth.value = width;

    // Auto-collapse sidebar on tablet, expand on desktop
    if (isTablet) {
      isSidebarExpanded.value = false;
    } else if (!isMobile) {
      isSidebarExpanded.value = true;
    }
  }

  /// Reactive list of sidebar items visible to the current user.
  ///
  /// Filters out [superAdminOnly] items when the current user is not a
  /// super admin. Reading `_isSuperAdmin` through the auth controller
  /// ensures GetX tracks this dependency for reactive rebuilds.
  List<SidebarItem> getVisibleItems() {
    final auth = Get.find<AdminAuthController>();
    // Access the observable value directly so Obx tracks the dependency.
    final superAdmin = auth.isSuperAdmin;
    if (superAdmin) {
      return _sidebarItems;
    }
    return _sidebarItems.where((item) => !item.superAdminOnly).toList();
  }

  @override
  void onInit() {
    super.onInit();
    // Sync currentRoute with the actual active route on startup.
    final initial = Get.currentRoute;
    if (initial.isNotEmpty) {
      currentRoute.value = initial;
    }
  }

  /// Called by the global routing callback whenever a navigation occurs.
  ///
  /// Keeps [currentRoute] (and therefore the topbar title and sidebar
  /// active-highlight) in sync even when navigation is triggered from
  /// outside [navigateTo] (e.g. `Get.toNamed()` calls from screens).
  void syncCurrentRoute(String route) {
    if (route.isNotEmpty && route != currentRoute.value) {
      currentRoute.value = route;
    }
  }

  /// Navigate to a route and update current route
  void navigateTo(String route) {
    if (currentRoute.value == route) return;
    currentRoute.value = route;
    Get.offAllNamed(route);
  }

  /// Select a sidebar menu item by index
  void selectItem(int index) {
    selectedIndex.value = index;
  }

  /// Toggle sidebar expanded/collapsed state
  void toggleSidebar() {
    isSidebarExpanded.value = !isSidebarExpanded.value;
  }
}
