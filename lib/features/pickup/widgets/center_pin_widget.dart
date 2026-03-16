import 'package:biko/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Fixed center-pin overlay positioned at the map center.
///
/// This is a Flutter widget (not a Google Maps Marker) that stays
/// fixed in the middle of the screen while the map pans underneath.
/// Uses [AppTheme.primary] for the pin color with a subtle shadow.
class CenterPinWidget extends StatelessWidget {
  const CenterPinWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      // Offset upward by half the pin height so the point
      // aligns with the true map center
      child: Padding(
        padding: const EdgeInsets.only(bottom: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pin icon
            Icon(
              Icons.location_on,
              size: 48,
              color: AppTheme.primary,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            // Shadow dot below pin
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
