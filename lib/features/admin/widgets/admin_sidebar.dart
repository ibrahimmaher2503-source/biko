import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/features/admin/controllers/admin_layout_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Responsive sidebar with nav items, active highlighting, and badges.
class AdminSidebar extends GetView<AdminLayoutController> {
  const AdminSidebar({super.key});

  static const double expandedWidth = 240;
  static const double collapsedWidth = 72;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;

    return Obx(() {
      final expanded = controller.isSidebarExpanded.value;
      final width = expanded ? expandedWidth : collapsedWidth;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        decoration: BoxDecoration(
          color: colors.surfaceElevated,
          border: BorderDirectional(
            end: BorderSide(color: colors.borderSubtle),
          ),
        ),
        child: Column(
          children: [
            // Header / logo area
            Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: expanded
                  ? AlignmentDirectional.centerStart
                  : Alignment.center,
              child: expanded
                  ? Text(
                      'admin.app_name'.tr,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    )
                  : Icon(
                      Icons.two_wheeler_rounded,
                      color: theme.colorScheme.primary,
                      size: 28,
                    ),
            ),
            const Divider(height: 1),

            // Nav items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: controller.getVisibleItems().map((item) {
                  return _SidebarNavItem(
                    item: item,
                    isActive: controller.currentRoute.value == item.route,
                    isExpanded: expanded,
                    onTap: () {
                      controller.navigateTo(item.route);
                      // Close drawer on mobile
                      if (controller.isMobile) {
                        Navigator.of(context).pop();
                      }
                    },
                  );
                }).toList(),
              ),
            ),

            // Collapse toggle (desktop/tablet only)
            if (!controller.isMobile)
              InkWell(
                onTap: controller.toggleSidebar,
                child: Container(
                  height: 48,
                  alignment: Alignment.center,
                  child: Builder(
                    builder: (context) {
                      final isRtl =
                          Directionality.of(context) == TextDirection.rtl;
                      return Icon(
                        expanded
                            ? (isRtl
                                  ? Icons.chevron_right_rounded
                                  : Icons.chevron_left_rounded)
                            : (isRtl
                                  ? Icons.chevron_left_rounded
                                  : Icons.chevron_right_rounded),
                        color: colors.textMuted,
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}

class _SidebarNavItem extends StatelessWidget {
  const _SidebarNavItem({
    required this.item,
    required this.isActive,
    required this.isExpanded,
    required this.onTap,
  });

  final SidebarItem item;
  final bool isActive;
  final bool isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final colors = theme.extension<AppColorsExtension>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: isActive ? primary.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusDefault),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusDefault),
          child: Container(
            height: 44,
            padding: EdgeInsets.symmetric(horizontal: isExpanded ? 12 : 0),
            child: Row(
              mainAxisAlignment: isExpanded
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                Icon(
                  item.icon,
                  size: 22,
                  color: isActive ? primary : colors.textMuted,
                ),
                if (isExpanded) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.labelKey.tr,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isActive ? primary : null,
                        fontWeight: isActive
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Badge
                  if (item.badgeCount != null)
                    Obx(() {
                      final count = item.badgeCount!.value;
                      if (count <= 0) return const SizedBox.shrink();
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: primary,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusFull,
                          ),
                        ),
                        child: Text(
                          count > 99 ? '99+' : '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }),
                ] else if (!isExpanded && item.badgeCount != null)
                  // Mini badge dot for collapsed mode
                  Obx(() {
                    final count = item.badgeCount!.value;
                    if (count <= 0) return const SizedBox.shrink();
                    return Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsetsDirectional.only(start: 4),
                      decoration: BoxDecoration(
                        color: primary,
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
