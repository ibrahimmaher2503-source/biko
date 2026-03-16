import 'package:biko/features/admin/services/admin_firestore_service.dart';
import 'package:get/get.dart';

class AdminPromosController extends GetxController {
  final promos = <Map<String, dynamic>>[].obs;
  final statusFilter = 'all'.obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadPromos();
  }

  Future<void> loadPromos() async {
    try {
      isLoading.value = true;

      final allPromos = await AdminFirestoreService.getPromoCodes();

      promos.value = allPromos.where((promo) {
        if (statusFilter.value == 'all') return true;

        final status = getStatusLabel(promo);
        return status == statusFilter.value;
      }).toList();
    } catch (e) {
      Get.snackbar(
        'admin.promos.error_title'.tr,
        'admin.promos.load_error'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createPromo({
    required String code,
    required String type,
    required double value,
    required int maxUses,
    required double minTripValue,
    required DateTime expiryDate,
  }) async {
    try {
      isLoading.value = true;

      await AdminFirestoreService.createPromoCode(code, {
        'type': type,
        'value': value,
        'max_uses': maxUses,
        'used_count': 0,
        'min_trip_value': minTripValue,
        'expiry_date': expiryDate,
        'is_active': true,
      });

      Get.snackbar(
        'admin.promos.success_title'.tr,
        'admin.promos.create_success'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );

      await loadPromos();
    } catch (e) {
      Get.snackbar(
        'admin.promos.error_title'.tr,
        'admin.promos.create_error'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> editPromo(String code, Map<String, dynamic> updates) async {
    try {
      isLoading.value = true;

      await AdminFirestoreService.updatePromoCode(code, updates);

      Get.snackbar(
        'admin.promos.success_title'.tr,
        'admin.promos.edit_success'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );

      await loadPromos();
    } catch (e) {
      Get.snackbar(
        'admin.promos.error_title'.tr,
        'admin.promos.edit_error'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deactivatePromo(String code) async {
    try {
      isLoading.value = true;

      await AdminFirestoreService.updatePromoCode(code, {
        'is_active': false,
      });

      Get.snackbar(
        'admin.promos.success_title'.tr,
        'admin.promos.deactivate_success'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );

      await loadPromos();
    } catch (e) {
      Get.snackbar(
        'admin.promos.error_title'.tr,
        'admin.promos.deactivate_error'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  bool isExhausted(Map<String, dynamic> promo) {
    final usedCount = promo['used_count'] as int? ?? 0;
    final maxUses = promo['max_uses'] as int? ?? 0;
    return usedCount >= maxUses;
  }

  String getStatusLabel(Map<String, dynamic> promo) {
    final isActive = promo['is_active'] as bool? ?? false;
    final expiryDate =
        AdminFirestoreService.timestampToDateTime(promo['expiry_date']);
    final now = DateTime.now();

    if (!isActive) return 'inactive';
    if (expiryDate != null && expiryDate.isBefore(now)) return 'expired';
    if (isExhausted(promo)) return 'exhausted';
    return 'active';
  }
}
