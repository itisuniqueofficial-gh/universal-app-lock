/// Strongly-typed model for an installed, user-launchable application, as
/// returned by the native [ApplicationDiscoveryManager] over the platform
/// bridge. Serialization is explicit (no dynamic maps flowing through the app).
library;

class AppInfo {
  const AppInfo({
    required this.packageName,
    required this.applicationName,
    required this.isSystemApp,
    required this.isEnabled,
    required this.launchable,
    this.versionName = '',
    this.versionCode = 0,
  });

  final String packageName;
  final String applicationName;
  final bool isSystemApp;
  final bool isEnabled;
  final bool launchable;
  final String versionName;
  final int versionCode;

  /// Builds an [AppInfo] from a platform-channel map, tolerating missing or
  /// malformed fields (a single bad app must never crash discovery).
  factory AppInfo.fromMap(Map<dynamic, dynamic> map) {
    return AppInfo(
      packageName: (map['packageName'] as String?)?.trim() ?? '',
      applicationName:
          (map['applicationName'] as String?)?.trim().isNotEmpty == true
          ? (map['applicationName'] as String).trim()
          : ((map['packageName'] as String?) ?? ''),
      isSystemApp: map['isSystemApp'] as bool? ?? false,
      isEnabled: map['isEnabled'] as bool? ?? true,
      launchable: map['launchable'] as bool? ?? false,
      versionName: (map['versionName'] as String?) ?? '',
      versionCode: (map['versionCode'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, Object?> toMap() => {
    'packageName': packageName,
    'applicationName': applicationName,
    'isSystemApp': isSystemApp,
    'isEnabled': isEnabled,
    'launchable': launchable,
    'versionName': versionName,
    'versionCode': versionCode,
  };

  @override
  bool operator ==(Object other) =>
      other is AppInfo && other.packageName == packageName;

  @override
  int get hashCode => packageName.hashCode;
}
