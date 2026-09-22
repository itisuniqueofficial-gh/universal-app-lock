#!/usr/bin/env bash
#
# build_info.sh — emit build-info.json describing the build, using ACTUAL values
# from the CI environment (tool versions are detected at runtime, never hardcoded).
#
# Required env: OUT, BASE_VERSION, VERSION_NAME, VERSION_CODE, COMMIT, BRANCH,
#               RUN_NUMBER, WORKFLOW, SIGNED, BUILD_STATUS
#
set -euo pipefail

OUT="${OUT:?OUT (output path) is required}"

# Detect tool versions from the runner (best-effort; empty if unavailable).
flutter_version=""
dart_version=""
if command -v flutter >/dev/null 2>&1; then
  machine="$(flutter --version --machine 2>/dev/null || echo '{}')"
  flutter_version="$(printf '%s' "$machine" | (jq -r '.frameworkVersion // empty' 2>/dev/null || true))"
  dart_version="$(printf '%s' "$machine" | (jq -r '.dartSdkVersion // empty' 2>/dev/null || true))"
fi
java_version="$(java -version 2>&1 | head -1 | sed -E 's/.*version "([^"]+)".*/\1/' || true)"

agp_version="$(grep -Eo 'com.android.application[^0-9]*[0-9]+\.[0-9]+\.[0-9]+' android/settings.gradle.kts 2>/dev/null | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || true)"

build_date="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# JSON-escape helper.
esc() { printf '%s' "${1:-}" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'; }

signed_bool="${SIGNED:-false}"
case "$signed_bool" in true|false) ;; *) signed_bool=false ;; esac

cat > "$OUT" <<EOF
{
  "appName": "Universal App Lock",
  "packageName": "com.itisuniqueofficial.ual",
  "baseVersion": $(esc "${BASE_VERSION:-}"),
  "versionName": $(esc "${VERSION_NAME:-}"),
  "versionCode": ${VERSION_CODE:-0},
  "commit": $(esc "${COMMIT:-}"),
  "branch": $(esc "${BRANCH:-}"),
  "runNumber": ${RUN_NUMBER:-0},
  "workflow": $(esc "${WORKFLOW:-}"),
  "buildDate": $(esc "$build_date"),
  "flutterVersion": $(esc "$flutter_version"),
  "dartVersion": $(esc "$dart_version"),
  "javaVersion": $(esc "$java_version"),
  "androidGradlePlugin": $(esc "$agp_version"),
  "signed": ${signed_bool},
  "buildStatus": $(esc "${BUILD_STATUS:-success}")
}
EOF

echo "Wrote $OUT:"
cat "$OUT"
