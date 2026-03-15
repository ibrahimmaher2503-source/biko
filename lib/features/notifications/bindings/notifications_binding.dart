import 'package:biko/features/notifications/controllers/notifications_controller.dart';
import 'package:get/get.dart';

/// Binding for notifications screen
class NotificationsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NotificationsController>(NotificationsController.new);
  }
}
