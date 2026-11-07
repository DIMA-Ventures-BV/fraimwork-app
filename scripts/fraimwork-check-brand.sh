#!/usr/bin/env bash
# Fails when text a user can see in the built app still says "cmux".
# Usage: scripts/fraimwork-check-brand.sh path/to/fraimwork.app
# Paths, file names and identifiers (~/.config/cmux, cmux.json, com.cmux.*) are allowed.
set -euo pipefail

app="${1:?usage: $0 path/to/app}"
plist="$app/Contents/Info.plist"
test -f "$plist" || { echo "no Info.plist in $app" >&2; exit 2; }

# Same rule as scripts/fraimwork-rebrand.py VISIBLE.
visible() { perl -ne 'print if /(?<![\w.\/~-])cmux(?![\w\/-])(?!\.\w)/i'; }
fail=0

report() {
  echo "BRAND: $1: $2"
  fail=1
}

name="$(basename "$app" .app)"
if printf '%s\n' "$name" | grep -qi cmux; then report "bundle" "$name.app"; fi

for key in CFBundleName CFBundleDisplayName; do
  value="$(/usr/libexec/PlistBuddy -c "Print :$key" "$plist" 2>/dev/null || true)"
  if [ -n "$(printf '%s\n' "$value" | visible)" ]; then report "Info.plist $key" "$value"; fi
done

while IFS= read -r line; do
  report "Info.plist" "$line"
done < <(plutil -convert json -o - "$plist" \
  | jq -r 'to_entries[] | select(.key | test("UsageDescription$")) | "\(.key)=\(.value)"' \
  | visible)

while IFS= read -r -d '' strings; do
  while IFS= read -r line; do
    report "${strings#"$app"/}" "$line"
  done < <(plutil -convert json -o - "$strings" 2>/dev/null \
    | jq -r '.. | strings' \
    | visible)
done < <(find "$app/Contents" \( -name '*.strings' -o -name '*.stringsdict' \) -print0)

if [ "$fail" -ne 0 ]; then
  echo "FAIL: user-visible text still says cmux" >&2
  exit 1
fi
echo "OK: no user-visible cmux text"
