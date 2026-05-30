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

log "Checking for updates from github.com/$REPO ..."

LATEST=$(curl -sf "https://api.github.com/repos/$REPO/releases/latest" 2>/dev/null \
  | grep '"tag_name"' | cut -d'"' -f4) || {
  log "Failed to check GitHub. Set REPO in update.conf or check your network."
  exit 1
}

[ -z "$LATEST" ] && { log "No releases found."; exit 0; }

CURRENT=""
[ -f "$VERSION_FILE" ] && CURRENT=$(grep CHROMIUM_VERSION "$VERSION_FILE" | cut -d= -f2)

log "  Current version: ${CURRENT:-unknown}"
log "  Latest release:  $LATEST"

[ "$LATEST" = "$CURRENT" ] && { log "Already up to date."; exit 0; }

$CHECK_ONLY && { log "Update available: $LATEST"; exit 0; }

ASSET_URL=$(curl -sf "https://api.github.com/repos/$REPO/releases/latest" \
  | grep '"browser_download_url"' | grep -i 'chrome-linux' | cut -d'"' -f4)

if [ -z "$ASSET_URL" ]; then
  log "No chrome-linux asset found in latest release."
  log "Download the release manually and extract chrome-linux/ to this directory."
  exit 1
fi

log "Downloading $LATEST ..."
ZIP="$TMPDIR/update.zip"
curl -#L -o "$ZIP" "$ASSET_URL"

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

echo "CHROMIUM_VERSION=$LATEST" > "$VERSION_FILE"
CHROME_VER=$("$DIR/chrome-linux/chrome" --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+\.\d+' || echo "")
[ -n "$CHROME_VER" ] && echo "CHROME_VERSION=$CHROME_VER" >> "$VERSION_FILE"

log "Update complete: $LATEST"
log "Old backup saved at chrome-linux.old — delete it when ready."
