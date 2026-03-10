import 'package:biko/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// BikeRide bottom sheet wrapper
///
/// Provides consistent bottom sheet styling with drag handle,
/// rounded top corners, and theme-aware colors.
///
/// Example usage:
/// ```dart
/// AppBottomSheet.show(
///   child: Column(
///     children: [
///       Text('title'.tr),
///       // ... content
///     ],
///   ),
/// );
/// ```
class AppBottomSheet {
  AppBottomSheet._();

  /// Show a modal bottom sheet with consistent styling
  static Future<T?> show<T>({
    required Widget child,
    bool isDismissible = true,
    bool enableDrag = true,
    bool isScrollControlled = true,
    double? maxHeight,
  }) {
    return Get.bottomSheet<T>(
      _BottomSheetContent(
        maxHeight: maxHeight,
        child: child,
      ),
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
    );
  }
}

class _BottomSheetContent extends StatelessWidget {
  const _BottomSheetContent({
    required this.child,
    this.maxHeight,
  });

  final Widget child;
  final double? maxHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget content = Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: AppConstants.spacingSm),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppConstants.spacingSm),
          // Content
          Flexible(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppConstants.spacingLg,
                0,
                AppConstants.spacingLg,
                AppConstants.spacingLg,
              ),
              child: child,
            ),
          ),
        ],
      ),
    );

    if (maxHeight != null) {
      content = ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight!),
        child: content,
      );
    }

    return content;
  }
}
