import 'package:flutter_test/flutter_test.dart';
import 'package:universal_app_lock/core/models/app_settings.dart';

void main() {
  group('AppSettings', () {
    test('has safe defaults', () {
      const s = AppSettings();
      expect(s.lockTimeoutSeconds, 0);
      expect(s.biometricEnabled, isFalse);
      expect(s.pinConfigured, isFalse);
      expect(s.lockOnScreenOff, isTrue);
      expect(s.lockNewlyInstalledApps, isFalse);
    });

    test('copyWith updates only the given field', () {
      const s = AppSettings();
      final u = s.copyWith(biometricEnabled: true, lockTimeoutSeconds: 30);
      expect(u.biometricEnabled, isTrue);
      expect(u.lockTimeoutSeconds, 30);
      expect(u.lockOnScreenOff, isTrue); // unchanged default
    });

    test('round-trips through JSON', () {
      const s = AppSettings(
        lockTimeoutSeconds: 15,
        biometricEnabled: true,
        pinConfigured: true,
        lockOnScreenOff: false,
        lockNewlyInstalledApps: true,
      );
      final restored = AppSettings.fromJson(s.toJson());
      expect(restored.toMap(), s.toMap());
    });
  });
}
