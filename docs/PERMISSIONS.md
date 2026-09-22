# Permissions — Universal App Lock

Every permission maps to a concrete, implemented feature. Universal App Lock uses only
public, third-party-safe Android APIs — no Samsung private APIs or privileged permissions.

| Permission | Type | Used by | Why |
|---|---|---|---|
| `PACKAGE_USAGE_STATS` | special (Settings) | `ForegroundMonitorService` | Detect the current foreground app to decide whether to lock. Does **not** read app content. |
| `SYSTEM_ALERT_WINDOW` | special (Settings) | `ForegroundMonitorService` → `LockActivity` | Lets the lock screen appear above a protected app, and permits the background activity start that launches it. Does **not** read/capture other apps. |
| `FOREGROUND_SERVICE` + `FOREGROUND_SERVICE_SPECIAL_USE` | normal | `ForegroundMonitorService` | Keep the monitoring service alive (Android 14+ requires a typed foreground service). |
| `POST_NOTIFICATIONS` | runtime (13+) | `ForegroundMonitorService` | Show the ongoing "protection active" service notification Android requires. |
| `RECEIVE_BOOT_COMPLETED` | normal | `BootReceiver` | Restart monitoring after reboot **only if** the user enabled it. |

## Deliberately NOT used
- **Accessibility Service** — not declared. UsageStats is the supported primary foreground
  signal; Accessibility would only be an optional future provider for device gaps, minimum-scope.
- **Device Administrator** (`BIND_DEVICE_ADMIN`) — not declared. Not required for core app
  locking. (Optional uninstall-protection is a possible future opt-in, clearly explained.)
- **`QUERY_ALL_PACKAGES`** — avoided; launchable apps are enumerated via a `<queries>` entry.
- Samsung privileged permissions (`WRITE_SECURE_SETTINGS`, `INTERACT_ACROSS_USERS(_FULL)`,
  `MANAGE_USERS`, `CHANGE_COMPONENT_ENABLED_STATE`) — forbidden and CI-enforced.

## Honest limitations (Android reality)
App locking on stock Android is **best-effort**, not an unbreakable boundary:
- Foreground detection latency and reliability vary by Android version and OEM; the lock screen
  may briefly appear after the protected app.
- Aggressive OEM battery/background management (Xiaomi/Oppo/Vivo/OnePlus/Samsung/etc.) can kill
  the monitoring service; the user may need to exempt the app.
- Background activity start requires the overlay permission; without it, the lock screen cannot
  be launched from the background.
- ADB, Safe Mode, and factory reset can bypass/remove protection. We do not claim otherwise.

> These behaviors are implemented against documented APIs but have **not** been verified on a
> physical device in this project (builds run on GitHub Actions only).
