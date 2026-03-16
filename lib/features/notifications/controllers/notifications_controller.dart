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
    final uid = AuthService.currentUid;
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
    // Optimistic update
    final index = notifications.indexWhere((n) => n.id == notificationId);
    if (index == -1) return;

    final original = notifications[index];
    if (original.isRead) return; // Already read

    notifications[index] = original.copyWith(isRead: true);
    unreadCount.value = notifications.where((n) => !n.isRead).length;

    try {
      await FirestoreService.markNotificationRead(notificationId);
    } catch (e) {
      // Rollback on failure
      debugPrint('[NotificationsController] markAsRead failed: $e');
      notifications[index] = original;
      unreadCount.value = notifications.where((n) => !n.isRead).length;
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    final uid = AuthService.currentUid;
    if (uid == null) return;

    // Save original state for rollback
    final originalList = List<NotificationModel>.from(notifications);
    final originalUnread = unreadCount.value;

    // Optimistic update
    notifications.value = notifications
        .map((n) => n.copyWith(isRead: true))
        .toList();
    unreadCount.value = 0;

    try {
      await FirestoreService.markAllNotificationsRead(uid);
      AppSnackbar.success('notifications.all_read'.tr);
    } catch (e) {
      // Rollback on failure
      debugPrint('[NotificationsController] markAllAsRead failed: $e');
      notifications.value = originalList;
      unreadCount.value = originalUnread;
      AppSnackbar.error('error.operation_failed'.tr);
    }
  }
}
