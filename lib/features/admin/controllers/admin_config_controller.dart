import 'package:biko/features/admin/controllers/admin_auth_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:get/get.dart';

class AdminConfigController extends GetxController {
  final _firestore = FirebaseFirestore.instance;
  final _functions = FirebaseFunctions.instance;

  // Config field observables
  final baseFare = 0.0.obs;
  final pricePerKm = 0.0.obs;
  final pricePerMin = 0.0.obs;
  final surgeMultiplier = 1.0.obs;
  final commissionRide = 0.0.obs;
  final commissionC2c = 0.0.obs;
  final commissionB2b = 0.0.obs;
  final minBidRadius = 0.0.obs;
  final bidTimeout = 0.0.obs;
  final referrerReward = 0.0.obs;
  final refereeReward = 0.0.obs;
  final maintenanceMode = false.obs;
  final supportPhone = ''.obs;
  final supportEmail = ''.obs;

  final isLoading = false.obs;
  final isSaving = false.obs;

  // Original values for dirty tracking
  final Map<String, dynamic> originalValues = {};

  bool get hasUnsavedChanges {
    return baseFare.value != (originalValues['base_fare'] ?? 0.0) ||
        pricePerKm.value != (originalValues['price_per_km'] ?? 0.0) ||
        pricePerMin.value != (originalValues['price_per_min'] ?? 0.0) ||
        surgeMultiplier.value != (originalValues['surge_multiplier'] ?? 1.0) ||
        commissionRide.value != (originalValues['commission_ride'] ?? 0.0) ||
        commissionC2c.value != (originalValues['commission_c2c'] ?? 0.0) ||
        commissionB2b.value != (originalValues['commission_b2b'] ?? 0.0) ||
        minBidRadius.value != (originalValues['min_bid_radius_km'] ?? 0.0) ||
        bidTimeout.value != (originalValues['bid_timeout_seconds'] ?? 0.0) ||
        referrerReward.value != (originalValues['referrer_reward'] ?? 0.0) ||
        refereeReward.value != (originalValues['referee_reward'] ?? 0.0) ||
        maintenanceMode.value !=
            (originalValues['maintenance_mode'] ?? false) ||
        supportPhone.value != (originalValues['support_phone'] ?? '') ||
        supportEmail.value != (originalValues['support_email'] ?? '');
  }

  @override
  void onInit() {
    super.onInit();
    loadConfig();
  }

  @override
  // ignore: unnecessary_overrides
  void onClose() {
    super.onClose();
  }

  Future<void> loadConfig() async {
    try {
      isLoading.value = true;

      final doc = await _firestore.collection('app_config').doc('config').get();

      if (doc.exists) {
        final data = doc.data()!;
        _updateValuesFromData(data);
        _storeOriginalValues(data);
      }
    } catch (e) {
      Get.snackbar(
        'admin.config.error'.tr,
        'admin.config.load_error'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _updateValuesFromData(Map<String, dynamic> data) {
    baseFare.value = (data['base_fare'] ?? 0.0).toDouble();
    pricePerKm.value = (data['price_per_km'] ?? 0.0).toDouble();
    pricePerMin.value = (data['price_per_min'] ?? 0.0).toDouble();
    surgeMultiplier.value = (data['surge_multiplier'] ?? 1.0).toDouble();
    commissionRide.value = (data['commission_ride'] ?? 0.0).toDouble();
    commissionC2c.value = (data['commission_c2c'] ?? 0.0).toDouble();
    commissionB2b.value = (data['commission_b2b'] ?? 0.0).toDouble();
    minBidRadius.value = (data['min_bid_radius_km'] ?? 0.0).toDouble();
    bidTimeout.value = (data['bid_timeout_seconds'] ?? 0.0).toDouble();
    referrerReward.value = (data['referrer_reward'] ?? 0.0).toDouble();
    refereeReward.value = (data['referee_reward'] ?? 0.0).toDouble();
    maintenanceMode.value = data['maintenance_mode'] ?? false;
    supportPhone.value = data['support_phone'] ?? '';
    supportEmail.value = data['support_email'] ?? '';
  }

  void _storeOriginalValues(Map<String, dynamic> data) {
    originalValues.clear();
    originalValues.addAll(data);
  }

  Future<void> saveConfig() async {
    // Check if user is super admin
    final authController = Get.find<AdminAuthController>();
    if (!authController.isSuperAdmin) {
      Get.snackbar(
        'admin.config.error'.tr,
        'admin.config.super_admin_required'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Validate inputs
    final validationError = validateInputs();
    if (validationError != null) {
      Get.snackbar(
        'admin.config.error'.tr,
        validationError,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      isSaving.value = true;

      final configData = {
        'base_fare': baseFare.value,
        'price_per_km': pricePerKm.value,
        'price_per_min': pricePerMin.value,
        'surge_multiplier': surgeMultiplier.value,
        'commission_ride': commissionRide.value,
        'commission_c2c': commissionC2c.value,
        'commission_b2b': commissionB2b.value,
        'min_bid_radius_km': minBidRadius.value,
        'bid_timeout_seconds': bidTimeout.value,
        'referrer_reward': referrerReward.value,
        'referee_reward': refereeReward.value,
        'maintenance_mode': maintenanceMode.value,
        'support_phone': supportPhone.value,
        'support_email': supportEmail.value,
      };

      // Call Cloud Function to update config
      final callable = _functions.httpsCallable('updateAppConfig');
      await callable.call(configData);

      // Update original values
      _storeOriginalValues(configData);

      Get.snackbar(
        'admin.config.success'.tr,
        'admin.config.save_success'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'admin.config.error'.tr,
        'admin.config.save_error'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSaving.value = false;
    }
  }

  String? validateInputs() {
    if (baseFare.value < 0) {
      return 'admin.config.base_fare_invalid'.tr;
    }
    if (pricePerKm.value < 0) {
      return 'admin.config.price_per_km_invalid'.tr;
    }
    if (pricePerMin.value < 0) {
      return 'admin.config.price_per_min_invalid'.tr;
    }
    if (baseFare.value == 0 &&
        pricePerKm.value == 0 &&
        pricePerMin.value == 0) {
      return 'admin.config.all_prices_zero'.tr;
    }
    if (surgeMultiplier.value < 1.0) {
      return 'admin.config.surge_invalid'.tr;
    }
    if (commissionRide.value < 0 || commissionRide.value > 1) {
      return 'admin.config.commission_ride_invalid'.tr;
    }
    if (commissionC2c.value < 0 || commissionC2c.value > 1) {
      return 'admin.config.commission_c2c_invalid'.tr;
    }
    if (commissionB2b.value < 0 || commissionB2b.value > 1) {
      return 'admin.config.commission_b2b_invalid'.tr;
    }
    if (minBidRadius.value < 0) {
      return 'admin.config.min_bid_radius_invalid'.tr;
    }
    if (bidTimeout.value < 0) {
      return 'admin.config.bid_timeout_invalid'.tr;
    }
    if (referrerReward.value < 0) {
      return 'admin.config.referrer_reward_invalid'.tr;
    }
    if (refereeReward.value < 0) {
      return 'admin.config.referee_reward_invalid'.tr;
    }
    if (supportEmail.value.isNotEmpty &&
        !GetUtils.isEmail(supportEmail.value)) {
      return 'admin.config.support_email_invalid'.tr;
    }
    return null;
  }

  void resetToSaved() {
    if (originalValues.isNotEmpty) {
      _updateValuesFromData(originalValues);
      Get.snackbar(
        'admin.config.success'.tr,
        'admin.config.reset_success'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> toggleMaintenanceMode(bool value) async {
    // Check if user is super admin
    final authController = Get.find<AdminAuthController>();
    if (!authController.isSuperAdmin) {
      Get.snackbar(
        'admin.config.error'.tr,
        'admin.config.super_admin_required'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    maintenanceMode.value = value;

    if (value) {
      // Show warning for enabling maintenance mode
      Get.snackbar(
        'admin.config.warning'.tr,
        'admin.config.maintenance_mode_enabled_warning'.tr,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
    }
  }
}
