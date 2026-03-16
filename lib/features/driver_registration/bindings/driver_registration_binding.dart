import 'package:biko/features/driver_registration/controllers/driver_registration_controller.dart';
import 'package:get/get.dart';

class DriverRegistrationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(DriverRegistrationController.new);
  }
}
