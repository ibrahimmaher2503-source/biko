import 'package:flutter/material.dart';
import 'package:biko/core/theme/app_theme.dart';

/// BikeRide loading indicator widget with two modes:
/// - **Inline mode**: Simple centered spinner for use within widgets
/// - **Overlay mode**: Full-screen semi-transparent overlay with spinner
///
/// Supports:
/// - Custom colors, sizes, and loading messages
/// - RTL-compatible text alignment
/// - Theme-aware default colors
///
/// Example usage:
/// ```dart
/// // Inline mode (within a widget)
/// AppLoading()
///
/// // Overlay mode (blocking full screen)
/// AppLoading(
///   showOverlay: true,
///   message: 'Loading your data...',
/// )
/// ```
class AppLoading extends StatelessWidget {
  const AppLoading({
    super.key,
    this.showOverlay = false,
    this.color,
    this.size = 40.0,
    this.message,
  });

  /// Show as full-screen overlay (default: false for inline mode)
  final bool showOverlay;

  /// Spinner color (defaults to primary color)
  final Color? color;

  /// Spinner size in pixels (default: 40)
  final double size;

  /// Optional loading message displayed below spinner
  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.primary;

    final spinnerWidget = SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 3.0,
        valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
      ),
    );

    final contentWidget = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        spinnerWidget,
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            message!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: showOverlay ? Colors.white : theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );

    if (showOverlay) {
      // Overlay mode: full-screen with semi-transparent black background
      return Stack(
        children: [
          // Semi-transparent overlay
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.5),
            ),
          ),
          // Centered spinner with message
          Center(
            child: contentWidget,
          ),
        ],
      );
    } else {
      // Inline mode: simple centered spinner
      return Center(
        child: contentWidget,
      );
    }
  }
}
