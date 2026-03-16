import 'package:cloud_firestore/cloud_firestore.dart';

class WalletActivityModel {
  const WalletActivityModel({
    required this.id,
    required this.userUid,
    required this.userName,
    required this.type,
    required this.timestamp,
    this.amount = 0.0,
    this.balanceAfter = 0.0,
  });

  factory WalletActivityModel.fromJson(Map<String, dynamic> json) {
    return WalletActivityModel(
      id: json['id'] as String? ?? '',
      userUid: json['user_uid'] as String? ?? '',
      userName: json['user_name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      balanceAfter:
          (json['balance_after'] as num?)?.toDouble() ?? 0.0,
      timestamp: _parseDate(json['timestamp']),
    );
  }

  final String id;
  final String userUid;
  final String userName;
  final String type;
  final double amount;
  final double balanceAfter;
  final DateTime timestamp;

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_uid': userUid,
      'user_name': userName,
      'type': type,
      'amount': amount,
      'balance_after': balanceAfter,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  WalletActivityModel copyWith({
    String? id,
    String? userUid,
    String? userName,
    String? type,
    double? amount,
    double? balanceAfter,
    DateTime? timestamp,
  }) {
    return WalletActivityModel(
      id: id ?? this.id,
      userUid: userUid ?? this.userUid,
      userName: userName ?? this.userName,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      balanceAfter: balanceAfter ?? this.balanceAfter,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
