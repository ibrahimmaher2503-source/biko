import 'package:biko/features/dropoff/controllers/dropoff_controller.dart';
import 'package:get/get.dart';

/// GetX binding for the Set Dropoff Location screen.
class DropoffBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(DropoffController.new);
  }
}
