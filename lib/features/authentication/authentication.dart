/// Authentication feature (PLANNED — not implemented in this phase).
///
/// This file only documents the intended future surface. No authentication is
/// performed here. All security-sensitive verification (PIN hashing,
/// BiometricPrompt, Keystore) will live in the native Kotlin
/// `AuthenticationManager`, invoked through the platform bridge — never in Dart.
///
/// See docs/SECURITY.md and docs/ARCHITECTURE.md.
library;

/// Candidate unlock methods, derived from the S Secure feature model
/// (documented in docs/FORENSIC-ANALYSIS.md). Reference only; selecting one has
/// no effect yet.
enum LockMethod {
  pin,
  password,
  pattern,
  biometric,
}
