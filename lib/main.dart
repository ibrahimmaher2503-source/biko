// ignore_for_file: unused_import
import 'package:biko/main_admin.dart' as admin;
import 'package:biko/main_customer.dart' as customer;
import 'package:biko/main_driver.dart' as driver;

/// Default entry point — launches Customer App
///
/// For specific apps, use:
/// - Customer: flutter run -t lib/main_customer.dart
/// - Driver:   flutter run -t lib/main_driver.dart
/// - Admin:    flutter run -d chrome -t lib/main_admin.dart
void main() => admin.main();
