/// Failed-attempt lockout policy: a pure, testable function mapping the number
/// of consecutive failed attempts to a temporary lockout duration.
///
/// Uses bounded exponential backoff so a transient mistake is not punished, but
/// brute-force is slowed. It never permanently locks the user out and performs
/// no destructive action.
library;

class LockoutPolicy {
  const LockoutPolicy({
    this.threshold = 5,
    this.baseLockout = const Duration(seconds: 30),
    this.factor = 2,
    this.maxLockout = const Duration(minutes: 15),
  });

  /// Number of consecutive failures allowed before any lockout begins.
  final int threshold;
  final Duration baseLockout;
  final int factor;
  final Duration maxLockout;

  /// Lockout duration after [failedAttempts] consecutive failures.
  /// Returns [Duration.zero] until the threshold is exceeded.
  Duration lockoutFor(int failedAttempts) {
    if (failedAttempts < threshold) return Duration.zero;
    final over = failedAttempts - threshold; // 0 at first lockout
    var ms = baseLockout.inMilliseconds;
    for (var i = 0; i < over; i++) {
      ms *= factor;
      if (ms >= maxLockout.inMilliseconds) return maxLockout;
    }
    return Duration(milliseconds: ms.clamp(0, maxLockout.inMilliseconds));
  }

  /// Attempts remaining before the next lockout (never negative).
  int attemptsRemaining(int failedAttempts) {
    final r = threshold - failedAttempts;
    return r < 0 ? 0 : r;
  }
}
