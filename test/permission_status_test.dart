import 'package:flutter_test/flutter_test.dart';
import 'package:universal_app_lock/core/models/permission_status.dart';

void main() {
  group('PermissionInfo', () {
    const info = PermissionInfo(
      kind: PermissionKind.usageAccess,
      title: 'Usage Access',
      description: 'desc',
      status: PermissionStatus.denied,
      required: true,
    );

    test('isGranted reflects status', () {
      expect(info.isGranted, isFalse);
      final granted = info.copyWith(status: PermissionStatus.granted);
      expect(granted.isGranted, isTrue);
    });

    test('copyWith preserves other fields', () {
      final updated = info.copyWith(status: PermissionStatus.granted);
      expect(updated.kind, PermissionKind.usageAccess);
      expect(updated.title, 'Usage Access');
      expect(updated.required, isTrue);
    });

    test('models more than a boolean', () {
      expect(PermissionStatus.values, contains(PermissionStatus.unavailable));
      expect(PermissionStatus.values, contains(PermissionStatus.notRequired));
      expect(PermissionStatus.values, contains(PermissionStatus.unknown));
    });
  });
}
