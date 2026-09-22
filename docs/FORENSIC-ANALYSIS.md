# Universal App Lock — Phase 1 Forensic Analysis

**Subject APK:** `original/s_secure-v5.0.10.apk` (Samsung "S Secure")
**Analysis type:** Read-only (no modifications to the original APK)
**Date:** 2026-09-22
**Analyst:** Lead engineering (project: Universal App Lock)
**Tools used:** APKTool 3.0.3, JADX, `unzip`, `sha256sum`

> **Legal note:** This document analyzes a discontinued Samsung application for the purpose of building an
> independent, non-affiliated rebuild. Universal App Lock is **not affiliated with, sponsored by, or endorsed
> by Samsung Electronics.** Decompiled Samsung/third-party material referenced here (in `decoded/`, `jadx/`)
> must **not** be published to the public repository. Only original analysis and original new code should be committed.

---

## 0. Executive conclusion (read this first)

The single most important finding of this analysis:

> **S Secure is NOT a self-contained app locker. It is a thin, privileged Samsung *system* dashboard UI.**
> The actual app-lock enforcement (foreground-app detection, lock overlay, credential/biometric prompting)
> lives in a **separate Samsung system package** (`com.samsung.android.applock`) and the One UI framework —
> **none of that enforcement code is present in this APK.**

Consequences:

- There is **very little reusable functional logic** for app locking in this APK. What exists is glue: it
  toggles `Settings.Secure` flags, launches the system App Lock settings activity, fires Samsung framework
  intents, and reports analytics.
- The APK depends on **system/signature-level permissions** (`WRITE_SECURE_SETTINGS`, `INTERACT_ACROSS_USERS`,
  `MANAGE_USERS`, `CHANGE_COMPONENT_ENABLED_STATE`) that are **impossible for a third-party app to obtain** on a
  stock, non-rooted device — Samsung or otherwise.
- Therefore, "Universal App Lock" cannot be produced by patching this APK. The lock engine must be **built new**
  using supported, third-party-available Android APIs (UsageStats/foreground detection + overlay + BiometricPrompt +
  secure storage). This APK is valuable primarily as a **product/feature reference and UX spec**, not as a code base.

---

## 1. APK metadata & integrity

| Property | Value |
|---|---|
| File | `original/s_secure-v5.0.10.apk` |
| Size | 3.9 MB (4,014,518 bytes) |
| SHA-256 | `2e9440cb65716ba78f9384c8dc8aafa21c596142e8778d61e3d2c0dd9611f668` |
| Package | `com.samsung.android.app.sprotect` |
| App label | **S Secure** (`@string/app_name`) |
| versionName | `5.0.10` |
| versionCode | `501000100` |
| minSdkVersion | **28** (Android 9) |
| targetSdkVersion | **29** (Android 10) |
| compileSdkVersion | 28 (codename 9) |
| DEX | single `classes.dex` (~4.2 MB) |
| Native libraries | **None** (no `lib/`, no `.so`) |
| Build signature (meta) | `SProtect-500100-5.0.10`, env `3.0.1/L28.1.21/28.1.4` |
| Kotlin | Not present (pure Java + Samsung/Google libs) |

The APK decodes cleanly with APKTool and the resulting `decoded/` tree rebuilds successfully (see §11).

---

## 2. AndroidManifest.xml — component inventory

**Package:** `com.samsung.android.app.sprotect`
**Backup:** `allowBackup="false"` (good). **Cleartext:** `usesCleartextTraffic="true"` (legacy update-check endpoints, see §9).

### 2.1 Activities

| Activity | Role | Exported |
|---|---|---|
| `dashboard.DashBoard` | Launcher / main dashboard (`MAIN`/`LAUNCHER`, also `com.samsung.android.yuva_feature`) | implicit true (launcher) |
| `dashboard.SProtectSettingsActivity` | Settings screen | false |
| `dashboard.AboutSProtectActivity` | About + update check | false |
| `dashboard.OpenSourceLicenseActivity` | OSS licenses | false |
| `securewifi.SecureWifiPopupActivity` | Secure Wi-Fi enable popup (transparent) | **true** |
| `securewifi.EulaActivity` | Secure Wi-Fi EULA | **true** |
| `securewifi.SecureWifiDescriptionActivity` | Secure Wi-Fi description | **true** |
| `com.google.android.gms.common.api.GoogleApiActivity` | GMS internal | false |

### 2.2 Services

| Service | Role |
|---|---|
| `securewifi.SecureWifiService` | Core Secure Wi-Fi service; integrates Opera Max client |

### 2.3 Receivers

| Receiver | Role | Exported | Protection |
|---|---|---|---|
| `securewifi.SecureWifiReceiver` | Wi-Fi/connectivity/locale + Secure Wi-Fi enable/disable intents | true | `permission.LAUNCH_SPROTECT_COMPONENT` (signature) on the sprotect intent-filter |
| `analytics.AnalyticsReceiver` | Listens to `APP_LOCK_CHANGED` / `APP_HIDE_CHANGED` → logs analytics | **true** | **none** (see §10 security note) |

### 2.4 Providers

| Provider | Role |
|---|---|
| `android.arch.lifecycle.ProcessLifecycleOwnerInitializer` (authority `…lifecycle-trojan`) | AndroidX-era lifecycle bootstrap (auto-generated), `exported=false` |

### 2.5 Device Administrator

**None.** There is **no `DeviceAdminReceiver`, no `BIND_DEVICE_ADMIN`, no `device_admin.xml`, and no
`DevicePolicyManager` usage anywhere in the code.** S Secure does **not** use Device Admin to lock apps.

### 2.6 Declared permissions

Custom: `com.samsung.android.app.sprotect.permission.LAUNCH_SPROTECT_COMPONENT` (`signature`).

Requested (privileged/system in bold):

- `INTERNET`, `ACCESS_NETWORK_STATE`, `ACCESS_WIFI_STATE`, `CHANGE_WIFI_STATE`, `WAKE_LOCK`, `FOREGROUND_SERVICE`, `EXPAND_STATUS_BAR`, `SYSTEM_ALERT_WINDOW`
- **`WRITE_SETTINGS`**, **`WRITE_SECURE_SETTINGS`** — system/signature only
- **`INTERACT_ACROSS_USERS`**, **`INTERACT_ACROSS_USERS_FULL`**, **`MANAGE_USERS`** — system/signature only
- **`CHANGE_COMPONENT_ENABLED_STATE`** — system/signature only
- Samsung custom perms: `com.samsung.applock.permission.STATUSCHANGED`, `…STATUS_UPDATE`, `com.samsung.android.mfi.UPDATE_WIDGET`, `com.samsung.android.providers.context.permission.WRITE_USE_APP_FEATURE_SURVEY`, two `com.sec.spp.permission.TOKEN_…` push tokens

### 2.7 Required features (blocking installers)

- `com.samsung.android.api.version.2901` (**required=true**) — Samsung SDK/One UI API level gate; **prevents install on non-Samsung devices**
- `com.samsung.feature.samsung_experience_mobile`
- `<meta-data com.samsung.android.multiuser.install_only_owner=true>`

---

## 3. Application architecture (as built)

S Secure v5.0.10 is a **two-feature dashboard shell**:

```
S Secure (com.samsung.android.app.sprotect)   [Samsung SYSTEM app, system-signed]
│
├── Dashboard UI (dashboard.*)
│     • DashBoard: entry, observes secure-settings, shows App Lock + Secure Wi-Fi cards
│     • SettingsFragment / SProtectSettingsActivity / AboutSProtectActivity
│
├── Feature 1: APP LOCK  ──►  NOT IMPLEMENTED HERE
│     • Real engine = separate system app  com.samsung.android.applock
│     • S Secure only:
│         - Settings.Secure.putInt("app_lock_enabled", …)      (Utils.enableAppLock)
│         - Settings.Secure.getInt("applock_lock_type" / "app_lock_enabled")
│         - Settings.System.getInt("locked_app_count")
│         - launches com.samsung.android.applock.settings.AppLockSettingsActivity
│         - fires framework intents  com.samsung.android.intent.action.CHECK_APPLOCK_*
│           (PIN / PASSWORD / PATTERN / FINGERPRINT / FACE / IRISES / SPASS)  → One UI keyguard
│         - AnalyticsReceiver logs APP_LOCK_CHANGED / APP_HIDE_CHANGED
│
├── Feature 2: SECURE Wi-Fi  ──►  bundled Opera Max engine
│     • securewifi.SecureWifiService + SecureWifiReceiver + popups/EULA
│     • com.opera.max.* (34 classes) client; gated by SemFloatingFeature
│
└── Support: Utils/*, uihelper/SwitchBar, analytics (Samsung Analytics SDK)
```

### 3.1 App's own code (the only classes we authored/would own conceptually)

`com.samsung.android.app.sprotect` subpackages and notable classes:

- `dashboard/` — `DashBoard`, `SettingsFragment`, `SProtectSettingsActivity`, `AboutSProtectActivity` (+ `UpdateCheckTask`), `OpenSourceLicenseActivity`
- `securewifi/` — `SecureWifiService` (+ `OperaMaxListener`, `WifiBroadcastReceiver`, `SecureWifiBroadcastReceiver`, `SettingsObserver`), `SecureWifiReceiver`, `SecureWifiServiceHandler`, `SecureWifiPopupActivity`, `SecureWifiDescriptionActivity`, `EulaActivity`
- `analytics/` — `AnalyticsReceiver`
- `Utils/` — `Utils`, `Constants`, `AnalyticTracker`, `SaLogging`, `SecureWifiUtils`, `NotificationUtils`, `BadgeUtils`, `BadgePreference`, `UpdateCardPreference`
- `uihelper/` — `SwitchBar`

### 3.2 Storage / preferences / database

- **No SQLite database.** No `SQLiteOpenHelper`, no Room.
- **State lives in system `Settings.Secure`/`Settings.System`** (written via the privileged permissions), which is
  how S Secure and the system App Lock share state. This is exactly the mechanism unavailable to third-party apps.
- One `SharedPreferences` file: `SecureWIFISharedPref` (Secure Wi-Fi feature state only).

### 3.3 Authentication

- **No authentication is implemented in this app.** There is no `BiometricPrompt`, no `KeyguardManager`, no PIN/pattern
  verification code. `FingerprintManagerCompat` appears only inside the bundled `android.support.v4` library and is unused by app code.
- Authentication for App Lock is delegated entirely to the One UI framework via `CHECK_APPLOCK_*` broadcast intents
  (declared in `Constants`). The framework, not this app, renders the credential/biometric challenge.

### 3.4 Package / application monitoring

- **No foreground-app monitoring exists in this app.** No `UsageStatsManager`, no `AccessibilityService`, no
  running-tasks polling. Monitoring/enforcement is done by the external `com.samsung.android.applock` system component.
- The only PackageManager use is benign: `isPackageInstalled`, `isPackageEnabled`, `setApplicationEnabledSetting`, label lookup.

---

## 4. Component inventory summary

| Category | Present in this APK? | Notes |
|---|---|---|
| Dashboard / settings UI | ✅ | Reusable as **UX reference** only |
| App-lock enforcement | ❌ | External system app `com.samsung.android.applock` |
| Foreground monitoring | ❌ | Framework/system |
| Authentication (PIN/bio) | ❌ | Delegated to One UI via intents |
| Local DB | ❌ | Uses system Settings.Secure |
| SharedPreferences | ✅ (Secure Wi-Fi only) | `SecureWIFISharedPref` |
| Secure Wi-Fi (Opera Max) | ✅ | Not relevant to app-lock product goal |
| Analytics | ✅ | Samsung Analytics SDK (should be dropped) |
| Device Admin | ❌ | Not used |
| Native code | ❌ | — |

---

## 5. Dependency inventory (bundled in classes.dex)

| Dependency | Package root | Status for rebuild |
|---|---|---|
| Android Support Library v4/v7 (appcompat, recyclerview, preference, fragment, coreui/coreutils, graphics) | `android.support.*` | **Obsolete** — pre-AndroidX; replace with AndroidX (or moot: UI moves to Flutter) |
| Arch Components (lifecycle, core) | `android.arch.*` | **Obsolete** — pre-AndroidX Jetpack |
| Google Play Services / Firebase | `com.google.android.gms.*`, `com.google.firebase.*` | Optional; drop unless a concrete need |
| Opera Max client | `com.opera.max.*` (34 classes) | Samsung Secure Wi-Fi engine — **out of scope**, discard |
| Samsung Analytics SDK | `com.samsung.context.sdk.*` | Samsung-only — **discard** |
| Samsung Push (SPP) | `com.sec.spp.push.*` | Samsung-only — discard |
| Samsung DiagMonAgent | `com.sec.android.diagmonagent.*` | Samsung-only — discard |
| Samsung SemFloatingFeature | `com.samsung.android.feature.SemFloatingFeature` | Samsung-only framework class — **unavailable to third parties** |

No Kotlin runtime is bundled (app is Java).

---

## 6. Samsung-specific functionality & privilege dependencies

Every core capability of S Secure depends on Samsung system privileges or Samsung-only components:

1. **Secure-settings state sharing** — `WRITE_SECURE_SETTINGS` (system). Reads/writes `app_lock_enabled`,
   `applock_lock_type`, `locked_app_count`. *Third-party apps cannot write secure settings.*
2. **External App Lock engine** — `com.samsung.android.applock` (+ `AppLockSettingsActivity`). Not installable/available off Samsung.
3. **Framework auth intents** — `com.samsung.android.intent.action.CHECK_APPLOCK_{PINCODE,PASSWORD,PATTERN,FINGERPRINT,FACE,IRISES,…}` handled only by One UI keyguard.
4. **SemFloatingFeature** — Samsung `/system` feature flags (gates Secure Wi-Fi).
5. **Multi-user / component control** — `INTERACT_ACROSS_USERS(_FULL)`, `MANAGE_USERS`, `CHANGE_COMPONENT_ENABLED_STATE` (system).
6. **Install gate** — required feature `com.samsung.android.api.version.2901` blocks non-Samsung installs.
7. **Samsung services** — Analytics SDK, SPP push, DiagMonAgent, Galaxy Store update endpoints, MFI/Yuva feature hooks.

**Determination per dependency:**

| Samsung dependency | Classification | Action |
|---|---|---|
| `WRITE_SECURE_SETTINGS` state model | **unavailable to third parties** | Replace with app-local secure storage |
| `com.samsung.android.applock` engine | **unavailable / system** | Rebuild enforcement from scratch |
| `CHECK_APPLOCK_*` intents | **unavailable / system** | Replace with in-app `BiometricPrompt` + PIN |
| SemFloatingFeature | **unavailable / system** | Remove (feature detection via standard APIs) |
| Analytics/SPP/DiagMon | **optional / obsolete** | Remove |
| Opera Max Secure Wi-Fi | **out of scope** | Discard |
| Galaxy Store update check | **replaceable** | Replace with GitHub Releases update model |
| Yuva/MFI dashboard hooks | **Samsung-only** | Remove |

---

## 7. Obsolete / broken APIs (for a modern rebuild)

- **Pre-AndroidX** `android.support.*` and `android.arch.*` — deprecated; incompatible with modern Gradle/AndroidX toolchains.
- **targetSdk 29 (Android 10)** — below current Play requirements; modern target is 34/35.
- **`usesCleartextTraffic="true"`** with `http://` update endpoints — insecure and Samsung-specific; remove.
- **`versionCode`/`versionName`** encode Samsung's internal scheme; a new deterministic scheme is needed.
- **Analytics/push/diagmon SDKs** — tied to Samsung backends that no longer serve this app (discontinued).

---

## 8. Likely compatibility problems on non-Samsung devices

1. **Install blocked** by required feature `com.samsung.android.api.version.2901`.
2. **App Lock does nothing** — the external `com.samsung.android.applock` package and framework intent handlers are absent.
3. **Secure-settings writes throw `SecurityException`** — `WRITE_SECURE_SETTINGS` not grantable.
4. **Secure Wi-Fi inert** — SemFloatingFeature/Opera Max integration absent.
5. **Analytics/push/update** endpoints dead.

Net: even after re-signing, the APK is **non-functional** on any device where it is not system-signed with Samsung platform keys.

---

## 9. Hard-coded values

**URLs:**
- `http://vas.samsungapps.com/stub/stubUpdateCheck.as` (Galaxy Store update check)
- `http://cn-ms.snamsungapps.com/getCNVasURL.as` (China update routing)
- `https://play.google.com/store/apps/details` (store link)

**Package names referenced in code:**
- `com.samsung.android.applock` (+ `…applock.settings.AppLockSettingsActivity`) — the real app-lock engine
- `com.opera.max.oem`, `com.opera.max.global.extra.destination`
- `com.sec.android.app.samsungapps` (+ `.Main`) — Galaxy Store
- `com.android.settings`, `com.samsung.android.mfi`, `com.samsung.android.providers.context`
- `com.samsung.android.yuva_feature.*` (dashboard feature hooks)

**Secure-settings keys:** `app_lock_enabled`, `applock_lock_type`, `locked_app_count`, `app_lock_analytics`.

---

## 10. Security observations (of the original)

- `analytics.AnalyticsReceiver` is **exported with no permission** and reads a package-name extra from the incoming
  intent. In the Samsung environment the broadcasts are permission-guarded upstream, but as a pattern it is unsafe.
  The rebuild must **not** export lock/state receivers without a signature permission and intent validation.
- `usesCleartextTraffic="true"` + `http://` endpoints — the rebuild should be HTTPS-only with cleartext disabled.
- `allowBackup="false"` is correct and should be preserved for a security app.
- No secrets/keys are embedded in the APK (checked); `SEC-INF/` holds Samsung build-confirm cert only.

---

## 11. Build / rebuild feasibility (APKTool)

- `apktool d` (decode) → succeeded; produced `decoded/` (smali + resources + manifest).
- `apktool b decoded` (rebuild) → **succeeded** with APKTool 3.0.3 (aapt2), produced a ~3.9 MB APK.
- JADX decompilation → **succeeded**, 1,384 Java files in `jadx/` (analysis reference only).

**Feasibility verdict:** The decode→rebuild loop is mechanically sound (useful for controlled resource/smali edits and
for extracting the master icon and string/UX references). **However, a rebuilt APK will not *function*** off a Samsung
platform image for the reasons in §8. APK-level patching is therefore **not** a viable path to the product; it is only a
source of reference assets.

---

## 12. What can be retained vs replaced

### Retainable (as reference / assets, not as running code)
- **Product/feature definition & UX**: dashboard layout, settings structure, About screen pattern, lock-type taxonomy
  (PIN / password / pattern / fingerprint / face), "lock & hide apps" concept.
- **String resources & localization set** (large multi-language `values-*`) — useful reference for wording (rebrand required).
- **Launcher icon densities** — reference only; new master icon is `icons/icon.png` per project spec.
- **Lock-type/intent taxonomy** in `Constants` — informs our own auth options.

### Must be rebuilt (no reusable implementation exists)
- **The entire lock engine**: foreground-app detection, lock decision, lock overlay UI, unlock flow.
- **Authentication**: PIN storage/verification + `BiometricPrompt`.
- **Protected-apps repository + persistence** (app-local, encrypted).
- **Boot/lifecycle handling**, foreground service, permission onboarding (Usage Access, overlay, notifications).

### Discard
- Opera Max / Secure Wi-Fi, Samsung Analytics/SPP/DiagMon, SemFloatingFeature, Galaxy Store update, Yuva/MFI hooks,
  all system/signature permissions and the Samsung install-gate feature.

---

## 13. Risks

| Risk | Severity | Mitigation |
|---|---|---|
| Misconception that lock logic is reusable from this APK | High | This report: enforcement is external; plan to build new |
| Third-party foreground detection is less reliable than system App Lock | Medium | Use UsageStats (primary) + optional Accessibility (user-opt-in), document limits |
| Overlay/UsageAccess require manual user grants on modern Android | Medium | Guided onboarding; graceful degradation |
| Publishing decompiled Samsung code (legal/IP) | High | Keep `decoded/`,`jadx/`,`original/` **out of git**; commit only original code |
| Feature creep (Secure Wi-Fi, analytics) | Low | Explicitly out of scope |
| Android version fragmentation of lock behavior | Medium | Platform adapter layer + compatibility testing matrix |

---

## 14. Recommended migration plan

1. **Reframe the product**: build an **independent third-party app locker** using supported APIs; treat S Secure as a
   UX/feature reference, not a code source. (Corrects the initial "repair the APK" framing.)
2. **Architecture**: Flutter/Dart for UI (dashboard, protected-app picker, settings, auth screens, About/Credits,
   localization) + Kotlin for the security-critical engine, joined by a narrow MethodChannel/EventChannel.
   - Kotlin: `ApplicationMonitor` (UsageStats-based foreground detection), `LockOverlayService` (foreground service +
     `SYSTEM_ALERT_WINDOW`), `AuthenticationManager` (`BiometricPrompt` + PIN), `StorageManager`
     (EncryptedSharedPreferences / Android Keystore), `PlatformAdapter` with a `SamsungCompatAdapter` seam (optional,
     no privileged calls), `BootReceiver`.
   - Dart: `AppLockManager`, `ProtectedAppsRepository`, `LockStateManager`, `PolicyManager`, `SecurityManager` orchestration/UI.
3. **Permissions (third-party-safe only)**: `PACKAGE_USAGE_STATS` (via Settings), `SYSTEM_ALERT_WINDOW`,
   `FOREGROUND_SERVICE` (+ typed), `USE_BIOMETRIC`, `RECEIVE_BOOT_COMPLETED`, `POST_NOTIFICATIONS`, `QUERY_ALL_PACKAGES`
   (justified). **No** secure-settings/system/device-admin permissions. **No** Device Admin unless a concrete supported need appears.
4. **Package/brand migration** to `com.itisuniqueofficial.ual` done in the *new* project (not by patching smali).
5. **Icon pipeline**: master `icons/icon.png` (512×512) → automated launcher/adaptive/round generation script.
6. **CI/CD**: GitHub Actions — Flutter analyze/test, Android build, APK/AAB, signing from Secrets, SHA-256, semantic
   versioning (Conventional Commits), changelog, GitHub Releases. Never commit signing keys.
7. **Docs & attribution**: README + `docs/` (ARCHITECTURE, FEATURES, CHANGELOG, DEVELOPMENT, SECURITY, CREDITS) with the
   required "independent rebuild of discontinued Samsung S Secure / not affiliated with Samsung" disclosures.
8. **Testing**: unit (Dart + Kotlin), install/startup, auth, protected-app config, reboot, lifecycle, biometric (where
   hardware permits), across API 28→current.

---

## 15. Repository state at time of analysis

- Remote: `https://github.com/itisuniqueofficial-gh/universal-app-lock.git`, branch `main`.
- History: **1 commit** (`first commit`) containing only `README.md` (`# universal-app-lock`).
- No branches beyond `main`, no GitHub Actions workflows, no Flutter/Android project yet.
- Untracked working dirs: `decoded/`, `original/` (and analysis dirs `jadx/`, `rebuilt/`, `signed/`, `keys/`, `logs/`, `backups/`).
- **Action required before any commit:** add a `.gitignore` excluding `original/`, `decoded/`, `jadx/`, `rebuilt/`,
  `signed/`, `keys/`, `logs/`, `backups/` (proprietary/derived material + secrets) so no Samsung/decompiled content or
  keystores are ever pushed.

---

*End of Phase 1 forensic analysis. No modifications were made to the original APK. Implementation begins only after sign-off.*

---

## Appendix A — Phase 5 conclusion (project direction)

Based on the findings above, the project has moved from **"repair the S Secure APK"** to
**building an independent Flutter + native Kotlin application**, "Universal App Lock"
(`com.itisuniqueofficial.ual`), inspired by the documented S Secure UX/feature model.

Rationale (see §0, §6, §8): the original APK is a privileged Samsung *system* dashboard;
its app-lock enforcement lives in the separate privileged package
`com.samsung.android.applock` and the One UI framework, and it depends on
system/signature permissions unavailable to third-party apps. It therefore cannot be
patched into a functional universal locker.

Phase 5 delivered repository hygiene and a clean, buildable scaffold only. It does **not**
implement any app-lock engine, authentication, monitoring, overlay, boot handling, or any
Samsung privileged API. The original APK was not modified. Decompiled/decoded Samsung
material remains local-only and git-ignored (`original/`, `decoded/`, `jadx/`, `rebuilt/`).
See `ARCHITECTURE.md`, `FEATURES.md`, and `SECURITY.md`.
