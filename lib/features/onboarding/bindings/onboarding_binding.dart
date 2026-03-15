import 'package:biko/features/onboarding/controllers/onboarding_controller.dart';
import 'package:get/get.dart';

class OnboardingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(OnboardingController.new);
  }
}
