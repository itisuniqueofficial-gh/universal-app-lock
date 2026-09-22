/// Error types for Universal App Lock.
library;

/// Thrown when a call across the native platform bridge fails or is
/// unavailable (for example, when running in a test/host environment without
/// the native side attached).
class PlatformBridgeException implements Exception {
  const PlatformBridgeException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'PlatformBridgeException: $message';
}
