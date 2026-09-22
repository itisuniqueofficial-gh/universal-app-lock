# Releases — Universal App Lock

The authoritative, always-current release history lives on the GitHub Releases page:

- **All releases:** https://github.com/itisuniqueofficial-gh/universal-app-lock/releases
- **Latest stable:** https://github.com/itisuniqueofficial-gh/universal-app-lock/releases/latest

> This file documents the release **model** and asset naming. It is intentionally
> not auto-committed on every build (that would create a CI commit loop); the live
> Releases page above is the source of truth for the per-build history.

## Release channels

| Channel | Trigger | Tag format | Prerelease? | Signing |
|---|---|---|---|---|
| **Commit build** | every push to `main` (and manual dispatch) | `build-v<X.Y.Z>-<run>` | ✅ yes (`make_latest=false`) | development/CI key (debug) |
| **Production** | pushing a `v<X.Y.Z>` tag (or manual dispatch) | `v<X.Y.Z>` | ❌ no (`make_latest=true`) | production key (GitHub Secrets) |

Every commit build has a **unique** tag and version (`versionName = X.Y.Z-build.<run>`,
`versionCode = <run>`), so builds never collide. Production releases use
`versionName = X.Y.Z` and `versionCode = X*1000000 + Y*1000 + Z`.

## Asset naming

Commit build (`<N>` = run number):

```
Universal-App-Lock-v1.0.0-build-<N>-universal.apk
Universal-App-Lock-v1.0.0-build-<N>-arm64-v8a.apk      (when generated)
Universal-App-Lock-v1.0.0-build-<N>-armeabi-v7a.apk    (when generated)
Universal-App-Lock-v1.0.0-build-<N>-x86_64.apk         (when generated)
Universal-App-Lock-v1.0.0-build-<N>.aab
SHA256SUMS.txt
CHANGELOG.md
build-info.json
```

Production:

```
Universal-App-Lock-v1.0.0-universal.apk
Universal-App-Lock-v1.0.0-arm64-v8a.apk                (when generated)
Universal-App-Lock-v1.0.0-armeabi-v7a.apk              (when generated)
Universal-App-Lock-v1.0.0-x86_64.apk                   (when generated)
Universal-App-Lock-v1.0.0.aab
SHA256SUMS.txt
CHANGELOG.md
build-info.json
```

## Verification

Each release includes `SHA256SUMS.txt`. Verify a download with:

```bash
sha256sum -c SHA256SUMS.txt
```

`build-info.json` records the exact commit, versions, and toolchain used for the build.
