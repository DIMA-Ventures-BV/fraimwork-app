#!/usr/bin/env python3
"""Rename what users see from cmux to fraimwork, in the checkout, before the build.

The fork keeps upstream sources unchanged so upstream merges stay cheap. CI runs
this script on a fresh checkout. It is safe to run twice. It writes nothing
unless every expected replacement in the Xcode project is found.

Usage: python3 scripts/fraimwork-rebrand.py [repo-root]
"""
import json
import pathlib
import re
import sys

BRAND = "fraimwork"
APP_ID = "com.cmuxterm.app.fraimwork"

# "cmux" as a word a user reads. Not paths (~/.config/cmux, cmux.json),
# identifiers (com.cmux.x, CMUX_SOCKET, cmux-dev) or URLs (cmux.com).
# ASCII word characters only, so "cmux를" and "cmuxの" are renamed too.
VISIBLE = re.compile(r"(?ia)(?<![\w./~-])cmux(?![\w/-])(?!\.\w)")

PROJECT_EDITS = [
    # (old, new, expected count)
    ("PRODUCT_BUNDLE_IDENTIFIER = com.cmuxterm.app;",
     f"PRODUCT_BUNDLE_IDENTIFIER = {APP_ID};", 1),
    ("PRODUCT_NAME = cmux;\n\t\t\t\tSPARKLE_PUBLIC_KEY",
     f"PRODUCT_MODULE_NAME = cmux;\n\t\t\t\tPRODUCT_NAME = {BRAND};\n\t\t\t\tSPARKLE_PUBLIC_KEY", 1),
    ("PRODUCT_BUNDLE_IDENTIFIER = com.cmuxterm.app.tunnel;",
     f"PRODUCT_BUNDLE_IDENTIFIER = {APP_ID}.tunnel;", 1),
    ("PRODUCT_BUNDLE_IDENTIFIER = com.cmuxterm.app.docktileplugin;",
     f"PRODUCT_BUNDLE_IDENTIFIER = {APP_ID}.docktileplugin;", 1),
    ('INFOPLIST_KEY_CFBundleDisplayName = "cmux Dock Tile Plugin";',
     f'INFOPLIST_KEY_CFBundleDisplayName = "{BRAND} Dock Tile Plugin";', 2),
    ("CMUX_AUTH_CALLBACK_SCHEME = cmux;",
     f"CMUX_AUTH_CALLBACK_SCHEME = {BRAND};", 1),
]

CATALOG_ROOTS = ["Resources", "TunnelExtension", "Packages/macOS", "Packages/Shared"]


def rename(text):
    return VISIBLE.sub(BRAND, text)


def rewrite_values(node):
    """Rewrite every localized "value" string below a localizations object."""
    changed = 0
    if isinstance(node, dict):
        for key, child in node.items():
            if key == "value" and isinstance(child, str):
                new = rename(child)
                if new != child:
                    node[key] = new
                    changed += 1
            else:
                changed += rewrite_values(child)
    elif isinstance(node, list):
        for child in node:
            changed += rewrite_values(child)
    return changed


def edit_project(root):
    path = root / "cmux.xcodeproj/project.pbxproj"
    text = path.read_text()
    if f"PRODUCT_NAME = {BRAND};" in text:
        return "project: already renamed"
    for old, new, count in PROJECT_EDITS:
        found = text.count(old)
        if found != count:
            sys.exit(f"project.pbxproj: expected {count} x {old!r}, found {found}")
        text = text.replace(old, new)
    path.write_text(text)
    return f"project: {len(PROJECT_EDITS)} settings"


def edit_info_plist(root):
    path = root / "Resources/Info.plist"
    lines = path.read_text().splitlines(keepends=True)
    changed = 0
    for i, line in enumerate(lines):
        if i > 0 and "UsageDescription</key>" in lines[i - 1] and "<string>" in line:
            new = rename(line)
            if new != line:
                lines[i] = new
                changed += 1
    path.write_text("".join(lines))
    return f"Info.plist: {changed} permission strings"


def edit_catalogs(root):
    files = 0
    values = 0
    for base in CATALOG_ROOTS:
        for path in sorted((root / base).rglob("*.xcstrings")):
            data = json.loads(path.read_text())
            changed = sum(
                rewrite_values(entry.get("localizations", {}))
                for entry in data.get("strings", {}).values()
            )
            if changed:
                path.write_text(json.dumps(data, ensure_ascii=False, indent=2, separators=(",", " : ")) + "\n")
                files += 1
                values += changed
    return f"catalogs: {values} strings in {files} files"


def main():
    root = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else ".").resolve()
    for report in (edit_project(root), edit_info_plist(root), edit_catalogs(root)):
        print(report)


if __name__ == "__main__":
    main()
