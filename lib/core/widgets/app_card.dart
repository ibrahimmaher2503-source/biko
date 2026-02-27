import 'package:flutter/material.dart';
import 'package:biko/core/theme/app_theme.dart';

/// BikeRide branded card widget with Material 3 styling
///
/// Provides consistent card styling across all apps with support for:
/// - Optional tap interaction with ripple effect
/// - Customizable padding, elevation, and background color
/// - Border radius following design system
///
/// Example usage:
/// ```dart
/// // Basic card
/// AppCard(
///   child: Text('Card content'),
/// )
///
/// // Tappable card
/// AppCard(
///   onTap: () => _handleCardTap(),
///   child: Column(
///     children: [
///       Text('Title'),
///       Text('Description'),
///     ],
///   ),
/// )
/// ```
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = 16.0,
    this.elevation = 2.0,
    this.backgroundColor,
    this.borderRadius,
  });

  /// Widget to display inside the card
  final Widget child;

  /// Optional tap callback (enables ripple effect)
  final VoidCallback? onTap;

  /// Internal padding (default 16dp)
  final double padding;

  /// Card elevation/shadow depth (default 2)
  final double elevation;

  /// Custom background color (defaults to theme card color)
  final Color? backgroundColor;

  /// Custom border radius (defaults to 12dp per design system)
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveRadius = borderRadius ?? AppTheme.radiusLarge;

    return Card(
      elevation: elevation,
      color: backgroundColor ?? theme.cardTheme.color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(effectiveRadius),
      ),
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(effectiveRadius),
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: child,
              ),
            )
          : Padding(
              padding: EdgeInsets.all(padding),
              child: child,
            ),
    );
  }
}
