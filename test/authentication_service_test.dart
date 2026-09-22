import 'package:flutter_test/flutter_test.dart';
import 'package:universal_app_lock/core/auth/lockout_policy.dart';
import 'package:universal_app_lock/repositories/key_value_store.dart';
import 'package:universal_app_lock/services/auth/authentication_service.dart';

import 'support/fake_platform_service.dart';

void main() {
  group('AuthenticationService', () {
    late FakePlatformService platform;
    late InMemoryKeyValueStore store;
    late int now;
    late AuthenticationService svc;

    setUp(() {
      platform = FakePlatformService();
      store = InMemoryKeyValueStore();
      now = 0;
      svc = AuthenticationService(
        platform: platform,
        store: store,
        lockoutPolicy: const LockoutPolicy(threshold: 3),
        clock: () => now,
      );
    });

    test('setPin rejects bad format, accepts valid', () async {
      expect((await svc.setPin('12')).status, PinSetStatus.invalidFormat);
      expect((await svc.setPin('123456')).isOk, isTrue);
      expect(await svc.hasPin(), isTrue);
    });

    test('verify success resets attempts', () async {
      await svc.setPin('123456');
      expect((await svc.verifyPin('000000')).status, AuthStatus.failed);
      final ok = await svc.verifyPin('123456');
      expect(ok.status, AuthStatus.success);
      // After success, a subsequent wrong attempt shows full remaining again.
      final r = await svc.verifyPin('999999');
      expect(r.attemptsRemaining, 2); // threshold 3, 1 failure
    });

    test('lockout after threshold failures', () async {
      await svc.setPin('123456');
      expect(
        (await svc.verifyPin('0')).status,
        AuthStatus.failed,
      ); // format? '0' invalid length -> but verify doesn't validate format
      // Note: verifyPin does not enforce format; wrong PINs count as failures.
      await svc.verifyPin('111111'); // 2 (first was '0')
      final third = await svc.verifyPin('222222'); // 3 -> lockout
      expect(third.status, AuthStatus.lockedOut);
      expect(third.lockoutMs, greaterThan(0));

      // While locked out, even the correct PIN is refused.
      final duringLock = await svc.verifyPin('123456');
      expect(duringLock.status, AuthStatus.lockedOut);
    });

    test('lockout expires after time passes', () async {
      await svc.setPin('123456');
      await svc.verifyPin('a'); // 1
      await svc.verifyPin('b'); // 2
      final locked = await svc.verifyPin('c'); // 3 -> lockout
      expect(locked.status, AuthStatus.lockedOut);
      now += locked.lockoutMs + 1;
      final ok = await svc.verifyPin('123456');
      expect(ok.status, AuthStatus.success);
    });

    test('clearPin removes and resets', () async {
      await svc.setPin('123456');
      await svc.clearPin();
      expect(await svc.hasPin(), isFalse);
      expect(await svc.lockoutRemainingMs(), 0);
    });
  });
}
