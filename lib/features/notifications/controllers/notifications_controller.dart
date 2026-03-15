import 'dart:async';

import 'package:biko/core/models/notification_model.dart';
import 'package:biko/core/services/auth_service.dart';
import 'package:biko/core/services/firestore_service.dart';
import 'package:biko/core/widgets/app_snackbar.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// Controller for the notifications center.
///
/// Loads user notifications from Firestore and provides
/// mark-as-read functionality (single and batch).
class NotificationsController extends GetxController {
  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxInt unreadCount = 0.obs;

  StreamSubscription<List<NotificationModel>>? _notificationsSub;

  @override
  void onInit() {
    super.onInit();
    _loadNotifications();
  }

  @override
  void onClose() {
    _notificationsSub?.cancel();
    super.onClose();
  }

  /// Load notifications from Firestore
  void _loadNotifications() {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) {
      isLoading.value = false;
      return;
    }

    _notificationsSub = FirestoreService.listenToNotifications(uid).listen(
      (notifs) {
        notifications.value = notifs;
        unreadCount.value = notifs.where((n) => !n.isRead).length;
        isLoading.value = false;
      },
      onError: (e) {
        debugPrint('[NotificationsController] Stream error: $e');
        isLoading.value = false;
      },
    );
  }

  /// Mark a single notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await FirestoreService.markNotificationRead(notificationId);
      // Optimistic update
      final index = notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        notifications[index] = notifications[index].copyWith(isRead: true);
        unreadCount.value = notifications.where((n) => !n.isRead).length;
      }
    } catch (e) {
      debugPrint('[NotificationsController] markAsRead failed: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return;

    try {
      await FirestoreService.markAllNotificationsRead(uid);
      // Optimistic update
      notifications.value = notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();
      unreadCount.value = 0;
      AppSnackbar.success('notifications.all_read'.tr);
    } catch (e) {
      debugPrint('[NotificationsController] markAllAsRead failed: $e');
      AppSnackbar.error('error.operation_failed'.tr);
    }
  }
}
