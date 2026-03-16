import 'package:cloud_firestore/cloud_firestore.dart';

/// User wallet model
class WalletModel {
  const WalletModel({
    required this.uid,
    required this.balance,
    this.currency = 'EGP',
    this.lastUpdated,
  });

  factory WalletModel.fromMap(Map<String, dynamic> map) {
    return WalletModel(
      uid: map['uid'] as String? ?? '',
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] as String? ?? 'EGP',
      lastUpdated: map['last_updated'] is Timestamp
          ? (map['last_updated'] as Timestamp).toDate()
          : null,
    );
  }

  final String uid;
  final double balance;
  final String currency;
  final DateTime? lastUpdated;

  /// Formatted balance with currency
  String get formattedBalance => '${balance.toStringAsFixed(2)} $currency';

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'balance': balance,
      'currency': currency,
      'last_updated': lastUpdated != null
          ? Timestamp.fromDate(lastUpdated!)
          : FieldValue.serverTimestamp(),
    };
  }

  WalletModel copyWith({
    String? uid,
    double? balance,
    String? currency,
    DateTime? lastUpdated,
  }) {
    return WalletModel(
      uid: uid ?? this.uid,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  String toString() => 'WalletModel(uid: $uid, balance: $formattedBalance)';
}
