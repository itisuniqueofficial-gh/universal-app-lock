#!/usr/bin/env bash
#
# make_release_notes.sh — assemble the GitHub Release body for a version, using
# the auto-generated changelog plus fixed sections (compatibility, install,
# verification, credits). Emits Markdown to stdout (or --out FILE).
#
# Usage: scripts/release/make_release_notes.sh <version> [--changelog FILE] [--out FILE]
#
set -euo pipefail

VERSION="${1:?usage: make_release_notes.sh <version> [--changelog FILE] [--out FILE]}"
shift || true

CHANGELOG_FILE=""
OUT=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --changelog) CHANGELOG_FILE="$2"; shift 2 ;;
    --out) OUT="$2"; shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

if [[ -n "$CHANGELOG_FILE" && -f "$CHANGELOG_FILE" ]]; then
  CHANGES="$(cat "$CHANGELOG_FILE")"
else
  CHANGES="_See commit history._"
fi

render() {
cat <<EOF
# Universal App Lock v${VERSION}

## What's New

${CHANGES}

## Compatibility

- Android (minSdk defined by the Flutter toolchain; see docs/DEVELOPMENT.md).
- Universal App Lock is an independent third-party application. It does not use
  Samsung privileged/system APIs and does not require a Samsung device.

## Installation

- Download \`Universal-App-Lock-v${VERSION}.apk\` and install it on your device.
- The Android App Bundle \`Universal-App-Lock-v${VERSION}.aab\` is provided for
  store distribution.

## Verification

- Verify downloads against \`SHA256SUMS.txt\` included with this release:
  \`sha256sum -c SHA256SUMS.txt\`

## Credits

Developed by **Jaydatt Khodave** — **IT IS UNIQUE OFFICIAL**.

Universal App Lock is an independent rebuild and modification inspired by the
discontinued Samsung S Secure application. It is **not affiliated with, sponsored
by, or endorsed by Samsung Electronics.**
EOF
}

if [[ -n "$OUT" ]]; then
  render > "$OUT"
  echo "Release notes written to $OUT" >&2
else
  render
fi
