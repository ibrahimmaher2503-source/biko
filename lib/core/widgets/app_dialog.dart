import 'package:biko/core/constants/app_constants.dart';
import 'package:biko/core/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// BikeRide confirmation dialog wrapper
///
/// Provides consistent dialog styling with title, content,
/// and confirm/cancel actions using GetX.
///
/// Example usage:
/// ```dart
/// final confirmed = await AppDialog.confirm(
///   title: 'cancel_trip'.tr,
///   content: 'cancel_trip_confirm'.tr,
///   confirmText: 'yes'.tr,
///   cancelText: 'no'.tr,
/// );
/// if (confirmed) { /* ... */ }
/// ```
class AppDialog {
  AppDialog._();

  /// Show a confirmation dialog with confirm/cancel buttons
  ///
  /// Returns `true` if confirmed, `false` if cancelled or dismissed.
  static Future<bool> confirm({
    required String title,
    required String content,
    String? confirmText,
    String? cancelText,
    bool isDestructive = false,
  }) async {
    final result = await Get.dialog<bool>(
      _ConfirmDialog(
        title: title,
        content: content,
        confirmText: confirmText ?? 'confirm'.tr,
        cancelText: cancelText ?? 'cancel'.tr,
        isDestructive: isDestructive,
      ),
    );
    return result ?? false;
  }

  /// Show an info dialog with a single OK button
  static Future<void> info({
    required String title,
    required String content,
    String? buttonText,
  }) async {
    await Get.dialog(
      _InfoDialog(
        title: title,
        content: content,
        buttonText: buttonText ?? 'ok'.tr,
      ),
    );
  }
}

class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({
    required this.title,
    required this.content,
    required this.confirmText,
    required this.cancelText,
    required this.isDestructive,
  });

  final String title;
  final String content;
  final String confirmText;
  final String cancelText;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title, style: theme.textTheme.titleLarge),
      content: Text(
        content,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      actions: [
        AppButton(
          text: cancelText,
          onPressed: () => Get.back(result: false),
          variant: ButtonVariant.text,
          width: null,
          height: 40,
        ),
        const SizedBox(width: AppConstants.spacingSm),
        if (isDestructive)
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(
              confirmText,
              style: TextStyle(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        else
          AppButton(
            text: confirmText,
            onPressed: () => Get.back(result: true),
            width: null,
            height: 40,
          ),
      ],
      actionsPadding: const EdgeInsetsDirectional.fromSTEB(
        AppConstants.spacingLg,
        0,
        AppConstants.spacingLg,
        AppConstants.spacingLg,
      ),
    );
  }
}

class _InfoDialog extends StatelessWidget {
  const _InfoDialog({
    required this.title,
    required this.content,
    required this.buttonText,
  });

  final String title;
  final String content;
  final String buttonText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title, style: theme.textTheme.titleLarge),
      content: Text(
        content,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      actions: [
        AppButton(
          text: buttonText,
          onPressed: Get.back,
          width: null,
          height: 40,
        ),
      ],
      actionsPadding: const EdgeInsetsDirectional.fromSTEB(
        AppConstants.spacingLg,
        0,
        AppConstants.spacingLg,
        AppConstants.spacingLg,
      ),
    );
  }
}
