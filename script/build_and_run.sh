#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="EW Clock"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="$ROOT_DIR/EWClock.xcodeproj"
DERIVED_DATA="$ROOT_DIR/build/DerivedData"
APP_BUNDLE="$DERIVED_DATA/Build/Products/Debug/$APP_NAME.app"
APP_BINARY="$APP_BUNDLE/Contents/MacOS/$APP_NAME"

usage() {
  echo "Usage: $0 [run|--debug|--logs|--verify]" >&2
}

if [[ $# -gt 1 ]]; then
  usage
  exit 2
fi

case "$MODE" in
  run|--debug|--logs|--verify)
    ;;
  *)
    usage
    exit 2
    ;;
esac

pkill -x "$APP_NAME" >/dev/null 2>&1 || true

"$ROOT_DIR/script/generate.sh"
xcodebuild \
  -project "$PROJECT" \
  -scheme EWClock-macOS \
  -destination 'platform=macOS' \
  -derivedDataPath "$DERIVED_DATA" \
  build

case "$MODE" in
  run)
    /usr/bin/open -n "$APP_BUNDLE"
    ;;
  --debug)
    exec lldb -- "$APP_BINARY"
    ;;
  --logs)
    /usr/bin/open -n "$APP_BUNDLE"
    exec /usr/bin/log stream \
      --info \
      --style compact \
      --predicate "process == \"$APP_NAME\""
    ;;
  --verify)
    /usr/bin/open -n "$APP_BUNDLE"
    for _ in {1..20}; do
      if pgrep -x "$APP_NAME" >/dev/null; then
        echo "$APP_NAME is running."
        exit 0
      fi
      sleep 0.25
    done
    echo "$APP_NAME did not start." >&2
    exit 1
    ;;
esac
