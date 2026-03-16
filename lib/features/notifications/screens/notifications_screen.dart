import 'package:biko/core/models/notification_model.dart';
import 'package:biko/core/routes/app_routes.dart';
import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_empty_state.dart';
import 'package:biko/core/widgets/app_loading.dart';
import 'package:biko/features/notifications/controllers/notifications_controller.dart';
import 'package:biko/features/notifications/widgets/notification_list_item.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Notifications center screen with styled list items
class NotificationsScreen extends GetView<NotificationsController> {
  const NotificationsScreen({super.key});

  void _navigateToTarget(NotificationModel notif) {
    final targetId = notif.data?['target_id'] as String?;
    switch (notif.type) {
      case 'trip':
      case 'bid':
        if (targetId?.isNotEmpty ?? false) {
          Get.toNamed<void>(
            AppRoutes.trackTrip,
            arguments: {'tripId': targetId},
          );
        }
      case 'wallet':
        Get.toNamed<void>(AppRoutes.customerWallet);
      default:
        break; // non-navigable notification
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('notifications.title'.tr),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: controller.markAllAsRead,
            child: Text(
              'notifications.mark_all_read'.tr,
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: AppLoading());
        }

        if (controller.notifications.isEmpty) {
          return Center(
            child: AppEmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'notifications.empty'.tr,
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          itemCount: controller.notifications.length,
          itemBuilder: (context, index) {
            final notif = controller.notifications[index];
            return NotificationListItem(
              notification: notif,
              onTap: () {
                controller.markAsRead(notif.id);
                _navigateToTarget(notif);
              },
            );
          },
        );
      }),
    );
  }
}
