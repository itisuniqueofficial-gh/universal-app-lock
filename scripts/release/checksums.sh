#!/usr/bin/env bash
#
# checksums.sh — generate SHA256SUMS.txt for the given files, using basenames
# so the checksum file is portable.
#
# Usage: scripts/release/checksums.sh <output-file> <file> [file ...]
#
set -euo pipefail

OUT="${1:?usage: checksums.sh <output-file> <file> [file ...]}"
shift

: > "$OUT"
for f in "$@"; do
  if [[ ! -f "$f" ]]; then
    echo "ERROR: file '$f' not found" >&2
    exit 1
  fi
  dir="$(dirname "$f")"
  base="$(basename "$f")"
  ( cd "$dir" && sha256sum "$base" ) >> "$OUT"
done

echo "Wrote checksums to $OUT:"
cat "$OUT"
