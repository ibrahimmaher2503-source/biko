class SettlementSummaryModel {
  const SettlementSummaryModel({
    this.driversToPayCount = 0,
    this.totalAmount = 0.0,
    this.pendingSettlements = 0,
  });

  factory SettlementSummaryModel.fromJson(Map<String, dynamic> json) {
    return SettlementSummaryModel(
      driversToPayCount:
          (json['drivers_to_pay_count'] as num?)?.toInt() ?? 0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      pendingSettlements:
          (json['pending_settlements'] as num?)?.toInt() ?? 0,
    );
  }

  final int driversToPayCount;
  final double totalAmount;
  final int pendingSettlements;

  Map<String, dynamic> toJson() {
    return {
      'drivers_to_pay_count': driversToPayCount,
      'total_amount': totalAmount,
      'pending_settlements': pendingSettlements,
    };
  }

  SettlementSummaryModel copyWith({
    int? driversToPayCount,
    double? totalAmount,
    int? pendingSettlements,
  }) {
    return SettlementSummaryModel(
      driversToPayCount: driversToPayCount ?? this.driversToPayCount,
      totalAmount: totalAmount ?? this.totalAmount,
      pendingSettlements:
          pendingSettlements ?? this.pendingSettlements,
    );
  }
}
