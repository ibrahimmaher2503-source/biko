import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class AdminPromosController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

      final Query query = _firestore
          .collection('promo_codes')
          .orderBy('expiry_date', descending: true);

      final snapshot = await query.get();

      promos.value = snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['code'] = doc.id;
            return data;
          })
          .where((promo) {
            if (statusFilter.value == 'all') return true;

            final status = getStatusLabel(promo);
            return status == statusFilter.value;
          })
          .toList();
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

      await _firestore.collection('promo_codes').doc(code).set({
        'type': type,
        'value': value,
        'max_uses': maxUses,
        'used_count': 0,
        'min_trip_value': minTripValue,
        'expiry_date': Timestamp.fromDate(expiryDate),
        'is_active': true,
        'created_at': FieldValue.serverTimestamp(),
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

      // Convert DateTime to Timestamp if expiry_date is being updated
      if (updates.containsKey('expiry_date') &&
          updates['expiry_date'] is DateTime) {
        updates['expiry_date'] = Timestamp.fromDate(
          updates['expiry_date'] as DateTime,
        );
      }

      await _firestore.collection('promo_codes').doc(code).update(updates);

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

      await _firestore.collection('promo_codes').doc(code).update({
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
    final expiryDate = (promo['expiry_date'] as Timestamp?)?.toDate();
    final now = DateTime.now();

    if (!isActive) return 'inactive';
    if (expiryDate != null && expiryDate.isBefore(now)) return 'expired';
    if (isExhausted(promo)) return 'exhausted';
    return 'active';
  }
}
