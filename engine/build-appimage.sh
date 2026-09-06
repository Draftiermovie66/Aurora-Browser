#!/usr/bin/env bash
set -euo pipefail
# Aurora Browser — Build .AppImage from Ladybird build output

BUILD_DIR="${1:?Usage: build-appimage.sh <ladybird-build-dir> <output-dir> <version>}"
OUTPUT_DIR="${2:?}"
VERSION="${3:?}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "  Building AppImage..."

APPDIR=$(mktemp -d)/AppDir
mkdir -p "$APPDIR/usr/bin" "$APPDIR/usr/lib" \
         "$APPDIR/usr/share/applications" \
         "$APPDIR/usr/share/icons/hicolor/256x256/apps"

# Find the built ladybird binary
BUILT_BIN=$(find "$BUILD_DIR" -name "ladybird" -type f -executable 2>/dev/null | head -n1)
if [ -z "$BUILT_BIN" ]; then
  echo "ERROR: ladybird binary not found"
  exit 1
fi
BUILT_DIR=$(dirname "$BUILT_BIN")

# Copy engine files
cp -R "$BUILT_DIR"/* "$APPDIR/usr/lib/aurora-browser/"

# Copy icon
ICON="$ROOT/assets/icons/aurora.png"
[ -f "$ICON" ] || ICON="$ROOT/aurora.png"
[ -f "$ICON" ] && cp "$ICON" "$APPDIR/usr/share/icons/hicolor/256x256/apps/aurora-browser.png"
[ -f "$ICON" ] && cp "$ICON" "$APPDIR/aurora-browser.png"

# Launcher wrapper
cat > "$APPDIR/usr/bin/aurora-browser" <<'WRAP'
#!/bin/bash
DIR="$(dirname "$(readlink -f "$0")")"
LIB="$DIR/../lib/aurora-browser"
exec "$LIB/ladybird" "$@"
WRAP
chmod +x "$APPDIR/usr/bin/aurora-browser"

# .desktop file
cat > "$APPDIR/usr/share/applications/aurora-browser.desktop" <<'DESK'
[Desktop Entry]
Name=Aurora Browser
Comment=Custom open-source browser with LibWeb engine
Exec=aurora-browser %U
Icon=aurora-browser
Terminal=false
Type=Application
Categories=Network;WebBrowser;
MimeType=text/html;x-scheme-handler/http;x-scheme-handler/https;
DESK
cp "$APPDIR/usr/share/applications/aurora-browser.desktop" "$APPDIR/aurora-browser.desktop"

# AppRun
cat > "$APPDIR/AppRun" <<'APPRUN'
#!/bin/bash
SELF="$(readlink -f "$0")"
DIR="$(dirname "$SELF")"
exec "$DIR/usr/bin/aurora-browser" "$@"
APPRUN
chmod +x "$APPDIR/AppRun"

# Download linuxdeploy if needed
LINUXDEPLOY="$ROOT/build/linuxdeploy-x86_64.AppImage"
mkdir -p "$ROOT/build"
if [ ! -f "$LINUXDEPLOY" ]; then
  echo "  Downloading linuxdeploy..."
  curl -L -o "$LINUXDEPLOY" \
    "https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage"
  chmod +x "$LINUXDEPLOY"
fi

# Build AppImage
OUT="$OUTPUT_DIR/Aurora-Browser-${VERSION}-x86_64.AppImage"
OUTTMP=$(mktemp -d)

echo "  Bundling AppImage..."
export APPIMAGE_EXTRACT_AND_RUN=1
export ARCH="${ARCH:-x86_64}"
(
  cd "$OUTTMP"
  "$LINUXDEPLOY" \
    --appdir "$APPDIR" \
    --output appimage \
    --desktop-file "$APPDIR/usr/share/applications/aurora-browser.desktop" \
    --icon-file "$APPDIR/aurora-browser.png"
)

PRODUCED=$(find "$OUTTMP" -maxdepth 1 -name "*.AppImage" | head -n1)
if [ -z "$PRODUCED" ]; then
  echo "ERROR: appimagetool did not produce an AppImage"
  exit 1
fi
mv "$PRODUCED" "$OUT"
chmod +x "$OUT"
rm -rf "$OUTTMP" "$APPDIR"
echo "  Built: $OUT"
