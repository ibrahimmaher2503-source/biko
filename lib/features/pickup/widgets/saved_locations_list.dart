import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/features/home/models/recent_location.dart';
import 'package:biko/features/pickup/controllers/pickup_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Section showing saved (Home/Work) and recent locations
/// in the bottom sheet.
///
/// Hidden when no locations are available. Each row is tappable
/// and calls [PickupController.onSavedLocationTap].
class SavedLocationsList extends GetView<PickupController> {
  const SavedLocationsList({super.key});

  // Placeholder saved/recent locations.
  // In a real implementation these come from SharedPreferences or Firestore.
  static const List<RecentLocation> _savedLocations = [
    RecentLocation(
      name: 'Home',
      address: 'Kafr Saad, Banha',
      lat: 30.4667,
      lng: 31.1833,
      iconType: 'home',
    ),
    RecentLocation(
      name: 'Work',
      address: 'Benha University',
      lat: 30.4590,
      lng: 31.1860,
      iconType: 'work',
    ),
  ];

  static const List<RecentLocation> _recentLocations = [
    RecentLocation(
      name: 'Benha Station',
      address: 'Benha Railway Station, Al Qalyubia',
      lat: 30.4620,
      lng: 31.1800,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    final theme = Theme.of(context);

    final hasSaved = _savedLocations.isNotEmpty;
    final hasRecent = _recentLocations.isNotEmpty;

    if (!hasSaved && !hasRecent) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasSaved) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 4),
            child: Text(
              'pickup.saved_locations'.tr,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.textMuted,
              ),
            ),
          ),
          const SizedBox(height: 4),
          ..._savedLocations.map(
            (loc) => _LocationRow(
              location: loc,
              colors: colors,
              theme: theme,
              onTap: () => controller.onSavedLocationTap(
                name: loc.iconType == 'home'
                    ? 'pickup.home_label'.tr
                    : loc.iconType == 'work'
                    ? 'pickup.work_label'.tr
                    : loc.name,
                address: loc.address,
                lat: loc.lat,
                lng: loc.lng,
              ),
            ),
          ),
        ],
        if (hasRecent) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 4),
            child: Text(
              'pickup.recent_locations'.tr,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.textMuted,
              ),
            ),
          ),
          const SizedBox(height: 4),
          ..._recentLocations.map(
            (loc) => _LocationRow(
              location: loc,
              colors: colors,
              theme: theme,
              onTap: () => controller.onSavedLocationTap(
                name: loc.name,
                address: loc.address,
                lat: loc.lat,
                lng: loc.lng,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _LocationRow extends StatelessWidget {
  const _LocationRow({
    required this.location,
    required this.colors,
    required this.theme,
    required this.onTap,
  });

  final RecentLocation location;
  final AppColorsExtension colors;
  final ThemeData theme;
  final VoidCallback onTap;

  IconData _iconForType(String type) {
    switch (type) {
      case 'home':
        return Icons.home_outlined;
      case 'work':
        return Icons.work_outline;
      case 'favorite':
        return Icons.favorite_outline;
      default:
        return Icons.access_time;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colors.surfaceContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _iconForType(location.iconType),
                size: 18,
                color: colors.textMuted,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location.name,
                    style: theme.textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    location.address,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
