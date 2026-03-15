import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for promo/discount codes
class PromoCodeModel {
  const PromoCodeModel({
    required this.id,
    required this.code,
    required this.discountPercent,
    required this.maxDiscount,
    required this.expiresAt,
    this.isUsed = false,
    this.minTripAmount = 0.0,
  });

  factory PromoCodeModel.fromMap(Map<String, dynamic> map) {
    return PromoCodeModel(
      id: map['id'] as String? ?? '',
      code: map['code'] as String? ?? '',
      discountPercent: (map['discount_percent'] as num?)?.toDouble() ?? 0.0,
      maxDiscount: (map['max_discount'] as num?)?.toDouble() ?? 0.0,
      minTripAmount: (map['min_trip_amount'] as num?)?.toDouble() ?? 0.0,
      isUsed: map['is_used'] as bool? ?? false,
      expiresAt: map['expires_at'] is Timestamp
          ? (map['expires_at'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  final String id;
  final String code;
  final double discountPercent;
  final double maxDiscount;
  final double minTripAmount;
  final bool isUsed;
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isValid => !isUsed && !isExpired;

  String get formattedDiscount => '${discountPercent.toStringAsFixed(0)}%';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'discount_percent': discountPercent,
      'max_discount': maxDiscount,
      'min_trip_amount': minTripAmount,
      'is_used': isUsed,
      'expires_at': Timestamp.fromDate(expiresAt),
    };
  }

  PromoCodeModel copyWith({
    String? id,
    String? code,
    double? discountPercent,
    double? maxDiscount,
    double? minTripAmount,
    bool? isUsed,
    DateTime? expiresAt,
  }) {
    return PromoCodeModel(
      id: id ?? this.id,
      code: code ?? this.code,
      discountPercent: discountPercent ?? this.discountPercent,
      maxDiscount: maxDiscount ?? this.maxDiscount,
      minTripAmount: minTripAmount ?? this.minTripAmount,
      isUsed: isUsed ?? this.isUsed,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}
