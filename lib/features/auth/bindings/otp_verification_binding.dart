import 'package:get/get.dart';

/// Binding for the OTP Verification screen.
///
/// [AuthController] is registered globally in [AppInitializer],
/// so no additional controllers need to be lazily created here.
class OtpVerificationBinding extends Bindings {
  @override
  void dependencies() {
    // AuthController is already registered as permanent in AppInitializer.
    // This binding exists for route consistency.
  }
}
