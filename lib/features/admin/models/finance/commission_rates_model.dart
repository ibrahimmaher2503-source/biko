class CommissionRatesModel {
  const CommissionRatesModel({
    this.rideRate = 0.0,
    this.c2cRate = 0.0,
    this.b2bDefaultRate = 0.0,
  });

  factory CommissionRatesModel.fromJson(Map<String, dynamic> json) {
    return CommissionRatesModel(
      rideRate: (json['ride_rate'] as num?)?.toDouble() ?? 0.0,
      c2cRate: (json['c2c_rate'] as num?)?.toDouble() ?? 0.0,
      b2bDefaultRate:
          (json['b2b_default_rate'] as num?)?.toDouble() ?? 0.0,
    );
  }

  final double rideRate;
  final double c2cRate;
  final double b2bDefaultRate;

  Map<String, dynamic> toJson() {
    return {
      'ride_rate': rideRate,
      'c2c_rate': c2cRate,
      'b2b_default_rate': b2bDefaultRate,
    };
  }

  CommissionRatesModel copyWith({
    double? rideRate,
    double? c2cRate,
    double? b2bDefaultRate,
  }) {
    return CommissionRatesModel(
      rideRate: rideRate ?? this.rideRate,
      c2cRate: c2cRate ?? this.c2cRate,
      b2bDefaultRate: b2bDefaultRate ?? this.b2bDefaultRate,
    );
  }
}
