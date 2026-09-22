/// Channel identifiers for the Flutter <-> Kotlin platform bridge.
///
/// These MUST match the constants declared in the native
/// [PlatformBridge] (Kotlin). The bridge is versioned via [bridgeVersion].
library;

class PlatformChannels {
  PlatformChannels._();

  /// Expected native bridge contract version. Kept in sync with
  /// `PlatformBridge.BRIDGE_VERSION` on the Kotlin side.
  static const int bridgeVersion = 1;

  static const String methodChannel = 'com.itisuniqueofficial.ual/platform';
  static const String eventChannel =
      'com.itisuniqueofficial.ual/platform_events';
}
