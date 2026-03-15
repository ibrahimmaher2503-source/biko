import 'package:get/get.dart';

/// Binding for the Phone Login screen.
///
/// [AuthController] is registered globally in [AppInitializer],
/// so no additional controllers need to be lazily created here.
class PhoneLoginBinding extends Bindings {
  @override
  void dependencies() {
    // AuthController is already registered as permanent in AppInitializer.
    // This binding exists for route consistency.
  }
}
