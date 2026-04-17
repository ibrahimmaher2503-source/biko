import 'package:biko/features/dispatch/controllers/dispatch_controller.dart';
import 'package:get/get.dart';

class DispatchBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DispatchController>(() => DispatchController());
  }
}
