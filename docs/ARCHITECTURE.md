# Architecture — Universal App Lock

> Status: **Phase 5 (scaffold).** This document describes the *intended* architecture.
> Implementation details are added incrementally in later phases. Where something is
> not yet implemented, it is labelled **PLANNED**.

Universal App Lock is an independent Flutter + native Kotlin Android application,
inspired by the documented UX/feature model of the discontinued Samsung S Secure app
(see `FORENSIC-ANALYSIS.md`). It is **not** a repair of the S Secure APK and shares no
runtime code with it.

## High-level layering

```
Flutter/Dart
    │
    ├── UI
    ├── Dashboard
    ├── Protected Apps            (PLANNED)
    ├── Settings
    ├── Authentication UI         (PLANNED)
    └── About/Credits
             │
             ▼
       Platform Bridge
    MethodChannel / EventChannel
             │
             ▼
       Kotlin Android
             │
    ┌────────┼─────────┐
    ▼        ▼         ▼
Monitor   Security   Storage       (all PLANNED — stubs only)
    │        │         │
    └────────┼─────────┘
             ▼
      Supported Android APIs
```

## Responsibilities

### Flutter / Dart (presentation & orchestration)
- App UI, navigation, dashboard, settings, protected-app selection UI,
  authentication *screens*, About/Credits, localization, accessibility.
- Orchestration of use-cases by calling the native layer through a single,
  versioned platform bridge.
- Dart does **not** implement any security-sensitive operation (see `SECURITY.md`).

Current Dart structure:

```
lib/
├── core/
│   ├── constants/   # AppInfo (branding/attribution)
│   ├── errors/      # PlatformBridgeException
│   ├── models/      # PlatformInfo, AppInfo, PermissionStatus/PermissionInfo, AppSettings
│   ├── utils/       # AppTheme (dark minimalist)
│   └── widgets/     # FlatCard
├── features/
│   ├── app_lock/    # DashboardScreen (real state)
│   ├── authentication/  # PLANNED (reference LockMethod enum only)
│   ├── apps/            # ProtectedAppsScreen, app_filter, widgets/AppIcon
│   ├── permissions/     # PermissionSetupScreen
│   ├── settings/    # SettingsScreen (minimal)
│   └── about/       # AboutScreen (credits/attribution)
├── repositories/    # KeyValueStore (abstraction) + ProtectedAppsRepository
├── services/
│   ├── platform/    # PlatformService (Dart facade over the bridge)
│   └── channels/    # PlatformChannels + PlatformMethods
└── main.dart
```

### Platform bridge (the boundary)
- **MethodChannel** `com.itisuniqueofficial.ual/platform` — request/response.
- **EventChannel** `com.itisuniqueofficial.ual/platform_events` — native → Dart stream.
- Versioned via `BRIDGE_VERSION` (Kotlin) / `PlatformChannels.bridgeVersion` (Dart). Currently **v2**.
- **Phase 6 surface:** diagnostics (`getBridgeVersion`, `getAndroidSdk`, `getPlatformInfo`,
  `getAppVersion`); discovery (`getInstalledApplications`, `getApplicationIcon`); permissions
  (`isUsageAccessGranted`, `openUsageAccessSettings`, `isOverlayPermissionGranted`,
  `openOverlaySettings`, `getBiometricAvailability`). No enforcement/monitoring/auth methods.
  Heavy calls (discovery, icons) run on a background thread and reply on the main thread.

### Kotlin Android (security-critical layer)
Package root `com.itisuniqueofficial.ual`:

| Component | Package | Status |
|---|---|---|
| `MainActivity` | `.` | Implemented (hosts Flutter + registers bridge) |
| `PlatformBridge` | `.platform` | Implemented (v2: diagnostics + discovery + permissions) |
| `ApplicationDiscoveryManager` | `.platform` | Implemented (launcher-query enumeration + icons) |
| `UsageAccessManager` | `.platform` | Implemented (detect + open settings) |
| `OverlayPermissionManager` | `.platform` | Implemented (detect + open settings) |
| `PlatformAdapter` | `.platform` | **PLANNED** — interface stub |
| `ApplicationMonitor` | `.platform` | **PLANNED** — interface stub |
| `AuthenticationManager` | `.platform` | **PLANNED** — interface stub |
| `StorageManager` | `.platform` | **PLANNED** — interface stub |
| `LockOverlayService` | `.service` | **PLANNED** — inert stub, not registered in manifest |
| `BootReceiver` | `.receiver` | **PLANNED** — inert stub, not registered in manifest |

## Intended future implementation (PLANNED, third-party-safe only)
- **ApplicationMonitor** → `UsageStatsManager` foreground detection (user grants Usage Access).
- **LockOverlayService** → foreground service + `SYSTEM_ALERT_WINDOW` (user-granted overlay).
- **AuthenticationManager** → `androidx.biometric.BiometricPrompt` + salted/hashed PIN.
- **StorageManager** → `EncryptedSharedPreferences` backed by the Android Keystore.
- **PlatformAdapter** → isolates OS/vendor differences; optional NON-privileged Samsung seam.

## Explicit non-goals / prohibitions
- No Samsung privileged permissions (`WRITE_SECURE_SETTINGS`, `INTERACT_ACROSS_USERS(_FULL)`,
  `MANAGE_USERS`, `CHANGE_COMPONENT_ENABLED_STATE`).
- No dependence on `com.samsung.android.applock` or Samsung system components.
- No security logic in Dart. No fake/placeholder "locking" behavior.
