import 'package:get/get.dart';
import '../controllers/admin_referral_controller.dart';

class AdminReferralBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminReferralController>(AdminReferralController.new);
  }
}
