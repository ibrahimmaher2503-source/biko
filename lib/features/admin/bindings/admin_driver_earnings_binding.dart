import 'package:biko/features/admin/controllers/admin_driver_earnings_controller.dart';
import 'package:get/get.dart';

class AdminDriverEarningsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminDriverEarningsController>(
      AdminDriverEarningsController.new,
    );
  }
}
