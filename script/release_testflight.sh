#!/usr/bin/env bash
# Builds, tests, and uploads a new internal TestFlight build from origin/main.
#
# Usage: script/release_testflight.sh [--if-older-than-days N]
#
# With --if-older-than-days, the release is skipped while the newest build in
# App Store Connect is younger than N days. The scheduled nightly release uses
# this to keep a three-week cadence and to retry automatically after a failure.
#
# The release runs in a temporary git worktree of origin/main, so local changes
# in this checkout are never built or committed. The next build number is one
# higher than both App Store Connect's highest build and project.yml. After
# both platform builds finish processing and reach EVERYWOW Internal, the
# build-number bump is committed and pushed to main.
#
# The last line of output is RESULT: RELEASED, RESULT: SKIPPED, or RESULT: FAILED.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_ID="6791122125"
INTERNAL_GROUP="EVERYWOW Internal"
PROCESSING_TIMEOUT_SECONDS=3600
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

MIN_AGE_DAYS=""
case "${1:-}" in
  "") ;;
  --if-older-than-days)
    MIN_AGE_DAYS="${2:?Missing day count}"
    ;;
  *)
    echo "Usage: $0 [--if-older-than-days N]" >&2
    exit 2
    ;;
esac

LOG_DIR="$ROOT_DIR/build/release-logs/$(date +%Y-%m-%d_%H-%M-%S)"
mkdir -p "$LOG_DIR"
LOCK_DIR="$ROOT_DIR/build/release.lock"
WORKTREE=""

fail() {
  echo "ERROR: $*" >&2
  echo "Logs: $LOG_DIR"
  echo "RESULT: FAILED"
  exit 1
}

cleanup() {
  if [[ -n "$WORKTREE" && -d "$WORKTREE" ]]; then
    git -C "$ROOT_DIR" worktree remove --force "$WORKTREE" >/dev/null 2>&1 || true
  fi
  rmdir "$LOCK_DIR" 2>/dev/null || true
}

mkdir "$LOCK_DIR" 2>/dev/null || {
  echo "Another release is running ($LOCK_DIR exists)."
  echo "RESULT: FAILED"
  exit 1
}
trap cleanup EXIT

# shellcheck source=script/asc_env.sh
source "$ROOT_DIR/script/asc_env.sh"

asc() {
  ruby "$ROOT_DIR/script/asc_api.rb" "$@"
}

# Prints "<highest build number> <newest upload epoch seconds>".
latest_build_info() {
  asc GET "/v1/builds?filter[app]=$APP_ID&sort=-uploadedDate&limit=200&fields[builds]=version,uploadedDate" |
    ruby -rjson -rtime -e '
      builds = JSON.parse(STDIN.read)["data"]
      max = builds.map { |b| b["attributes"]["version"].to_i }.max || 0
      newest = builds.map { |b| Time.parse(b["attributes"]["uploadedDate"]).to_i }.max || 0
      puts "#{max} #{newest}"'
}

# Prints platform states for one build number, for example "IOS=VALID MAC_OS=PROCESSING".
build_states() {
  asc GET "/v1/builds?filter[app]=$APP_ID&filter[version]=$1&fields[builds]=processingState,preReleaseVersion&include=preReleaseVersion&fields[preReleaseVersions]=platform" |
    ruby -rjson -e '
      d = JSON.parse(STDIN.read)
      platforms = (d["included"] || []).to_h { |i| [i["id"], i["attributes"]["platform"]] }
      puts d["data"].map { |b|
        "#{platforms[b.dig("relationships", "preReleaseVersion", "data", "id")]}=#{b["attributes"]["processingState"]}"
      }.sort.join(" ")'
}

# Prints how many builds with the given number are in the internal group.
internal_group_count() {
  local group_id
  group_id="$(asc GET "/v1/apps/$APP_ID/betaGroups?fields[betaGroups]=name" |
    ruby -rjson -e 'puts JSON.parse(STDIN.read)["data"].find { |g| g["attributes"]["name"] == ARGV[0] }&.fetch("id")' "$INTERNAL_GROUP")"
  [[ -n "$group_id" ]] || return 1
  asc GET "/v1/betaGroups/$group_id/builds?fields[builds]=version&limit=200" |
    ruby -rjson -e 'puts JSON.parse(STDIN.read)["data"].count { |b| b["attributes"]["version"] == ARGV[0] }' "$1"
}

run_step() {
  local name="$1"
  shift
  echo "==> $name"
  if ! "$@" >"$LOG_DIR/$name.log" 2>&1; then
    echo "--- last lines of $LOG_DIR/$name.log ---"
    grep -E "error:|ERROR|FAILED|✘" "$LOG_DIR/$name.log" | tail -20 || true
    tail -20 "$LOG_DIR/$name.log"
    fail "$name failed"
  fi
}

read -r ASC_MAX_BUILD NEWEST_UPLOAD < <(latest_build_info) || fail "Could not read builds from App Store Connect"
echo "App Store Connect: highest build $ASC_MAX_BUILD, newest upload $(date -r "$NEWEST_UPLOAD" '+%Y-%m-%d %H:%M')"

if [[ -n "$MIN_AGE_DAYS" ]]; then
  AGE_DAYS=$(( ($(date +%s) - NEWEST_UPLOAD) / 86400 ))
  if (( AGE_DAYS < MIN_AGE_DAYS )); then
    echo "Newest build is $AGE_DAYS days old; release is due after $MIN_AGE_DAYS days."
    echo "RESULT: SKIPPED"
    exit 0
  fi
  echo "Newest build is $AGE_DAYS days old; releasing."
fi

xcodebuild -version | head -1

git -C "$ROOT_DIR" fetch --quiet origin main || fail "git fetch failed"
WORKTREE="$(mktemp -d "${TMPDIR:-/tmp}/ewclock-release.XXXXXX")"
rmdir "$WORKTREE"
git -C "$ROOT_DIR" worktree add --quiet --detach "$WORKTREE" origin/main || fail "Could not create release worktree"
cd "$WORKTREE"

REPO_BUILD="$(sed -nE 's/^ *CURRENT_PROJECT_VERSION: *([0-9]+) *$/\1/p' project.yml)"
[[ -n "$REPO_BUILD" ]] || fail "CURRENT_PROJECT_VERSION not found in project.yml"
BUILD=$(( (ASC_MAX_BUILD > REPO_BUILD ? ASC_MAX_BUILD : REPO_BUILD) + 1 ))
VERSION="$(sed -nE 's/^ *MARKETING_VERSION: *([0-9.]+) *$/\1/p' project.yml)"
echo "Releasing version $VERSION build $BUILD from origin/main $(git rev-parse --short HEAD)"
sed -i '' -E "s/^( *CURRENT_PROJECT_VERSION: *)[0-9]+ *$/\1$BUILD/" project.yml

run_step test ./script/test.sh
run_step archive ./script/archive.sh
run_step upload ./script/upload_testflight.sh all

echo "==> Waiting for App Store Connect processing"
deadline=$(( $(date +%s) + PROCESSING_TIMEOUT_SECONDS ))
while true; do
  states="$(build_states "$BUILD" || true)"
  echo "    $(date +%H:%M:%S) ${states:-not listed yet}"
  [[ "$states" == "IOS=VALID MAC_OS=VALID" ]] && break
  [[ "$states" =~ FAILED|INVALID ]] && fail "Processing failed: $states"
  (( $(date +%s) < deadline )) || fail "Processing did not finish within $((PROCESSING_TIMEOUT_SECONDS / 60)) minutes: ${states:-not listed}"
  sleep 30
done

echo "==> Checking $INTERNAL_GROUP"
for _ in {1..10}; do
  count="$(internal_group_count "$BUILD" || echo 0)"
  [[ "$count" == "2" ]] && break
  sleep 30
done
[[ "$count" == "2" ]] || fail "Build $BUILD is not in $INTERNAL_GROUP for both platforms (found $count)"

echo "==> Committing build number"
git add project.yml EWClock.xcodeproj/project.pbxproj
git commit --quiet -m "Release TestFlight build $BUILD

Automated internal TestFlight release of version $VERSION build $BUILD.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
if ! git push --quiet origin HEAD:main 2>"$LOG_DIR/push.log"; then
  git fetch --quiet origin main
  git rebase --quiet origin/main >>"$LOG_DIR/push.log" 2>&1 || {
    git rebase --abort >/dev/null 2>&1 || true
    fail "Build $BUILD was uploaded, but the version bump could not be rebased onto main"
  }
  git push --quiet origin HEAD:main 2>>"$LOG_DIR/push.log" ||
    fail "Build $BUILD was uploaded, but pushing the version bump failed"
fi

# Fast-forward this checkout when it is clean and on main.
if [[ "$(git -C "$ROOT_DIR" branch --show-current)" == "main" && -z "$(git -C "$ROOT_DIR" status --porcelain)" ]]; then
  git -C "$ROOT_DIR" pull --quiet --ff-only origin main || true
fi

echo "Released version $VERSION build $BUILD for iOS/iPadOS and macOS to $INTERNAL_GROUP."
echo "Logs: $LOG_DIR"
echo "RESULT: RELEASED"
