import 'package:biko/core/models/referral_model.dart';
import 'package:biko/core/services/auth_service.dart';
import 'package:biko/core/services/firestore_service.dart';
import 'package:biko/core/widgets/app_snackbar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

/// Controller for the referral program feature.
///
/// Loads referral data, and provides sharing/copying
/// of the user's referral code.
class ReferralController extends GetxController {
  final RxList<ReferralModel> referrals = <ReferralModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxString referralCode = ''.obs;
  final RxDouble totalEarnings = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    _loadReferralData();
  }

  /// Load referral data from Firestore
  Future<void> _loadReferralData() async {
    final uid = AuthService.currentUid;
    if (uid == null) {
      isLoading.value = false;
      return;
    }

    try {
      final data = await FirestoreService.getReferralData(uid);
      referralCode.value = data['code'] as String? ?? '';
      totalEarnings.value =
          (data['totalEarnings'] as num?)?.toDouble() ?? 0.0;
      final referralList = data['referrals'] as List<ReferralModel>? ?? [];
      referrals.value = referralList;
    } catch (e) {
      debugPrint('[ReferralController] Load referral data failed: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Share referral code via platform share sheet
  void shareReferralCode() {
    if (referralCode.value.isEmpty) return;

    final message =
        '${'referral.share_message'.tr} ${referralCode.value}';
    Share.share(message);
  }

  /// Copy referral code to clipboard
  void copyReferralCode() {
    if (referralCode.value.isEmpty) return;

    Clipboard.setData(ClipboardData(text: referralCode.value));
    AppSnackbar.success('referral.copied'.tr);
  }
}
