class CustomerProfile {
  const CustomerProfile({
    required this.email,
    required this.fullName,
    this.phone,
    this.photoPath,
    this.photoUrl,
  });

  final String email;
  final String fullName;
  final String? phone;
  final String? photoPath;
  final String? photoUrl;
}
