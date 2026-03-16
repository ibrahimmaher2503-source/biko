/// Stub implementation for non-web platforms.
///
/// This file is used when `dart:html` is not available (tests, mobile).
void downloadFileAsBlob(List<int> bytes, String filename) {
  // No-op on non-web platforms
}
