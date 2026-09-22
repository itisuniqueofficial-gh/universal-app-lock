#!/usr/bin/env bash
#
# check_no_samsung.sh — forbid Samsung proprietary package references and
# Samsung/system privileged permissions in application code (docs excluded).
#
set -euo pipefail

if grep -rInE "com\.samsung|android\.permission\.(WRITE_SECURE_SETTINGS|INTERACT_ACROSS_USERS(_FULL)?|MANAGE_USERS|CHANGE_COMPONENT_ENABLED_STATE)" android/app/src lib 2>/dev/null; then
  echo "FAIL: Samsung proprietary reference or privileged permission found in application code"
  exit 1
fi

echo "OK: no Samsung proprietary references or privileged permissions in application code"
