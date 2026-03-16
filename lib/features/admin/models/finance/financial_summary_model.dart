class FinancialSummaryModel {
  const FinancialSummaryModel({
    this.totalRevenue = 0.0,
    this.totalCommission = 0.0,
    this.driverPayouts = 0.0,
    this.netProfit = 0.0,
    this.pendingPayouts = 0.0,
    this.totalWalletBalance = 0.0,
    this.completedTrips = 0,
    this.cancelledTrips = 0,
    this.cancellationRate = 0.0,
  });

  factory FinancialSummaryModel.fromJson(Map<String, dynamic> json) {
    return FinancialSummaryModel(
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0.0,
      totalCommission:
          (json['total_commission'] as num?)?.toDouble() ?? 0.0,
      driverPayouts:
          (json['driver_payouts'] as num?)?.toDouble() ?? 0.0,
      netProfit: (json['net_profit'] as num?)?.toDouble() ?? 0.0,
      pendingPayouts:
          (json['pending_payouts'] as num?)?.toDouble() ?? 0.0,
      totalWalletBalance:
          (json['total_wallet_balance'] as num?)?.toDouble() ?? 0.0,
      completedTrips:
          (json['completed_trips'] as num?)?.toInt() ?? 0,
      cancelledTrips:
          (json['cancelled_trips'] as num?)?.toInt() ?? 0,
      cancellationRate:
          (json['cancellation_rate'] as num?)?.toDouble() ?? 0.0,
    );
  }

  final double totalRevenue;
  final double totalCommission;
  final double driverPayouts;
  final double netProfit;
  final double pendingPayouts;
  final double totalWalletBalance;
  final int completedTrips;
  final int cancelledTrips;
  final double cancellationRate;

  Map<String, dynamic> toJson() {
    return {
      'total_revenue': totalRevenue,
      'total_commission': totalCommission,
      'driver_payouts': driverPayouts,
      'net_profit': netProfit,
      'pending_payouts': pendingPayouts,
      'total_wallet_balance': totalWalletBalance,
      'completed_trips': completedTrips,
      'cancelled_trips': cancelledTrips,
      'cancellation_rate': cancellationRate,
    };
  }

  FinancialSummaryModel copyWith({
    double? totalRevenue,
    double? totalCommission,
    double? driverPayouts,
    double? netProfit,
    double? pendingPayouts,
    double? totalWalletBalance,
    int? completedTrips,
    int? cancelledTrips,
    double? cancellationRate,
  }) {
    return FinancialSummaryModel(
      totalRevenue: totalRevenue ?? this.totalRevenue,
      totalCommission: totalCommission ?? this.totalCommission,
      driverPayouts: driverPayouts ?? this.driverPayouts,
      netProfit: netProfit ?? this.netProfit,
      pendingPayouts: pendingPayouts ?? this.pendingPayouts,
      totalWalletBalance: totalWalletBalance ?? this.totalWalletBalance,
      completedTrips: completedTrips ?? this.completedTrips,
      cancelledTrips: cancelledTrips ?? this.cancelledTrips,
      cancellationRate: cancellationRate ?? this.cancellationRate,
    );
  }
}
