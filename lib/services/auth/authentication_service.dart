/// AuthenticationService orchestrates PIN authentication.
///
/// Secret handling (hash/derive/compare) is performed natively (Android
/// Keystore). This service owns only NON-secret policy state: PIN format
/// validation, consecutive-failure counting, and temporary lockout — all
/// persisted locally so lockout survives process death. No PIN or derived
/// material is ever stored or logged here.
library;

// Private fields are exposed as public named constructor params, so
// initializing formals (this._x) are not usable by external callers here.
// ignore_for_file: prefer_initializing_formals

import '../../core/auth/lockout_policy.dart';
import '../../core/auth/pin_format_policy.dart';
import '../../repositories/key_value_store.dart';
import '../platform/platform_service.dart';

typedef ClockMs = int Function();

enum AuthStatus { success, failed, lockedOut, error }

class AuthResult {
  const AuthResult(
    this.status, {
    this.attemptsRemaining = 0,
    this.lockoutMs = 0,
  });

  final AuthStatus status;
  final int attemptsRemaining;
  final int lockoutMs;

  bool get isSuccess => status == AuthStatus.success;
}

enum PinSetStatus { ok, invalidFormat, error }

class PinSetResult {
  const PinSetResult(this.status, {this.reason});
  final PinSetStatus status;
  final PinRejectReason? reason;
  bool get isOk => status == PinSetStatus.ok;
}

class AuthenticationService {
  AuthenticationService({
    required PlatformService platform,
    required KeyValueStore store,
    this.pinPolicy = const PinFormatPolicy(),
    this.lockoutPolicy = const LockoutPolicy(),
    ClockMs? clock,
  }) : _platform = platform,
       _store = store,
       _clock = clock ?? (() => DateTime.now().millisecondsSinceEpoch);

  static const _kAttempts = 'auth_failed_attempts';
  static const _kLockedUntil = 'auth_locked_until_ms';

  final PlatformService _platform;
  final KeyValueStore _store;
  final PinFormatPolicy pinPolicy;
  final LockoutPolicy lockoutPolicy;
  final ClockMs _clock;

  Future<bool> hasPin() => _platform.authHasPin();

  Future<PinSetResult> setPin(String pin) async {
    final v = pinPolicy.validate(pin);
    if (!v.isValid) {
      return PinSetResult(PinSetStatus.invalidFormat, reason: v.reason);
    }
    try {
      final ok = await _platform.authSetPin(pin);
      if (!ok) return const PinSetResult(PinSetStatus.error);
      await _resetAttempts();
      return const PinSetResult(PinSetStatus.ok);
    } catch (_) {
      return const PinSetResult(PinSetStatus.error);
    }
  }

  Future<AuthResult> verifyPin(String pin) async {
    final now = _clock();
    final lockedUntil = await _readInt(_kLockedUntil);
    if (now < lockedUntil) {
      return AuthResult(AuthStatus.lockedOut, lockoutMs: lockedUntil - now);
    }
    bool matched;
    try {
      matched = await _platform.authVerifyPin(pin);
    } catch (_) {
      return const AuthResult(AuthStatus.error);
    }
    if (matched) {
      await _resetAttempts();
      return const AuthResult(AuthStatus.success);
    }
    final attempts = (await _readInt(_kAttempts)) + 1;
    await _writeInt(_kAttempts, attempts);
    final lockout = lockoutPolicy.lockoutFor(attempts);
    if (lockout > Duration.zero) {
      await _writeInt(_kLockedUntil, now + lockout.inMilliseconds);
      return AuthResult(
        AuthStatus.lockedOut,
        lockoutMs: lockout.inMilliseconds,
        attemptsRemaining: 0,
      );
    }
    return AuthResult(
      AuthStatus.failed,
      attemptsRemaining: lockoutPolicy.attemptsRemaining(attempts),
    );
  }

  Future<void> clearPin() async {
    try {
      await _platform.authClearPin();
    } finally {
      await _resetAttempts();
    }
  }

  /// Current lockout remaining in ms (0 if not locked out).
  Future<int> lockoutRemainingMs() async {
    final now = _clock();
    final until = await _readInt(_kLockedUntil);
    return until > now ? until - now : 0;
  }

  Future<void> _resetAttempts() async {
    await _writeInt(_kAttempts, 0);
    await _writeInt(_kLockedUntil, 0);
  }

  Future<int> _readInt(String key) async {
    final v = await _store.getString(key);
    return int.tryParse(v ?? '') ?? 0;
  }

  Future<void> _writeInt(String key, int value) =>
      _store.setString(key, '$value');
}
