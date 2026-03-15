class PaymentStatsModel {
  const PaymentStatsModel({
    required this.method,
    this.count = 0,
    this.totalAmount = 0.0,
    this.percentage = 0.0,
    this.avgPerTransaction = 0.0,
  });

  factory PaymentStatsModel.fromJson(Map<String, dynamic> json) {
    return PaymentStatsModel(
      method: json['method'] as String? ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      avgPerTransaction:
          (json['avg_per_transaction'] as num?)?.toDouble() ?? 0.0,
    );
  }

  final String method;
  final int count;
  final double totalAmount;
  final double percentage;
  final double avgPerTransaction;

  Map<String, dynamic> toJson() {
    return {
      'method': method,
      'count': count,
      'total_amount': totalAmount,
      'percentage': percentage,
      'avg_per_transaction': avgPerTransaction,
    };
  }

  PaymentStatsModel copyWith({
    String? method,
    int? count,
    double? totalAmount,
    double? percentage,
    double? avgPerTransaction,
  }) {
    return PaymentStatsModel(
      method: method ?? this.method,
      count: count ?? this.count,
      totalAmount: totalAmount ?? this.totalAmount,
      percentage: percentage ?? this.percentage,
      avgPerTransaction: avgPerTransaction ?? this.avgPerTransaction,
    );
  }
}
