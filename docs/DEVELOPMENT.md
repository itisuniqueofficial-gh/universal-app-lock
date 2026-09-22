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
