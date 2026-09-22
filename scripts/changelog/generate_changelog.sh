#!/usr/bin/env bash
#
# generate_changelog.sh — build a categorized changelog from Conventional
# Commits between the previous tag and a target ref. Emits Markdown to stdout
# (and to a file if given). Only real Git history is used; nothing is fabricated.
#
# Usage: scripts/changelog/generate_changelog.sh [--out FILE] [--range A..B]
#
set -euo pipefail

OUT=""
RANGE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --out) OUT="$2"; shift 2 ;;
    --range) RANGE="$2"; shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

if [[ -z "$RANGE" ]]; then
  last_tag="$(git describe --tags --abbrev=0 2>/dev/null || true)"
  if [[ -n "$last_tag" ]]; then RANGE="${last_tag}..HEAD"; else RANGE=""; fi
fi

# Collect "type|scope|breaking|subject" lines.
mapfile -t LINES < <(git log ${RANGE} --no-merges --pretty=format:'%s' 2>/dev/null || true)

declare -A BUCKETS=(
  [feat]="" [fix]="" [security]="" [perf]="" [refactor]="" [docs]="" [cicd]="" [other]=""
)
BREAKING=""

for subj in "${LINES[@]}"; do
  [[ -z "$subj" ]] && continue
  # Parse: type(scope)!: description
  if [[ "$subj" =~ ^([a-zA-Z]+)(\([^\)]*\))?(!)?:\ (.*)$ ]]; then
    type="$(tr '[:upper:]' '[:lower:]' <<< "${BASH_REMATCH[1]}")"
    bang="${BASH_REMATCH[3]}"
    desc="${BASH_REMATCH[4]}"
  else
    type="other"; bang=""; desc="$subj"
  fi
  entry="- ${desc}"
  case "$type" in
    feat) BUCKETS[feat]+="$entry"$'\n' ;;
    fix) BUCKETS[fix]+="$entry"$'\n' ;;
    security) BUCKETS[security]+="$entry"$'\n' ;;
    perf) BUCKETS[perf]+="$entry"$'\n' ;;
    refactor) BUCKETS[refactor]+="$entry"$'\n' ;;
    docs) BUCKETS[docs]+="$entry"$'\n' ;;
    ci|build) BUCKETS[cicd]+="$entry"$'\n' ;;
    *) BUCKETS[other]+="$entry"$'\n' ;;
  esac
  [[ -n "$bang" ]] && BREAKING+="$entry"$'\n'
done

emit() {
  local title="$1" body="$2"
  [[ -n "$body" ]] && printf '### %s\n\n%s\n' "$title" "$body"
}

render() {
  local any=0
  [[ -n "$BREAKING" ]] && { emit "⚠ Breaking Changes" "$BREAKING"; any=1; }
  [[ -n "${BUCKETS[feat]}" ]] && { emit "Features" "${BUCKETS[feat]}"; any=1; }
  [[ -n "${BUCKETS[fix]}" ]] && { emit "Bug Fixes" "${BUCKETS[fix]}"; any=1; }
  [[ -n "${BUCKETS[security]}" ]] && { emit "Security" "${BUCKETS[security]}"; any=1; }
  [[ -n "${BUCKETS[perf]}" ]] && { emit "Performance" "${BUCKETS[perf]}"; any=1; }
  [[ -n "${BUCKETS[refactor]}" ]] && { emit "Refactoring" "${BUCKETS[refactor]}"; any=1; }
  [[ -n "${BUCKETS[docs]}" ]] && { emit "Documentation" "${BUCKETS[docs]}"; any=1; }
  [[ -n "${BUCKETS[cicd]}" ]] && { emit "CI/CD" "${BUCKETS[cicd]}"; any=1; }
  [[ -n "${BUCKETS[other]}" ]] && { emit "Other" "${BUCKETS[other]}"; any=1; }
  [[ $any -eq 0 ]] && printf '_No categorized changes found in range %s._\n' "${RANGE:-<all history>}"
}

if [[ -n "$OUT" ]]; then
  render > "$OUT"
  echo "Changelog written to $OUT" >&2
else
  render
fi
