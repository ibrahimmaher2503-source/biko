import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/features/home/controllers/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Custom bottom navigation bar with elevated center action button.
///
/// 5 items: Home, Rides, + (center), Wallet, Profile.
/// The center button is not a tab — it triggers navigation to the
/// ride/delivery creation flow.
class CustomerBottomNav extends GetView<HomeController> {
  const CustomerBottomNav({
    required this.onTabChanged,
    required this.onCenterTap,
    super.key,
  });

  final Function(int) onTabChanged;
  final VoidCallback onCenterTap;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppColorsExtension>()!;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsetsDirectional.only(
        top: 12,
        bottom: bottomPadding + 8,
        start: 24,
        end: 24,
      ),
      decoration: BoxDecoration(
        color: ext.surfaceElevated,
        border: Border(top: BorderSide(color: ext.borderSubtle)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildTabItem(
            context,
            ext,
            index: 0,
            icon: Icons.home,
            label: 'nav.home'.tr,
          ),
          _buildTabItem(
            context,
            ext,
            index: 1,
            icon: Icons.directions_car,
            label: 'nav.rides'.tr,
          ),
          _buildCenterButton(context, ext),
          _buildTabItem(
            context,
            ext,
            index: 3,
            icon: Icons.wallet,
            label: 'nav.wallet'.tr,
          ),
          _buildTabItem(
            context,
            ext,
            index: 4,
            icon: Icons.person,
            label: 'nav.profile'.tr,
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(
    BuildContext context,
    AppColorsExtension ext, {
    required int index,
    required IconData icon,
    required String label,
  }) {
    return Obx(() {
      final isActive = controller.currentTabIndex.value == index;
      final color = isActive ? AppTheme.primary : ext.textMuted;

      return GestureDetector(
        onTap: () => onTabChanged(index),
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 56,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, size: 28, color: color),
                  // Active dot indicator for Home tab
                  if (isActive && index == 0)
                    PositionedDirectional(
                      top: -2,
                      end: -4,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildCenterButton(BuildContext context, AppColorsExtension ext) {
    return GestureDetector(
      onTap: onCenterTap,
      child: Transform.translate(
        offset: const Offset(0, -24),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppTheme.primary,
            shape: BoxShape.circle,
            border: Border.all(color: ext.surfaceElevated, width: 4),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}
