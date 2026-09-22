/// Explicit state machines for the lock engine, replacing scattered booleans.
library;

/// Foreground-monitoring availability/state.
enum MonitoringState {
  unavailable,
  permissionRequired,
  starting,
  active,
  error,
}

/// Authentication flow state.
enum AuthenticationState {
  idle,
  biometricAvailable,
  authenticating,
  authenticated,
  failed,
  lockedOut,
}

/// Overall protection/enforcement state.
enum ProtectionState { disabled, ready, locking, locked, unlocked, error }
