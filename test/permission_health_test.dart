import 'package:flutter_test/flutter_test.dart';
import 'package:universal_app_lock/features/permissions/permission_health.dart';

void main() {
  group('computeSecurityHealth', () {
    test('no PIN => notConfigured (regardless of permissions)', () {
      expect(
        computeSecurityHealth(
          hasPin: false,
          usageGranted: true,
          overlayGranted: true,
        ),
        SecurityHealth.notConfigured,
      );
    });

    test('PIN + all required => ready', () {
      expect(
        computeSecurityHealth(
          hasPin: true,
          usageGranted: true,
          overlayGranted: true,
        ),
        SecurityHealth.ready,
      );
    });

    test('PIN + some required => limited', () {
      expect(
        computeSecurityHealth(
          hasPin: true,
          usageGranted: true,
          overlayGranted: false,
        ),
        SecurityHealth.limited,
      );
    });

    test('PIN + none required => actionRequired', () {
      expect(
        computeSecurityHealth(
          hasPin: true,
          usageGranted: false,
          overlayGranted: false,
        ),
        SecurityHealth.actionRequired,
      );
    });

    test('labels', () {
      expect(securityHealthLabel(SecurityHealth.ready), 'READY');
      expect(
        securityHealthLabel(SecurityHealth.notConfigured),
        'NOT CONFIGURED',
      );
      expect(
        securityHealthLabel(SecurityHealth.actionRequired),
        'ACTION REQUIRED',
      );
      expect(securityHealthLabel(SecurityHealth.limited), 'LIMITED');
    });
  });
}
