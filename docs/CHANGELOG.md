# Changelog

All notable changes to Universal App Lock are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/) and this
project adheres to [Semantic Versioning](https://semver.org/). Release sections
are generated from Conventional Commits by CI (`scripts/changelog/`).

## [Unreleased]

### Features
- Android application discovery (launchable apps) with real icons, search, and
  user/system/all filtering.
- Protected-app policy storage (local) via `ProtectedAppsRepository`.
- Permission onboarding: Usage Access and overlay detection + open-settings, with
  resume-based refresh; informational biometric availability.
- Dashboard now shows real state (protection not set up, protected count, permissions to grant).
- Platform bridge v2 (discovery + permission methods) with background execution.

### CI/CD
- GitHub-first CI/CD foundation: CI, pull-request, build, release, nightly, and
  security workflows; versioning, changelog, icon, and validation scripts.

### Documentation
- Added architecture, features, security, development, credits, and forensic
  analysis documentation.

_App-lock enforcement, authentication, monitoring, overlay, and boot recovery are not
implemented yet (Phase 7+). See docs/FEATURES.md._
