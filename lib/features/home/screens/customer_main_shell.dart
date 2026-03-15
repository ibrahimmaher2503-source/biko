import 'package:biko/features/history/screens/trip_history_screen.dart';
import 'package:biko/features/home/controllers/home_controller.dart';
import 'package:biko/features/home/screens/customer_home_screen.dart';
import 'package:biko/features/home/widgets/customer_bottom_nav.dart';
import 'package:biko/features/profile/screens/profile_screen.dart';
import 'package:biko/features/wallet/screens/wallet_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Main shell scaffold for the customer app.
///
/// Wraps tab pages in an [IndexedStack] with a persistent bottom
/// navigation bar. The center "+" button navigates to the booking
/// flow instead of switching tabs.
class CustomerMainShell extends GetView<HomeController> {
  const CustomerMainShell({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Tab pages — IndexedStack preserves state
          Obx(
            () => IndexedStack(
              index: _mapTabToPage(controller.currentTabIndex.value),
              children: const [
                CustomerHomeScreen(), // tab 0
                TripHistoryScreen(), // tab 1
                WalletScreen(), // tab 3 (mapped)
                ProfileScreen(), // tab 4 (mapped)
              ],
            ),
          ),

          // Bottom navigation bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomerBottomNav(
              onTabChanged: controller.changeTab,
              onCenterTap: controller.navigateToRideBooking,
            ),
          ),
        ],
      ),
    );
  }

  /// Maps the 5-item nav index (0,1,2,3,4) to the 4-page IndexedStack.
  /// Index 2 (center button) is never a tab, so 3→2, 4→3.
  int _mapTabToPage(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return 0; // Home
      case 1:
        return 1; // Rides
      case 3:
        return 2; // Wallet
      case 4:
        return 3; // Profile
      default:
        return 0;
    }
  }
}
