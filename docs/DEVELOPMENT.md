# Development — Universal App Lock

## Prerequisites
- **Flutter** stable (developed against Flutter 3.47.x / Dart 3.13.x).
- **Android SDK** with build-tools and platform-tools (`adb`). Build-tools 35.x used.
- **JDK 17** for the Gradle/Android build. This project's Gradle wrapper is 9.3.x.
  Ensure Flutter uses a JDK 17:
  ```bash
  flutter config --jdk-dir /usr/lib/jvm/java-17-openjdk-amd64
  ```

## Project layout
```
.
├── android/                # Android host + Kotlin platform layer
│   └── app/src/main/kotlin/com/itisuniqueofficial/ual/
│       ├── MainActivity.kt
│       ├── platform/       # PlatformBridge + interface stubs
│       ├── service/        # LockOverlayService (stub, not registered)
│       └── receiver/       # BootReceiver (stub, not registered)
├── lib/                    # Flutter/Dart app (see ARCHITECTURE.md)
├── test/                   # Flutter widget/unit tests
├── docs/                   # Project documentation
├── icons/icon.png          # Master launcher icon (source of truth)
└── pubspec.yaml
```

> Note: `original/`, `decoded/`, `jadx/`, `rebuilt/`, `signed/`, `keys/`, `logs/`,
> `backups/` are local-only forensic/build working directories and are **git-ignored**.
> They must never be committed.

## Common commands
```bash
flutter pub get              # resolve dependencies
flutter analyze              # static analysis (must be clean)
flutter test                 # run unit/widget tests
flutter build apk --debug    # build debug APK
flutter run                  # run on a connected device/emulator
```

## Verifying the built package
```bash
# Verify the applicationId of the built debug APK using aapt/aapt2:
AAPT=$(ls $ANDROID_HOME/build-tools/*/aapt2 | sort | tail -1)
"$AAPT" dump badging build/app/outputs/flutter-apk/app-debug.apk | grep package
```
Expected package name: `com.itisuniqueofficial.ual`.

## Platform bridge
- Method channel: `com.itisuniqueofficial.ual/platform`
- Event channel:  `com.itisuniqueofficial.ual/platform_events`
- Bridge version constant kept in sync between Dart (`PlatformChannels.bridgeVersion`)
  and Kotlin (`PlatformBridge.BRIDGE_VERSION`). Currently **v2**.
- Methods (v2): `getBridgeVersion`, `getAndroidSdk`, `getPlatformInfo`, `getAppVersion`,
  `getInstalledApplications`, `getApplicationIcon`, `isUsageAccessGranted`,
  `openUsageAccessSettings`, `isOverlayPermissionGranted`, `openOverlaySettings`,
  `getBiometricAvailability`. All access is via `PlatformService`. See `SECURITY.md`
  before adding methods.

## Android permissions & queries
- `PACKAGE_USAGE_STATS` (special permission, user-granted in Settings) is declared for
  future foreground detection; its state is detected via `AppOpsManager`.
- A `<queries>` entry for the `MAIN`/`LAUNCHER` intent lets the app enumerate launchable
  apps **without** the flagged `QUERY_ALL_PACKAGES` permission.
- No Samsung privileged permissions are present (CI enforces this).

## Notable dependencies
- `shared_preferences` — local key/value persistence (protected-apps policy, settings).
- `flutter_launcher_icons` (dev) — icon generation from `icons/icon.png` (CI).

## Conventions
- Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:` …) for future semantic versioning.
- Keep the project buildable after every major change.
- Never commit secrets, keystores, generated APK/AAB, or decompiled Samsung source.
- Keep security-sensitive logic in the native layer, not in Dart.

## Release automation (GitHub Actions)

All building, signing, and publishing happens on GitHub Actions — never locally.

### Workflows
| Workflow | Trigger | Purpose |
|---|---|---|
| `ci.yml` | pull requests | validation + format + analyze + test + Android debug compilation |
| `pull-request.yml` | pull requests | PR hygiene (conventional title, no binaries) |
| `every-commit-release.yml` | push to `main`, dispatch | full build → APK (universal + per-ABI) + AAB → verify → checksums → changelog → metadata → **prerelease** |
| `release.yml` | push tag `v*.*.*`, dispatch | **signed production** release (universal + per-ABI APKs, AAB, checksums, changelog, metadata) |
| `build.yml` | dispatch only | manual development/debug build artifact |
| `nightly.yml` | schedule, dispatch | nightly debug build artifact |
| `security.yml` | push `main`, PR, schedule | secret/permission/binary hardening checks |

### Versioning
`VERSION` (semver) is the authoritative base version and is **not** auto-edited per commit.
`scripts/version/compute_version.sh` derives, per channel:
- `release`: `versionName=X.Y.Z`, `versionCode=X*1000000+Y*1000+Z`, tag `vX.Y.Z`.
- `build` (every commit): `versionName=X.Y.Z-build.<run>`, `versionCode=<run>` (unique,
  monotonic), tag `build-vX.Y.Z-<run>`.

### Signing model
- **Production** (`release.yml`, `environment: production`): keystore is decoded from
  `ANDROID_KEYSTORE_BASE64` to a temp file, used for signing, then deleted. `build.gradle.kts`
  reads the keystore path/passwords from environment variables. Signatures are verified by
  `scripts/release/verify_signing.sh` and the release fails if unsigned.
- **Commit prereleases** (`every-commit-release.yml`): no production secrets are exposed;
  the release build falls back to the **debug/CI key** and artifacts are clearly marked as
  test prereleases.

### Required GitHub configuration
- **Environment** `production` with these **secrets**:
  `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`,
  `ANDROID_KEY_PASSWORD`.
- Recommended: keep signing secrets at the `production` **environment** scope (tighter than
  repo scope) and add required reviewers.

### Publishing a production release
```bash
# 1. Bump VERSION deliberately (e.g. 1.0.1) and commit.
# 2. Tag and push:
git tag v1.0.1
git push origin v1.0.1
# GitHub Actions builds, signs, verifies, and publishes the release.
```

### Troubleshooting
- **Release fails "does not match VERSION"**: the tag must equal the `VERSION` file.
- **Release fails "already exists"**: releases are never overwritten; use a new version.
- **Signing step fails**: confirm all four secrets exist in the `production` environment.
- **No per-ABI APKs**: uploaded only if the split build produced them; the universal APK and
  AAB are always produced.
