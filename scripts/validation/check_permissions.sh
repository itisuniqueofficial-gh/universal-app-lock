#!/usr/bin/env bash
#
# check_permissions.sh — fail if any forbidden Samsung/system privileged
# permission (or dependence on the Samsung system app-lock package) appears in
# the Android sources. See docs/SECURITY.md and docs/FORENSIC-ANALYSIS.md.
#
set -euo pipefail

FORBIDDEN_PERMS=(
  "WRITE_SECURE_SETTINGS"
  "INTERACT_ACROSS_USERS_FULL"
  "INTERACT_ACROSS_USERS"
  "MANAGE_USERS"
  "CHANGE_COMPONENT_ENABLED_STATE"
)
FORBIDDEN_PKG="com.samsung.android.applock"

found=0

while IFS= read -r -d '' manifest; do
  for perm in "${FORBIDDEN_PERMS[@]}"; do
    if grep -Eq "android\.permission\.${perm}\b" "$manifest"; then
      echo "FAIL: forbidden privileged permission '$perm' found in $manifest"
      found=1
    fi
  done
done < <(find android -name AndroidManifest.xml -print0 2>/dev/null)

# The Samsung system app-lock package must not be used as a runtime dependency.
if grep -rIq "$FORBIDDEN_PKG" android/app/src 2>/dev/null; then
  echo "FAIL: reference to Samsung system package '$FORBIDDEN_PKG' in android/app/src"
  found=1
fi

if [[ $found -eq 0 ]]; then
  echo "OK: no forbidden privileged permissions or Samsung system dependencies"
else
  exit 1
fi
