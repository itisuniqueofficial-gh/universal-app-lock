# Security — Universal App Lock

> Status: **Phase 5 (scaffold).** No security features are implemented yet. This
> document defines the security boundary and the rules future work must follow.
> Nothing here should be read as a claim that locking or authentication works today.

## Security boundary
```
Flutter/Dart  →  UI & orchestration only (NO security logic)
      │
      ▼   MethodChannel / EventChannel  (narrow, versioned)
      ▼
Kotlin Android  →  ALL security-sensitive operations
      │
      ▼
Supported Android APIs (third-party-safe only)
```

Flutter/Dart MUST NOT directly implement any of:
- foreground process detection
- overlay enforcement
- `DevicePolicyManager` logic
- boot handling
- Android Keystore operations
- `BiometricPrompt` integration
- security-sensitive authentication state

These belong exclusively to the native Android (Kotlin) layer.

## Privileged-API prohibition (hard rule)
Universal App Lock is a **normal third-party application**. It MUST NOT request,
retain, or depend on Samsung/system privileged capabilities, including:
- `WRITE_SECURE_SETTINGS`
- `INTERACT_ACROSS_USERS`, `INTERACT_ACROSS_USERS_FULL`
- `MANAGE_USERS`
- `CHANGE_COMPONENT_ENABLED_STATE`

It MUST NOT access `com.samsung.android.applock` as if it were available to a
third-party app, and MUST NOT rely on Samsung-only install requirements.
(The forensic analysis explains why the original S Secure could not be repaired
into a universal locker — see `FORENSIC-ANALYSIS.md`.)

## Current permission posture
The Phase 5 scaffold adds **no** runtime permissions beyond Flutter defaults.
There are **no** privileged permissions in the manifest. Future phases will add
only user-grantable, third-party-safe permissions (e.g. `PACKAGE_USAGE_STATS`
via Settings, `SYSTEM_ALERT_WINDOW`, `FOREGROUND_SERVICE`, `USE_BIOMETRIC`,
`RECEIVE_BOOT_COMPLETED`, `POST_NOTIFICATIONS`), each justified when introduced.

## Rules for future security implementation
- Never store plaintext credentials; PINs must be salted and hashed.
- Use the Android Keystore for sensitive cryptographic material.
- Never log authentication secrets or sensitive user data.
- Validate all incoming intents; do not export lock/state components without a
  signature-level permission and explicit intent validation.
- Keep `android:allowBackup="false"` for security-relevant data.
- HTTPS only; do not enable cleartext traffic.
- Do not use Accessibility Services as a shortcut when a supported API exists.
- Do not claim a security feature works until it has actually been tested.

## Bridge review policy
Every new platform-bridge method that touches security must be reviewed
individually, named explicitly, and documented in `ARCHITECTURE.md`. The bridge
is versioned (`BRIDGE_VERSION`) so incompatibilities can be detected.

## Reporting
Security issues should be reported privately to the developer/company via the
contact channels on the websites listed in `CREDITS.md`.
