import 'package:cloud_firestore/cloud_firestore.dart';

class SuspiciousTransactionModel {
  const SuspiciousTransactionModel({
    required this.txnId,
    required this.uid,
    required this.amount,
    required this.flaggedAt,
    this.userName = '',
    this.reason = '',
    this.type = '',
    this.method = '',
    this.status = 'flagged',
    this.reviewedBy,
    this.reviewNote,
  });

  factory SuspiciousTransactionModel.fromMap(Map<String, dynamic> map) {
    return SuspiciousTransactionModel(
      txnId: map['txn_id'] as String? ?? '',
      uid: map['uid'] as String? ?? '',
      userName: map['user_name'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      reason: map['reason'] as String? ?? '',
      type: map['type'] as String? ?? '',
      method: map['method'] as String? ?? '',
      status: map['status'] as String? ?? 'flagged',
      reviewedBy: map['reviewed_by'] as String?,
      reviewNote: map['review_note'] as String?,
      flaggedAt: map['flagged_at'] is Timestamp
          ? (map['flagged_at'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  final String txnId;
  final String uid;
  final String userName;
  final double amount;
  final String reason;
  final String type;
  final String method;
  final String status;
  final String? reviewedBy;
  final String? reviewNote;
  final DateTime flaggedAt;

  Map<String, dynamic> toMap() {
    return {
      'txn_id': txnId,
      'uid': uid,
      'user_name': userName,
      'amount': amount,
      'reason': reason,
      'type': type,
      'method': method,
      'status': status,
      'reviewed_by': reviewedBy,
      'review_note': reviewNote,
      'flagged_at': Timestamp.fromDate(flaggedAt),
    };
  }

  SuspiciousTransactionModel copyWith({
    String? txnId,
    String? uid,
    String? userName,
    double? amount,
    String? reason,
    String? type,
    String? method,
    String? status,
    String? reviewedBy,
    String? reviewNote,
    DateTime? flaggedAt,
  }) {
    return SuspiciousTransactionModel(
      txnId: txnId ?? this.txnId,
      uid: uid ?? this.uid,
      userName: userName ?? this.userName,
      amount: amount ?? this.amount,
      reason: reason ?? this.reason,
      type: type ?? this.type,
      method: method ?? this.method,
      status: status ?? this.status,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewNote: reviewNote ?? this.reviewNote,
      flaggedAt: flaggedAt ?? this.flaggedAt,
    );
  }
}
