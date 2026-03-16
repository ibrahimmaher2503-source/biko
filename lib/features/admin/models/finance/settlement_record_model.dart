import 'package:cloud_firestore/cloud_firestore.dart';

class SettlementRecordModel {
  const SettlementRecordModel({
    required this.id,
    required this.processedAt,
    required this.processedBy,
    this.totalAmount = 0.0,
    this.driverCount = 0,
  });

  factory SettlementRecordModel.fromJson(Map<String, dynamic> json) {
    return SettlementRecordModel(
      id: json['id'] as String? ?? '',
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      driverCount: (json['driver_count'] as num?)?.toInt() ?? 0,
      processedAt: _parseDate(json['processed_at']),
      processedBy: json['processed_by'] as String? ?? '',
    );
  }

  final String id;
  final double totalAmount;
  final int driverCount;
  final DateTime processedAt;
  final String processedBy;

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'total_amount': totalAmount,
      'driver_count': driverCount,
      'processed_at': Timestamp.fromDate(processedAt),
      'processed_by': processedBy,
    };
  }

  SettlementRecordModel copyWith({
    String? id,
    double? totalAmount,
    int? driverCount,
    DateTime? processedAt,
    String? processedBy,
  }) {
    return SettlementRecordModel(
      id: id ?? this.id,
      totalAmount: totalAmount ?? this.totalAmount,
      driverCount: driverCount ?? this.driverCount,
      processedAt: processedAt ?? this.processedAt,
      processedBy: processedBy ?? this.processedBy,
    );
  }
}
