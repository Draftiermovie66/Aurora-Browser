#!/usr/bin/env bash
# Aurora Browser BETA — macOS engine updater
# Downloads the Chrome-for-Testing engine for macOS and swaps it in.
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
RES="$DIR"
CONFIG="$DIR/update.conf"
VERSION_FILE="$DIR/version.txt"

REPO="USER/Aurora-Browser"
[ -f "$CONFIG" ] && source "$CONFIG"

QUIET=false
for arg in "$@"; do
  [ "$arg" = "--quiet" ] && QUIET=true
done
log() { $QUIET || echo "$@"; }

cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT
WORK=$(mktemp -d)

CURRENT=""
[ -f "$VERSION_FILE" ] && CURRENT=$(grep CHROMIUM_VERSION "$VERSION_FILE" | cut -d= -f2)

# Detect architecture
ARCH=$(uname -m)
case "$ARCH" in
  arm64)
    # Chrome-for-Testing asset suffix
    SNAP="arm64"
    # Our own GitHub release asset suffix
    GH_SUFFIX="mac_arm"
    ;;
  x86_64)
    SNAP="x64"
    GH_SUFFIX="mac_x64"
    ;;
  *)      log "Unsupported arch: $ARCH"; exit 1 ;;
esac

log "Aurora Browser BETA updater (arch: $ARCH)"

# GitHub release first (repo has no chrome-mac asset today, so usually empty).
DOWNLOADS=""
LATEST_TAG=""

# Prefer the platform-specific variant matching the current architecture.
fetch_github_release() {
  local json url
  json=$(curl -sf "https://api.github.com/repos/$REPO/releases/latest" 2>/dev/null) || return 1
  GITHUB_TAG=$(echo "$json" | grep '"tag_name"' | cut -d'"' -f4)
  if [ -n "$GITHUB_TAG" ] && [ "$GITHUB_TAG" = "$CURRENT" ]; then
    log "Already up to date ($GITHUB_TAG)."
    exit 0
  fi
  LATEST_TAG="$GITHUB_TAG"
  # Any chrome-mac asset, but prefer the matching arch variant.
  url=$(echo "$json" \
    | grep '"browser_download_url"' \
    | grep -i "chrome-mac.*${GH_SUFFIX}" \
    | head -n1 | cut -d'"' -f4)
  [ -z "$url" ] && \
    url=$(echo "$json" \
      | grep '"browser_download_url"' \
      | grep -i 'chrome-mac' \
      | head -n1 | cut -d'"' -f4)
  [ -n "$url" ] && DOWNLOADS="$url"
}

fetch_chrome_testing() {
  local json ver
  json=$(curl -sf "https://googlechromelabs.github.io/chrome-for-testing/last-known-good-versions-with-downloads.json") || return 1
  ver=$(echo "$json" | python3 -c "import sys,json;print(json.load(sys.stdin)['channels']['Stable']['version'])" 2>/dev/null \
        || echo "$json" | grep -o '"version": *"[^"]*"' | head -1 | cut -d'"' -f4)
  [ "$ver" = "$CURRENT" ] && { log "Already up to date ($ver)."; exit 0; }
  LATEST_TAG="$ver"
  # Filter downloads to the platform-specific chrome-mac variant.
  DOWNLOADS=$(echo "$json" \
    | grep -o 'https://[^"]*chrome-mac[^"]*\.zip' \
    | grep -E "chrome-mac[-_.]?${SNAP}" \
    | head -n1 || true)
}

fetch_github_release || true
if [ -z "$DOWNLOADS" ]; then
  log "No GitHub chrome-mac asset; falling back to Chrome-for-Testing snapshot ..."
  fetch_chrome_testing || true
fi

if [ -z "$DOWNLOADS" ] || [ -z "$LATEST_TAG" ]; then
  log "ERROR: could not determine a download URL."
  exit 1
fi

log "Downloading $LATEST_TAG ..."
ZIP="$WORK/engine.zip"
curl -#L -o "$ZIP" "${DOWNLOADS%%$'\n'*}"
unzip -qo "$ZIP" -d "$WORK/engine"

# Locate the extracted chrome-mac directory (may be chrome-mac, -arm64, -x64 …)
ENGINE_DIR=$(find "$WORK/engine" -maxdepth 1 -type d -name 'chrome-mac*' | head -n1 || true)
if [ -z "$ENGINE_DIR" ]; then
  log "ERROR: chrome-mac/ not found in archive."
  exit 1
fi

log "Applying update ..."
rm -rf "$RES/chrome-mac.old"
[ -d "$RES/chrome-mac" ] && mv "$RES/chrome-mac" "$RES/chrome-mac.old"
mv "$ENGINE_DIR" "$RES/chrome-mac"

ENGINE="$RES/chrome-mac"
BIN="$ENGINE/Google Chrome for Testing.app/Contents/MacOS/Google Chrome for Testing"
[ -f "$BIN" ] || BIN="$ENGINE/chrome"
chmod +x "$BIN" 2>/dev/null || true

echo "CHROMIUM_VERSION=$LATEST_TAG" > "$VERSION_FILE"
log "Update complete: $LATEST_TAG (BETA)"
