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

# shellcheck source=script/asc_env.sh
source "$ROOT_DIR/script/asc_env.sh"

# Archives are not signed with local certificates. The export steps below use
# the App Store Connect API key for cloud-managed distribution signing, so a
# release needs only the API key, not development or distribution identities
# in this Mac's keychain. The iOS app has no entitlements and is archived
# unsigned. The Mac app is signed ad hoc so its sandbox entitlement is kept.
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
  CODE_SIGNING_ALLOWED=NO \
  archive

xcodebuild \
  -project "$PROJECT" \
  -scheme EWClock-macOS \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  -derivedDataPath "$DERIVED_DATA" \
  -archivePath "$MACOS_ARCHIVE" \
  DEVELOPMENT_TEAM="$TEAM_ID" \
  CODE_SIGN_STYLE=Manual \
  CODE_SIGN_IDENTITY=- \
  PROVISIONING_PROFILE_SPECIFIER= \
  archive

xcodebuild \
  -exportArchive \
  -archivePath "$IOS_ARCHIVE" \
  -exportPath "$EXPORT_DIR/iOS" \
  -exportOptionsPlist "$ROOT_DIR/ExportOptions-iOS.plist" \
  -allowProvisioningUpdates \
  "${ASC_AUTH_ARGS[@]}"

xcodebuild \
  -exportArchive \
  -archivePath "$MACOS_ARCHIVE" \
  -exportPath "$EXPORT_DIR/macOS" \
  -exportOptionsPlist "$ROOT_DIR/ExportOptions-macOS.plist" \
  -allowProvisioningUpdates \
  "${ASC_AUTH_ARGS[@]}"

echo "Created iOS archive: $IOS_ARCHIVE"
echo "Created macOS archive: $MACOS_ARCHIVE"
echo "Exported App Store Connect packages under: $EXPORT_DIR"
