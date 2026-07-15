#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="$ROOT_DIR/EWClock.xcodeproj"
ARCHIVE_DIR="$ROOT_DIR/build/archives"
EXPORT_DIR="$ROOT_DIR/build/exports"
DERIVED_DATA="$ROOT_DIR/build/ArchiveDerivedData"
TEAM_ID="L69664DD39"

IOS_ARCHIVE="$ARCHIVE_DIR/EWClock-iOS.xcarchive"
MACOS_ARCHIVE="$ARCHIVE_DIR/EWClock-macOS.xcarchive"

"$ROOT_DIR/script/generate.sh"
rm -rf "$IOS_ARCHIVE" "$MACOS_ARCHIVE" "$EXPORT_DIR/iOS" "$EXPORT_DIR/macOS"
mkdir -p "$ARCHIVE_DIR" "$EXPORT_DIR"

xcodebuild \
  -project "$PROJECT" \
  -scheme EWClock-iOS \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -derivedDataPath "$DERIVED_DATA" \
  -archivePath "$IOS_ARCHIVE" \
  DEVELOPMENT_TEAM="$TEAM_ID" \
  CODE_SIGN_STYLE=Automatic \
  -allowProvisioningUpdates \
  archive

xcodebuild \
  -project "$PROJECT" \
  -scheme EWClock-macOS \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  -derivedDataPath "$DERIVED_DATA" \
  -archivePath "$MACOS_ARCHIVE" \
  DEVELOPMENT_TEAM="$TEAM_ID" \
  CODE_SIGN_STYLE=Automatic \
  -allowProvisioningUpdates \
  archive

xcodebuild \
  -exportArchive \
  -archivePath "$IOS_ARCHIVE" \
  -exportPath "$EXPORT_DIR/iOS" \
  -exportOptionsPlist "$ROOT_DIR/ExportOptions-iOS.plist" \
  -allowProvisioningUpdates

xcodebuild \
  -exportArchive \
  -archivePath "$MACOS_ARCHIVE" \
  -exportPath "$EXPORT_DIR/macOS" \
  -exportOptionsPlist "$ROOT_DIR/ExportOptions-macOS.plist" \
  -allowProvisioningUpdates

echo "Created iOS archive: $IOS_ARCHIVE"
echo "Created macOS archive: $MACOS_ARCHIVE"
echo "Exported App Store Connect packages under: $EXPORT_DIR"
