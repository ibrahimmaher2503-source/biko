// Shared enums for BikeRide application
// All enums include Firestore snake_case serialization helpers

enum UserType {
  customer,
  driver,
  merchant;

  String toJson() => name;

  static UserType fromJson(String value) {
    return UserType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => UserType.customer,
    );
  }
}

enum UserStatus {
  active,
  suspended,
  pendingApproval;

  String toJson() {
    switch (this) {
      case UserStatus.active:
        return 'active';
      case UserStatus.suspended:
        return 'suspended';
      case UserStatus.pendingApproval:
        return 'pending_approval';
    }
  }

  static UserStatus fromJson(String value) {
    switch (value) {
      case 'pending_approval':
        return UserStatus.pendingApproval;
      case 'suspended':
        return UserStatus.suspended;
      default:
        return UserStatus.active;
    }
  }
}

enum VehicleType {
  motorcycle,
  scooter,
  ebike;

  String toJson() => name;

  static VehicleType fromJson(String value) {
    return VehicleType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => VehicleType.motorcycle,
    );
  }
}

enum DocumentType {
  nationalId,
  license,
  vehicleRegistration,
  criminalRecord;

  String toJson() {
    switch (this) {
      case DocumentType.nationalId:
        return 'national_id';
      case DocumentType.license:
        return 'license';
      case DocumentType.vehicleRegistration:
        return 'vehicle_registration';
      case DocumentType.criminalRecord:
        return 'criminal_record';
    }
  }

  static DocumentType fromJson(String value) {
    switch (value) {
      case 'national_id':
        return DocumentType.nationalId;
      case 'license':
        return DocumentType.license;
      case 'vehicle_registration':
        return DocumentType.vehicleRegistration;
      case 'criminal_record':
        return DocumentType.criminalRecord;
      default:
        return DocumentType.nationalId;
    }
  }
}

enum DocumentStatus {
  pending,
  approved,
  rejected;

  String toJson() => name;

  static DocumentStatus fromJson(String value) {
    return DocumentStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DocumentStatus.pending,
    );
  }
}

enum AuthState {
  idle,
  sendingOtp,
  codeSent,
  verifying,
  signingInWithGoogle,
  signingInWithFacebook,
  authenticated,
  error,
}

enum TripStatus {
  searching,
  bidding,
  accepted,
  onTheWay,
  arrived,
  inProgress,
  completed,
  cancelled;

  String toJson() {
    switch (this) {
      case TripStatus.searching:
        return 'searching';
      case TripStatus.bidding:
        return 'bidding';
      case TripStatus.accepted:
        return 'accepted';
      case TripStatus.onTheWay:
        return 'on_the_way';
      case TripStatus.arrived:
        return 'arrived';
      case TripStatus.inProgress:
        return 'in_progress';
      case TripStatus.completed:
        return 'completed';
      case TripStatus.cancelled:
        return 'cancelled';
    }
  }

  static TripStatus fromJson(String value) {
    switch (value) {
      case 'on_the_way':
        return TripStatus.onTheWay;
      case 'in_progress':
        return TripStatus.inProgress;
      default:
        return TripStatus.values.firstWhere(
          (e) => e.name == value,
          orElse: () => TripStatus.searching,
        );
    }
  }
}

enum TripType {
  ride,
  c2cDelivery,
  b2bDelivery;

  String toJson() {
    switch (this) {
      case TripType.ride:
        return 'ride';
      case TripType.c2cDelivery:
        return 'c2c_delivery';
      case TripType.b2bDelivery:
        return 'b2b_delivery';
    }
  }

  static TripType fromJson(String value) {
    switch (value) {
      case 'c2c_delivery':
        return TripType.c2cDelivery;
      case 'b2b_delivery':
        return TripType.b2bDelivery;
      default:
        return TripType.ride;
    }
  }
}

enum PaymentMethod {
  cash,
  wallet,
  card,
  vodafoneCash,
  fawry;

  String toJson() {
    switch (this) {
      case PaymentMethod.cash:
        return 'cash';
      case PaymentMethod.wallet:
        return 'wallet';
      case PaymentMethod.card:
        return 'card';
      case PaymentMethod.vodafoneCash:
        return 'vodafone_cash';
      case PaymentMethod.fawry:
        return 'fawry';
    }
  }

  static PaymentMethod fromJson(String value) {
    switch (value) {
      case 'vodafone_cash':
        return PaymentMethod.vodafoneCash;
      default:
        return PaymentMethod.values.firstWhere(
          (e) => e.name == value,
          orElse: () => PaymentMethod.cash,
        );
    }
  }
}

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

enum TrackingStatus {
  driverEnRoute,
  driverArrived,
  tripInProgress,
  arrivingSoon,
  completed,
  cancelled;

  String toJson() {
    switch (this) {
      case TrackingStatus.driverEnRoute:
        return 'driver_en_route';
      case TrackingStatus.driverArrived:
        return 'driver_arrived';
      case TrackingStatus.tripInProgress:
        return 'in_progress';
      case TrackingStatus.arrivingSoon:
        return 'arriving_soon';
      case TrackingStatus.completed:
        return 'completed';
      case TrackingStatus.cancelled:
        return 'cancelled';
    }
  }

  static TrackingStatus fromJson(String value) {
    switch (value) {
      case 'driver_en_route':
        return TrackingStatus.driverEnRoute;
      case 'driver_arrived':
        return TrackingStatus.driverArrived;
      case 'in_progress':
        return TrackingStatus.tripInProgress;
      case 'arriving_soon':
        return TrackingStatus.arrivingSoon;
      case 'completed':
        return TrackingStatus.completed;
      case 'cancelled':
        return TrackingStatus.cancelled;
      default:
        return TrackingStatus.driverEnRoute;
    }
  }

  /// Translation key for display
  String get translationKey {
    switch (this) {
      case TrackingStatus.driverEnRoute:
        return 'tracking.driver_en_route';
      case TrackingStatus.driverArrived:
        return 'tracking.driver_arrived';
      case TrackingStatus.tripInProgress:
        return 'tracking.trip_in_progress';
      case TrackingStatus.arrivingSoon:
        return 'tracking.arriving_soon';
      case TrackingStatus.completed:
        return 'tracking.completed';
      case TrackingStatus.cancelled:
        return 'tracking.cancelled';
    }
  }
}

enum AdminRole {
  admin,
  superAdmin;

  String toJson() {
    switch (this) {
      case AdminRole.admin:
        return 'admin';
      case AdminRole.superAdmin:
        return 'super_admin';
    }
  }

  static AdminRole fromJson(String value) {
    switch (value) {
      case 'super_admin':
        return AdminRole.superAdmin;
      default:
        return AdminRole.admin;
    }
  }
}
