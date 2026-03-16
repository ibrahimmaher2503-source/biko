import 'package:biko/features/admin/controllers/admin_payment_analytics_controller.dart';
import 'package:get/get.dart';

class AdminPaymentAnalyticsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminPaymentAnalyticsController>(
      AdminPaymentAnalyticsController.new,
    );
  }
}
