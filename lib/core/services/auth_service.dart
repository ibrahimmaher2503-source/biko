import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Opaque wrapper for phone auth credentials.
///
/// Hides [PhoneAuthCredential] from controllers so they never
/// import `firebase_auth` directly (RULE-06 compliance).
class PhoneCredential {
  PhoneCredential._(this._credential);
  final PhoneAuthCredential _credential;
}

/// Wraps Firebase Phone Authentication
class AuthService {
  AuthService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Current authenticated user (null if not signed in)
  static User? get currentUser => _auth.currentUser;

  /// Send OTP to the given phone number (E.164 format: +20XXXXXXXXXX)
  ///
  /// Callbacks use project types instead of Firebase types:
  /// - [onAutoVerify] receives a [PhoneCredential] (opaque)
  /// - [onFailed] receives an error message [String]
  static Future<void> sendOtp({
    required String phoneNumber,
    required void Function(PhoneCredential) onAutoVerify,
    required void Function(String errorMessage) onFailed,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(String verificationId) onTimeout,
    int? resendToken,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (credential) {
        onAutoVerify(PhoneCredential._(credential));
      },
      verificationFailed: (exception) {
        onFailed(exception.message ?? 'error.otp_failed');
      },
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: onTimeout,
      forceResendingToken: resendToken,
      timeout: const Duration(seconds: 60),
    );
  }

  /// Verify OTP code and sign in
  static Future<UserCredential> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return _auth.signInWithCredential(credential);
  }

  /// Sign in with an opaque [PhoneCredential] (auto-verify flow)
  static Future<UserCredential> signInWithPhoneCredential(
    PhoneCredential credential,
  ) async {
    return _auth.signInWithCredential(credential._credential);
  }

  /// Sign in with Google — returns null if user cancelled the picker
  static Future<UserCredential?> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  /// Sign in with Facebook — returns null if user cancelled
  static Future<UserCredential?> signInWithFacebook() async {
    final result = await FacebookAuth.instance.login(
      permissions: ['public_profile'],
    );
    if (result.status != LoginStatus.success) return null;

    final accessToken = result.accessToken;
    if (accessToken == null) return null;

    final credential = FacebookAuthProvider.credential(accessToken.tokenString);
    return _auth.signInWithCredential(credential);
  }

  /// Sign out from all providers and Firebase
  static Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
    } catch (e) {
      debugPrint('GoogleSignIn.signOut failed: $e');
    }
    try {
      await FacebookAuth.instance.logOut();
    } catch (e) {
      debugPrint('FacebookAuth.logOut failed: $e');
    }
    await _auth.signOut();
  }
}
