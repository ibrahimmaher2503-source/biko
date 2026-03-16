import 'package:biko/core/widgets/app_snackbar.dart';
import 'package:get/get.dart';

import '../models/notification_record_model.dart';
import '../services/admin_firestore_service.dart';
import 'admin_auth_controller.dart';

class AdminNotificationsController extends GetxController {
  final targetSegment = 'all'.obs;
  final specificUid = ''.obs;
  final titleAr = ''.obs;
  final titleEn = ''.obs;
  final bodyAr = ''.obs;
  final bodyEn = ''.obs;
  final isLoading = false.obs;
  final isSending = false.obs;
  final sentHistory = <NotificationRecordModel>[].obs;

  /// Whether the notification form is complete and ready to send.
  bool get isFormValid =>
      titleAr.value.isNotEmpty &&
      titleEn.value.isNotEmpty &&
      bodyAr.value.isNotEmpty &&
      bodyEn.value.isNotEmpty &&
      (targetSegment.value != 'specific' || specificUid.value.isNotEmpty);

  @override
  void onInit() {
    super.onInit();
    loadSentHistory();
  }

  Future<void> sendNotification() async {
    try {
      isSending.value = true;

      final authController = Get.find<AdminAuthController>();
      final senderUid = authController.currentUser?.uid ?? '';
      final senderName = authController.currentUser?.displayName ?? 'Admin';

      if (targetSegment.value == 'specific') {
        // Send to specific user
        await AdminFirestoreService.callCloudFunction('sendToUser', {
          'uid': specificUid.value,
          'title_ar': titleAr.value,
          'title_en': titleEn.value,
          'body_ar': bodyAr.value,
          'body_en': bodyEn.value,
        });
      } else {
        // Send to segment
        await AdminFirestoreService.callCloudFunction('sendToSegment', {
          'segment': targetSegment.value,
          'title_ar': titleAr.value,
          'title_en': titleEn.value,
          'body_ar': bodyAr.value,
          'body_en': bodyEn.value,
        });
      }

      // Record notification in history
      final record = NotificationRecordModel(
        id: '',
        targetSegment: targetSegment.value == 'specific'
            ? 'specific:${specificUid.value}'
            : targetSegment.value,
        titleAr: titleAr.value,
        titleEn: titleEn.value,
        bodyAr: bodyAr.value,
        bodyEn: bodyEn.value,
        senderUid: senderUid,
        senderName: senderName,
        sentAt: DateTime.now(),
      );

      await AdminFirestoreService.recordNotification(record.toJson());

      AppSnackbar.success('admin.notifications.send_success'.tr);

      clearForm();
      await loadSentHistory();
    } catch (e) {
      AppSnackbar.error('admin.notifications.send_error'.tr);
    } finally {
      isSending.value = false;
    }
  }

  Future<void> loadSentHistory() async {
    try {
      isLoading.value = true;

      final docs = await AdminFirestoreService.getNotificationHistory();

      sentHistory.value = docs
          .map((map) => NotificationRecordModel.fromMap(map, map['id'] as String?))
          .toList();
    } catch (e) {
      AppSnackbar.error('admin.notifications.load_error'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  // ignore: unnecessary_overrides
  void onClose() {
    super.onClose();
  }

  void clearForm() {
    targetSegment.value = 'all';
    specificUid.value = '';
    titleAr.value = '';
    titleEn.value = '';
    bodyAr.value = '';
    bodyEn.value = '';
  }
}
