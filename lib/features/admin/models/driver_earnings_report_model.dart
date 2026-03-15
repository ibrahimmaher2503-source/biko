import 'package:cloud_firestore/cloud_firestore.dart';

class DriverEarningsReportModel {
  const DriverEarningsReportModel({
    required this.driverUid,
    this.driverName = '',
    this.driverPhone = '',
    this.grossEarnings = 0.0,
    this.commission = 0.0,
    this.tips = 0.0,
    this.bonuses = 0.0,
    this.netEarnings = 0.0,
    this.totalTrips = 0,
    this.pendingPayout = 0.0,
    this.lastPayoutDate,
  });

  factory DriverEarningsReportModel.fromMap(Map<String, dynamic> map) {
    return DriverEarningsReportModel(
      driverUid: map['driver_uid'] as String? ?? '',
      driverName: map['driver_name'] as String? ?? '',
      driverPhone: map['driver_phone'] as String? ?? '',
      grossEarnings: (map['gross_earnings'] as num?)?.toDouble() ?? 0.0,
      commission: (map['commission'] as num?)?.toDouble() ?? 0.0,
      tips: (map['tips'] as num?)?.toDouble() ?? 0.0,
      bonuses: (map['bonuses'] as num?)?.toDouble() ?? 0.0,
      netEarnings: (map['net_earnings'] as num?)?.toDouble() ?? 0.0,
      totalTrips: (map['total_trips'] as num?)?.toInt() ?? 0,
      pendingPayout: (map['pending_payout'] as num?)?.toDouble() ?? 0.0,
      lastPayoutDate: map['last_payout_date'] is Timestamp
          ? (map['last_payout_date'] as Timestamp).toDate()
          : null,
    );
  }

  final String driverUid;
  final String driverName;
  final String driverPhone;
  final double grossEarnings;
  final double commission;
  final double tips;
  final double bonuses;
  final double netEarnings;
  final int totalTrips;
  final double pendingPayout;
  final DateTime? lastPayoutDate;

  Map<String, dynamic> toMap() {
    return {
      'driver_uid': driverUid,
      'driver_name': driverName,
      'driver_phone': driverPhone,
      'gross_earnings': grossEarnings,
      'commission': commission,
      'tips': tips,
      'bonuses': bonuses,
      'net_earnings': netEarnings,
      'total_trips': totalTrips,
      'pending_payout': pendingPayout,
      'last_payout_date': lastPayoutDate != null
          ? Timestamp.fromDate(lastPayoutDate!)
          : null,
    };
  }

  DriverEarningsReportModel copyWith({
    String? driverUid,
    String? driverName,
    String? driverPhone,
    double? grossEarnings,
    double? commission,
    double? tips,
    double? bonuses,
    double? netEarnings,
    int? totalTrips,
    double? pendingPayout,
    DateTime? lastPayoutDate,
  }) {
    return DriverEarningsReportModel(
      driverUid: driverUid ?? this.driverUid,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      grossEarnings: grossEarnings ?? this.grossEarnings,
      commission: commission ?? this.commission,
      tips: tips ?? this.tips,
      bonuses: bonuses ?? this.bonuses,
      netEarnings: netEarnings ?? this.netEarnings,
      totalTrips: totalTrips ?? this.totalTrips,
      pendingPayout: pendingPayout ?? this.pendingPayout,
      lastPayoutDate: lastPayoutDate ?? this.lastPayoutDate,
    );
  }
}
