import 'package:biko/features/home/controllers/home_controller.dart';
import 'package:biko/features/home/widgets/home_header.dart';
import 'package:biko/features/home/widgets/home_search_bar.dart';
import 'package:biko/features/home/widgets/recent_locations_section.dart';
import 'package:biko/features/home/widgets/ride_service_card.dart';
import 'package:biko/features/home/widgets/service_card_grid.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Customer home screen — services overview.
///
/// Displays location header, search bar, service cards, and recent
/// locations over a map background. Sits inside [CustomerMainShell]
/// as tab index 0.
class CustomerHomeScreen extends GetView<HomeController> {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Layer 0: Map background
        Positioned.fill(child: _buildMapBackground(context)),

        // Layer 1: Fixed header (z-index above scroll content)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: HomeHeader(onWalletTap: controller.navigateToWallet),
        ),

        // Layer 2: Scrollable content
        Positioned.fill(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              // Top padding: safe area + header height (~100dp)
              top: MediaQuery.of(context).padding.top + 100,
              bottom: 96, // space for bottom nav overlay
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search bar
                HomeSearchBar(onTap: controller.navigateToSearch),
                const SizedBox(height: 24),

                // Take a Ride card
                RideServiceCard(onBookNow: controller.navigateToRideBooking),
                const SizedBox(height: 16),

                // Delivery + Merchant grid
                ServiceCardGrid(
                  onDeliveryTap: controller.navigateToDeliveryBooking,
                  onMerchantTap: controller.onMerchantTap,
                ),
                const SizedBox(height: 24),

                // Recent locations
                RecentLocationsSection(
                  onLocationTap: controller.onRecentLocationTap,
                  onSeeAllTap: controller.navigateToLocationHistory,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Static grayscale map background with gradient overlay.
  Widget _buildMapBackground(BuildContext context) {
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Grayscale map image
        ColorFiltered(
          colorFilter: const ColorFilter.matrix(<double>[
            0.2126, 0.7152, 0.0722, 0, 0, // red
            0.2126, 0.7152, 0.0722, 0, 0, // green
            0.2126, 0.7152, 0.0722, 0, 0, // blue
            0, 0, 0, 0.8, 0, // alpha (80% opacity)
          ]),
          child: Image.asset(
            'assets/images/backgrounds/cairo_map.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: bgColor),
          ),
        ),
        // Gradient overlay for readability
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.4, 1.0],
              colors: [
                bgColor.withValues(alpha: 0.6),
                bgColor.withValues(alpha: 0.0),
                bgColor.withValues(alpha: 0.9),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
