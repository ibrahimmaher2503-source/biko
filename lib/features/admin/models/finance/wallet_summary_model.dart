class WalletSummaryModel {
  const WalletSummaryModel({
    this.totalCustomerBalance = 0.0,
    this.totalDriverBalance = 0.0,
    this.recentTopUps = 0.0,
    this.recentSpending = 0.0,
  });

  factory WalletSummaryModel.fromJson(Map<String, dynamic> json) {
    return WalletSummaryModel(
      totalCustomerBalance:
          (json['total_customer_balance'] as num?)?.toDouble() ?? 0.0,
      totalDriverBalance:
          (json['total_driver_balance'] as num?)?.toDouble() ?? 0.0,
      recentTopUps:
          (json['recent_top_ups'] as num?)?.toDouble() ?? 0.0,
      recentSpending:
          (json['recent_spending'] as num?)?.toDouble() ?? 0.0,
    );
  }

  final double totalCustomerBalance;
  final double totalDriverBalance;
  final double recentTopUps;
  final double recentSpending;

  Map<String, dynamic> toJson() {
    return {
      'total_customer_balance': totalCustomerBalance,
      'total_driver_balance': totalDriverBalance,
      'recent_top_ups': recentTopUps,
      'recent_spending': recentSpending,
    };
  }

  WalletSummaryModel copyWith({
    double? totalCustomerBalance,
    double? totalDriverBalance,
    double? recentTopUps,
    double? recentSpending,
  }) {
    return WalletSummaryModel(
      totalCustomerBalance:
          totalCustomerBalance ?? this.totalCustomerBalance,
      totalDriverBalance:
          totalDriverBalance ?? this.totalDriverBalance,
      recentTopUps: recentTopUps ?? this.recentTopUps,
      recentSpending: recentSpending ?? this.recentSpending,
    );
  }
}
