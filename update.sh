#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG="$DIR/update.conf"
VERSION_FILE="$DIR/version.txt"

# Default repo — change this or create update.conf with REPO="your/repo"
REPO="USER/Aurora-Browser"
[ -f "$CONFIG" ] && source "$CONFIG"

QUIET=false
CHECK_ONLY=false
for arg in "$@"; do
  [ "$arg" = "--quiet" ] && QUIET=true
  [ "$arg" = "--check" ] && CHECK_ONLY=true
done

log() { $QUIET || echo "$@"; }

cleanup() { rm -rf "$TMPDIR"; }
trap cleanup EXIT
TMPDIR=$(mktemp -d)

CURRENT=""
[ -f "$VERSION_FILE" ] && CURRENT=$(grep CHROMIUM_VERSION "$VERSION_FILE" | cut -d= -f2)

DOWNLOAD_URL=""
LATEST_TAG=""

# Try GitHub release first
log "Checking github.com/$REPO for updates ..."
GITHUB_TAG=$(curl -sf "https://api.github.com/repos/$REPO/releases/latest" 2>/dev/null \
  | grep '"tag_name"' | cut -d'"' -f4) || GITHUB_TAG=""

if [ -n "$GITHUB_TAG" ]; then
  log "  Current version: ${CURRENT:-unknown}"
  log "  Latest release:  $GITHUB_TAG"
  [ "$GITHUB_TAG" = "$CURRENT" ] && { log "Already up to date."; exit 0; }
  LATEST_TAG="$GITHUB_TAG"
  DOWNLOAD_URL=$(curl -sf "https://api.github.com/repos/$REPO/releases/latest" \
    | grep '"browser_download_url"' | grep -i 'chrome-linux' | cut -d'"' -f4)
fi

# Fallback to Chromium snapshot
if [ -z "$DOWNLOAD_URL" ]; then
  log "No GitHub release asset. Falling back to latest Chromium snapshot..."
  SNAPSHOT_REV=$(curl -sf "https://www.googleapis.com/download/storage/v1/b/chromium-browser-snapshots/o/Linux_x64%2FLAST_CHANGE?alt=media") || {
    log "Failed to fetch Chromium snapshot revision."
    exit 1
  }
  [ "$SNAPSHOT_REV" = "$CURRENT" ] && { log "Already up to date."; exit 0; }
  LATEST_TAG="$SNAPSHOT_REV"
  DOWNLOAD_URL="https://www.googleapis.com/download/storage/v1/b/chromium-browser-snapshots/o/Linux_x64%2F${SNAPSHOT_REV}%2Fchrome-linux.zip?alt=media"
fi

$CHECK_ONLY && { log "Update available: $LATEST_TAG"; exit 0; }

log "Downloading $LATEST_TAG ..."
ZIP="$TMPDIR/update.zip"
curl -#L -o "$ZIP" "$DOWNLOAD_URL"

log "Extracting ..."
unzip -qo "$ZIP" -d "$TMPDIR/extracted"

if [ ! -d "$TMPDIR/extracted/chrome-linux" ]; then
  log "ERROR: chrome-linux/ not found in the archive."
  exit 1
fi

log "Applying update ..."
rm -rf "$DIR/chrome-linux.old"
[ -d "$DIR/chrome-linux" ] && mv "$DIR/chrome-linux" "$DIR/chrome-linux.old"
mv "$TMPDIR/extracted/chrome-linux" "$DIR/chrome-linux"
chmod +x "$DIR/chrome-linux/chrome"

echo "CHROMIUM_VERSION=$LATEST_TAG" > "$VERSION_FILE"
CHROME_VER=$("$DIR/chrome-linux/chrome" --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+\.\d+' || echo "")
[ -n "$CHROME_VER" ] && echo "CHROME_VERSION=$CHROME_VER" >> "$VERSION_FILE"

log "Update complete: $LATEST_TAG"
log "Old backup saved at chrome-linux.old — delete it when ready."
