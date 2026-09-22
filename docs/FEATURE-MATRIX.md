# Feature Matrix — Universal App Lock

Status legend: **Implemented** (code complete) · **CI-tested** (unit-tested in GitHub Actions) ·
**Compile-verified** (built by CI, not unit/device-tested) · **Planned** (not started).

> No feature is marked device-tested: this project is built entirely on GitHub Actions and
> has **not** been run on a physical device yet. Runtime behavior is therefore unverified.

| Feature | Status | Android API | Permission | Implementation | Test Coverage | Known Limitations |
|---|---|---|---|---|---|---|
| Application discovery (launchable) | Implemented + Compile-verified | PackageManager launcher query | `<queries>` (no QUERY_ALL_PACKAGES) | `ApplicationDiscoveryManager.kt` | Dart search/filter unit-tested | Launchable apps only; not device-tested |
| App icons | Implemented + Compile-verified | PackageManager | — | `ApplicationDiscoveryManager` + `AppIcon` | — | Not device-tested |
| Protected-app policy (local) | Implemented + CI-tested | — | — | `ProtectedAppsRepository` (Dart) | Repository unit tests | Kotlin `ProtectedAppPolicy` still Planned |
| Usage Access detection | Implemented + Compile-verified | `AppOpsManager` | `PACKAGE_USAGE_STATS` | `UsageAccessManager.kt` | — | Not device-tested |
| Overlay permission detection + visibility | Implemented + Compile-verified | `Settings.canDrawOverlays`, `ACTION_MANAGE_OVERLAY_PERMISSION` | `SYSTEM_ALERT_WINDOW` (declared) | `OverlayPermissionManager.kt` + manifest | health widget test | Not device-tested |
| Security & Permissions health screen | Implemented + CI-tested | — | — | `SecurityPermissionsScreen` + `permission_health` | health logic + widget tests | Not device-tested |
| Accessibility service | Excluded (documented) | — | — | Not declared (UsageStats is primary) | — | Add only if a device gap requires it |
| Device Administrator | Excluded (documented) | — | — | Not declared; not needed for core lock | — | — |
| PIN format policy | Implemented + CI-tested | — | — | `PinFormatPolicy` (Dart) | Unit tests | — |
| Failed-attempt lockout | Implemented + CI-tested | — | — | `LockoutPolicy` + `AuthenticationService` | Unit tests | Attempt state is non-secret (by design) |
| Auth session / relock timing | Implemented + CI-tested | — | — | `AuthSessionManager` (Dart) | Unit tests | Not yet wired to enforcement |
| Secure PIN storage | Implemented + Compile-verified | Keystore, `EncryptedSharedPreferences`, PBKDF2 | — | `SecureCredentialStore.kt` | — | Not device-tested; needs API 23+ |
| PIN auth (set/verify/clear) | Implemented + Compile-verified | — | — | `AuthenticationManager.kt` + bridge v3 | Dart service unit-tested with fake | Native path not device-tested |
| Biometric availability probe | Implemented + Compile-verified | `KeyguardManager`, PackageManager features | — | `AuthenticationManager.kt` | — | Informational only |
| BiometricPrompt auth | Planned | `androidx.biometric` | `USE_BIOMETRIC` | — | — | Next branch |
| Foreground monitoring | Planned | `UsageStatsManager.queryEvents` | `PACKAGE_USAGE_STATS` | — | — | Android detection limits apply |
| Lock enforcement service | Planned | Foreground service | `FOREGROUND_SERVICE`, `POST_NOTIFICATIONS` | — | — | — |
| Lock screen (LockActivity) | Planned | Activity / overlay | `SYSTEM_ALERT_WINDOW` (if overlay) | — | — | — |
| Relock: screen-off / app-exit / timeout | Partially (logic) | lifecycle | — | `AuthSessionManager` logic only | Session unit tests | Not wired to OS events yet |
| Boot recovery | Planned | `BOOT_COMPLETED` | `RECEIVE_BOOT_COMPLETED` | `BootReceiver` stub | — | — |
| Package install/remove/update handling | Planned | `PACKAGE_*` broadcasts | — | — | — | — |
| Self-lock prevention | Implemented (discovery excludes self) | — | — | `ApplicationDiscoveryManager` skips own package | — | — |
