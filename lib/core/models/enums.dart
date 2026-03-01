/// Shared enums for BikeRide application
/// All enums include Firestore snake_case serialization helpers

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
  authenticated,
  error,
}
