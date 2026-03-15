import 'package:cloud_firestore/cloud_firestore.dart';

class WalletActivityModel {
  const WalletActivityModel({
    required this.id,
    required this.uid,
    required this.type,
    required this.amount,
    required this.createdAt,
    this.userName = '',
    this.method = '',
    this.status = 'completed',
    this.reference,
  });

  factory WalletActivityModel.fromMap(Map<String, dynamic> map) {
    return WalletActivityModel(
      id: map['id'] as String? ?? '',
      uid: map['uid'] as String? ?? '',
      userName: map['user_name'] as String? ?? '',
      type: map['type'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      method: map['method'] as String? ?? '',
      status: map['status'] as String? ?? 'completed',
      reference: map['reference'] as String?,
      createdAt: map['created_at'] is Timestamp
          ? (map['created_at'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  final String id;
  final String uid;
  final String userName;
  final String type;
  final double amount;
  final String method;
  final String status;
  final String? reference;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': uid,
      'user_name': userName,
      'type': type,
      'amount': amount,
      'method': method,
      'status': status,
      'reference': reference,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  WalletActivityModel copyWith({
    String? id,
    String? uid,
    String? userName,
    String? type,
    double? amount,
    String? method,
    String? status,
    String? reference,
    DateTime? createdAt,
  }) {
    return WalletActivityModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      userName: userName ?? this.userName,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      method: method ?? this.method,
      status: status ?? this.status,
      reference: reference ?? this.reference,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
