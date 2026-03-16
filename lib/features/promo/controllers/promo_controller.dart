import 'package:biko/core/models/promo_code_model.dart';
import 'package:biko/core/services/auth_service.dart';
import 'package:biko/core/services/firestore_service.dart';
import 'package:biko/core/widgets/app_snackbar.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// Controller for the promo codes feature.
///
/// Loads user's promo codes from Firestore and validates
/// new codes via Cloud Function.
class PromoController extends GetxController {
  final RxList<PromoCodeModel> promoCodes = <PromoCodeModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isApplying = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString promoInput = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _loadPromoCodes();
  }

  /// Load user's promo codes from Firestore
  Future<void> _loadPromoCodes() async {
    final uid = AuthService.currentUid;
    if (uid == null) {
      isLoading.value = false;
      return;
    }

    try {
      final codes = await FirestoreService.getUserPromoCodes(uid);
      promoCodes.value = codes;
    } catch (e) {
      debugPrint('[PromoController] Load promo codes failed: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Apply a promo code via Cloud Function validation
  Future<void> applyPromoCode(String code) async {
    if (code.trim().isEmpty) {
      errorMessage.value = 'promo.enter_code'.tr;
      return;
    }

    final uid = AuthService.currentUid;
    if (uid == null) return;

    isApplying.value = true;
    errorMessage.value = '';

    try {
      final result = await FirestoreService.validatePromoCode(code.trim(), uid);
      if (result != null) {
        promoCodes.add(result);
        promoInput.value = '';
        AppSnackbar.success('promo.applied_success'.tr);
      } else {
        errorMessage.value = 'promo.invalid_code'.tr;
      }
    } catch (e) {
      debugPrint('[PromoController] Apply promo code failed: $e');
      errorMessage.value = 'promo.apply_failed'.tr;
    } finally {
      isApplying.value = false;
    }
  }
}
