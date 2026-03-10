import 'package:biko/core/models/enums.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Bid status for individual driver bids on a trip
enum BidStatus {
  pending,
  accepted,
  rejected,
  expired;

  String toJson() => name;

  static BidStatus fromJson(String value) {
    return BidStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => BidStatus.pending,
    );
  }
}

/// Model for a driver's bid on a customer trip request
class BidModel {
  const BidModel({
    required this.bidId,
    required this.tripId,
    required this.driverUid,
    required this.driverName,
    required this.driverRating,
    required this.vehicleType,
    required this.amount,
    required this.status,
    required this.etaMinutes,
    required this.createdAt,
    this.driverPhotoUrl,
  });

  factory BidModel.fromMap(Map<String, dynamic> map) {
    return BidModel(
      bidId: map['bid_id'] as String? ?? '',
      tripId: map['trip_id'] as String? ?? '',
      driverUid: map['driver_uid'] as String? ?? '',
      driverName: map['driver_name'] as String? ?? '',
      driverPhotoUrl: map['driver_photo_url'] as String?,
      driverRating: (map['driver_rating'] as num?)?.toDouble() ?? 0.0,
      vehicleType: VehicleType.fromJson(
        map['vehicle_type'] as String? ?? 'motorcycle',
      ),
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      status: BidStatus.fromJson(map['status'] as String? ?? 'pending'),
      etaMinutes: (map['eta_minutes'] as num?)?.toInt() ?? 0,
      createdAt: map['created_at'] is Timestamp
          ? (map['created_at'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  final String bidId;
  final String tripId;
  final String driverUid;
  final String driverName;
  final String? driverPhotoUrl;
  final double driverRating;
  final VehicleType vehicleType;
  final double amount;
  final BidStatus status;
  final int etaMinutes;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return {
      'bid_id': bidId,
      'trip_id': tripId,
      'driver_uid': driverUid,
      'driver_name': driverName,
      'driver_photo_url': driverPhotoUrl,
      'driver_rating': driverRating,
      'vehicle_type': vehicleType.toJson(),
      'amount': amount,
      'status': status.toJson(),
      'eta_minutes': etaMinutes,
      'created_at': FieldValue.serverTimestamp(),
    };
  }

  BidModel copyWith({
    String? bidId,
    String? tripId,
    String? driverUid,
    String? driverName,
    String? driverPhotoUrl,
    double? driverRating,
    VehicleType? vehicleType,
    double? amount,
    BidStatus? status,
    int? etaMinutes,
    DateTime? createdAt,
  }) {
    return BidModel(
      bidId: bidId ?? this.bidId,
      tripId: tripId ?? this.tripId,
      driverUid: driverUid ?? this.driverUid,
      driverName: driverName ?? this.driverName,
      driverPhotoUrl: driverPhotoUrl ?? this.driverPhotoUrl,
      driverRating: driverRating ?? this.driverRating,
      vehicleType: vehicleType ?? this.vehicleType,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'BidModel(bidId: $bidId, driver: $driverName, amount: $amount)';
}
