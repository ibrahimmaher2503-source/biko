class DriverEarningsModel {
  const DriverEarningsModel({
    this.grossEarnings = 0.0,
    this.commission = 0.0,
    this.tips = 0.0,
    this.bonuses = 0.0,
    this.netEarnings = 0.0,
    this.totalTrips = 0,
    this.avgEarningPerTrip = 0.0,
  });

  factory DriverEarningsModel.fromJson(Map<String, dynamic> json) {
    return DriverEarningsModel(
      grossEarnings:
          (json['gross_earnings'] as num?)?.toDouble() ?? 0.0,
      commission: (json['commission'] as num?)?.toDouble() ?? 0.0,
      tips: (json['tips'] as num?)?.toDouble() ?? 0.0,
      bonuses: (json['bonuses'] as num?)?.toDouble() ?? 0.0,
      netEarnings: (json['net_earnings'] as num?)?.toDouble() ?? 0.0,
      totalTrips: (json['total_trips'] as num?)?.toInt() ?? 0,
      avgEarningPerTrip:
          (json['avg_earning_per_trip'] as num?)?.toDouble() ?? 0.0,
    );
  }

  final double grossEarnings;
  final double commission;
  final double tips;
  final double bonuses;
  final double netEarnings;
  final int totalTrips;
  final double avgEarningPerTrip;

  Map<String, dynamic> toJson() {
    return {
      'gross_earnings': grossEarnings,
      'commission': commission,
      'tips': tips,
      'bonuses': bonuses,
      'net_earnings': netEarnings,
      'total_trips': totalTrips,
      'avg_earning_per_trip': avgEarningPerTrip,
    };
  }

  DriverEarningsModel copyWith({
    double? grossEarnings,
    double? commission,
    double? tips,
    double? bonuses,
    double? netEarnings,
    int? totalTrips,
    double? avgEarningPerTrip,
  }) {
    return DriverEarningsModel(
      grossEarnings: grossEarnings ?? this.grossEarnings,
      commission: commission ?? this.commission,
      tips: tips ?? this.tips,
      bonuses: bonuses ?? this.bonuses,
      netEarnings: netEarnings ?? this.netEarnings,
      totalTrips: totalTrips ?? this.totalTrips,
      avgEarningPerTrip: avgEarningPerTrip ?? this.avgEarningPerTrip,
    );
  }
}
