class ReferralStatsModel {
  const ReferralStatsModel({
    this.totalReferrals = 0,
    this.totalRewarded = 0,
    this.totalPayout = 0.0,
  });

  factory ReferralStatsModel.fromMap(Map<String, dynamic> map) {
    return ReferralStatsModel(
      totalReferrals: (map['totalReferrals'] as num?)?.toInt() ?? 0,
      totalRewarded: (map['totalRewarded'] as num?)?.toInt() ?? 0,
      totalPayout: (map['totalPayout'] as num?)?.toDouble() ?? 0.0,
    );
  }

  final int totalReferrals;
  final int totalRewarded;
  final double totalPayout;

  Map<String, dynamic> toMap() {
    return {
      'totalReferrals': totalReferrals,
      'totalRewarded': totalRewarded,
      'totalPayout': totalPayout,
    };
  }

  ReferralStatsModel copyWith({
    int? totalReferrals,
    int? totalRewarded,
    double? totalPayout,
  }) {
    return ReferralStatsModel(
      totalReferrals: totalReferrals ?? this.totalReferrals,
      totalRewarded: totalRewarded ?? this.totalRewarded,
      totalPayout: totalPayout ?? this.totalPayout,
    );
  }
}
