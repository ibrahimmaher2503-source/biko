import 'package:cloud_firestore/cloud_firestore.dart';

/// Transaction type
enum TransactionType {
  credit,
  debit;

  String toJson() => name;

  static TransactionType fromJson(String value) {
    return TransactionType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TransactionType.debit,
    );
  }
}

/// Transaction status
enum TransactionStatus {
  pending,
  completed,
  failed;

  String toJson() => name;

  static TransactionStatus fromJson(String value) {
    return TransactionStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TransactionStatus.pending,
    );
  }
}

/// Financial transaction model
class TransactionModel {
  const TransactionModel({
    required this.txnId,
    required this.uid,
    required this.type,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.method = '',
    this.reference,
    this.tripId,
    this.currency = 'EGP',
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      txnId: map['txn_id'] as String? ?? '',
      uid: map['uid'] as String? ?? '',
      type: TransactionType.fromJson(map['type'] as String? ?? 'debit'),
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      method: map['method'] as String? ?? '',
      reference: map['reference'] as String?,
      tripId: map['trip_id'] as String?,
      status: TransactionStatus.fromJson(map['status'] as String? ?? 'pending'),
      createdAt: map['created_at'] is Timestamp
          ? (map['created_at'] as Timestamp).toDate()
          : DateTime.now(),
      currency: map['currency'] as String? ?? 'EGP',
    );
  }

  final String txnId;
  final String uid;
  final TransactionType type;
  final double amount;
  final String method;
  final String? reference;
  final String? tripId;
  final TransactionStatus status;
  final DateTime createdAt;
  final String currency;

  /// Formatted amount with sign
  String get formattedAmount {
    final sign = type == TransactionType.credit ? '+' : '-';
    return '$sign${amount.toStringAsFixed(2)} $currency';
  }

  Map<String, dynamic> toMap() {
    return {
      'txn_id': txnId,
      'uid': uid,
      'type': type.toJson(),
      'amount': amount,
      'method': method,
      'reference': reference,
      'trip_id': tripId,
      'status': status.toJson(),
      'created_at': FieldValue.serverTimestamp(),
      'currency': currency,
    };
  }

  TransactionModel copyWith({
    String? txnId,
    String? uid,
    TransactionType? type,
    double? amount,
    String? method,
    String? reference,
    String? tripId,
    TransactionStatus? status,
    DateTime? createdAt,
    String? currency,
  }) {
    return TransactionModel(
      txnId: txnId ?? this.txnId,
      uid: uid ?? this.uid,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      method: method ?? this.method,
      reference: reference ?? this.reference,
      tripId: tripId ?? this.tripId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      currency: currency ?? this.currency,
    );
  }

  @override
  String toString() =>
      'TransactionModel(txnId: $txnId, type: $type, amount: $formattedAmount)';
}
