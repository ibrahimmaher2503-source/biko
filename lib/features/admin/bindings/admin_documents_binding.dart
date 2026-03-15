import 'package:biko/features/admin/controllers/admin_documents_controller.dart';
import 'package:get/get.dart';

/// Binding for AdminDocumentsController.
class AdminDocumentsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminDocumentsController>(AdminDocumentsController.new);
  }
}
