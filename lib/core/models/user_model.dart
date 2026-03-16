import 'package:biko/core/models/enums.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  const UserModel({
    required this.uid,
    required this.name,
    required this.phone,
    required this.type,
    required this.createdAt,
    this.email,
    this.authProviders = const [],
    this.status = UserStatus.active,
    this.walletBalance = 0.0,
    this.referralCode = '',
    this.referredBy,
    this.lang = 'ar',
    this.theme = 'light',
    this.avatarUrl,
    this.fcmToken,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String?,
      authProviders:
          (json['auth_providers'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      type: UserType.fromJson(json['type'] as String? ?? 'customer'),
      status: UserStatus.fromJson(json['status'] as String? ?? 'active'),
      walletBalance: (json['wallet_balance'] as num?)?.toDouble() ?? 0.0,
      referralCode: json['referral_code'] as String? ?? '',
      referredBy: json['referred_by'] as String?,
      lang: json['lang'] as String? ?? 'ar',
      theme: json['theme'] as String? ?? 'light',
      avatarUrl: json['avatar_url'] as String?,
      fcmToken: json['fcm_token'] as String?,
      createdAt: json['created_at'] is Timestamp
          ? (json['created_at'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  final String uid;
  final String name;
  final String phone;
  final String? email;
  final List<String> authProviders;
  final UserType type;
  final UserStatus status;
  final double walletBalance;
  final String referralCode;
  final String? referredBy;
  final String lang;
  final String theme;
  final String? avatarUrl;
  final String? fcmToken;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'phone': phone,
      'email': email,
      'auth_providers': authProviders,
      'type': type.toJson(),
      'status': status.toJson(),
      'wallet_balance': walletBalance,
      'referral_code': referralCode,
      'referred_by': referredBy,
      'lang': lang,
      'theme': theme,
      'avatar_url': avatarUrl,
      'fcm_token': fcmToken,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? phone,
    String? email,
    List<String>? authProviders,
    UserType? type,
    UserStatus? status,
    double? walletBalance,
    String? referralCode,
    String? referredBy,
    String? lang,
    String? theme,
    String? avatarUrl,
    String? fcmToken,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      authProviders: authProviders ?? this.authProviders,
      type: type ?? this.type,
      status: status ?? this.status,
      walletBalance: walletBalance ?? this.walletBalance,
      referralCode: referralCode ?? this.referralCode,
      referredBy: referredBy ?? this.referredBy,
      lang: lang ?? this.lang,
      theme: theme ?? this.theme,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Whether the user's profile is considered complete.
  ///
  /// Requires both name and phone to prevent social-login users
  /// from bypassing profile setup without a phone number.
  bool get isProfileComplete =>
      name.trim().isNotEmpty && phone.trim().isNotEmpty;
}
