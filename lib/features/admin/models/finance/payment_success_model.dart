class PaymentSuccessModel {
  const PaymentSuccessModel({
    required this.method,
    this.totalAttempts = 0,
    this.successCount = 0,
    this.failCount = 0,
    this.successRate = 0.0,
  });

  factory PaymentSuccessModel.fromJson(Map<String, dynamic> json) {
    return PaymentSuccessModel(
      method: json['method'] as String? ?? '',
      totalAttempts:
          (json['total_attempts'] as num?)?.toInt() ?? 0,
      successCount:
          (json['success_count'] as num?)?.toInt() ?? 0,
      failCount: (json['fail_count'] as num?)?.toInt() ?? 0,
      successRate:
          (json['success_rate'] as num?)?.toDouble() ?? 0.0,
    );
  }

  final String method;
  final int totalAttempts;
  final int successCount;
  final int failCount;
  final double successRate;

  Map<String, dynamic> toJson() {
    return {
      'method': method,
      'total_attempts': totalAttempts,
      'success_count': successCount,
      'fail_count': failCount,
      'success_rate': successRate,
    };
  }

  PaymentSuccessModel copyWith({
    String? method,
    int? totalAttempts,
    int? successCount,
    int? failCount,
    double? successRate,
  }) {
    return PaymentSuccessModel(
      method: method ?? this.method,
      totalAttempts: totalAttempts ?? this.totalAttempts,
      successCount: successCount ?? this.successCount,
      failCount: failCount ?? this.failCount,
      successRate: successRate ?? this.successRate,
    );
  }
}
