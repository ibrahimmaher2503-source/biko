import 'package:biko/core/models/enums.dart';
import 'package:biko/core/services/auth_service.dart';

/// Represents the authenticated admin user.
///
/// Constructed from [AuthUserInfo] + ID token claims.
/// Not stored in Firestore — derived entirely from Firebase Auth.
class AdminUserModel {
  const AdminUserModel({
    required this.uid,
    required this.email,
    required this.role,
    this.displayName,
    this.lastLoginAt,
  });

  /// Construct from [AuthUserInfo] + token claims.
  ///
  /// Uses the service-layer wrapper instead of `firebase_auth.User`
  /// to maintain RULE-06 compliance across models and controllers.
  factory AdminUserModel.fromAuthUserInfo(
    AuthUserInfo userInfo,
    Map<String, dynamic> claims,
  ) {
    return AdminUserModel(
      uid: userInfo.uid,
      email: userInfo.email ?? '',
      displayName: userInfo.displayName,
      role: AdminRole.fromJson(claims['role'] as String? ?? 'admin'),
      lastLoginAt: userInfo.lastSignInTime,
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
