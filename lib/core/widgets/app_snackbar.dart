import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Snackbar type for different notification states
enum SnackbarType {
  /// Success notification (green background)
  success,

  /// Error notification (red background)
  error,

  /// Info notification (blue background)
  info,

  /// Warning notification (orange background)
  warning,
}

/// BikeRide branded snackbar utility using GetX
///
/// Provides consistent notification styling across all apps with:
/// - Four predefined types (success, error, info, warning)
/// - Custom colors and icons for each type
/// - Auto-dismiss with configurable duration
/// - Swipe to dismiss support
/// - Optional tap callback
/// - RTL-compatible layout
///
/// Example usage:
/// ```dart
/// // Show success message
/// AppSnackbar.success('Profile updated successfully');
///
/// // Show error with custom duration
/// AppSnackbar.error(
///   'Failed to save data',
///   duration: Duration(seconds: 5),
/// );
///
/// // Show with tap callback
/// AppSnackbar.info(
///   'New update available',
///   onTap: () => _handleUpdateTap(),
/// );
/// ```
class AppSnackbar {
  // Prevent instantiation
  AppSnackbar._();

  /// Show a snackbar with custom type, message, and options
  static void show({
    required String message,
    required SnackbarType type,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onTap,
  }) {
    final config = _getConfig(type);

    if (kDebugMode) {
      final log = message.isEmpty
          ? '[Snackbar] ${config.title}'
          : '[Snackbar] ${config.title}: $message';
      debugPrint(log);
    }

    Get.snackbar(
      config.title,
      message,
      backgroundColor: config.backgroundColor,
      colorText: Colors.white,
      icon: Icon(config.icon, color: Colors.white, size: 24),
      duration: duration,
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      onTap: onTap != null ? (_) => onTap() : null,
      animationDuration: const Duration(milliseconds: 300),
    );
  }

  /// Show success snackbar
  static void success(
    String message, {
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onTap,
  }) {
    show(
      message: message,
      type: SnackbarType.success,
      duration: duration,
      onTap: onTap,
    );
  }

  /// Show error snackbar
  static void error(
    String message, {
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onTap,
  }) {
    show(
      message: message,
      type: SnackbarType.error,
      duration: duration,
      onTap: onTap,
    );
  }

  /// Show info snackbar
  static void info(
    String message, {
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onTap,
  }) {
    show(
      message: message,
      type: SnackbarType.info,
      duration: duration,
      onTap: onTap,
    );
  }

  /// Show warning snackbar
  static void warning(
    String message, {
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onTap,
  }) {
    show(
      message: message,
      type: SnackbarType.warning,
      duration: duration,
      onTap: onTap,
    );
  }

  /// Get snackbar configuration for each type
  static _SnackbarConfig _getConfig(SnackbarType type) {
    switch (type) {
      case SnackbarType.success:
        return const _SnackbarConfig(
          title: 'Success',
          backgroundColor: Color(0xFF4CAF50), // Green
          icon: Icons.check_circle,
        );

      case SnackbarType.error:
        return const _SnackbarConfig(
          title: 'Error',
          backgroundColor: Color(0xFFF44336), // Red
          icon: Icons.error,
        );

      case SnackbarType.info:
        return const _SnackbarConfig(
          title: 'Info',
          backgroundColor: Color(0xFF2196F3), // Blue
          icon: Icons.info,
        );

      case SnackbarType.warning:
        return const _SnackbarConfig(
          title: 'Warning',
          backgroundColor: Color(0xFFFF9800), // Orange
          icon: Icons.warning,
        );
    }
  }
}

/// Internal configuration class for snackbar styling
class _SnackbarConfig {
  const _SnackbarConfig({
    required this.title,
    required this.backgroundColor,
    required this.icon,
  });

  final String title;
  final Color backgroundColor;
  final IconData icon;
}
