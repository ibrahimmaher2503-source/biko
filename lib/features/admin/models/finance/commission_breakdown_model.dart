class CommissionBreakdownModel {
  const CommissionBreakdownModel({
    this.rideCommission = 0.0,
    this.c2cCommission = 0.0,
    this.b2bCommission = 0.0,
    this.totalCommission = 0.0,
    this.rideRate = 0.0,
    this.c2cRate = 0.0,
    this.b2bRate = 0.0,
  });

  factory CommissionBreakdownModel.fromJson(Map<String, dynamic> json) {
    return CommissionBreakdownModel(
      rideCommission:
          (json['ride_commission'] as num?)?.toDouble() ?? 0.0,
      c2cCommission:
          (json['c2c_commission'] as num?)?.toDouble() ?? 0.0,
      b2bCommission:
          (json['b2b_commission'] as num?)?.toDouble() ?? 0.0,
      totalCommission:
          (json['total_commission'] as num?)?.toDouble() ?? 0.0,
      rideRate: (json['ride_rate'] as num?)?.toDouble() ?? 0.0,
      c2cRate: (json['c2c_rate'] as num?)?.toDouble() ?? 0.0,
      b2bRate: (json['b2b_rate'] as num?)?.toDouble() ?? 0.0,
    );
  }

  final double rideCommission;
  final double c2cCommission;
  final double b2bCommission;
  final double totalCommission;
  final double rideRate;
  final double c2cRate;
  final double b2bRate;

  Map<String, dynamic> toJson() {
    return {
      'ride_commission': rideCommission,
      'c2c_commission': c2cCommission,
      'b2b_commission': b2bCommission,
      'total_commission': totalCommission,
      'ride_rate': rideRate,
      'c2c_rate': c2cRate,
      'b2b_rate': b2bRate,
    };
  }

  CommissionBreakdownModel copyWith({
    double? rideCommission,
    double? c2cCommission,
    double? b2bCommission,
    double? totalCommission,
    double? rideRate,
    double? c2cRate,
    double? b2bRate,
  }) {
    return CommissionBreakdownModel(
      rideCommission: rideCommission ?? this.rideCommission,
      c2cCommission: c2cCommission ?? this.c2cCommission,
      b2bCommission: b2bCommission ?? this.b2bCommission,
      totalCommission: totalCommission ?? this.totalCommission,
      rideRate: rideRate ?? this.rideRate,
      c2cRate: c2cRate ?? this.c2cRate,
      b2bRate: b2bRate ?? this.b2bRate,
    );
  }
}
