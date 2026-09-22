import 'package:flutter_test/flutter_test.dart';
import 'package:universal_app_lock/core/auth/lockout_policy.dart';

void main() {
  group('LockoutPolicy', () {
    const p = LockoutPolicy(); // threshold 5, base 30s, factor 2, cap 15m

    test('no lockout below threshold', () {
      expect(p.lockoutFor(0), Duration.zero);
      expect(p.lockoutFor(4), Duration.zero);
    });

    test('lockout begins at threshold and grows', () {
      expect(p.lockoutFor(5), const Duration(seconds: 30));
      expect(p.lockoutFor(6), const Duration(seconds: 60));
      expect(p.lockoutFor(7), const Duration(seconds: 120));
    });

    test('lockout is capped', () {
      expect(p.lockoutFor(100), const Duration(minutes: 15));
    });

    test('attemptsRemaining never negative', () {
      expect(p.attemptsRemaining(0), 5);
      expect(p.attemptsRemaining(5), 0);
      expect(p.attemptsRemaining(9), 0);
    });
  });
}
