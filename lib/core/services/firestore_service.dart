import 'package:biko/core/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Firestore data operations service
///
/// Static class following the same pattern as [AuthService].
/// All Firestore and Realtime Database operations go through this service.
/// Controllers MUST use this service — never import Firebase directly.
class FirestoreService {
  FirestoreService._();

  static final _firestore = FirebaseFirestore.instance;

  // ==================== Users ====================

  /// Get a user document by UID
  static Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromJson({...doc.data()!, 'uid': doc.id});
    } catch (e) {
      debugPrint('❌ FirestoreService.getUser failed: $e');
      return null;
    }
  }

  /// Create a new user document
  static Future<void> createUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set(user.toJson());
    } catch (e) {
      debugPrint('❌ FirestoreService.createUser failed: $e');
      rethrow;
    }
  }

  /// Update specific fields on a user document
  static Future<void> updateUser(
    String uid,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      debugPrint('❌ FirestoreService.updateUser failed: $e');
      rethrow;
    }
  }

  /// Listen to user document changes in real-time
  static Stream<UserModel?> listenToUser(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromJson({...doc.data()!, 'uid': doc.id});
    });
  }
}
