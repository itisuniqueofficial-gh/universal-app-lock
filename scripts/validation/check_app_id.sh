#!/usr/bin/env bash
#
# check_app_id.sh — verify the application ID / namespace / Kotlin package are
# exactly com.itisuniqueofficial.ual across the Android configuration.
#
set -euo pipefail

EXPECTED="com.itisuniqueofficial.ual"
GRADLE="android/app/build.gradle.kts"
fail=0

if [[ ! -f "$GRADLE" ]]; then
  echo "FAIL: $GRADLE not found" >&2
  exit 1
fi

grep -q "applicationId = \"$EXPECTED\"" "$GRADLE" \
  || { echo "FAIL: applicationId is not '$EXPECTED' in $GRADLE"; fail=1; }

grep -q "namespace = \"$EXPECTED\"" "$GRADLE" \
  || { echo "FAIL: namespace is not '$EXPECTED' in $GRADLE"; fail=1; }

if [[ ! -d "android/app/src/main/kotlin/com/itisuniqueofficial/ual" ]]; then
  echo "FAIL: Kotlin package directory com/itisuniqueofficial/ual is missing"
  fail=1
fi

if [[ $fail -eq 0 ]]; then
  echo "OK: application ID, namespace and Kotlin package verified as '$EXPECTED'"
else
  exit 1
fi
