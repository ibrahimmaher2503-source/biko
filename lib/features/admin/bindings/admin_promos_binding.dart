import 'package:get/get.dart';
import '../controllers/admin_promos_controller.dart';

class AdminPromosBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminPromosController>(AdminPromosController.new);
  }
}
