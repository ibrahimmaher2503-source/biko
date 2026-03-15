import 'package:biko/features/driver_settings/controllers/driver_settings_controller.dart';
import 'package:get/get.dart';

/// Binding for the driver settings screen.
class DriverSettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DriverSettingsController>(DriverSettingsController.new);
  }
}
