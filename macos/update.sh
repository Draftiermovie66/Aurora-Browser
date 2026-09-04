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

cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT
TMP=$(mktemp -d)

CURRENT=""
[ -f "$VERSION_FILE" ] && CURRENT=$(grep CHROMIUM_VERSION "$VERSION_FILE" | cut -d= -f2)

# Detect architecture
ARCH=$(uname -m)
case "$ARCH" in
  arm64)  SNAP="Mac_Arm";       ;;
  x86_64) SNAP="Mac";           ;;
  *)      log "Unsupported arch: $ARCH"; exit 1 ;;
esac

log "Aurora Browser BETA updater (arch: $ARCH)"

# GitHub release first
DOWNLOAD_URL=""
LATEST_TAG=""
GITHUB_TAG=$(curl -sf "https://api.github.com/repos/$REPO/releases/latest" 2>/dev/null \
  | grep '"tag_name"' | cut -d'"' -f4) || GITHUB_TAG=""

if [ -n "$GITHUB_TAG" ]; then
  [ "$GITHUB_TAG" = "$CURRENT" ] && { log "Already up to date."; exit 0; }
  LATEST_TAG="$GITHUB_TAG"
  DOWNLOAD_URL=$(curl -sf "https://api.github.com/repos/$REPO/releases/latest" \
    | grep '"browser_download_url"' | grep -i 'chrome-mac' | cut -d'"' -f4 || true)
fi

# Fallback to Chrome-for-Testing snapshot
if [ -z "$DOWNLOAD_URL" ]; then
  log "Falling back to Chrome-for-Testing snapshot..."
  JSON=$(curl -sf "https://googlechromelabs.github.io/chrome-for-testing/last-known-good-versions-with-downloads.json")
  LATEST_TAG=$(echo "$JSON" | grep -o '"version": *"[^"]*"' | head -1 | cut -d'"' -f4)
  [ "$LATEST_TAG" = "$CURRENT" ] && { log "Already up to date."; exit 0; }
  # Extract matching download URL for Mac
  DOWNLOAD_URL=$(echo "$JSON" | grep -o 'https://[^"]*chrome-mac[^"]*\.zip' | grep -i "$SNAP" | head -1 || true)
fi

if [ -z "$DOWNLOAD_URL" ]; then
  log "ERROR: could not determine a download URL."
  exit 1
fi

log "Downloading $LATEST_TAG ..."
ZIP="$TMP/engine.zip"
curl -#L -o "$ZIP" "$DOWNLOAD_URL"
unzip -qo "$ZIP" -d "$TMP/engine"

if [ ! -d "$TMP/engine/chrome-mac*" ]; then
  log "ERROR: chrome-mac/ not found in archive."
  exit 1
fi

log "Applying update ..."
rm -rf "$RES/chrome-mac.old"
[ -d "$RES/chrome-mac" ] && mv "$RES/chrome-mac" "$RES/chrome-mac.old"
mv "$TMP"/engine/chrome-mac* "$RES/chrome-mac"

echo "CHROMIUM_VERSION=$LATEST_TAG" > "$VERSION_FILE"
log "Update complete: $LATEST_TAG (BETA)"
