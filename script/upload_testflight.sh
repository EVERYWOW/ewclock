#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARCHIVE_DIR="$ROOT_DIR/build/archives"
UPLOAD_DIR="$ROOT_DIR/build/uploads"
EXPORT_OPTIONS="$ROOT_DIR/ExportOptions-Upload.plist"

IOS_ARCHIVE="$ARCHIVE_DIR/EWClock-iOS.xcarchive"
MACOS_ARCHIVE="$ARCHIVE_DIR/EWClock-macOS.xcarchive"
PLATFORM="${1:-all}"

mkdir -p "$UPLOAD_DIR"

upload_archive() {
  local archive="$1"
  local output="$2"

  if [[ ! -d "$archive" ]]; then
    echo "Missing archive: $archive" >&2
    echo "Run ./script/archive.sh before uploading." >&2
    exit 1
  fi

  rm -rf "$output"
  xcodebuild \
    -exportArchive \
    -archivePath "$archive" \
    -exportPath "$output" \
    -exportOptionsPlist "$EXPORT_OPTIONS" \
    -allowProvisioningUpdates
}

case "$PLATFORM" in
  all)
    upload_archive "$IOS_ARCHIVE" "$UPLOAD_DIR/iOS"
    upload_archive "$MACOS_ARCHIVE" "$UPLOAD_DIR/macOS"
    ;;
  ios)
    upload_archive "$IOS_ARCHIVE" "$UPLOAD_DIR/iOS"
    ;;
  macos)
    upload_archive "$MACOS_ARCHIVE" "$UPLOAD_DIR/macOS"
    ;;
  *)
    echo "Usage: $0 [all|ios|macos]" >&2
    exit 2
    ;;
esac

echo "Uploaded $PLATFORM archive selection to App Store Connect."
