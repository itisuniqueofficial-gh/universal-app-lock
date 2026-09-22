import 'dart:typed_data';

import 'package:universal_app_lock/core/models/app_info.dart';
import 'package:universal_app_lock/services/platform/platform_service.dart';

/// A fake PlatformService for widget/unit tests. Returns canned, deterministic
/// values without touching the native platform bridge.
class FakePlatformService extends PlatformService {
  FakePlatformService({
    this.usageGranted = false,
    this.overlayGranted = false,
    this.biometric = 'unavailable',
    List<AppInfo>? apps,
  }) : apps = apps ?? const <AppInfo>[];

  final bool usageGranted;
  final bool overlayGranted;
  final String biometric;
  final List<AppInfo> apps;

  @override
  Future<List<AppInfo>> getInstalledApplications({
    bool includeSystem = false,
  }) async {
    return includeSystem ? apps : apps.where((a) => !a.isSystemApp).toList();
  }

  @override
  Future<Uint8List?> getApplicationIcon(
    String packageName, {
    int sizePx = 96,
  }) async => null;

  @override
  Future<bool> isUsageAccessGranted() async => usageGranted;

  @override
  Future<bool> openUsageAccessSettings() async => true;

  @override
  Future<bool> isOverlayPermissionGranted() async => overlayGranted;

  @override
  Future<bool> openOverlaySettings() async => true;

  @override
  Future<String> getBiometricAvailability() async => biometric;

  // --- Auth (in-memory, for tests) -----------------------------------------
  String? storedPin;

  @override
  Future<bool> authHasPin() async => storedPin != null;

  @override
  Future<bool> authSetPin(String pin) async {
    storedPin = pin;
    return true;
  }

  @override
  Future<bool> authVerifyPin(String pin) async =>
      storedPin != null && pin == storedPin;

  @override
  Future<bool> authClearPin() async {
    storedPin = null;
    return true;
  }
}
