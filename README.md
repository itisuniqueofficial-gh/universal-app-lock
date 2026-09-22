# Universal App Lock

[![CI](https://github.com/itisuniqueofficial-gh/universal-app-lock/actions/workflows/ci.yml/badge.svg)](https://github.com/itisuniqueofficial-gh/universal-app-lock/actions/workflows/ci.yml)
[![Security](https://github.com/itisuniqueofficial-gh/universal-app-lock/actions/workflows/security.yml/badge.svg)](https://github.com/itisuniqueofficial-gh/universal-app-lock/actions/workflows/security.yml)
[![Release](https://img.shields.io/github/v/release/itisuniqueofficial-gh/universal-app-lock?sort=semver)](https://github.com/itisuniqueofficial-gh/universal-app-lock/releases)
[![Flutter](https://img.shields.io/badge/Flutter-stable-02569B?logo=flutter)](https://flutter.dev)
[![License](https://img.shields.io/badge/license-Proprietary-red)](LICENSE)

**Universal App Lock** is an independent app locker for Android, built with Flutter and
native Kotlin. It is an independent rebuild and modification **inspired by** the
discontinued Samsung **S Secure** application.

> **Not affiliated with Samsung.** Universal App Lock is **not affiliated with, sponsored
> by, or endorsed by Samsung Electronics.** Samsung and S Secure are trademarks of their
> respective owners. This is **not** an official Samsung product.

- **App ID:** `com.itisuniqueofficial.ual`
- **Website:** https://ual.itisuniqueofficial.com/
- **Developer:** Jaydatt Khodave — https://jaydatt.pages.dev/
- **Company:** IT IS UNIQUE OFFICIAL — https://www.itisuniqueofficial.com/

---

## ⚠️ Project status: Phase 5 — scaffold only

**App locking does not work yet.** This repository currently contains a clean, buildable
Flutter + Kotlin **scaffold**. The following are intentionally **not implemented** and are
planned for later phases:

- foreground-app monitoring
- lock overlay enforcement
- PIN / biometric authentication
- protected-app selection & secure storage
- boot handling
- release automation (APK/AAB/signing)

See [`docs/FEATURES.md`](docs/FEATURES.md) for the implemented-vs-planned matrix.

## Why not just repair Samsung S Secure?

A full read-only forensic analysis of Samsung S Secure v5.0.10 (see
[`docs/FORENSIC-ANALYSIS.md`](docs/FORENSIC-ANALYSIS.md)) found that S Secure is a
privileged Samsung **system dashboard**, not a self-contained app locker:

- The actual app-lock enforcement lives in a **separate privileged system package**,
  `com.samsung.android.applock`, plus the One UI framework.
- S Secure depends on **system/signature permissions** (`WRITE_SECURE_SETTINGS`,
  `INTERACT_ACROSS_USERS`, `MANAGE_USERS`, `CHANGE_COMPONENT_ENABLED_STATE`) that a
  third-party app cannot obtain, and on a Samsung-only install gate.

Therefore the APK **cannot** be patched into a functional universal locker. Universal App
Lock is instead a fresh Flutter + Kotlin implementation that uses only third-party-safe
Android APIs, informed by the S Secure UX/feature model.

## Technology

- **Flutter / Dart** — UI, navigation, dashboard, settings, About/Credits, orchestration.
- **Kotlin / Android** — the security-critical platform layer (monitoring, overlay,
  authentication, storage, boot) — **planned**, currently interface stubs.
- **Platform channels** — a single, versioned MethodChannel/EventChannel bridge between
  Dart and Kotlin. See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

Security-sensitive logic stays native; Dart never implements it. See
[`docs/SECURITY.md`](docs/SECURITY.md).

## Repository structure

```
android/            Android host + Kotlin platform layer (stubs)
lib/                Flutter/Dart application
  core/             constants, errors, models, utils
  features/         app_lock (dashboard), authentication, apps, settings, about
  services/         platform bridge (PlatformService) + channel constants
test/               widget/unit tests
docs/               ARCHITECTURE, FEATURES, SECURITY, DEVELOPMENT, CREDITS, FORENSIC-ANALYSIS
icons/icon.png      master launcher icon (source of truth)
```

Local-only working directories (`original/`, `decoded/`, `jadx/`, `rebuilt/`, `signed/`,
`keys/`, `logs/`, `backups/`) hold the proprietary APK and forensic/build artifacts and are
**git-ignored** — they are never committed.

## Development requirements

- Flutter stable (developed on 3.47.x / Dart 3.13.x)
- Android SDK (build-tools 35.x, platform-tools/`adb`)
- JDK 17 for the Gradle build (`flutter config --jdk-dir /usr/lib/jvm/java-17-openjdk-amd64`)

See [`docs/DEVELOPMENT.md`](docs/DEVELOPMENT.md) for details.

## Build & run

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
# install on a connected device:
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

## Credits & attribution

Developed by **Jaydatt Khodave** — **IT IS UNIQUE OFFICIAL**. Full attribution in
[`docs/CREDITS.md`](docs/CREDITS.md).

Universal App Lock is an independent rebuild and modification inspired by the discontinued
Samsung S Secure application. It is not affiliated with, sponsored by, or endorsed by
Samsung Electronics.
