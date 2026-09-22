#!/usr/bin/env bash
#
# verify_apk.sh — assert that a built APK declares the expected package name.
# Uses aapt2 from the Android SDK build-tools. Intended to run inside CI.
#
# Usage: scripts/validation/verify_apk.sh <path-to-apk> [expected-package]
#
set -euo pipefail

APK="${1:?usage: verify_apk.sh <apk> [expected-package]}"
EXPECTED="${2:-com.itisuniqueofficial.ual}"

if [[ ! -f "$APK" ]]; then
  echo "FAIL: APK '$APK' not found" >&2
  exit 1
fi

SDK="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-}}"
if [[ -z "$SDK" ]]; then
  echo "FAIL: ANDROID_SDK_ROOT/ANDROID_HOME not set" >&2
  exit 1
fi

AAPT2="$(ls "$SDK"/build-tools/*/aapt2 2>/dev/null | sort -V | tail -1 || true)"
if [[ -z "$AAPT2" || ! -x "$AAPT2" ]]; then
  echo "FAIL: aapt2 not found under $SDK/build-tools" >&2
  exit 1
fi

BADGING="$("$AAPT2" dump badging "$APK")"
PKG="$(sed -n "s/^package: name='\([^']*\)'.*/\1/p" <<< "$BADGING" | head -1)"

echo "APK: $APK"
echo "Declared package: $PKG"

if [[ "$PKG" != "$EXPECTED" ]]; then
  echo "FAIL: APK package '$PKG' does not match expected '$EXPECTED'" >&2
  exit 1
fi

echo "OK: APK package verified as '$EXPECTED'"
