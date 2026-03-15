import 'package:cloud_firestore/cloud_firestore.dart';

class DailyRevenueModel {
  const DailyRevenueModel({
    required this.date,
    this.totalRevenue = 0.0,
    this.totalCommission = 0.0,
    this.tripCount = 0,
    this.avgTripValue = 0.0,
  });

  factory DailyRevenueModel.fromMap(Map<String, dynamic> map) {
    return DailyRevenueModel(
      date: map['date'] is Timestamp
          ? (map['date'] as Timestamp).toDate()
          : map['date'] is DateTime
              ? map['date'] as DateTime
              : DateTime.now(),
      totalRevenue: (map['total_revenue'] as num?)?.toDouble() ?? 0.0,
      totalCommission: (map['total_commission'] as num?)?.toDouble() ?? 0.0,
      tripCount: (map['trip_count'] as num?)?.toInt() ?? 0,
      avgTripValue: (map['avg_trip_value'] as num?)?.toDouble() ?? 0.0,
    );
  }

  final DateTime date;
  final double totalRevenue;
  final double totalCommission;
  final int tripCount;
  final double avgTripValue;

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'total_revenue': totalRevenue,
      'total_commission': totalCommission,
      'trip_count': tripCount,
      'avg_trip_value': avgTripValue,
    };
  }

  DailyRevenueModel copyWith({
    DateTime? date,
    double? totalRevenue,
    double? totalCommission,
    int? tripCount,
    double? avgTripValue,
  }) {
    return DailyRevenueModel(
      date: date ?? this.date,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      totalCommission: totalCommission ?? this.totalCommission,
      tripCount: tripCount ?? this.tripCount,
      avgTripValue: avgTripValue ?? this.avgTripValue,
    );
  }
}
