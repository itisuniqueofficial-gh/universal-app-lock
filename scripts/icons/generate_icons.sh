#!/usr/bin/env bash
#
# generate_icons.sh — regenerate Android launcher/adaptive/round icons from the
# master icons/icon.png using the flutter_launcher_icons package.
#
# Intended to run inside GitHub Actions before an Android build. It requires the
# Flutter toolchain (provisioned by the runner) and the flutter_launcher_icons
# dev dependency (declared in pubspec.yaml). Do not run locally per project policy.
#
set -euo pipefail

if [[ ! -f "icons/icon.png" ]]; then
  echo "ERROR: master icon icons/icon.png not found" >&2
  exit 1
fi

echo "Fetching packages..."
flutter pub get

echo "Generating launcher icons from icons/icon.png..."
dart run flutter_launcher_icons

echo "OK: launcher icons generated."
