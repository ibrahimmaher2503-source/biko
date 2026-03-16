import 'package:biko/core/routes/app_routes.dart';
import 'package:biko/core/services/background_location_service.dart';
import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_error_widget.dart';
import 'package:biko/core/widgets/app_loading.dart';
import 'package:biko/features/driver_home/controllers/driver_home_controller.dart';
import 'package:biko/features/driver_home/widgets/earnings_summary_card.dart';
import 'package:biko/features/driver_home/widgets/online_toggle_card.dart';
import 'package:biko/features/driver_home/widgets/today_stats_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Driver home screen with online toggle, stats, and bottom navigation.
///
/// Matches stitch design: greeting header with wallet badge,
/// prominent online toggle, stat cards, and styled bottom nav.
class DriverHomeScreen extends GetView<DriverHomeController> {
  const DriverHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppColorsExtension>()!;

    return Scaffold(
      body: Obx(() => _buildBody(context)),
      bottomNavigationBar: Obx(
        () => DecoratedBox(
          decoration: BoxDecoration(
            color: ext.surfaceElevated,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: NavigationBar(
            selectedIndex: controller.currentNavIndex.value,
            onDestinationSelected: _onNavTap,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            indicatorColor: AppTheme.primary.withValues(alpha: 0.1),
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(
                  Icons.home,
                  color: AppTheme.primary,
                ),
                label: 'driver_home.nav_home'.tr,
              ),
              NavigationDestination(
                icon: const Icon(Icons.list_alt_outlined),
                selectedIcon: const Icon(
                  Icons.list_alt,
                  color: AppTheme.primary,
                ),
                label: 'driver_home.nav_trips'.tr,
              ),
              NavigationDestination(
                icon: const Icon(Icons.account_balance_wallet_outlined),
                selectedIcon: const Icon(
                  Icons.account_balance_wallet,
                  color: AppTheme.primary,
                ),
                label: 'driver_home.nav_earnings'.tr,
              ),
              NavigationDestination(
                icon: const Icon(Icons.person_outline),
                selectedIcon: const Icon(
                  Icons.person,
                  color: AppTheme.primary,
                ),
                label: 'driver_home.nav_profile'.tr,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (controller.currentNavIndex.value) {
      case 0:
        return _buildHomeTab(context);
      case 1:
        return _buildPlaceholderTab(
          context,
          icon: Icons.list_alt,
          title: 'driver_home.nav_trips'.tr,
        );
      case 2:
        return _buildPlaceholderTab(
          context,
          icon: Icons.account_balance_wallet,
          title: 'driver_home.nav_earnings'.tr,
        );
      case 3:
        return _buildPlaceholderTab(
          context,
          icon: Icons.person,
          title: 'driver_home.nav_profile'.tr,
        );
      default:
        return _buildHomeTab(context);
    }
  }

  Widget _buildHomeTab(BuildContext context) {
    final theme = Theme.of(context);
    final ext = theme.extension<AppColorsExtension>()!;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: controller.refreshStats,
        color: AppTheme.primary,
        child: CustomScrollView(
          slivers: [
            // Custom header with greeting and wallet badge
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 0),
                child: Row(
                  children: [
                    // Greeting
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'driver_home.greeting'.tr,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: ext.textMuted,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'driver_home.title'.tr,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Wallet balance badge
                    GestureDetector(
                      onTap: () => Get.toNamed(AppRoutes.driverWallet),
                      child: Obx(
                        () => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: ext.surfaceElevated,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusFull,
                            ),
                            border: Border.all(color: ext.borderSubtle),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.account_balance_wallet,
                                  size: 14,
                                  color: AppTheme.primary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${controller.walletBalance.value.toStringAsFixed(0)} ${'common.egp'.tr}',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: controller.hasDebt
                                      ? theme.colorScheme.error
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Content
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: _buildContent(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (controller.isLoading.value) {
      return const SliverFillRemaining(
        child: AppLoading(message: 'common.loading'),
      );
    }

    if (controller.hasError.value) {
      return SliverFillRemaining(
        child: AppErrorWidget(
          message: 'error.unknown'.tr,
          onRetry: controller.refreshStats,
        ),
      );
    }

    return SliverList(
      delegate: SliverChildListDelegate([
        const SizedBox(height: 20),
        // Online/Offline Toggle
        Obx(
          () => OnlineToggleCard(
            isOnline: Get.find<BackgroundLocationService>().isOnline.value,
            onToggle: controller.toggleOnline,
            hasDebt: controller.hasDebt,
          ),
        ),
        const SizedBox(height: 20),
        // Today's Stats
        Obx(
          () => TodayStatsCard(
            tripCount: controller.todayTrips.value,
            totalEarned: controller.todayEarnings.value,
          ),
        ),
        const SizedBox(height: 16),
        // Weekly Earnings
        Obx(
          () => EarningsSummaryCard(
            weeklyEarnings: controller.weeklyEarnings.value,
          ),
        ),
        const SizedBox(height: 32),
      ]),
    );
  }

  Widget _buildPlaceholderTab(
    BuildContext context, {
    required IconData icon,
    required String title,
  }) {
    final ext = Theme.of(context).extension<AppColorsExtension>()!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: ext.surfaceContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 36, color: ext.textMuted),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: ext.textMuted),
          ),
        ],
      ),
    );
  }

  void _onNavTap(int index) {
    // Navigate to actual screens when they exist
    switch (index) {
      case 1:
        Get.toNamed(AppRoutes.incomingRequests);
        return;
      case 2:
        Get.toNamed(AppRoutes.earnings);
        return;
      case 3:
        Get.toNamed(AppRoutes.driverProfile);
        return;
      default:
        controller.onNavTap(index);
    }
  }
}
