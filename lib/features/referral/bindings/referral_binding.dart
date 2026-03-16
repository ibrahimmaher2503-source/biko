import 'package:biko/features/referral/controllers/referral_controller.dart';
import 'package:get/get.dart';

/// Binding for referral screen
class ReferralBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ReferralController>(ReferralController.new);
  }
}
