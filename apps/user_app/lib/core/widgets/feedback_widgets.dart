import 'package:app_core/app_core.dart';
import 'package:flutter/material.dart';
import 'package:user_app/app/user_theme.dart';

class UserInlineMessage extends StatelessWidget {
  const UserInlineMessage({
    required this.message,
    this.icon = Icons.info_outline_rounded,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      border: Border.all(color: UserColors.border),
      borderRadius: BorderRadius.circular(BikoRadius.medium),
    ),
    child: Padding(
      padding: const EdgeInsets.all(BikoSpace.md),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: UserColors.primarySoft,
              borderRadius: BorderRadius.circular(BikoRadius.small),
            ),
            child: Padding(
              padding: const EdgeInsets.all(BikoSpace.xs),
              child: Icon(icon, color: UserColors.primary, size: 20),
            ),
          ),
          const SizedBox(width: BikoSpace.gap),
          Expanded(child: Text(message)),
          if (onAction != null)
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel ?? 'إعادة المحاولة'),
            ),
        ],
      ),
    ),
  );
}

class UserErrorState extends StatelessWidget {
  const UserErrorState({
    required this.message,
    required this.onRetry,
    this.footer,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;
  final Widget? footer;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(BikoSpace.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 48,
            color: UserColors.muted,
          ),
          const SizedBox(height: BikoSpace.md),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: BikoSpace.md),
          FilledButton.tonal(
            onPressed: onRetry,
            child: const Text('إعادة المحاولة'),
          ),
          if (footer != null) ...[
            const SizedBox(height: BikoSpace.gap),
            footer!,
          ],
        ],
      ),
    ),
  );
}
