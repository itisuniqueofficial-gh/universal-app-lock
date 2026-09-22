/// Authentication session model + manager.
///
/// Tracks temporary "unlocked" state per protected package so the lock engine
/// can decide whether re-authentication is required. Pure logic (clock is
/// injectable) so it is fully unit-testable. Holds no secrets.
library;

/// A temporary unlock for a single package.
class AuthSession {
  const AuthSession({
    required this.packageName,
    required this.grantedAtMs,
    required this.timeout,
  });

  final String packageName;
  final int grantedAtMs;

  /// Session lifetime. [Duration.zero] means "lock immediately" (never valid
  /// after the moment it is granted).
  final Duration timeout;

  bool isValidAt(int nowMs) {
    if (timeout == Duration.zero) return false;
    return (nowMs - grantedAtMs) < timeout.inMilliseconds;
  }
}

typedef ClockMs = int Function();

/// Manages active unlock sessions. Not a secret store.
class AuthSessionManager {
  AuthSessionManager({ClockMs? clock})
    : _clock = clock ?? (() => DateTime.now().millisecondsSinceEpoch);

  final ClockMs _clock;
  final Map<String, AuthSession> _sessions = {};

  /// Grant a temporary unlock for [packageName].
  void grant(String packageName, Duration timeout) {
    _sessions[packageName] = AuthSession(
      packageName: packageName,
      grantedAtMs: _clock(),
      timeout: timeout,
    );
  }

  /// Whether [packageName] currently has a valid (unexpired) session.
  bool isUnlocked(String packageName) {
    final s = _sessions[packageName];
    if (s == null) return false;
    if (!s.isValidAt(_clock())) {
      _sessions.remove(packageName);
      return false;
    }
    return true;
  }

  /// Invalidate a single package's session (e.g. on app exit relock).
  void invalidate(String packageName) => _sessions.remove(packageName);

  /// Invalidate all sessions (e.g. on screen-off relock or reboot).
  void invalidateAll() => _sessions.clear();

  int get activeCount => _sessions.length;
}
