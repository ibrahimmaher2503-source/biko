import 'package:cloud_firestore/cloud_firestore.dart';

class SuspiciousTransactionModel {
  const SuspiciousTransactionModel({
    required this.id,
    required this.transactionId,
    required this.userUid,
    required this.userName,
    required this.reason,
    required this.flaggedAt,
    this.amount = 0.0,
    this.isReviewed = false,
  });

  factory SuspiciousTransactionModel.fromJson(Map<String, dynamic> json) {
    return SuspiciousTransactionModel(
      id: json['id'] as String? ?? '',
      transactionId: json['transaction_id'] as String? ?? '',
      userUid: json['user_uid'] as String? ?? '',
      userName: json['user_name'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      flaggedAt: _parseDate(json['flagged_at']),
      isReviewed: json['is_reviewed'] as bool? ?? false,
    );
  }

  final String id;
  final String transactionId;
  final String userUid;
  final String userName;
  final String reason;
  final double amount;
  final DateTime flaggedAt;
  final bool isReviewed;

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transaction_id': transactionId,
      'user_uid': userUid,
      'user_name': userName,
      'reason': reason,
      'amount': amount,
      'flagged_at': Timestamp.fromDate(flaggedAt),
      'is_reviewed': isReviewed,
    };
  }

  SuspiciousTransactionModel copyWith({
    String? id,
    String? transactionId,
    String? userUid,
    String? userName,
    String? reason,
    double? amount,
    DateTime? flaggedAt,
    bool? isReviewed,
  }) {
    return SuspiciousTransactionModel(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      userUid: userUid ?? this.userUid,
      userName: userName ?? this.userName,
      reason: reason ?? this.reason,
      amount: amount ?? this.amount,
      flaggedAt: flaggedAt ?? this.flaggedAt,
      isReviewed: isReviewed ?? this.isReviewed,
    );
  }
}
