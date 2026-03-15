class WalletSummaryModel {
  const WalletSummaryModel({
    this.totalWalletBalance = 0.0,
    this.activeWallets = 0,
    this.totalTopUps = 0.0,
    this.totalWithdrawals = 0.0,
    this.pendingPayouts = 0.0,
    this.avgWalletBalance = 0.0,
  });

  factory WalletSummaryModel.fromMap(Map<String, dynamic> map) {
    return WalletSummaryModel(
      totalWalletBalance:
          (map['total_wallet_balance'] as num?)?.toDouble() ?? 0.0,
      activeWallets: (map['active_wallets'] as num?)?.toInt() ?? 0,
      totalTopUps: (map['total_top_ups'] as num?)?.toDouble() ?? 0.0,
      totalWithdrawals:
          (map['total_withdrawals'] as num?)?.toDouble() ?? 0.0,
      pendingPayouts: (map['pending_payouts'] as num?)?.toDouble() ?? 0.0,
      avgWalletBalance:
          (map['avg_wallet_balance'] as num?)?.toDouble() ?? 0.0,
    );
  }

  final double totalWalletBalance;
  final int activeWallets;
  final double totalTopUps;
  final double totalWithdrawals;
  final double pendingPayouts;
  final double avgWalletBalance;

  Map<String, dynamic> toMap() {
    return {
      'total_wallet_balance': totalWalletBalance,
      'active_wallets': activeWallets,
      'total_top_ups': totalTopUps,
      'total_withdrawals': totalWithdrawals,
      'pending_payouts': pendingPayouts,
      'avg_wallet_balance': avgWalletBalance,
    };
  }

  WalletSummaryModel copyWith({
    double? totalWalletBalance,
    int? activeWallets,
    double? totalTopUps,
    double? totalWithdrawals,
    double? pendingPayouts,
    double? avgWalletBalance,
  }) {
    return WalletSummaryModel(
      totalWalletBalance: totalWalletBalance ?? this.totalWalletBalance,
      activeWallets: activeWallets ?? this.activeWallets,
      totalTopUps: totalTopUps ?? this.totalTopUps,
      totalWithdrawals: totalWithdrawals ?? this.totalWithdrawals,
      pendingPayouts: pendingPayouts ?? this.pendingPayouts,
      avgWalletBalance: avgWalletBalance ?? this.avgWalletBalance,
    );
  }
}
