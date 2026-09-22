# Changelog

All notable changes to Universal App Lock are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/) and this
project adheres to [Semantic Versioning](https://semver.org/). Release sections
are generated from Conventional Commits by CI (`scripts/changelog/`).

## [Unreleased]

### Fixed
- Overlay permission was not visible on the system "Display over other apps" screen
  (no toggle). Root cause: `SYSTEM_ALERT_WINDOW` was not declared. Now declared so the app
  is listable and grantable; state read via `Settings.canDrawOverlays` and re-checked on resume.

### Features
- Security & Permissions health screen: real per-permission status (PIN, Usage Access,
  Display over other apps, biometric availability) with accurate explanations, "Open
  Settings"/"Re-check", and an overall health state (READY/LIMITED/ACTION REQUIRED/NOT
  CONFIGURED). Documented decisions to exclude Accessibility and Device Administrator.
- Secure PIN authentication foundation: Keystore-backed `EncryptedSharedPreferences` + PBKDF2
  hashing (`SecureCredentialStore`), `AuthenticationManager`, platform bridge v3
  (`authHasPin/authSetPin/authVerifyPin/authClearPin`); Dart `PinFormatPolicy`, `LockoutPolicy`,
  `AuthSessionManager`, `AuthenticationService` (unit-tested). New CI security checks
  (`check_no_samsung.sh`, `check_secure_impl.sh`). minSdk raised to 23.
- Android application discovery (launchable apps) with real icons, search, and
  user/system/all filtering.
- Protected-app policy storage (local) via `ProtectedAppsRepository`.
- Permission onboarding: Usage Access and overlay detection + open-settings, with
  resume-based refresh; informational biometric availability.
- Dashboard now shows real state (protection not set up, protected count, permissions to grant).
- Platform bridge v2 (discovery + permission methods) with background execution.

### CI/CD
- Every-commit release pipeline: each push to `main` builds APK (universal + per-ABI) and
  AAB, verifies package ID and signatures, generates checksums, changelog, and build
  metadata, and publishes a unique GitHub **prerelease** (`build-v<version>-<run>`).
- Production `release.yml` enhanced: signed universal + per-ABI APKs and AAB, signing
  verification, `build-info.json`, and full release assets on `v*.*.*` tags.
- Added `verify_signing.sh`, `build_info.sh`, `commit_release_notes.sh`; extended
  `compute_version.sh` (RELEASE_TAG/RELEASE_NAME per channel). CI scoped to PRs; `build.yml`
  made dispatch-only to avoid redundant main builds.
- GitHub-first CI/CD foundation: CI, pull-request, build, release, nightly, and
  security workflows; versioning, changelog, icon, and validation scripts.

### Documentation
- Added architecture, features, security, development, credits, and forensic
  analysis documentation.

_App-lock enforcement, authentication, monitoring, overlay, and boot recovery are not
implemented yet (Phase 7+). See docs/FEATURES.md._
