import 'package:biko/core/models/notification_model.dart';
import 'package:biko/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Single notification list item with bordered container
class NotificationListItem extends StatelessWidget {
  const NotificationListItem({
    required this.notification,
    required this.onTap,
    super.key,
  });

  final NotificationModel notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = Theme.of(context).extension<AppColorsExtension>()!;
    final dateFormat = DateFormat('dd MMM, hh:mm a');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: notification.isRead
                ? ext.surfaceElevated
                : AppTheme.primary.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(
              color: notification.isRead
                  ? ext.borderSubtle
                  : AppTheme.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              // Icon in tinted circle
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: notification.isRead
                      ? ext.surfaceContainer
                      : AppTheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getIconForType(notification.type),
                  color: notification.isRead
                      ? ext.textMuted
                      : AppTheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: notification.isRead
                            ? FontWeight.w500
                            : FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateFormat.format(notification.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: ext.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              // Unread dot
              if (!notification.isRead)
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'trip':
        return Icons.directions_bike_rounded;
      case 'wallet':
        return Icons.account_balance_wallet_rounded;
      case 'promo':
        return Icons.local_offer_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }
}
