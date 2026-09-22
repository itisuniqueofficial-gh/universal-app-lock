import 'package:flutter/services.dart';

import '../../core/errors/platform_bridge_exception.dart';
import '../../core/models/platform_info.dart';
import '../channels/platform_channels.dart';

/// PlatformService is the Dart-side facade over the native platform bridge.
///
/// It currently exposes ONLY harmless, read-only diagnostic capabilities. It
/// does not perform, request, or expose any security-sensitive or privileged
/// operation. Security-critical functionality lives natively (Kotlin) and will
/// be surfaced through explicitly named methods in later phases.
class PlatformService {
  PlatformService({
    MethodChannel? methodChannel,
    EventChannel? eventChannel,
  })  : _method =
            methodChannel ?? const MethodChannel(PlatformChannels.methodChannel),
        _events =
            eventChannel ?? const EventChannel(PlatformChannels.eventChannel);

  final MethodChannel _method;
  final EventChannel _events;

  /// Returns the native bridge contract version.
  Future<int> getBridgeVersion() => _invoke<int>('getBridgeVersion');

  /// Returns the running Android SDK integer (e.g. 34).
  Future<int> getAndroidSdk() => _invoke<int>('getAndroidSdk');

  /// Returns read-only device/platform metadata.
  Future<PlatformInfo> getPlatformInfo() async {
    final map = await _invoke<Map<dynamic, dynamic>>('getPlatformInfo');
    return PlatformInfo.fromMap(map);
  }

  /// Returns the installed application's version metadata.
  Future<AppVersion> getAppVersion() async {
    final map = await _invoke<Map<dynamic, dynamic>>('getAppVersion');
    return AppVersion.fromMap(map);
  }

  /// A stream of harmless diagnostic events from the native side (currently a
  /// single "ready" capability event on listen). No sensitive data is emitted.
  Stream<Map<dynamic, dynamic>> events() {
    return _events
        .receiveBroadcastStream()
        .map((event) => (event as Map).cast<dynamic, dynamic>());
  }

  Future<T> _invoke<T>(String method) async {
    try {
      final result = await _method.invokeMethod<T>(method);
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
      throw PlatformBridgeException(
        'Native call "$method" failed',
        cause: e,
      );
    }
  }
}
