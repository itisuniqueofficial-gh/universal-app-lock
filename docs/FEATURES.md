# Features — Universal App Lock

> Status legend: ✅ implemented & verified on CI · 🧱 scaffold/stub only · 🕒 planned (not started)
>
> This file is conservative: a feature is only ✅ when implemented **and** verified by
> GitHub Actions. App-lock **enforcement** is not implemented yet.

## Current phase: 6 — Application discovery & permission onboarding

### Implemented
| Feature | Status | Notes |
|---|---|---|
| Android application discovery | ✅ | Launchable apps via PackageManager launcher query (no QUERY_ALL_PACKAGES) |
| Application search | ✅ | Case-insensitive; matches name + package; filters a cached list (no per-keystroke PM queries) |
| User / System / All filtering | ✅ | Uses `FLAG_SYSTEM`/`FLAG_UPDATED_SYSTEM_APP`, not hard-coded package names |
| Real application icons | ✅ | Fetched lazily as PNG over the bridge, cached in-memory, graceful fallback |
| Protected-app policy storage | ✅ | Local only; `ProtectedAppsRepository` over a storage abstraction |
| Usage Access detection | ✅ | `AppOpsManager` op check |
| Open Usage Access settings | ✅ | With package-scoped + fallback intents |
| Overlay permission detection | ✅ | `Settings.canDrawOverlays` |
| Open overlay settings | ✅ | With fallback intents |
| Biometric availability (info only) | ✅ | Capability probe; no authentication performed |
| Permission onboarding screen | ✅ | Real status; opens settings; refreshes on resume |
| Permission onboarding screen | ✅ | Security & Permissions screen: real status, explanations, open-settings, re-check, overall health |
| Overlay permission visibility | ✅ | `SYSTEM_ALERT_WINDOW` declared so the app is listable/grantable; detected via `canDrawOverlays` |
| Dashboard real state | ✅ | Protection "Not set up"; protected count; permissions-to-grant count |
| Permission state model | ✅ | `PermissionStatus` enum (granted/denied/unavailable/notRequired/unknown) |
| Central settings model | 🧱 | `AppSettings` foundation persisted locally; no user-editable toggles yet |
| Platform bridge v3 | ✅ | Single channel; discovery + permission + PIN auth methods; background execution |
| Secure PIN storage (Keystore) | 🧱 | `SecureCredentialStore` (PBKDF2 + EncryptedSharedPreferences); compile-verified, not device-tested |
| PIN policy + lockout + auth session | ✅ | Dart `PinFormatPolicy`, `LockoutPolicy`, `AuthSessionManager`, `AuthenticationService` (unit-tested) |
| PIN setup / change / remove UI | ✅ | Sharp `PinEntryScreen` keypad + `PinFlows` wired to Keystore-backed backend; remove requires verification (widget-tested) |
| Sharp zero-corner design system | ✅ | `AppTheme` 0dp buttons/inputs/cards/dialogs; `FlatCard` squared |

### Selecting an app for protection
Adding an app only records it in the **local protection policy**. It does **not** lock or
intercept the app. Enforcement arrives in a later phase.

### NOT yet implemented
| Feature | Status | Target |
|---|---|---|
| Foreground monitoring | 🕒 | Phase 7 |
| App-lock enforcement | 🕒 | Phase 7 |
| Lock overlay UI | 🕒 | Phase 7 |
| PIN authentication | 🕒 | Phase 7 |
| Biometric authentication | 🕒 | Phase 7 |
| Lock session / re-lock | 🕒 | Phase 7 |
| Boot recovery | 🕒 | Phase 7+ |
| Release automation to production | 🕒 | needs signing secrets (Phase 12) |

## Out of scope (from S Secure, intentionally dropped)
Secure Wi-Fi (Opera Max), Samsung Analytics/Push/DiagMon, SemFloatingFeature, Galaxy Store
update flow, and all Samsung privileged/system behavior. Rationale in `FORENSIC-ANALYSIS.md`.
