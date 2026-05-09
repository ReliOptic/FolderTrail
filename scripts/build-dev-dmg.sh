#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT_DIR/app/macos/FolderTrail"
BUILD_DIR="$ROOT_DIR/build/dev-dmg"
APP_BUNDLE="$BUILD_DIR/FolderTrail.app"
EXECUTABLE="$APP_BUNDLE/Contents/MacOS/FolderTrail"
OUTPUT_DMG="${1:-$HOME/Downloads/FolderTrail-0.1.0-dev-unsigned.dmg}"

rm -rf "$BUILD_DIR"
mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources"

swiftc \
  -O \
  -target arm64-apple-macosx14.0 \
  "$APP_DIR/App"/*.swift \
  "$APP_DIR/Entry"/*.swift \
  "$APP_DIR/UX"/*.swift \
  "$APP_DIR/Safety"/*.swift \
  "$APP_DIR/Intelligence"/*.swift \
  "$APP_DIR/Execution"/*.swift \
  "$APP_DIR/Output"/*.swift \
  -o "$EXECUTABLE"

python3 - "$APP_DIR/Info.plist" "$APP_BUNDLE/Contents/Info.plist" <<'PY'
import plistlib
import sys
from pathlib import Path

source = Path(sys.argv[1])
destination = Path(sys.argv[2])

values = {
    "$(DEVELOPMENT_LANGUAGE)": "en",
    "$(EXECUTABLE_NAME)": "FolderTrail",
    "$(PRODUCT_BUNDLE_IDENTIFIER)": "com.relioptic.FolderTrail",
    "$(PRODUCT_NAME)": "FolderTrail",
    "$(MARKETING_VERSION)": "0.1.0",
    "$(CURRENT_PROJECT_VERSION)": "1",
    "$(MACOSX_DEPLOYMENT_TARGET)": "14.0",
}


def render(value):
    if isinstance(value, str):
        rendered = values.get(value, value)
        if "$(" in rendered:
            raise SystemExit(f"unexpanded Info.plist placeholder: {rendered}")
        return rendered
    if isinstance(value, list):
        return [render(item) for item in value]
    if isinstance(value, dict):
        return {key: render(item) for key, item in value.items()}
    return value

plist = render(plistlib.loads(source.read_bytes()))
executable = plist.get("CFBundleExecutable")
if executable != "FolderTrail":
    raise SystemExit(f"CFBundleExecutable must be FolderTrail, got {executable!r}")
if plist.get("CFBundleIdentifier") != "com.relioptic.FolderTrail":
    raise SystemExit("CFBundleIdentifier must be com.relioptic.FolderTrail")

destination.write_bytes(plistlib.dumps(plist, sort_keys=False))
PY

printf 'APPL????' > "$APP_BUNDLE/Contents/PkgInfo"
plutil -lint "$APP_BUNDLE/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$APP_BUNDLE/Contents/Info.plist" | grep -qx 'FolderTrail'
test -x "$EXECUTABLE"

codesign --force --deep --sign - --entitlements "$APP_DIR/FolderTrail.entitlements" "$APP_BUNDLE"
codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"

rm -f "$OUTPUT_DMG"
hdiutil create \
  -volname "FolderTrail 0.1.0-dev" \
  -srcfolder "$APP_BUNDLE" \
  -ov \
  -format UDZO \
  "$OUTPUT_DMG"
hdiutil verify "$OUTPUT_DMG"
shasum -a 256 "$OUTPUT_DMG"
