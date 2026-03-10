import 'package:biko/core/constants/app_constants.dart';
import 'package:biko/core/widgets/app_button.dart';
import 'package:flutter/material.dart';

/// BikeRide error state widget
///
/// Displays an error icon, message, and optional retry button.
/// Use instead of inline error handling for consistent error UX.
///
/// Example usage:
/// ```dart
/// AppErrorWidget(
///   message: 'error.network'.tr,
///   onRetry: () => controller.reload(),
/// )
/// ```
class AppErrorWidget extends StatelessWidget {
  const AppErrorWidget({
    required this.message,
    super.key,
    this.onRetry,
    this.icon = Icons.error_outline,
  });

  /// Error message to display
  final String message;

  /// Callback for the retry button (hidden if null)
  final VoidCallback? onRetry;

  /// Error icon (defaults to error_outline)
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: AppConstants.spacingLg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppConstants.spacingXl),
              AppButton(
                text: 'retry'.tr,
                onPressed: onRetry,
                variant: ButtonVariant.outline,
                width: null,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
