import 'package:cloud_firestore/cloud_firestore.dart';

class FinancialReportModel {
  FinancialReportModel({
    required this.dateFrom,
    required this.dateTo,
    this.totalRevenue = 0.0,
    this.totalCommission = 0.0,
    this.totalTopUps = 0.0,
    this.totalRefunds = 0.0,
  });

  factory FinancialReportModel.fromMap(Map<String, dynamic> map) {
    return FinancialReportModel(
      totalRevenue: (map['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      totalCommission: (map['totalCommission'] as num?)?.toDouble() ?? 0.0,
      totalTopUps: (map['totalTopUps'] as num?)?.toDouble() ?? 0.0,
      totalRefunds: (map['totalRefunds'] as num?)?.toDouble() ?? 0.0,
      dateFrom: _parseDate(map['dateFrom']),
      dateTo: _parseDate(map['dateTo']),
    );
  }

  final double totalRevenue;
  final double totalCommission;
  final double totalTopUps;
  final double totalRefunds;
  final DateTime dateFrom;
  final DateTime dateTo;

  /// Safely parses a DateTime from Firestore Timestamp, DateTime, or String.
  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  Map<String, dynamic> toMap() {
    return {
      'totalRevenue': totalRevenue,
      'totalCommission': totalCommission,
      'totalTopUps': totalTopUps,
      'totalRefunds': totalRefunds,
      'dateFrom': Timestamp.fromDate(dateFrom),
      'dateTo': Timestamp.fromDate(dateTo),
    };
  }

  FinancialReportModel copyWith({
    double? totalRevenue,
    double? totalCommission,
    double? totalTopUps,
    double? totalRefunds,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) {
    return FinancialReportModel(
      totalRevenue: totalRevenue ?? this.totalRevenue,
      totalCommission: totalCommission ?? this.totalCommission,
      totalTopUps: totalTopUps ?? this.totalTopUps,
      totalRefunds: totalRefunds ?? this.totalRefunds,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
    );
  }
}
