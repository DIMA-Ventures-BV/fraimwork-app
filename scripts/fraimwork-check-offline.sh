#!/usr/bin/env bash
# Fails when the built app still holds upstream telemetry keys, update feeds or cloud endpoints.
# Usage: scripts/fraimwork-check-offline.sh path/to/fraimwork.app
set -euo pipefail

app="${1:?usage: $0 path/to/app}"
plist="$app/Contents/Info.plist"
test -f "$plist" || { echo "no Info.plist in $app" >&2; exit 2; }

forbidden='phc_opOVu7|ingest\.us\.sentry\.io|cmux\.com/api|manaflow-ai/cmux/releases'
fail=0

feed="$(/usr/libexec/PlistBuddy -c 'Print :SUFeedURL' "$plist" 2>/dev/null || true)"
if [ -n "$feed" ]; then
  echo "OFFLINE: Info.plist SUFeedURL=$feed"
  fail=1
fi

while IFS= read -r -d '' file; do
  if ! file -b "$file" | grep -q 'Mach-O'; then continue; fi
  while IFS= read -r hit; do
    echo "OFFLINE: ${file#"$app"/}: $hit"
    fail=1
  done < <(strings -a -n 8 "$file" | grep -oE "$forbidden" | sort -u || true)
done < <(find "$app/Contents" -type f \( -perm -u+x -o -name '*.dylib' \) -print0)

if [ "$fail" -ne 0 ]; then
  echo "FAIL: upstream services are still built in" >&2
  exit 1
fi
echo "OK: no upstream telemetry, update feed or cloud endpoints"
