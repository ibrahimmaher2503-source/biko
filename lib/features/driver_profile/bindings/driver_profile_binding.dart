import 'package:biko/features/driver_profile/controllers/driver_profile_controller.dart';
import 'package:get/get.dart';

/// Binding for the driver profile screen.
class DriverProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DriverProfileController>(DriverProfileController.new);
  }
}
