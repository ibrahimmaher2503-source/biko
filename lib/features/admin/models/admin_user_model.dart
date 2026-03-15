import 'package:biko/core/models/enums.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Represents the authenticated admin user.
///
/// Constructed from [FirebaseAuth.instance.currentUser] + ID token claims.
/// Not stored in Firestore — derived entirely from Firebase Auth.
class AdminUserModel {
  const AdminUserModel({
    required this.uid,
    required this.email,
    required this.role,
    this.displayName,
    this.lastLoginAt,
  });

  /// Construct from Firebase Auth current user + token claims.
  factory AdminUserModel.fromFirebaseUser(
    User user,
    Map<String, dynamic> claims,
  ) {
    return AdminUserModel(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      role: AdminRole.fromJson(claims['role'] as String? ?? 'admin'),
      lastLoginAt: user.metadata.lastSignInTime,
    );
  }

  factory AdminUserModel.fromMap(Map<String, dynamic> map) {
    return AdminUserModel(
      uid: map['uid'] as String? ?? '',
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String?,
      role: AdminRole.fromJson(map['role'] as String? ?? 'admin'),
      lastLoginAt: map['lastLoginAt'] is DateTime
          ? map['lastLoginAt'] as DateTime
          : null,
    );
  }

  final String uid;
  final String email;
  final String? displayName;
  final AdminRole role;
  final DateTime? lastLoginAt;

  bool get isSuperAdmin => role == AdminRole.superAdmin;

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'role': role.toJson(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
    };
  }

  AdminUserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    AdminRole? role,
    DateTime? lastLoginAt,
  }) {
    return AdminUserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}
