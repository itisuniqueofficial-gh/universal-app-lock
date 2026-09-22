import 'package:flutter_test/flutter_test.dart';
import 'package:universal_app_lock/core/models/app_info.dart';

void main() {
  group('AppInfo', () {
    test('round-trips through toMap/fromMap', () {
      const app = AppInfo(
        packageName: 'com.example.app',
        applicationName: 'Example',
        isSystemApp: false,
        isEnabled: true,
        launchable: true,
        versionName: '1.2.3',
        versionCode: 42,
      );
      final restored = AppInfo.fromMap(app.toMap());
      expect(restored.packageName, 'com.example.app');
      expect(restored.applicationName, 'Example');
      expect(restored.isSystemApp, false);
      expect(restored.isEnabled, true);
      expect(restored.launchable, true);
      expect(restored.versionName, '1.2.3');
      expect(restored.versionCode, 42);
    });

    test('tolerates missing/malformed fields', () {
      final app = AppInfo.fromMap({'packageName': 'com.x'});
      expect(app.packageName, 'com.x');
      // Falls back to package name when label is absent.
      expect(app.applicationName, 'com.x');
      expect(app.isSystemApp, false);
      expect(app.isEnabled, true);
      expect(app.launchable, false);
      expect(app.versionCode, 0);
    });

    test('equality is based on package name', () {
      const a = AppInfo(
        packageName: 'com.x',
        applicationName: 'A',
        isSystemApp: false,
        isEnabled: true,
        launchable: true,
      );
      const b = AppInfo(
        packageName: 'com.x',
        applicationName: 'B (renamed)',
        isSystemApp: true,
        isEnabled: false,
        launchable: false,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });
}
