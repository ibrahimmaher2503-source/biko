class DriverSettlementModel {
  const DriverSettlementModel({
    required this.driverUid,
    required this.driverName,
    this.pendingAmount = 0.0,
    this.bankDetails,
    this.status = 'pending',
  });

  factory DriverSettlementModel.fromJson(Map<String, dynamic> json) {
    return DriverSettlementModel(
      driverUid: json['driver_uid'] as String? ?? '',
      driverName: json['driver_name'] as String? ?? '',
      pendingAmount:
          (json['pending_amount'] as num?)?.toDouble() ?? 0.0,
      bankDetails: json['bank_details'] as String?,
      status: json['status'] as String? ?? 'pending',
    );
  }

  final String driverUid;
  final String driverName;
  final double pendingAmount;
  final String? bankDetails;
  final String status;

  Map<String, dynamic> toJson() {
    return {
      'driver_uid': driverUid,
      'driver_name': driverName,
      'pending_amount': pendingAmount,
      'bank_details': bankDetails,
      'status': status,
    };
  }

  DriverSettlementModel copyWith({
    String? driverUid,
    String? driverName,
    double? pendingAmount,
    String? bankDetails,
    String? status,
  }) {
    return DriverSettlementModel(
      driverUid: driverUid ?? this.driverUid,
      driverName: driverName ?? this.driverName,
      pendingAmount: pendingAmount ?? this.pendingAmount,
      bankDetails: bankDetails ?? this.bankDetails,
      status: status ?? this.status,
    );
  }
}
