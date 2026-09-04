#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
# INSTALL_DIR lets wrappers (e.g. AppImage) redirect engine downloads to a
# user-writable dir instead of the (read-only) bundle directory.
INSTALL_DIR="${INSTALL_DIR:-$DIR}"
CONFIG="$DIR/update.conf"
VERSION_FILE="$INSTALL_DIR/version.txt"

REPO="USER/Aurora-Browser"
[ -f "$CONFIG" ] && source "$CONFIG"

QUIET=false
CHECK_ONLY=false
for arg in "$@"; do
  [ "$arg" = "--quiet" ] && QUIET=true
  [ "$arg" = "--check" ] && CHECK_ONLY=true
done

log() { $QUIET || echo "$@"; }

cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT
WORK=$(mktemp -d)

# Canonical name the launchers expect (launch.sh / AppImage wrapper use
# $INSTALL_DIR/chrome-linux). We normalize whatever engine dir we extract
# (chrome-linux, chrome-linux64, ...) to this name during the apply step.
ENGINE_DIRNAME="chrome-linux"

CURRENT=""
[ -f "$VERSION_FILE" ] && CURRENT=$(grep CHROMIUM_VERSION "$VERSION_FILE" | cut -d= -f2)

DOWNLOADS=""
LATEST_TAG=""

# Fetch a URL list of candidate engine archives for a given release API.
# Returns nothing (not an error) when no matching asset exists, so callers
# guard with `|| true` to stay resilient under `set -e`.
github_release_assets() {
  local json url
  json=$(curl -sf --max-time 20 "https://api.github.com/repos/$REPO/releases/latest" 2>/dev/null) || return 0
  GITHUB_TAG=$(echo "$json" | grep '"tag_name"' | cut -d'"' -f4)
  if [ -n "$GITHUB_TAG" ]; then
    log "  Current version: ${CURRENT:-unknown}"
    log "  Latest release:  $GITHUB_TAG"
    [ "$GITHUB_TAG" = "$CURRENT" ] && { log "Already up to date."; return 2; }
    LATEST_TAG="$GITHUB_TAG"
    # Prefer a chrome-linux engine asset if one is ever published.
    url=$(echo "$json" \
      | grep '"browser_download_url"' \
      | grep -i 'chrome-linux' \
      | head -n1 | cut -d'"' -f4 || true)
    [ -n "$url" ] && DOWNLOADS="$url"
  fi
}

# Chrome for Testing is the reliable, versioned source for a Linux engine.
# Extract the Stable channel download URLs from the known-good JSON.
chrome_testing_assets() {
  local json ver url
  json=$(curl -sf --max-time 25 \
    "https://googlechromelabs.github.io/chrome-for-testing/last-known-good-versions-with-downloads.json" 2>/dev/null) || return 1
  ver=$(printf '%s' "$json" | python3 -c \
    "import sys,json;print(json.load(sys.stdin)['channels']['Stable']['version'])" 2>/dev/null \
    || printf '%s' "$json" | grep -o '"version": *"[^"]*"' | head -1 | cut -d'"' -f4 || true)
  [ -z "$ver" ] && return 1
  [ "$ver" = "$CURRENT" ] && { log "Already up to date ($ver)."; return 2; }
  LATEST_TAG="$ver"
  url=$(printf '%s' "$json" \
    | grep -o 'https://[^"]*chrome-linux64\.zip' \
    | head -n1 || true)
  [ -n "$url" ] && DOWNLOADS="$url"
}

# Legacy Chromium snapshot bucket (kept as a last resort).
snapshot_archive() {
  local rev
  rev=$(curl -sf --max-time 20 \
    "https://www.googleapis.com/download/storage/v1/b/chromium-browser-snapshots/o/Linux_x64%2FLAST_CHANGE?alt=media" 2>/dev/null) || return 1
  [ -z "$rev" ] && return 1
  [ "$rev" = "$CURRENT" ] && { log "Already up to date ($rev)."; return 2; }
  LATEST_TAG="$rev"
  DOWNLOADS="https://www.googleapis.com/download/storage/v1/b/chromium-browser-snapshots/o/Linux_x64%2F${rev}%2Fchrome-linux.zip?alt=media"
}

log "Checking github.com/$REPO for engine updates ..."
# Each source may return 0 (no match), 1 (network/parse failure), or
# 2 (already up to date). Treat only DOWNLOADS as the gate for continuing.
github_release_assets || true
if [ -z "$DOWNLOADS" ]; then
  log "No chrome-linux asset in release; trying Chrome-for-Testing..."
  chrome_testing_assets || true
fi
if [ -z "$DOWNLOADS" ]; then
  log "Chrome-for-Testing unavailable; falling back to Chromium snapshot..."
  snapshot_archive || true
fi

if [ -z "$DOWNLOADS" ] || [ -z "$LATEST_TAG" ]; then
  log "ERROR: could not determine a download URL for the engine."
  # Never terminate silently: keep a healthcheck-friendly exit code.
  exit 1
fi

$CHECK_ONLY && { log "Update available: $LATEST_TAG"; exit 0; }

log "Downloading $LATEST_TAG ..."
ZIP="$WORK/update.zip"
curl -#L --max-time 600 -o "$ZIP" "$DOWNLOADS"
if [ ! -s "$ZIP" ]; then
  log "ERROR: download produced an empty file."
  exit 1
fi

log "Extracting ..."
unzip -qo "$ZIP" -d "$WORK/extracted"

# Locate the engine directory. Chrome-for-Testing extracts as
# chrome-linux64/, the legacy snapshot as chrome-linux/.
EXTRACTED=$(find "$WORK/extracted" -maxdepth 1 -type d -name 'chrome-linux*' | head -n1 || true)
if [ -z "$EXTRACTED" ] || [ ! -x "$EXTRACTED/chrome" ]; then
  log "ERROR: engine 'chrome' binary not found in the archive."
  exit 1
fi

log "Applying update ..."
rm -rf "$INSTALL_DIR/$ENGINE_DIRNAME.old"
[ -d "$INSTALL_DIR/$ENGINE_DIRNAME" ] && mv "$INSTALL_DIR/$ENGINE_DIRNAME" "$INSTALL_DIR/$ENGINE_DIRNAME.old"
mv "$EXTRACTED" "$INSTALL_DIR/$ENGINE_DIRNAME"
chmod +x "$INSTALL_DIR/$ENGINE_DIRNAME/chrome"

echo "CHROMIUM_VERSION=$LATEST_TAG" > "$VERSION_FILE"
CHROME_VER=$("$INSTALL_DIR/$ENGINE_DIRNAME/chrome" --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+\.\d+' || echo "")
[ -n "$CHROME_VER" ] && echo "CHROME_VERSION=$CHROME_VER" >> "$VERSION_FILE"

log "Update complete: $LATEST_TAG"
log "Old backup saved at $ENGINE_DIRNAME.old — delete it when ready."
