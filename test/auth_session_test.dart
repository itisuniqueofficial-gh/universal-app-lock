import 'package:flutter_test/flutter_test.dart';
import 'package:universal_app_lock/core/auth/auth_session.dart';

void main() {
  group('AuthSessionManager', () {
    test('grant then valid within timeout', () {
      var now = 1000;
      final mgr = AuthSessionManager(clock: () => now);
      mgr.grant('com.a', const Duration(seconds: 10));
      expect(mgr.isUnlocked('com.a'), isTrue);
      now += 5000;
      expect(mgr.isUnlocked('com.a'), isTrue);
      now += 6000; // 11s total > 10s
      expect(mgr.isUnlocked('com.a'), isFalse);
    });

    test('timeout zero means lock immediately', () {
      final mgr = AuthSessionManager(clock: () => 0);
      mgr.grant('com.a', Duration.zero);
      expect(mgr.isUnlocked('com.a'), isFalse);
    });

    test('invalidate and invalidateAll', () {
      var now = 0;
      final mgr = AuthSessionManager(clock: () => now);
      mgr.grant('com.a', const Duration(minutes: 5));
      mgr.grant('com.b', const Duration(minutes: 5));
      expect(mgr.activeCount, 2);
      mgr.invalidate('com.a');
      expect(mgr.isUnlocked('com.a'), isFalse);
      expect(mgr.isUnlocked('com.b'), isTrue);
      mgr.invalidateAll();
      expect(mgr.isUnlocked('com.b'), isFalse);
      expect(mgr.activeCount, 0);
    });

    test('expired session is pruned on check', () {
      var now = 0;
      final mgr = AuthSessionManager(clock: () => now);
      mgr.grant('com.a', const Duration(seconds: 1));
      now = 2000;
      expect(mgr.isUnlocked('com.a'), isFalse);
      expect(mgr.activeCount, 0);
    });
  });
}
