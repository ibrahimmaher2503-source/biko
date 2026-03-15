class CommissionBreakdownModel {
  const CommissionBreakdownModel({
    this.rideCommission = 0.0,
    this.deliveryCommission = 0.0,
    this.totalCommission = 0.0,
    this.rideCount = 0,
    this.deliveryCount = 0,
    this.avgCommissionRate = 0.0,
    this.byType = const {},
  });

  factory CommissionBreakdownModel.fromMap(Map<String, dynamic> map) {
    return CommissionBreakdownModel(
      rideCommission: (map['ride_commission'] as num?)?.toDouble() ?? 0.0,
      deliveryCommission:
          (map['delivery_commission'] as num?)?.toDouble() ?? 0.0,
      totalCommission: (map['total_commission'] as num?)?.toDouble() ?? 0.0,
      rideCount: (map['ride_count'] as num?)?.toInt() ?? 0,
      deliveryCount: (map['delivery_count'] as num?)?.toInt() ?? 0,
      avgCommissionRate:
          (map['avg_commission_rate'] as num?)?.toDouble() ?? 0.0,
      byType: (map['by_type'] as Map<String, dynamic>?) ?? {},
    );
  }

  final double rideCommission;
  final double deliveryCommission;
  final double totalCommission;
  final int rideCount;
  final int deliveryCount;
  final double avgCommissionRate;
  final Map<String, dynamic> byType;

  Map<String, dynamic> toMap() {
    return {
      'ride_commission': rideCommission,
      'delivery_commission': deliveryCommission,
      'total_commission': totalCommission,
      'ride_count': rideCount,
      'delivery_count': deliveryCount,
      'avg_commission_rate': avgCommissionRate,
      'by_type': byType,
    };
  }

  CommissionBreakdownModel copyWith({
    double? rideCommission,
    double? deliveryCommission,
    double? totalCommission,
    int? rideCount,
    int? deliveryCount,
    double? avgCommissionRate,
    Map<String, dynamic>? byType,
  }) {
    return CommissionBreakdownModel(
      rideCommission: rideCommission ?? this.rideCommission,
      deliveryCommission: deliveryCommission ?? this.deliveryCommission,
      totalCommission: totalCommission ?? this.totalCommission,
      rideCount: rideCount ?? this.rideCount,
      deliveryCount: deliveryCount ?? this.deliveryCount,
      avgCommissionRate: avgCommissionRate ?? this.avgCommissionRate,
      byType: byType ?? this.byType,
    );
  }
}
