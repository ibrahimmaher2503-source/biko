import 'package:cloud_firestore/cloud_firestore.dart';

class DailyRevenueModel {
  const DailyRevenueModel({
    required this.date,
    this.tripRevenue = 0.0,
    this.deliveryRevenue = 0.0,
    this.totalRevenue = 0.0,
    this.commission = 0.0,
    this.tripCount = 0,
  });

  factory DailyRevenueModel.fromJson(Map<String, dynamic> json) {
    return DailyRevenueModel(
      date: _parseDate(json['date']),
      tripRevenue: (json['trip_revenue'] as num?)?.toDouble() ?? 0.0,
      deliveryRevenue:
          (json['delivery_revenue'] as num?)?.toDouble() ?? 0.0,
      totalRevenue:
          (json['total_revenue'] as num?)?.toDouble() ?? 0.0,
      commission: (json['commission'] as num?)?.toDouble() ?? 0.0,
      tripCount: (json['trip_count'] as num?)?.toInt() ?? 0,
    );
  }

  final DateTime date;
  final double tripRevenue;
  final double deliveryRevenue;
  final double totalRevenue;
  final double commission;
  final int tripCount;

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'date': Timestamp.fromDate(date),
      'trip_revenue': tripRevenue,
      'delivery_revenue': deliveryRevenue,
      'total_revenue': totalRevenue,
      'commission': commission,
      'trip_count': tripCount,
    };
  }

  DailyRevenueModel copyWith({
    DateTime? date,
    double? tripRevenue,
    double? deliveryRevenue,
    double? totalRevenue,
    double? commission,
    int? tripCount,
  }) {
    return DailyRevenueModel(
      date: date ?? this.date,
      tripRevenue: tripRevenue ?? this.tripRevenue,
      deliveryRevenue: deliveryRevenue ?? this.deliveryRevenue,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      commission: commission ?? this.commission,
      tripCount: tripCount ?? this.tripCount,
    );
  }
}
