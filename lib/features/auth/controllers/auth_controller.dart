import 'dart:async';

import 'package:biko/core/constants/dev_config.dart';
import 'package:biko/core/models/enums.dart';
import 'package:biko/core/routes/app_routes.dart';
import 'package:biko/core/services/auth_service.dart';
import 'package:biko/core/services/fcm_service.dart';
import 'package:biko/core/services/firestore_service.dart';
import 'package:biko/core/widgets/app_snackbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

/// Global authentication controller — registered permanently in AppInitializer
class AuthController extends GetxController {
  // ==================== Observable State ====================

  final _authState = AuthState.idle.obs;
  final phoneNumber = ''.obs;
  final _verificationId = ''.obs;
  final _resendToken = Rxn<int>();
  final secondsRemaining = 0.obs;
  final errorMessage = ''.obs;

  // ==================== Getters ====================

  AuthState get authState => _authState.value;
  bool get isLoading =>
      _authState.value == AuthState.sendingOtp ||
      _authState.value == AuthState.verifying ||
      _authState.value == AuthState.signingInWithGoogle ||
      _authState.value == AuthState.signingInWithFacebook;
  bool get isAuthenticated => AuthService.currentUser != null;
  bool get isResendEnabled => secondsRemaining.value == 0;

  Timer? _timer;

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  // ==================== Phone Validation ====================

  /// Validate Egyptian phone number (10 digits: 1X XXXX XXXX)
  /// Accepted operator prefixes: 10, 11, 12, 15
  bool isValidEgyptianPhone(String number) {
    final cleaned = number.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length != 10) return false;
    return RegExp(r'^1[0125]\d{8}$').hasMatch(cleaned);
  }

  // ==================== OTP Flow ====================

  /// Send OTP to the provided phone number
  Future<void> sendOtp(String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    if (!isValidEgyptianPhone(cleaned)) {
      errorMessage.value = 'error.invalid_phone'.tr;
      return;
    }

    // Dev bypass: skip Firebase OTP entirely
    if (DevConfig.skipOtp) {
      phoneNumber.value = cleaned;
      Get.offAllNamed(AppRoutes.profileSetup);
      return;
    }

    _authState.value = AuthState.sendingOtp;
    errorMessage.value = '';
    phoneNumber.value = cleaned;

    final fullNumber = '+20$cleaned';

    await AuthService.sendOtp(
      phoneNumber: fullNumber,
      resendToken: _resendToken.value,
      onAutoVerify: _onAutoVerify,
      onFailed: _onVerificationFailed,
      onCodeSent: _onCodeSent,
      onTimeout: _onTimeout,
    );
  }

  Future<void> _onAutoVerify(PhoneAuthCredential credential) async {
    _authState.value = AuthState.verifying;
    try {
      await AuthService.signInWithCredential(credential);
      _authState.value = AuthState.authenticated;
      await _navigateAfterAuth();
    } on FirebaseAuthException catch (e) {
      _authState.value = AuthState.error;
      errorMessage.value = e.message ?? 'error.otp_failed'.tr;
    }
  }

  void _onVerificationFailed(FirebaseAuthException e) {
    _authState.value = AuthState.error;
    errorMessage.value = e.message ?? 'error.otp_failed'.tr;
  }

  void _onCodeSent(String verificationId, int? resendToken) {
    _verificationId.value = verificationId;
    _resendToken.value = resendToken;
    _authState.value = AuthState.codeSent;
    _startTimer();
    Get.toNamed(AppRoutes.otpVerification);
  }

  void _onTimeout(String verificationId) {
    _verificationId.value = verificationId;
  }

  /// Verify the user-entered OTP code
  Future<void> verifyOtp(String smsCode) async {
    if (smsCode.length != 4) return;

    _authState.value = AuthState.verifying;
    errorMessage.value = '';

    try {
      await AuthService.verifyOtp(
        verificationId: _verificationId.value,
        smsCode: smsCode,
      );
      _authState.value = AuthState.authenticated;
      _timer?.cancel();
      await _navigateAfterAuth();
    } on FirebaseAuthException catch (e) {
      _authState.value = AuthState.error;
      errorMessage.value = e.message ?? 'error.otp_failed'.tr;
    }
  }

  /// Resend OTP — resets timer and re-sends
  Future<void> resendOtp() async {
    if (!isResendEnabled) return;
    await sendOtp(phoneNumber.value);
  }

  // ==================== Timer ====================

  void _startTimer() {
    _timer?.cancel();
    secondsRemaining.value = 30;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsRemaining.value > 0) {
        secondsRemaining.value--;
      } else {
        timer.cancel();
      }
    });
  }

  // ==================== Google Sign-In ====================

  /// Sign in with Google account
  Future<void> signInWithGoogle() async {
    _authState.value = AuthState.signingInWithGoogle;
    errorMessage.value = '';

    try {
      final userCredential = await AuthService.signInWithGoogle();

      // User cancelled the Google picker
      if (userCredential == null) {
        _authState.value = AuthState.idle;
        return;
      }

      _authState.value = AuthState.authenticated;
      await _navigateAfterAuth();
    } catch (e) {
      _authState.value = AuthState.idle;
      errorMessage.value = 'error.google_sign_in_failed'.tr;
      AppSnackbar.error('error.google_sign_in_failed'.tr);
    }
  }

  // ==================== Facebook Sign-In ====================

  /// Sign in with Facebook account
  Future<void> signInWithFacebook() async {
    _authState.value = AuthState.signingInWithFacebook;
    errorMessage.value = '';

    try {
      final userCredential = await AuthService.signInWithFacebook();

      // User cancelled the Facebook dialog
      if (userCredential == null) {
        _authState.value = AuthState.idle;
        return;
      }

      _authState.value = AuthState.authenticated;
      await _navigateAfterAuth();
    } catch (e) {
      _authState.value = AuthState.idle;
      errorMessage.value = 'error.facebook_sign_in_failed'.tr;
      AppSnackbar.error('error.facebook_sign_in_failed'.tr);
    }
  }

  // ==================== Post-Auth Navigation ====================

  Future<void> _navigateAfterAuth() async {
    final user = AuthService.currentUser;
    if (user == null) return;

    // Initialize FCM: request permission, save token, set up listeners
    await FcmService.initialize();

    final userModel = await FirestoreService.getUser(user.uid);

    // New user or incomplete profile → profile setup
    if (userModel == null || !userModel.isProfileComplete) {
      Get.offAllNamed(AppRoutes.profileSetup);
      return;
    }

    // Driver with pending approval
    if (userModel.type == UserType.driver &&
        userModel.status == UserStatus.pendingApproval) {
      Get.offAllNamed(AppRoutes.pendingApproval);
      return;
    }

    // Returning user → home
    if (userModel.type == UserType.driver) {
      Get.offAllNamed(AppRoutes.driverHome);
    } else {
      Get.offAllNamed(AppRoutes.customerHome);
    }
  }

  // ==================== Sign Out ====================

  Future<void> signOut() async {
    await FcmService.clearToken();
    await AuthService.signOut();
    _authState.value = AuthState.idle;
    phoneNumber.value = '';
    _verificationId.value = '';
    errorMessage.value = '';
    Get.offAllNamed(AppRoutes.phoneLogin);
  }
}
