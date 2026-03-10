/// Development configuration flags
///
/// Set these flags to bypass certain behaviors during development.
/// All flags should be `false` in production builds.
class DevConfig {
  DevConfig._();

  /// Skip Firebase OTP verification and go directly to profile setup.
  /// Set to `true` during development to speed up testing.
  static const bool skipOtp = false;

  /// Skip FCM token registration.
  static const bool skipFcm = false;

  /// Use mock location data instead of real GPS.
  static const bool useMockLocation = false;
}
