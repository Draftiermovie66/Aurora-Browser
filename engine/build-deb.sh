#!/usr/bin/env bash
set -euo pipefail
# Aurora Browser — Build .deb package from Ladybird build output

BUILD_DIR="${1:?Usage: build-deb.sh <ladybird-build-dir> <output-dir> <version>}"
OUTPUT_DIR="${2:?}"
VERSION="${3:?}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "  Building .deb package..."

STAGE=$(mktemp -d)
mkdir -p "$STAGE/DEBIAN" \
         "$STAGE/opt/aurora-browser" \
         "$STAGE/usr/local/bin" \
         "$STAGE/usr/share/applications" \
         "$STAGE/usr/share/icons/hicolor/48x48/apps"

# Find the built ladybird binary
BUILT_BIN=$(find "$BUILD_DIR" -name "ladybird" -type f -executable 2>/dev/null | head -n1)
if [ -z "$BUILT_BIN" ]; then
  echo "ERROR: ladybird binary not found"
  exit 1
fi
BUILT_DIR=$(dirname "$BUILT_BIN")

# Copy engine files
cp -R "$BUILT_DIR"/* "$STAGE/opt/aurora-browser/"

# Copy icon
ICON="$ROOT/assets/icons/aurora.png"
[ -f "$ICON" ] || ICON="$ROOT/aurora.png"
[ -f "$ICON" ] && cp "$ICON" "$STAGE/usr/share/icons/hicolor/48x48/apps/aurora-browser.png"
[ -f "$ICON" ] && cp "$ICON" "$STAGE/opt/aurora-browser/aurora-browser.png"

# Launcher script
cat > "$STAGE/usr/local/bin/aurora-browser" <<'LAUNCH'
#!/bin/bash
DIR="$(dirname "$(readlink -f "$0")")"
exec "$DIR/../opt/aurora-browser/ladybird" "$@"
LAUNCH
chmod +x "$STAGE/usr/local/bin/aurora-browser"

# .desktop file
cat > "$STAGE/usr/share/applications/aurora-browser.desktop" <<'DESK'
[Desktop Entry]
Name=Aurora Browser
Comment=Custom open-source browser with LibWeb engine
Exec=/usr/local/bin/aurora-browser %U
Icon=aurora-browser
Terminal=false
Type=Application
Categories=Network;WebBrowser;
MimeType=text/html;x-scheme-handler/http;x-scheme-handler/https;
DESK

# Control file
cat > "$STAGE/DEBIAN/control" <<CTRL
Package: aurora-browser
Version: ${VERSION}
Section: web
Priority: optional
Architecture: amd64
Depends: libgl1, libglu1-mesa, libpulse0, libssl3
Maintainer: Aurora Browser <draftiermovie66@users.noreply.github.com>
Description: Aurora Browser - Custom open-source browser
 Aurora Browser is built on the Ladybird LibWeb engine.
 No Chromium. No Firefox. Custom open-source engine.
CTRL

# Build
DEB="$OUTPUT_DIR/aurora-browser_${VERSION}_amd64.deb"
dpkg-deb --build "$STAGE" "$DEB"
rm -rf "$STAGE"
echo "  Built: $DEB"
