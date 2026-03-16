import 'package:biko/core/constants/app_constants.dart';
import 'package:flutter/material.dart';

/// BikeRide empty state widget
///
/// Displays an icon, title, optional subtitle, and optional action button
/// when a list or screen has no content.
///
/// Example usage:
/// ```dart
/// AppEmptyState(
///   icon: Icons.search_off,
///   title: 'no_results'.tr,
///   subtitle: 'try_different_search'.tr,
///   action: AppButton(
///     text: 'clear_search'.tr,
///     onPressed: () => controller.clearSearch(),
///     variant: ButtonVariant.outline,
///   ),
/// )
/// ```
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    required this.icon,
    required this.title,
    super.key,
    this.subtitle,
    this.action,
    this.iconSize = 80,
  });

  /// Icon displayed at the top
  final IconData icon;

  /// Primary message
  final String title;

  /// Optional secondary description
  final String? subtitle;

  /// Optional action widget (typically an AppButton)
  final Widget? action;

  /// Icon size (default 80dp)
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: iconSize, color: theme.colorScheme.outline),
            const SizedBox(height: AppConstants.spacingLg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppConstants.spacingSm),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppConstants.spacingXl),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
