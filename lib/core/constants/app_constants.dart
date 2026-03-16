/// App-wide constants for the BikeRide application
class AppConstants {
  // Prevent instantiation
  AppConstants._();

  /// Spacing scale for consistent padding and margins
  /// All values are in logical pixels (dp)
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 12.0;
  static const double spacingLg = 16.0;
  static const double spacingXl = 24.0;
  static const double spacing2xl = 32.0;
  static const double spacing3xl = 48.0;

  /// Touch target sizes (Material Design guidelines)
  static const double minTouchTarget = 48.0;

  /// Animation durations (milliseconds)
  static const int animationDurationShort = 200;
  static const int animationDurationMedium = 300;
  static const int animationDurationLong = 500;

  /// Timeout durations (seconds)
  static const int timeoutNetwork = 30;
  static const int timeoutShort = 5;
  static const int timeoutLong = 60;

  /// Default snackbar duration (seconds)
  static const int snackbarDuration = 3;

  /// Phone number format (Egypt)
  static const String phonePrefix = '+20';
  static const int phoneLength = 11; // Including country code digits
}
