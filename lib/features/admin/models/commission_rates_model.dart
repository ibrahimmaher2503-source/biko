class CommissionRatesModel {
  const CommissionRatesModel({
    this.rideRate = 0.0,
    this.c2cDeliveryRate = 0.0,
    this.b2bDeliveryRate = 0.0,
    this.minCommission = 0.0,
    this.maxCommission = 0.0,
  });

  factory CommissionRatesModel.fromMap(Map<String, dynamic> map) {
    return CommissionRatesModel(
      rideRate: (map['ride_rate'] as num?)?.toDouble() ?? 0.0,
      c2cDeliveryRate: (map['c2c_delivery_rate'] as num?)?.toDouble() ?? 0.0,
      b2bDeliveryRate: (map['b2b_delivery_rate'] as num?)?.toDouble() ?? 0.0,
      minCommission: (map['min_commission'] as num?)?.toDouble() ?? 0.0,
      maxCommission: (map['max_commission'] as num?)?.toDouble() ?? 0.0,
    );
  }

  final double rideRate;
  final double c2cDeliveryRate;
  final double b2bDeliveryRate;
  final double minCommission;
  final double maxCommission;

  Map<String, dynamic> toMap() {
    return {
      'ride_rate': rideRate,
      'c2c_delivery_rate': c2cDeliveryRate,
      'b2b_delivery_rate': b2bDeliveryRate,
      'min_commission': minCommission,
      'max_commission': maxCommission,
    };
  }

  CommissionRatesModel copyWith({
    double? rideRate,
    double? c2cDeliveryRate,
    double? b2bDeliveryRate,
    double? minCommission,
    double? maxCommission,
  }) {
    return CommissionRatesModel(
      rideRate: rideRate ?? this.rideRate,
      c2cDeliveryRate: c2cDeliveryRate ?? this.c2cDeliveryRate,
      b2bDeliveryRate: b2bDeliveryRate ?? this.b2bDeliveryRate,
      minCommission: minCommission ?? this.minCommission,
      maxCommission: maxCommission ?? this.maxCommission,
    );
  }

  /// Validates that all rates are within acceptable bounds (0-100%).
  bool get isValid =>
      rideRate >= 0 &&
      rideRate <= 100 &&
      c2cDeliveryRate >= 0 &&
      c2cDeliveryRate <= 100 &&
      b2bDeliveryRate >= 0 &&
      b2bDeliveryRate <= 100 &&
      minCommission >= 0 &&
      maxCommission >= minCommission;
}
