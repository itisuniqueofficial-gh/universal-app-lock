/// Immutable data models returned by the diagnostic platform bridge.
///
/// These carry only harmless, read-only device/app metadata. No sensitive or
/// security-relevant data is modeled here.
library;

class PlatformInfo {
  const PlatformInfo({
    required this.os,
    required this.sdkInt,
    required this.release,
    required this.manufacturer,
    required this.model,
    required this.bridgeVersion,
  });

  final String os;
  final int sdkInt;
  final String release;
  final String manufacturer;
  final String model;
  final int bridgeVersion;

  factory PlatformInfo.fromMap(Map<dynamic, dynamic> map) {
    return PlatformInfo(
      os: (map['os'] as String?) ?? 'unknown',
      sdkInt: (map['sdkInt'] as int?) ?? 0,
      release: (map['release'] as String?) ?? '',
      manufacturer: (map['manufacturer'] as String?) ?? '',
      model: (map['model'] as String?) ?? '',
      bridgeVersion: (map['bridgeVersion'] as int?) ?? 0,
    );
  }
}

class AppVersion {
  const AppVersion({
    required this.packageName,
    required this.versionName,
    required this.versionCode,
  });

  final String packageName;
  final String versionName;
  final int versionCode;

  factory AppVersion.fromMap(Map<dynamic, dynamic> map) {
    return AppVersion(
      packageName: (map['packageName'] as String?) ?? '',
      versionName: (map['versionName'] as String?) ?? '',
      versionCode: (map['versionCode'] as num?)?.toInt() ?? 0,
    );
  }
}
