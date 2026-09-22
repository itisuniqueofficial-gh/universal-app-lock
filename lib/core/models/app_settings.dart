/// Central, immutable application settings model.
///
/// This is the single source of truth for user preferences. Fields for future
/// capabilities are declared with safe defaults so persistence and plumbing can
/// be built now, but the UI only exposes settings that are actually implemented
/// (currently none are user-editable — locking is not implemented yet).
library;

import 'dart:convert';

class AppSettings {
  const AppSettings({
    this.lockTimeoutSeconds = 0,
    this.biometricEnabled = false,
    this.pinConfigured = false,
    this.lockOnScreenOff = true,
    this.lockNewlyInstalledApps = false,
  });

  /// Grace period before re-locking after a successful unlock (0 = immediate).
  final int lockTimeoutSeconds;

  /// Whether biometric unlock is enabled (not implemented yet).
  final bool biometricEnabled;

  /// Whether an app PIN has been configured (not implemented yet).
  final bool pinConfigured;

  /// Whether protected apps re-lock when the screen turns off.
  final bool lockOnScreenOff;

  /// Whether newly installed apps are auto-added to protection.
  final bool lockNewlyInstalledApps;

  AppSettings copyWith({
    int? lockTimeoutSeconds,
    bool? biometricEnabled,
    bool? pinConfigured,
    bool? lockOnScreenOff,
    bool? lockNewlyInstalledApps,
  }) {
    return AppSettings(
      lockTimeoutSeconds: lockTimeoutSeconds ?? this.lockTimeoutSeconds,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      pinConfigured: pinConfigured ?? this.pinConfigured,
      lockOnScreenOff: lockOnScreenOff ?? this.lockOnScreenOff,
      lockNewlyInstalledApps:
          lockNewlyInstalledApps ?? this.lockNewlyInstalledApps,
    );
  }

  Map<String, Object?> toMap() => {
    'lockTimeoutSeconds': lockTimeoutSeconds,
    'biometricEnabled': biometricEnabled,
    'pinConfigured': pinConfigured,
    'lockOnScreenOff': lockOnScreenOff,
    'lockNewlyInstalledApps': lockNewlyInstalledApps,
  };

  factory AppSettings.fromMap(Map<dynamic, dynamic> map) {
    return AppSettings(
      lockTimeoutSeconds: (map['lockTimeoutSeconds'] as num?)?.toInt() ?? 0,
      biometricEnabled: map['biometricEnabled'] as bool? ?? false,
      pinConfigured: map['pinConfigured'] as bool? ?? false,
      lockOnScreenOff: map['lockOnScreenOff'] as bool? ?? true,
      lockNewlyInstalledApps: map['lockNewlyInstalledApps'] as bool? ?? false,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory AppSettings.fromJson(String source) =>
      AppSettings.fromMap(jsonDecode(source) as Map<dynamic, dynamic>);
}
