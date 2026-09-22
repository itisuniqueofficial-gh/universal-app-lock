#!/usr/bin/env bash
#
# check_branding.sh — verify Universal App Lock branding and reject accidental
# use of the original Samsung package as this application's own identity.
# (Samsung attribution in docs/About is allowed and NOT checked here.)
#
set -euo pipefail

MANIFEST="android/app/src/main/AndroidManifest.xml"
FORBIDDEN_ID="com.samsung.android.app.sprotect"
fail=0

if ! grep -q 'android:label="Universal App Lock"' "$MANIFEST"; then
  echo "FAIL: application label 'Universal App Lock' not found in $MANIFEST"
  fail=1
fi

# The original Samsung package must never appear as our app's package in code
# or Android configuration (docs/ are intentionally excluded from this scan).
if grep -rIq "$FORBIDDEN_ID" android lib 2>/dev/null; then
  echo "FAIL: forbidden Samsung package '$FORBIDDEN_ID' referenced in android/ or lib/"
  fail=1
fi

if [[ $fail -eq 0 ]]; then
  echo "OK: branding verified (Universal App Lock; no Samsung package as app identity)"
else
  exit 1
fi
