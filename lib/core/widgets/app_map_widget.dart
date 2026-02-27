import 'package:flutter/material.dart';
import 'package:biko/core/theme/app_theme.dart';

/// BikeRide map widget placeholder
///
/// This is a placeholder widget for future map integration.
/// Will be replaced with google_maps_flutter implementation in a future update.
///
/// TODO: Integrate google_maps_flutter package
/// TODO: Implement real-time location tracking
/// TODO: Add route visualization and polylines
/// TODO: Implement marker clustering for multiple drivers/customers
/// TODO: Add map style switching (light/dark mode support)
///
/// Example usage:
/// ```dart
/// AppMapWidget(
///   height: 400,
///   initialPosition: LatLng(30.0444, 31.2357), // Cairo, Egypt
///   zoom: 15,
/// )
/// ```
class AppMapWidget extends StatelessWidget {
  const AppMapWidget({
    super.key,
    this.height = 300.0,
    this.initialPosition,
    this.zoom = 15.0,
  });

  /// Widget height (default 300dp)
  final double height;

  /// Initial map position (latitude, longitude)
  /// TODO: Replace with LatLng from google_maps_flutter
  final dynamic initialPosition;

  /// Initial zoom level (default 15)
  final double zoom;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF2D1316)
            : const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: isDark
              ? const Color(0xFF4A4458)
              : const Color(0xFFBDBDBD),
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map_outlined,
              size: 64,
              color: theme.colorScheme.primary.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'Map Widget',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Map integration will be implemented with google_maps_flutter',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (initialPosition != null || zoom != 15.0) ...[
              const SizedBox(height: 16),
              Text(
                'Zoom: ${zoom.toStringAsFixed(1)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
