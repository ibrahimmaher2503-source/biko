import 'package:biko/features/chat/controllers/chat_controller.dart';
import 'package:get/get.dart';

/// Binding for chat screen
class ChatBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ChatController>(ChatController.new);
  }
}
