#!/usr/bin/env bash
#
# check_secure_impl.sh — heuristic guards for the security implementation:
#  1. No Device Admin usage.
#  2. No logging of sensitive material.
#  3. If PIN storage exists, it must use Keystore-backed EncryptedSharedPreferences.
#  4. AccessibilityService must not be used as the lock mechanism.
#
set -euo pipefail

fail=0

# 1. No Device Admin.
if grep -rInE "BIND_DEVICE_ADMIN|DeviceAdminReceiver|DevicePolicyManager" android/app/src 2>/dev/null; then
  echo "FAIL: Device Admin usage is not permitted"
  fail=1
fi

# 2. No secret logging (drop comment lines from the match).
if grep -rInE "(Log\.[dviwe]|println|System\.out\.print|[^a-zA-Z]print)[[:space:]]*\(.*(pin|password|passphrase|secret|keystore|credential)" android/app/src lib 2>/dev/null | grep -vE "^\s*//|^\s*\*|///" ; then
  echo "FAIL: potential logging of sensitive material detected above"
  fail=1
fi

# 3. If PIN storage is implemented, EncryptedSharedPreferences must be used.
if grep -rIlq "fun setPin" android/app/src 2>/dev/null; then
  if ! grep -rIlq "EncryptedSharedPreferences" android/app/src 2>/dev/null; then
    echo "FAIL: PIN storage present but EncryptedSharedPreferences (Keystore-backed) is not used"
    fail=1
  fi
fi

# 4. AccessibilityService must not be the lock mechanism.
if grep -rInE "BIND_ACCESSIBILITY_SERVICE|android\.accessibilityservice\.AccessibilityService" android/app/src 2>/dev/null; then
  echo "FAIL: AccessibilityService is not permitted as the lock mechanism"
  fail=1
fi

if [[ $fail -eq 0 ]]; then
  echo "OK: secure implementation checks passed"
else
  exit 1
fi
