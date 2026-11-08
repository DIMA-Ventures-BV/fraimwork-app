#!/usr/bin/env bash
# Tests scripts/fraimwork-cli-brand.swift with swiftc. Usage: scripts/fraimwork-cli-brand-test.sh
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

swiftc -parse-as-library -O "$here/fraimwork-cli-brand.swift" "$here/fraimwork-cli-brand-test.swift" -o "$work/cmux"
ln -s cmux "$work/fraimwork"

fail=0
check() {
  local name="$1" expected="$2" got="$3"
  if [ "$got" = "$expected" ]; then
    echo "ok   $name"
  else
    echo "FAIL $name"
    echo "  expected: $(printf '%q' "$expected")"
    echo "  got:      $(printf '%q' "$got")"
    fail=1
  fi
}

check "rename cases" "rename ok" "$("$work/cmux" rename)"

check "help as fraimwork" \
  "$(printf 'fraimwork - control fraimwork via Unix socket\nConfig: ~/.config/cmux/cmux.json\nafter: cmux')" \
  "$("$work/fraimwork" --help)"

check "help as fraimwork, exit() inside" \
  "$(printf 'fraimwork - control fraimwork via Unix socket\nConfig: ~/.config/cmux/cmux.json')" \
  "$("$work/fraimwork" help exit)"

check "help as cmux unchanged" \
  "$(printf 'cmux - control cmux via Unix socket\nConfig: ~/.config/cmux/cmux.json\nafter: cmux')" \
  "$("$work/cmux" --help)"

check "non-help as fraimwork unchanged" \
  "$(printf 'cmux - control cmux via Unix socket\nConfig: ~/.config/cmux/cmux.json\nafter: cmux')" \
  "$("$work/fraimwork" ping)"

exit "$fail"
