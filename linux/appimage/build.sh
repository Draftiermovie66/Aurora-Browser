#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$DIR/../.." && pwd)"
COMMON="$DIR/../common"

VERSION="${VERSION:-2.0.1}"

echo "==> Building Aurora Browser AppImage (version $VERSION) ..."
APPDIR=$(mktemp -d)/AppDir
mkdir -p "$APPDIR/usr/bin" "$APPDIR/usr/lib" "$APPDIR/usr/share/applications" \
         "$APPDIR/usr/share/icons/hicolor/48x48/apps"

# Build React extension
if [ -d "$ROOT/extension/node_modules" ]; then
  echo "==> Building React extension ..."
  (cd "$ROOT/extension" && npm run build)
fi

# Copy shared launcher & update scripts
mkdir -p "$APPDIR/opt/aurora-browser"
cp "$COMMON/launch.sh" "$APPDIR/opt/aurora-browser/launch-aurora.sh"
chmod +x "$APPDIR/opt/aurora-browser/launch-aurora.sh"
cp "$COMMON/update.sh" "$APPDIR/opt/aurora-browser/update.sh"
chmod +x "$APPDIR/opt/aurora-browser/update.sh"
cp "$COMMON/update.conf" "$APPDIR/opt/aurora-browser/update.conf"
cp "$COMMON/setup-sandbox.sh" "$APPDIR/opt/aurora-browser/setup-sandbox.sh"
chmod +x "$APPDIR/opt/aurora-browser/setup-sandbox.sh"
echo "CHROMIUM_VERSION=0" > "$APPDIR/opt/aurora-browser/version.txt"
mkdir -p "$APPDIR/opt/aurora-browser/profile"
mkdir -p "$APPDIR/opt/aurora-browser/extension"

# Extension
cp -r "$ROOT/extension/"* "$APPDIR/opt/aurora-browser/extension/"

# Icon
cp "$ROOT/aurora.png" "$APPDIR/usr/share/icons/hicolor/48x48/apps/aurora-browser.png"
cp "$ROOT/aurora.png" "$APPDIR/aurora-browser.png"

# .desktop
cat > "$APPDIR/usr/share/applications/aurora-browser.desktop" <<'DESK'
[Desktop Entry]
Name=Aurora Browser
Comment=Aurora-based browser with auto-update
Exec=aurora-browser %U
Icon=aurora-browser
Terminal=false
Type=Application
Categories=Network;WebBrowser;
MimeType=text/html;x-scheme-handler/http;x-scheme-handler/https;
StartupWMClass=Aurora-Browser
DESK
cp "$APPDIR/usr/share/applications/aurora-browser.desktop" "$APPDIR/aurora-browser.desktop"

# Launcher symlink in AppDir
ln -sf /opt/aurora-browser/launch-aurora.sh "$APPDIR/usr/bin/aurora-browser"

# Extract linuxdeploy to build the AppImage
LINUXDEPLOY="$ROOT/build/linuxdeploy-x86_64.AppImage"
mkdir -p "$ROOT/build"
if [ ! -f "$LINUXDEPLOY" ]; then
  echo "==> Downloading linuxdeploy ..."
  curl -L -o "$LINUXDEPLOY" \
    "https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage"
  chmod +x "$LINUXDEPLOY"
fi

OUT="$ROOT/build/Aurora-Browser-${VERSION}-x86_64.AppImage"

echo "==> Bundling AppImage ..."
export APPIMAGE_EXTRACT_AND_RUN=1
"$LINUXDEPLOY" \
  --appdir "$APPDIR" \
  --output appimage \
  --desktop-file "$APPDIR/usr/share/applications/aurora-browser.desktop" \
  --icon-file "$ROOT/aurora.png"

# linuxdeploy outputs the .AppImage in $APPDIR by default
if [ -f "$APPDIR/Aurora_Browser-*.AppImage" ] || ls "$APPDIR"/*.AppImage >/dev/null 2>&1; then
  mv "$APPDIR"/*.AppImage "$OUT"
fi

echo "==> Built: $OUT"
echo "    Run with: chmod +x $OUT && ./$OUT"