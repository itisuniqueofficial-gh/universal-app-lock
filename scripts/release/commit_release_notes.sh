#!/usr/bin/env bash
#
# commit_release_notes.sh — build the GitHub prerelease body for an every-commit
# build. Emits Markdown to stdout. Uses only real values passed via env.
#
# Env: BUILD_NUMBER, COMMIT, BRANCH, AUTHOR, VERSION_NAME, APP_ID_STATUS,
#      TEST_STATUS, SIGNING_STATUS, CHANGELOG_FILE
#
set -euo pipefail

short_commit="${COMMIT:0:7}"
changelog="_See commit history._"
if [[ -n "${CHANGELOG_FILE:-}" && -f "${CHANGELOG_FILE}" ]]; then
  changelog="$(cat "${CHANGELOG_FILE}")"
fi

cat <<EOF
# Universal App Lock

**Build:** ${BUILD_NUMBER:-?}
**Version:** ${VERSION_NAME:-?}
**Commit:** \`${short_commit}\`
**Branch:** ${BRANCH:-?}
**Author:** ${AUTHOR:-?}

> ⚠️ This is an automated **pre-release** build for testing. It is signed with a
> development/CI key (not the production key) and is **not** a stable release.
> App-lock enforcement is not implemented yet — see docs/FEATURES.md.

## Changes

${changelog}

## Artifacts

- Universal APK + per-ABI APKs (where generated)
- Android App Bundle (AAB)
- \`SHA256SUMS.txt\` checksums
- \`build-info.json\` build metadata

## Verification

- Application ID: ${APP_ID_STATUS:-verified (com.itisuniqueofficial.ual)}
- Tests: ${TEST_STATUS:-passed on CI}
- Signing: ${SIGNING_STATUS:-development/CI key}

## Compatibility

Independent third-party Android application. No Samsung privileged/system APIs;
does not require a Samsung device.
EOF
