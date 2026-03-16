import 'package:biko/features/driver_chat/controllers/chat_controller.dart';
import 'package:get/get.dart';

/// Binding for the driver chat screen.
class ChatBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ChatController>(ChatController.new);
  }
}
