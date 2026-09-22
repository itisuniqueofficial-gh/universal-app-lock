/// Channel identifiers and method names for the Flutter <-> Kotlin platform
/// bridge. These MUST match the constants declared in the native
/// [PlatformBridge] (Kotlin). The bridge is versioned via [bridgeVersion].
library;

class PlatformChannels {
  PlatformChannels._();

  /// Expected native bridge contract version. Kept in sync with
  /// `PlatformBridge.BRIDGE_VERSION` on the Kotlin side.
  static const int bridgeVersion = 4;

  static const String methodChannel = 'com.itisuniqueofficial.ual/platform';
  static const String eventChannel =
      'com.itisuniqueofficial.ual/platform_events';
}

/// Method names exposed by the native bridge.
class PlatformMethods {
  PlatformMethods._();

  // Diagnostics
  static const String getBridgeVersion = 'getBridgeVersion';
  static const String getAndroidSdk = 'getAndroidSdk';
  static const String getPlatformInfo = 'getPlatformInfo';
  static const String getAppVersion = 'getAppVersion';

  // Application discovery
  static const String getInstalledApplications = 'getInstalledApplications';
  static const String getApplicationIcon = 'getApplicationIcon';

  // Permissions
  static const String isUsageAccessGranted = 'isUsageAccessGranted';
  static const String openUsageAccessSettings = 'openUsageAccessSettings';
  static const String isOverlayPermissionGranted = 'isOverlayPermissionGranted';
  static const String openOverlaySettings = 'openOverlaySettings';
  static const String getBiometricAvailability = 'getBiometricAvailability';

  // Authentication (PIN). Secret handling is native (Android Keystore).
  static const String authHasPin = 'authHasPin';
  static const String authSetPin = 'authSetPin';
  static const String authVerifyPin = 'authVerifyPin';
  static const String authClearPin = 'authClearPin';

  // Protected apps (native source of truth) + enforcement.
  static const String getProtectedApps = 'getProtectedApps';
  static const String setProtectedApps = 'setProtectedApps';
  static const String startMonitoring = 'startMonitoring';
  static const String stopMonitoring = 'stopMonitoring';
  static const String getMonitoringStatus = 'getMonitoringStatus';
  static const String grantUnlock = 'grantUnlock';
  static const String setRelockPolicy = 'setRelockPolicy';
}
