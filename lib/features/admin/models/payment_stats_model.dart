class PaymentStatsModel {
  const PaymentStatsModel({
    required this.method,
    this.count = 0,
    this.totalAmount = 0.0,
    this.percentage = 0.0,
  });

  factory PaymentStatsModel.fromMap(Map<String, dynamic> map) {
    return PaymentStatsModel(
      method: map['method'] as String? ?? '',
      count: (map['count'] as num?)?.toInt() ?? 0,
      totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0.0,
      percentage: (map['percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  final String method;
  final int count;
  final double totalAmount;
  final double percentage;

  Map<String, dynamic> toMap() {
    return {
      'method': method,
      'count': count,
      'total_amount': totalAmount,
      'percentage': percentage,
    };
  }

  PaymentStatsModel copyWith({
    String? method,
    int? count,
    double? totalAmount,
    double? percentage,
  }) {
    return PaymentStatsModel(
      method: method ?? this.method,
      count: count ?? this.count,
      totalAmount: totalAmount ?? this.totalAmount,
      percentage: percentage ?? this.percentage,
    );
  }
}
