#!/usr/bin/env bash
#
# verify_signing.sh — verify that a built APK or AAB carries a valid signature.
# APKs are checked with apksigner; AABs are JAR-signed and checked with jarsigner.
#
# Prints only the public signer certificate fingerprint (never private key
# material) and fails if the artifact is not signed. Does not use `set -x`.
#
# Usage: scripts/release/verify_signing.sh <artifact.apk|artifact.aab>
#
set -euo pipefail

ARTIFACT="${1:?usage: verify_signing.sh <artifact.apk|.aab>}"
if [[ ! -f "$ARTIFACT" ]]; then
  echo "FAIL: artifact '$ARTIFACT' not found" >&2
  exit 1
fi

SDK="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-}}"

case "$ARTIFACT" in
  *.apk)
    APKSIGNER="$(ls "$SDK"/build-tools/*/apksigner 2>/dev/null | sort -V | tail -1 || true)"
    if [[ -z "$APKSIGNER" || ! -x "$APKSIGNER" ]]; then
      echo "FAIL: apksigner not found under $SDK/build-tools" >&2
      exit 1
    fi
    if "$APKSIGNER" verify --print-certs "$ARTIFACT" > /tmp/_sig.txt 2>&1; then
      echo "OK: APK signature is valid — $ARTIFACT"
      grep -iE "certificate SHA-256 digest" /tmp/_sig.txt | head -1 || true
      rm -f /tmp/_sig.txt
    else
      echo "FAIL: APK is not signed or signature is invalid — $ARTIFACT" >&2
      cat /tmp/_sig.txt >&2 || true
      rm -f /tmp/_sig.txt
      exit 1
    fi
    ;;
  *.aab)
    if jarsigner -verify "$ARTIFACT" > /tmp/_sig.txt 2>&1; then
      # jarsigner exits 0 even for unsigned jars in some cases; require the
      # explicit "jar verified" marker.
      if grep -q "jar verified" /tmp/_sig.txt; then
        echo "OK: AAB is signed — $ARTIFACT"
        rm -f /tmp/_sig.txt
      else
        echo "FAIL: AAB does not appear to be signed — $ARTIFACT" >&2
        rm -f /tmp/_sig.txt
        exit 1
      fi
    else
      echo "FAIL: AAB signature verification failed — $ARTIFACT" >&2
      cat /tmp/_sig.txt >&2 || true
      rm -f /tmp/_sig.txt
      exit 1
    fi
    ;;
  *)
    echo "FAIL: unsupported artifact type — $ARTIFACT" >&2
    exit 1
    ;;
esac
