#!/usr/bin/env bash
#
# compute_version.sh — derive version identity from the authoritative VERSION
# file (semantic MAJOR.MINOR.PATCH) plus a channel and build number.
#
# Usage:
#   scripts/version/compute_version.sh [VERSION_FILE]
#
# Environment (optional):
#   CHANNEL       release | build | dev | nightly   (default: release)
#   BUILD_NUMBER  unique build counter for non-release channels (e.g. github.run_number)
#
# Outputs (stdout as KEY=VALUE, and appended to GITHUB_OUTPUT when present):
#   version        raw semver (e.g. 1.0.0)
#   version_name   Android versionName
#   version_code   Android versionCode (integer)
#   release_tag    Git tag / release tag
#   release_name   Human-readable release title
#
# Versioning model:
#   release  -> versionName=X.Y.Z         versionCode=X*1000000+Y*1000+Z
#               tag=vX.Y.Z                name="Universal App Lock vX.Y.Z"
#   build    -> versionName=X.Y.Z-build.N versionCode=N (unique, monotonic run number)
#               tag=build-vX.Y.Z-N        name="Universal App Lock X.Y.Z Build N"
#   dev/nightly behave like build with their own channel prefix.
#
set -euo pipefail

VERSION_FILE="${1:-VERSION}"
CHANNEL="${CHANNEL:-release}"
BUILD_NUMBER="${BUILD_NUMBER:-0}"
APP="Universal App Lock"

if [[ ! -f "$VERSION_FILE" ]]; then
  echo "ERROR: VERSION file '$VERSION_FILE' not found" >&2
  exit 1
fi

RAW="$(tr -d ' \t\n\r' < "$VERSION_FILE")"
if [[ ! "$RAW" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
  echo "ERROR: VERSION '$RAW' is not valid semantic version (MAJOR.MINOR.PATCH)" >&2
  exit 1
fi
MAJOR="${BASH_REMATCH[1]}"; MINOR="${BASH_REMATCH[2]}"; PATCH="${BASH_REMATCH[3]}"
if (( MINOR > 999 || PATCH > 999 )); then
  echo "ERROR: MINOR and PATCH must each be <= 999 for the versionCode scheme" >&2
  exit 1
fi
SEMVER_CODE=$(( MAJOR * 1000000 + MINOR * 1000 + PATCH ))

case "$CHANNEL" in
  release)
    VERSION_NAME="$RAW"
    VERSION_CODE="$SEMVER_CODE"
    RELEASE_TAG="v$RAW"
    RELEASE_NAME="$APP v$RAW"
    ;;
  build|dev|nightly)
    if (( BUILD_NUMBER < 1 )); then
      echo "ERROR: BUILD_NUMBER must be >= 1 for channel '$CHANNEL'" >&2
      exit 1
    fi
    VERSION_NAME="${RAW}-${CHANNEL}.${BUILD_NUMBER}"
    # For pre-release channels the versionCode is the unique, monotonic run
    # number. These artifacts are not published to Play; production uses the
    # semver-based code above.
    VERSION_CODE="$BUILD_NUMBER"
    RELEASE_TAG="${CHANNEL}-v${RAW}-${BUILD_NUMBER}"
    case "$CHANNEL" in
      build) LABEL="Build" ;;
      dev) LABEL="Dev" ;;
      nightly) LABEL="Nightly" ;;
    esac
    RELEASE_NAME="$APP $RAW $LABEL $BUILD_NUMBER"
    ;;
  *)
    echo "ERROR: unknown CHANNEL '$CHANNEL'" >&2
    exit 1
    ;;
esac

echo "version=$RAW"
echo "version_name=$VERSION_NAME"
echo "version_code=$VERSION_CODE"
echo "release_tag=$RELEASE_TAG"
echo "release_name=$RELEASE_NAME"

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  {
    echo "version=$RAW"
    echo "version_name=$VERSION_NAME"
    echo "version_code=$VERSION_CODE"
    echo "release_tag=$RELEASE_TAG"
    echo "release_name=$RELEASE_NAME"
  } >> "$GITHUB_OUTPUT"
fi
