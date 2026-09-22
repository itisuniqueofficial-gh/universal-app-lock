#!/usr/bin/env bash
#
# check_no_binaries.sh — fail if build artifacts, keystores, or private key
# material are tracked in Git. Uses the Git index (not the working tree) so it
# reflects what is actually committed.
#
set -euo pipefail

# Patterns that must never be committed.
PATTERNS='(\.apk$|\.aab$|\.idsig$|\.jks$|\.keystore$|\.p12$|\.pem$|\.der$|(^|/)key\.properties$)'

tracked="$(git ls-files || true)"

offenders="$(printf '%s\n' "$tracked" | grep -Ei "$PATTERNS" || true)"

# Scan tracked text files for obvious private-key headers.
key_hits=""
if [[ -n "$tracked" ]]; then
  key_hits="$(git grep -I -l -E 'BEGIN (RSA |EC |OPENSSH |DSA )?PRIVATE KEY' -- . 2>/dev/null || true)"
fi

fail=0
if [[ -n "$offenders" ]]; then
  echo "FAIL: forbidden binary/secret files are tracked in Git:"
  printf '  - %s\n' $offenders
  fail=1
fi
if [[ -n "$key_hits" ]]; then
  echo "FAIL: private key material found in tracked files:"
  printf '  - %s\n' $key_hits
  fail=1
fi

if [[ $fail -eq 0 ]]; then
  echo "OK: no APK/AAB/keystore/private-key files are tracked"
else
  exit 1
fi
