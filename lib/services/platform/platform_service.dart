import 'dart:typed_data';

import 'package:flutter/services.dart';

import '../../core/errors/platform_bridge_exception.dart';
import '../../core/models/app_info.dart';
import '../../core/models/platform_info.dart';
import '../channels/platform_channels.dart';

/// PlatformService is the Dart-side facade over the native platform bridge.
///
/// It is the ONLY place MethodChannel calls are made; the UI communicates
/// exclusively through this abstraction. In this phase it exposes read-only
/// diagnostics, application discovery, and permission detection/navigation.
/// It performs no locking, monitoring, or authentication.
class PlatformService {
  PlatformService({MethodChannel? methodChannel, EventChannel? eventChannel})
    : _method =
          methodChannel ?? const MethodChannel(PlatformChannels.methodChannel),
      _events =
          eventChannel ?? const EventChannel(PlatformChannels.eventChannel);

  final MethodChannel _method;
  final EventChannel _events;

  // --- Diagnostics ----------------------------------------------------------

  Future<int> getBridgeVersion() =>
      _invoke<int>(PlatformMethods.getBridgeVersion);

  Future<int> getAndroidSdk() => _invoke<int>(PlatformMethods.getAndroidSdk);

  Future<PlatformInfo> getPlatformInfo() async {
    final map = await _invoke<Map<dynamic, dynamic>>(
      PlatformMethods.getPlatformInfo,
    );
    return PlatformInfo.fromMap(map);
  }

  // --- Application discovery ------------------------------------------------

  /// Returns installed, user-launchable applications. Set [includeSystem] to
  /// include system apps. Malformed entries are skipped rather than throwing.
  Future<List<AppInfo>> getInstalledApplications({
    bool includeSystem = false,
  }) async {
    final raw = await _invoke<List<dynamic>>(
      PlatformMethods.getInstalledApplications,
      {'includeSystem': includeSystem},
    );
    final apps = <AppInfo>[];
    for (final entry in raw) {
      if (entry is Map) {
        try {
          apps.add(AppInfo.fromMap(entry));
        } catch (_) {
          // Skip a single malformed record.
        }
      }
    }
    return apps;
  }

  /// Returns the PNG icon bytes for [packageName], or null if unavailable.
  Future<Uint8List?> getApplicationIcon(
    String packageName, {
    int sizePx = 96,
  }) async {
    try {
      return await _method.invokeMethod<Uint8List>(
        PlatformMethods.getApplicationIcon,
        {'packageName': packageName, 'sizePx': sizePx},
      );
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  // --- Permissions ----------------------------------------------------------

  Future<bool> isUsageAccessGranted() =>
      _invoke<bool>(PlatformMethods.isUsageAccessGranted);

  Future<bool> openUsageAccessSettings() =>
      _invoke<bool>(PlatformMethods.openUsageAccessSettings);

  Future<bool> isOverlayPermissionGranted() =>
      _invoke<bool>(PlatformMethods.isOverlayPermissionGranted);

  Future<bool> openOverlaySettings() =>
      _invoke<bool>(PlatformMethods.openOverlaySettings);

  /// One of: "available", "not_enrolled", "unavailable".
  Future<String> getBiometricAvailability() =>
      _invoke<String>(PlatformMethods.getBiometricAvailability);

  // --- Events ---------------------------------------------------------------

  Stream<Map<dynamic, dynamic>> events() {
    return _events.receiveBroadcastStream().map(
      (event) => (event as Map).cast<dynamic, dynamic>(),
    );
  }

  // --- Internal -------------------------------------------------------------

  Future<T> _invoke<T>(String method, [dynamic args]) async {
    try {
      final result = await _method.invokeMethod<T>(method, args);
      if (result == null) {
        throw PlatformBridgeException('Method "$method" returned null');
      }
      return result;
    } on MissingPluginException catch (e) {
      throw PlatformBridgeException(
        'Native bridge unavailable for "$method"',
        cause: e,
      );
    } on PlatformException catch (e) {
      throw PlatformBridgeException('Native call "$method" failed', cause: e);
    }
  }
}
