import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/features/home/controllers/home_controller.dart';
import 'package:biko/features/home/models/recent_location.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Recent locations section — hidden when list is empty.
///
/// Shows up to 5 previously used destinations with icons, names,
/// addresses, and a "See All" link.
class RecentLocationsSection extends GetView<HomeController> {
  const RecentLocationsSection({
    required this.onLocationTap,
    required this.onSeeAllTap,
    super.key,
  });

  final Function(RecentLocation) onLocationTap;
  final VoidCallback onSeeAllTap;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.recentLocations.isEmpty) {
        return const SizedBox.shrink();
      }
      return _buildContent(context);
    });
  }

  Widget _buildContent(BuildContext context) {
    final ext = Theme.of(context).extension<AppColorsExtension>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'home.recent_locations'.tr,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            GestureDetector(
              onTap: onSeeAllTap,
              child: Text(
                'home.see_all'.tr,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Locations list container
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: ext.surfaceElevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ext.borderSubtle),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Obx(
            () => ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.recentLocations.length,
              separatorBuilder: (_, __) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Divider(height: 1, color: ext.borderSubtle),
              ),
              itemBuilder: (context, index) {
                final location = controller.recentLocations[index];
                return _buildLocationItem(context, ext, location);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationItem(
    BuildContext context,
    AppColorsExtension ext,
    RecentLocation location,
  ) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return GestureDetector(
      onTap: () => onLocationTap(location),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Icon circle
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: ext.surfaceContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIcon(location.iconType),
                size: 20,
                color: ext.textMuted,
              ),
            ),
            const SizedBox(width: 12),
            // Name + address
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    location.address,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: ext.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Chevron (flips in RTL)
            Transform.flip(
              flipX: isRtl,
              child: Icon(Icons.chevron_right, size: 20, color: ext.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'work':
        return Icons.work_outline;
      case 'home':
        return Icons.home_outlined;
      case 'favorite':
        return Icons.favorite_outline;
      case 'history':
      default:
        return Icons.history;
    }
  }
}
