import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for referral program entries
class ReferralModel {
  const ReferralModel({
    required this.id,
    required this.referrerUid,
    required this.referredUid,
    required this.createdAt,
    this.rewardAmount = 0.0,
    this.isRewarded = false,
  });

  factory ReferralModel.fromMap(Map<String, dynamic> map) {
    return ReferralModel(
      id: map['id'] as String? ?? '',
      referrerUid: map['referrer_uid'] as String? ?? '',
      referredUid: map['referred_uid'] as String? ?? '',
      rewardAmount: (map['reward_amount'] as num?)?.toDouble() ?? 0.0,
      isRewarded: map['is_rewarded'] as bool? ?? false,
      createdAt: map['created_at'] is Timestamp
          ? (map['created_at'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  final String id;
  final String referrerUid;
  final String referredUid;
  final double rewardAmount;
  final bool isRewarded;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'referrer_uid': referrerUid,
      'referred_uid': referredUid,
      'reward_amount': rewardAmount,
      'is_rewarded': isRewarded,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  ReferralModel copyWith({
    String? id,
    String? referrerUid,
    String? referredUid,
    double? rewardAmount,
    bool? isRewarded,
    DateTime? createdAt,
  }) {
    return ReferralModel(
      id: id ?? this.id,
      referrerUid: referrerUid ?? this.referrerUid,
      referredUid: referredUid ?? this.referredUid,
      rewardAmount: rewardAmount ?? this.rewardAmount,
      isRewarded: isRewarded ?? this.isRewarded,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
