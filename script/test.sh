#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="$ROOT_DIR/EWClock.xcodeproj"
DERIVED_DATA="$ROOT_DIR/build/DerivedData"

# shellcheck source=script/local_signing.sh
source "$ROOT_DIR/script/local_signing.sh"

"$ROOT_DIR/script/generate.sh"

xcodebuild \
  -project "$PROJECT" \
  -scheme EWClockTests \
  -destination 'platform=macOS' \
  -derivedDataPath "$DERIVED_DATA" \
  "${LOCAL_SIGNING_ARGS[@]}" \
  test

xcodebuild \
  -project "$PROJECT" \
  -scheme EWClock-iOS \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath "$DERIVED_DATA" \
  "${LOCAL_SIGNING_ARGS[@]}" \
  build

xcodebuild \
  -project "$PROJECT" \
  -scheme EWClock-macOS \
  -destination 'platform=macOS' \
  -derivedDataPath "$DERIVED_DATA" \
  "${LOCAL_SIGNING_ARGS[@]}" \
  build
