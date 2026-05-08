#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="$ROOT_DIR/app/macos/FolderTrail.xcodeproj"
SCHEME="FolderTrail"
CONFIGURATION="Release"
BUILD_DIR="$ROOT_DIR/build/distribution"
ARCHIVE_PATH="$BUILD_DIR/FolderTrail.xcarchive"
EXPORT_PATH="$BUILD_DIR/export"
DMG_PATH="$BUILD_DIR/FolderTrail-0.1.dmg"
EXPORT_OPTIONS="$ROOT_DIR/app/macos/ExportOptions.plist"

: "${NOTARYTOOL_PROFILE:?Set NOTARYTOOL_PROFILE to an App Store Connect notarytool keychain profile}"
: "${TEAM_ID:?Set TEAM_ID to your Apple Developer Team ID}"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR" "$EXPORT_PATH"

# Archive with Hardened Runtime enabled by the Xcode project and Developer ID signing.
xcodebuild archive \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -archivePath "$ARCHIVE_PATH" \
  DEVELOPMENT_TEAM="$TEAM_ID" \
  CODE_SIGN_IDENTITY="Developer ID Application" \
  SKIP_INSTALL=NO

# Export the signed .app bundle.
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist "$EXPORT_OPTIONS"

# Package a DMG for distribution.
hdiutil create \
  -volname "FolderTrail" \
  -srcfolder "$EXPORT_PATH/FolderTrail.app" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

# Notarize and staple. Human checkpoint: Apple ID / Keychain profile access may prompt.
xcrun notarytool submit "$DMG_PATH" \
  --keychain-profile "$NOTARYTOOL_PROFILE" \
  --wait

xcrun stapler staple "$DMG_PATH"

# Local assessment; final clean-Mac Gatekeeper verification remains HITL.
spctl --assess --verbose --type open "$DMG_PATH"

echo "Built, notarized, stapled, and assessed: $DMG_PATH"
