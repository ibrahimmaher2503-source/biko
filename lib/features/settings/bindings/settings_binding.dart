import 'package:biko/features/profile/controllers/profile_controller.dart';
import 'package:get/get.dart';

/// Binding for settings screen — reuses ProfileController
class SettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProfileController>(ProfileController.new);
  }
}
