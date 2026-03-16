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

/// Opaque wrapper for ID token results.
///
/// Hides [IdTokenResult] from controllers so they never
/// import `firebase_auth` directly (RULE-06 compliance).
class AuthTokenResult {
  AuthTokenResult._({this.claims});

  /// Custom claims from the ID token (e.g. `role`, `permissions`).
  final Map<String, dynamic>? claims;
}

/// Lightweight snapshot of the currently signed-in user.
///
/// Prevents controllers from depending on `firebase_auth.User`.
class AuthUserInfo {
  AuthUserInfo._({
    required this.uid,
    this.email,
    this.displayName,
    this.lastSignInTime,
  });

  final String uid;
  final String? email;
  final String? displayName;
  final DateTime? lastSignInTime;
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

  /// Sign in with email and password (used by admin panel).
  ///
  /// Returns an [AuthUserInfo] on success, or throws on failure.
  static Future<AuthUserInfo?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user == null) return null;
    return AuthUserInfo._(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      lastSignInTime: user.metadata.lastSignInTime,
    );
  }

  /// Retrieve the ID token result for the current user.
  ///
  /// Returns null if no user is signed in.
  static Future<AuthTokenResult?> getIdTokenResult() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final token = await user.getIdTokenResult();
    return AuthTokenResult._(claims: token.claims);
  }

  /// Returns a lightweight [AuthUserInfo] for the current user,
  /// or null if not signed in.
  static AuthUserInfo? get currentUserInfo {
    final user = _auth.currentUser;
    if (user == null) return null;
    return AuthUserInfo._(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      lastSignInTime: user.metadata.lastSignInTime,
    );
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

  /// Sign out from Firebase only (no social provider sign-out).
  ///
  /// Useful for the admin panel where only email/password auth is used.
  static Future<void> signOutFirebaseOnly() async {
    await _auth.signOut();
  }
}
