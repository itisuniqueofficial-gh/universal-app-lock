import 'package:flutter_test/flutter_test.dart';
import 'package:universal_app_lock/core/models/app_info.dart';
import 'package:universal_app_lock/features/apps/app_filter.dart';

AppInfo _app(String name, String pkg, {bool system = false}) => AppInfo(
  packageName: pkg,
  applicationName: name,
  isSystemApp: system,
  isEnabled: true,
  launchable: true,
);

void main() {
  final apps = <AppInfo>[
    _app('Camera', 'com.android.camera', system: true),
    _app('Chatter', 'com.example.chatter'),
    _app('Bank', 'com.acme.bank'),
  ];

  group('filterAndSearchApps', () {
    test('filters user apps only', () {
      final r = filterAndSearchApps(apps, filter: AppFilter.user);
      expect(
        r.map((a) => a.packageName),
        isNot(contains('com.android.camera')),
      );
      expect(r.length, 2);
    });

    test('filters system apps only', () {
      final r = filterAndSearchApps(apps, filter: AppFilter.system);
      expect(r.length, 1);
      expect(r.single.packageName, 'com.android.camera');
    });

    test('search is case-insensitive and matches name', () {
      final r = filterAndSearchApps(apps, filter: AppFilter.all, query: 'ch');
      // "Chatter" (name) — camera does not contain "ch".
      expect(r.map((a) => a.applicationName), contains('Chatter'));
      expect(
        r.every(
          (a) =>
              a.applicationName.toLowerCase().contains('ch') ||
              a.packageName.toLowerCase().contains('ch'),
        ),
        isTrue,
      );
    });

    test('search matches package name', () {
      final r = filterAndSearchApps(apps, filter: AppFilter.all, query: 'acme');
      expect(r.length, 1);
      expect(r.single.packageName, 'com.acme.bank');
    });

    test('empty query returns all in filter', () {
      final r = filterAndSearchApps(apps, filter: AppFilter.all, query: '   ');
      expect(r.length, 3);
    });
  });
}
