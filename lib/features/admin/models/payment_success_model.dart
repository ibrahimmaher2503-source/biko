class PaymentSuccessModel {
  const PaymentSuccessModel({
    required this.method,
    this.totalAttempts = 0,
    this.successfulAttempts = 0,
    this.failedAttempts = 0,
    this.successRate = 0.0,
    this.totalVolume = 0.0,
  });

  factory PaymentSuccessModel.fromMap(Map<String, dynamic> map) {
    return PaymentSuccessModel(
      method: map['method'] as String? ?? '',
      totalAttempts: (map['total_attempts'] as num?)?.toInt() ?? 0,
      successfulAttempts:
          (map['successful_attempts'] as num?)?.toInt() ?? 0,
      failedAttempts: (map['failed_attempts'] as num?)?.toInt() ?? 0,
      successRate: (map['success_rate'] as num?)?.toDouble() ?? 0.0,
      totalVolume: (map['total_volume'] as num?)?.toDouble() ?? 0.0,
    );
  }

  final String method;
  final int totalAttempts;
  final int successfulAttempts;
  final int failedAttempts;
  final double successRate;
  final double totalVolume;

  Map<String, dynamic> toMap() {
    return {
      'method': method,
      'total_attempts': totalAttempts,
      'successful_attempts': successfulAttempts,
      'failed_attempts': failedAttempts,
      'success_rate': successRate,
      'total_volume': totalVolume,
    };
  }

  PaymentSuccessModel copyWith({
    String? method,
    int? totalAttempts,
    int? successfulAttempts,
    int? failedAttempts,
    double? successRate,
    double? totalVolume,
  }) {
    return PaymentSuccessModel(
      method: method ?? this.method,
      totalAttempts: totalAttempts ?? this.totalAttempts,
      successfulAttempts: successfulAttempts ?? this.successfulAttempts,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      successRate: successRate ?? this.successRate,
      totalVolume: totalVolume ?? this.totalVolume,
    );
  }
}
