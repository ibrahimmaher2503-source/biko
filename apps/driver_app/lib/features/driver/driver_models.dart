import 'package:app_core/app_core.dart';

class DriverAppException extends BusinessFailure {
  const DriverAppException(super.message);
}

String driverErrorMessage(Object error) => switch (error) {
  DriverAppException(:final message) => message,
  _ => classifyReadError(error).message,
};

class DriverAccount {
  const DriverAccount({
    required this.id,
    required this.type,
    required this.status,
    required this.isOnline,
    this.officeId,
  });

  factory DriverAccount.fromJson(Map<String, dynamic> json) => DriverAccount(
    id: json['id'] as String,
    type: DriverType.values.firstWhere(
      (value) => value.databaseValue == json['driver_type'],
    ),
    status: DriverStatus.values.firstWhere(
      (value) => value.databaseValue == json['status'],
    ),
    isOnline: json['is_online'] as bool? ?? false,
    officeId: json['office_id'] as String?,
  );

  final String id;
  final DriverType type;
  final DriverStatus status;
  final bool isOnline;
  final String? officeId;

  bool get canGoOnline => status == DriverStatus.active;
}

enum DriverTripAction {
  onWay('ابدأ التحرك'),
  arrived('وصلت'),
  start('ابدأ الرحلة'),
  deliveryPickup('تم استلام الشحنة'),
  complete('إنهاء الرحلة'),
  deliveryComplete('إدخال كود تأكيد التسليم');

  const DriverTripAction(this.label);

  final String label;
}

class DriverOrder {
  const DriverOrder({
    required this.id,
    required this.serviceCode,
    required this.serviceName,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.proposedPrice,
    required this.status,
    required this.createdAt,
    this.agreedPrice,
    this.completedAt,
    this.pickupLatitude,
    this.pickupLongitude,
    this.destinationLatitude,
    this.destinationLongitude,
    this.routeDistanceMeters,
    this.routeDurationSeconds,
    this.routePolyline,
    this.driverDistanceMeters,
    this.dispatchRadiusMeters,
    this.biddingDeadline,
  });

  factory DriverOrder.fromJson(Map<String, dynamic> json) {
    final service = Map<String, dynamic>.from(
      json['service_types'] as Map? ?? const <String, dynamic>{},
    );
    return DriverOrder(
      id: json['id'] as String,
      serviceCode:
          json['service_code'] as String? ?? service['code'] as String? ?? '',
      serviceName:
          json['service_name'] as String? ??
          service['name_ar'] as String? ??
          'خدمة',
      pickupAddress: json['pickup_address'] as String,
      destinationAddress: json['destination_address'] as String,
      proposedPrice: _asDouble(json['proposed_price']),
      agreedPrice: json['agreed_price'] == null
          ? null
          : _asDouble(json['agreed_price']),
      status: OrderStatus.values.firstWhere(
        (value) => value.databaseValue == json['status'],
      ),
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      biddingDeadline: _serverAdjustedDateTime(json, 'bidding_expires_at'),
      completedAt: json['completed_at'] == null
          ? null
          : DateTime.parse(json['completed_at'] as String).toLocal(),
      pickupLatitude: _nullableDouble(json['pickup_lat']),
      pickupLongitude: _nullableDouble(json['pickup_lng']),
      destinationLatitude: _nullableDouble(json['destination_lat']),
      destinationLongitude: _nullableDouble(json['destination_lng']),
      routeDistanceMeters: json['route_distance_meters'] as int?,
      routeDurationSeconds: json['route_duration_seconds'] as int?,
      routePolyline: json['route_polyline'] as String?,
      driverDistanceMeters: json['driver_distance_meters'] as int?,
      dispatchRadiusMeters: json['dispatch_radius_meters'] as int?,
    );
  }

  final String id;
  final String serviceCode;
  final String serviceName;
  final String pickupAddress;
  final String destinationAddress;
  final double proposedPrice;
  final double? agreedPrice;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final double? destinationLatitude;
  final double? destinationLongitude;
  final int? routeDistanceMeters;
  final int? routeDurationSeconds;
  final String? routePolyline;
  final int? driverDistanceMeters;
  final int? dispatchRadiusMeters;
  final DateTime? biddingDeadline;

  bool get hasRouteCoordinates =>
      pickupLatitude != null &&
      pickupLongitude != null &&
      destinationLatitude != null &&
      destinationLongitude != null;

  double get displayPrice => agreedPrice ?? proposedPrice;
  bool get isDelivery => serviceCode == ServiceType.delivery.databaseValue;

  bool get canDriverCancel => switch (status) {
    OrderStatus.driverAssigned ||
    OrderStatus.driverOnWay ||
    OrderStatus.driverArrived => true,
    _ => false,
  };

  DriverTripAction? get nextAction => switch (status) {
    OrderStatus.driverAssigned => DriverTripAction.onWay,
    OrderStatus.driverOnWay =>
      isDelivery ? DriverTripAction.deliveryPickup : DriverTripAction.arrived,
    OrderStatus.driverArrived when !isDelivery => DriverTripAction.start,
    OrderStatus.inProgress =>
      isDelivery
          ? DriverTripAction.deliveryComplete
          : DriverTripAction.complete,
    _ => null,
  };
}

const driverCustomerContactStatuses = <OrderStatus>{
  OrderStatus.driverAssigned,
  OrderStatus.driverOnWay,
  OrderStatus.driverArrived,
  OrderStatus.inProgress,
};

bool canDriverContactCustomer(OrderStatus status) =>
    driverCustomerContactStatuses.contains(status);

class DriverCustomerContact {
  const DriverCustomerContact({required this.name, this.phone});

  factory DriverCustomerContact.fromJson(Map<String, dynamic> json) =>
      DriverCustomerContact(
        name: (json['customer_name'] as String? ?? '').trim(),
        phone: (json['customer_phone'] as String?)?.trim(),
      );

  final String name;
  final String? phone;
}

String? normalizeDriverCallPhone(String value) {
  final phone = value.trim();
  if (!RegExp(r'^\+?[0-9() -]+$').hasMatch(phone)) return null;
  final compact = phone.replaceAll(RegExp(r'[() -]'), '');
  final digits = compact.replaceAll('+', '');
  return digits.length >= 6 && digits.length <= 32 ? compact : null;
}

enum DocumentStatus {
  pending('PENDING'),
  approved('APPROVED'),
  rejected('REJECTED'),
  expired('EXPIRED');

  const DocumentStatus(this.databaseValue);
  final String databaseValue;
}

class VerificationDocument {
  const VerificationDocument({
    required this.id,
    required this.type,
    required this.status,
    this.expiryDate,
    this.rejectionReason,
  });

  factory VerificationDocument.fromJson(Map<String, dynamic> json) =>
      VerificationDocument(
        id: json['id'] as String,
        type: json['document_type'] as String,
        status: DocumentStatus.values.firstWhere(
          (value) => value.databaseValue == json['status'],
        ),
        expiryDate: json['expiry_date'] == null
            ? null
            : DateTime.parse(json['expiry_date'] as String),
        rejectionReason: json['rejection_reason'] as String?,
      );

  final String id;
  final String type;
  final DocumentStatus status;
  final DateTime? expiryDate;
  final String? rejectionReason;
}

class VerifiedMotorcycle {
  const VerifiedMotorcycle({
    required this.id,
    required this.brand,
    required this.model,
    required this.plateNumber,
    required this.status,
    required this.verificationStatus,
    this.rejectionReason,
  });

  factory VerifiedMotorcycle.fromJson(Map<String, dynamic> json) =>
      VerifiedMotorcycle(
        id: json['id'] as String,
        brand: json['brand'] as String,
        model: json['model'] as String,
        plateNumber: json['plate_number'] as String,
        status: json['status'] as String,
        verificationStatus: DocumentStatus.values.firstWhere(
          (value) => value.databaseValue == json['verification_status'],
        ),
        rejectionReason: json['rejection_reason'] as String?,
      );

  final String id;
  final String brand;
  final String model;
  final String plateNumber;
  final String status;
  final DocumentStatus verificationStatus;
  final String? rejectionReason;
}

class DriverVerificationOverview {
  const DriverVerificationOverview({
    required this.driverStatus,
    required this.safetyEquipmentConfirmed,
    required this.driverDocuments,
    required this.motorcycleDocuments,
    this.dateOfBirth,
    this.safetyReason,
    this.motorcycle,
  });

  factory DriverVerificationOverview.fromJson(Map<String, dynamic> json) {
    List<VerificationDocument> documents(Object? value) =>
        (value as List? ?? const [])
            .map(
              (item) => VerificationDocument.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList(growable: false);
    final motorcycle = json['motorcycle'];
    return DriverVerificationOverview(
      driverStatus: DriverStatus.values.firstWhere(
        (value) => value.databaseValue == json['driver_status'],
      ),
      dateOfBirth: json['date_of_birth'] == null
          ? null
          : DateTime.parse(json['date_of_birth'] as String),
      safetyReason: json['safety_reason'] as String?,
      safetyEquipmentConfirmed:
          json['ride_safety_equipment_confirmed'] as bool? ?? false,
      motorcycle: motorcycle == null
          ? null
          : VerifiedMotorcycle.fromJson(
              Map<String, dynamic>.from(motorcycle as Map),
            ),
      driverDocuments: documents(json['driver_documents']),
      motorcycleDocuments: documents(json['motorcycle_documents']),
    );
  }

  final DriverStatus driverStatus;
  final DateTime? dateOfBirth;
  final String? safetyReason;
  final bool safetyEquipmentConfirmed;
  final VerifiedMotorcycle? motorcycle;
  final List<VerificationDocument> driverDocuments;
  final List<VerificationDocument> motorcycleDocuments;

  bool get readyForNewWork => safetyReason == null;
}

class DeliveryCompletionResult {
  const DeliveryCompletionResult({
    required this.outcome,
    this.attemptsRemaining,
    this.lockedUntil,
  });

  factory DeliveryCompletionResult.fromJson(Map<String, dynamic> json) =>
      DeliveryCompletionResult(
        outcome: json['outcome'] as String,
        attemptsRemaining: (json['attempts_remaining'] as num?)?.toInt(),
        lockedUntil: json['locked_until'] == null
            ? null
            : DateTime.parse(json['locked_until'] as String).toLocal(),
      );

  final String outcome;
  final int? attemptsRemaining;
  final DateTime? lockedUntil;
}

class DriverOffer {
  const DriverOffer({
    required this.id,
    required this.orderId,
    required this.price,
    required this.status,
    this.pickupAddress = '',
    this.destinationAddress = '',
    this.orderStatus,
    this.biddingDeadline,
    this.customerPrice,
    this.assignedToMe = false,
    this.createdAt,
  });

  factory DriverOffer.fromJson(Map<String, dynamic> json) => DriverOffer(
    id: json['id'] as String,
    orderId: json['order_id'] as String,
    price: _asDouble(json['offered_price']),
    status: OfferStatus.values.firstWhere(
      (value) => value.databaseValue == json['status'],
    ),
    pickupAddress: json['pickup_address'] as String? ?? '',
    destinationAddress: json['destination_address'] as String? ?? '',
    orderStatus: json['order_status'] == null
        ? null
        : OrderStatus.values.firstWhere(
            (value) => value.databaseValue == json['order_status'],
          ),
    biddingDeadline: _serverAdjustedDateTime(json, 'bidding_expires_at'),
    customerPrice: json['proposed_price'] == null
        ? null
        : _asDouble(json['proposed_price']),
    assignedToMe: json['assigned_to_me'] == true,
    createdAt: json['created_at'] == null
        ? null
        : DateTime.parse(json['created_at'] as String),
  );

  final String id;
  final String orderId;
  final double price;
  final OfferStatus status;
  final String pickupAddress;
  final String destinationAddress;
  final OrderStatus? orderStatus;
  final DateTime? biddingDeadline;
  final double? customerPrice;
  final bool assignedToMe;
  final DateTime? createdAt;

  bool get canWithdraw =>
      status == OfferStatus.active &&
      orderStatus == OrderStatus.bidding &&
      biddingDeadline != null &&
      DateTime.now().isBefore(biddingDeadline!);
  bool get hasActiveTrip =>
      status == OfferStatus.selected &&
      assignedToMe &&
      const [
        OrderStatus.driverAssigned,
        OrderStatus.driverOnWay,
        OrderStatus.driverArrived,
        OrderStatus.inProgress,
      ].contains(orderStatus);
  String get closedLabel => switch (orderStatus) {
    OrderStatus.cancelled => 'تم إلغاء الطلب',
    OrderStatus.completed => 'تمت الرحلة',
    OrderStatus.expired => 'انتهت مهلة الطلب',
    _ => status == OfferStatus.withdrawn ? 'تم سحب العرض' : 'انتهى العرض',
  };
}

class WaitingOffersGeneration {
  int _value = 0;

  int capture() => _value;
  void reset() => _value++;
  bool accepts(int value) => value == _value;
}

class DriverDashboardData {
  const DriverDashboardData({
    required this.account,
    required this.availableRequests,
    required this.activeOrder,
    required this.waitingOffers,
  });

  const DriverDashboardData.noAccount()
    : account = null,
      availableRequests = const [],
      activeOrder = null,
      waitingOffers = const [];

  final DriverAccount? account;
  final List<DriverOrder> availableRequests;
  final DriverOrder? activeOrder;
  final List<DriverOffer> waitingOffers;
}

String driverStartupLocation(DriverOrder? order) =>
    order?.nextAction != null ? '/active-order/${order!.id}' : '/home';

class DriverEarningsData {
  const DriverEarningsData({
    required this.driverType,
    this.entries = const [],
    this.orders = const [],
  });

  final DriverType driverType;
  final List<DriverEarningEntry> entries;
  final List<DriverOrder> orders;
}

class DriverEarningEntry {
  const DriverEarningEntry({
    required this.orderId,
    required this.completedAt,
    required this.grossFare,
    required this.isFinanciallyKnown,
    this.platformCommission,
    this.driverNet,
  });

  factory DriverEarningEntry.fromJson(Map<String, dynamic> json) =>
      DriverEarningEntry(
        orderId: json['order_id'] as String,
        completedAt: DateTime.parse(json['completed_at'] as String).toLocal(),
        grossFare: _asDouble(json['gross_fare']),
        isFinanciallyKnown: json['financial_status'] == 'SNAPSHOTTED',
        platformCommission: _nullableDouble(json['platform_commission_amount']),
        driverNet: _nullableDouble(json['driver_net_amount']),
      );

  final String orderId;
  final DateTime completedAt;
  final double grossFare;
  final bool isFinanciallyKnown;
  final double? platformCommission;
  final double? driverNet;
}

double _asDouble(Object? value) => switch (value) {
  num number => number.toDouble(),
  String text => double.parse(text),
  _ => throw const FormatException('Expected numeric value'),
};

double? _nullableDouble(Object? value) =>
    value == null ? null : _asDouble(value);

DateTime? _serverAdjustedDateTime(Map<String, dynamic> json, String key) {
  final raw = json[key];
  if (raw == null) return null;
  final value = DateTime.parse(raw as String);
  final serverNow = json['server_now'];
  if (serverNow == null) return value.toLocal();
  return DateTime.now().add(
    value.difference(DateTime.parse(serverNow as String)),
  );
}
