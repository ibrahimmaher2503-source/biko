class DriverEarningsReportModel {
  const DriverEarningsReportModel({
    required this.driverUid,
    required this.driverName,
    this.grossEarnings = 0.0,
    this.commission = 0.0,
    this.tips = 0.0,
    this.bonuses = 0.0,
    this.netEarnings = 0.0,
    this.totalTrips = 0,
    this.avgPerTrip = 0.0,
  });

  factory DriverEarningsReportModel.fromJson(Map<String, dynamic> json) {
    return DriverEarningsReportModel(
      driverUid: json['driver_uid'] as String? ?? '',
      driverName: json['driver_name'] as String? ?? '',
      grossEarnings:
          (json['gross_earnings'] as num?)?.toDouble() ?? 0.0,
      commission: (json['commission'] as num?)?.toDouble() ?? 0.0,
      tips: (json['tips'] as num?)?.toDouble() ?? 0.0,
      bonuses: (json['bonuses'] as num?)?.toDouble() ?? 0.0,
      netEarnings: (json['net_earnings'] as num?)?.toDouble() ?? 0.0,
      totalTrips: (json['total_trips'] as num?)?.toInt() ?? 0,
      avgPerTrip:
          (json['avg_per_trip'] as num?)?.toDouble() ?? 0.0,
    );
  }

  final String driverUid;
  final String driverName;
  final double grossEarnings;
  final double commission;
  final double tips;
  final double bonuses;
  final double netEarnings;
  final int totalTrips;
  final double avgPerTrip;

  Map<String, dynamic> toJson() {
    return {
      'driver_uid': driverUid,
      'driver_name': driverName,
      'gross_earnings': grossEarnings,
      'commission': commission,
      'tips': tips,
      'bonuses': bonuses,
      'net_earnings': netEarnings,
      'total_trips': totalTrips,
      'avg_per_trip': avgPerTrip,
    };
  }

  DriverEarningsReportModel copyWith({
    String? driverUid,
    String? driverName,
    double? grossEarnings,
    double? commission,
    double? tips,
    double? bonuses,
    double? netEarnings,
    int? totalTrips,
    double? avgPerTrip,
  }) {
    return DriverEarningsReportModel(
      driverUid: driverUid ?? this.driverUid,
      driverName: driverName ?? this.driverName,
      grossEarnings: grossEarnings ?? this.grossEarnings,
      commission: commission ?? this.commission,
      tips: tips ?? this.tips,
      bonuses: bonuses ?? this.bonuses,
      netEarnings: netEarnings ?? this.netEarnings,
      totalTrips: totalTrips ?? this.totalTrips,
      avgPerTrip: avgPerTrip ?? this.avgPerTrip,
    );
  }
}
