#!/usr/bin/env python3
"""Turn off upstream telemetry, update checks and cloud endpoints, in the checkout, before the build.

Upstream sources stay unchanged in git; CI runs this on a fresh checkout.
Keys and DSNs become empty strings (PostHog and Sentry then stay off).
cmux.com endpoints point at upstream.invalid, a name that never resolves (RFC 2606).
Release links point at this fork. Every rule must match, or nothing is written.

Usage: python3 scripts/fraimwork-offline.py [repo-root]
"""
import pathlib
import re
import sys

FORK_RELEASES = "https://github.com/DIMA-Ventures-BV/fraimwork-app/releases"
SOURCE_ROOTS = ["Sources", "CLI", "Packages/macOS", "Packages/Shared"]

SOURCE_RULES = [
    # (name, pattern, replacement)
    ("PostHog key", re.compile(r'"phc_[A-Za-z0-9]{20,}"'), '""'),
    ("Sentry DSN", re.compile(r'"https://[0-9a-f]+@o\d+\.ingest\.us\.sentry\.io/\d+"'), '""'),
    ("cmux.com", re.compile(r"https://cmux\.com(?=[/\"])"), "https://upstream.invalid"),
    ("release links", re.compile(r"https://github\.com/manaflow-ai/cmux/releases"), FORK_RELEASES),
]

FILE_EDITS = [
    # (path, old, new)
    ("Packages/macOS/CmuxSettings/Sources/CmuxSettings/Keys/AppCatalogSection.swift",
     'id: "app.sendAnonymousTelemetry",\n        defaultValue: true,',
     'id: "app.sendAnonymousTelemetry",\n        defaultValue: false,'),
    ("Resources/Info.plist",
     "\t<key>SUEnableAutomaticChecks</key>\n\t<true/>\n",
     "\t<key>SUEnableAutomaticChecks</key>\n\t<false/>\n"),
    ("Resources/Info.plist",
     "\t<key>SUFeedURL</key>\n\t<string>https://github.com/manaflow-ai/cmux/releases/latest/download/appcast.xml</string>\n",
     ""),
]


def source_files(root):
    for base in SOURCE_ROOTS:
        for path in sorted((root / base).rglob("*.swift")):
            if "/Tests/" not in str(path) and not path.name.endswith("Tests.swift"):
                yield path


def main():
    root = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else ".").resolve()
    pending = {}

    def text_of(path):
        if path not in pending:
            pending[path] = path.read_text()
        return pending[path]

    info = root / "Resources/Info.plist"
    if "SUFeedURL" not in info.read_text():
        print("already offline")
        return

    counts = {name: 0 for name, _, _ in SOURCE_RULES}
    for path in source_files(root):
        text = path.read_text()
        new = text
        for name, pattern, replacement in SOURCE_RULES:
            new, n = pattern.subn(replacement, new)
            counts[name] += n
        if new != text:
            pending[path] = new

    for rel, old, new in FILE_EDITS:
        path = root / rel
        text = text_of(path)
        if text.count(old) != 1:
            sys.exit(f"{rel}: expected 1 x {old!r}, found {text.count(old)}")
        pending[path] = text.replace(old, new)

    missing = [name for name, n in counts.items() if n == 0]
    if missing:
        sys.exit(f"no match for: {', '.join(missing)}")

    for path, text in pending.items():
        path.write_text(text)
    for name, n in counts.items():
        print(f"{name}: {n}")
    print(f"settings: {len(FILE_EDITS)} edits; files written: {len(pending)}")


if __name__ == "__main__":
    main()
