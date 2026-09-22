# Features — Universal App Lock

> Status legend: ✅ implemented · 🧱 scaffold/stub only · 🕒 planned (not started)
>
> This file is maintained conservatively. A feature is only marked ✅ when it has
> been implemented **and** verified. App-lock functionality is **not** implemented yet.

## Current phase: 5 — Repository hygiene & Flutter/Kotlin scaffold

### Implemented in this phase
| Feature | Status | Notes |
|---|---|---|
| Flutter Android app scaffold | ✅ | `com.itisuniqueofficial.ual`, label "Universal App Lock" |
| Branding & attribution | ✅ | Centralized in `AppInfo`; shown on About screen |
| About / Credits screen | ✅ | Includes required Samsung non-affiliation notice |
| Dashboard (home) screen | ✅ | Branding + status + diagnostics; performs no locking |
| Minimal Settings screen | ✅ | Navigation only; no functional toggles |
| Platform bridge (diagnostics) | ✅ | `getBridgeVersion`, `getAndroidSdk`, `getPlatformInfo`, `getAppVersion` + a "ready" event |
| Kotlin platform layer | 🧱 | Interfaces/stubs only; no security behavior |
| Documentation set | ✅ | ARCHITECTURE, FEATURES, CREDITS, DEVELOPMENT, SECURITY, FORENSIC-ANALYSIS |

### Deliberately NOT implemented yet
| Feature | Status | Target phase |
|---|---|---|
| Foreground-app monitoring | 🕒 | Phase 6+ (UsageStats) |
| Lock overlay enforcement | 🕒 | Phase 6+ (foreground service + overlay) |
| PIN authentication | 🕒 | Phase 6+ |
| Biometric authentication | 🕒 | Phase 6+ (BiometricPrompt) |
| Protected-apps selection & storage | 🕒 | Phase 6+ (PackageManager + encrypted storage) |
| Boot handling | 🕒 | Phase 6+ |
| Secure storage (Keystore) | 🕒 | Phase 6+ |
| Icon generation pipeline | 🕒 | later phase (`icons/icon.png` is the master) |
| Release automation (APK/AAB/signing) | 🕒 | Phase 12 |

## Out of scope (from S Secure, intentionally dropped)
- Secure Wi-Fi (Opera Max engine), Samsung Analytics/Push/DiagMon, SemFloatingFeature,
  Galaxy Store update flow, and all Samsung privileged/system behavior.
  Rationale in `FORENSIC-ANALYSIS.md`.
