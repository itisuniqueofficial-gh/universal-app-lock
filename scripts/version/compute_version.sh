#!/usr/bin/env bash
#
# compute_version.sh — derive versionName and a monotonic versionCode from the
# authoritative VERSION file (semantic version MAJOR.MINOR.PATCH).
#
# Usage:
#   scripts/version/compute_version.sh [VERSION_FILE]
#
# Environment (optional):
#   CHANNEL       release | dev | nightly | rc   (default: release)
#   BUILD_NUMBER  integer build counter used for non-release channels (default: 0)
#
# Outputs (stdout, and GITHUB_OUTPUT when present):
#   version        raw semver (e.g. 1.0.0)
#   version_name   Android versionName (release: raw; else raw-<channel>.<build>)
#   version_code   Android versionCode (monotonic, derived from semver)
#
set -euo pipefail

VERSION_FILE="${1:-VERSION}"

if [[ ! -f "$VERSION_FILE" ]]; then
  echo "ERROR: VERSION file '$VERSION_FILE' not found" >&2
  exit 1
fi

RAW="$(tr -d ' \t\n\r' < "$VERSION_FILE")"

if [[ ! "$RAW" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
  echo "ERROR: VERSION '$RAW' is not a valid semantic version (MAJOR.MINOR.PATCH)" >&2
  exit 1
fi

MAJOR="${BASH_REMATCH[1]}"
MINOR="${BASH_REMATCH[2]}"
PATCH="${BASH_REMATCH[3]}"

# Guard against Play Store versionCode overflow (max 2,100,000,000).
if (( MINOR > 999 || PATCH > 999 )); then
  echo "ERROR: MINOR and PATCH must each be <= 999 for the versionCode scheme" >&2
  exit 1
fi

# Monotonic across semantic versions: 1.0.0 -> 1000000, 1.2.3 -> 1002003.
VERSION_CODE=$(( MAJOR * 1000000 + MINOR * 1000 + PATCH ))

CHANNEL="${CHANNEL:-release}"
BUILD_NUMBER="${BUILD_NUMBER:-0}"

if [[ "$CHANNEL" == "release" ]]; then
  VERSION_NAME="$RAW"
else
  VERSION_NAME="${RAW}-${CHANNEL}.${BUILD_NUMBER}"
fi

echo "version=$RAW"
echo "version_name=$VERSION_NAME"
echo "version_code=$VERSION_CODE"

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  {
    echo "version=$RAW"
    echo "version_name=$VERSION_NAME"
    echo "version_code=$VERSION_CODE"
  } >> "$GITHUB_OUTPUT"
fi
