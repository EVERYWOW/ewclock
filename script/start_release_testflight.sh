#!/usr/bin/env bash
# Starts script/release_testflight.sh fully detached in its own session and
# returns immediately. Use this from agents whose command runner terminates
# background processes when a command returns.
#
# Usage: script/start_release_testflight.sh [--if-older-than-days N]
#
# Output goes to build/release-logs/scheduled.out. The release is finished when
# its last line starts with "RESULT:".
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT="$ROOT_DIR/build/release-logs/scheduled.out"
mkdir -p "$(dirname "$OUTPUT")"
: >"$OUTPUT"

cd "$ROOT_DIR"
nohup /usr/bin/perl -MPOSIX -e 'POSIX::setsid() or die "setsid: $!"; exec @ARGV or die "exec: $!"' \
  "$ROOT_DIR/script/release_testflight.sh" "$@" >"$OUTPUT" 2>&1 </dev/null &
pid=$!
disown "$pid" 2>/dev/null || true

sleep 2
if ! kill -0 "$pid" 2>/dev/null && ! grep -q '^RESULT:' "$OUTPUT"; then
  echo "Release process $pid exited immediately:" >&2
  cat "$OUTPUT" >&2
  exit 1
fi
echo "Release started as process $pid in its own session."
echo "Follow it with: tail -5 $OUTPUT"
