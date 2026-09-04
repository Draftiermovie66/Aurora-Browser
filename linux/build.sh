#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$DIR/.." && pwd)"

VERSION="${VERSION:-2.0.0}"

# Build React extension if node_modules exists
if [ -d "$ROOT/extension/node_modules" ]; then
  echo "==> Building React extension ..."
  (cd "$ROOT/extension" && npm run build)
fi

echo "==> Building .deb package (version $VERSION) ..."
PKG="$ROOT/aurora-browser_${VERSION}_amd64.deb"
rm -f "$PKG"

TMP=$(mktemp -d)
mkdir -p "$TMP/DEBIAN" "$TMP/opt/aurora-browser/extension" \
         "$TMP/opt/aurora-browser/profile" \
         "$TMP/usr/local/bin" \
         "$TMP/usr/share/applications" \
         "$TMP/usr/share/icons/hicolor/48x48/apps"

# control
cat > "$TMP/DEBIAN/control" <<CTRL
Package: aurora-browser
Version: ${VERSION}
Section: web
Priority: optional
Architecture: amd64
Depends: curl, unzip, ca-certificates
Maintainer: Aurora Browser <draftiermovie66@users.noreply.github.com>
Description: Aurora Browser - Aurora-based browser with auto-update
 Automatically downloads and updates the latest Aurora engine snapshot.
 Self-contained profile, custom new tab page, and auto-update from GitHub.
CTRL

cat > "$TMP/DEBIAN/postinst" <<'PINST'
#!/bin/sh
set -e
if [ -x /opt/aurora-browser/update.sh ]; then
  /opt/aurora-browser/update.sh --quiet &
fi
update-desktop-database 2>/dev/null || true
update-icon-caches /usr/share/icons/hicolor 2>/dev/null || true
PINST
chmod +x "$TMP/DEBIAN/postinst"

# launcher
cp "$DIR/launch.sh" "$TMP/opt/aurora-browser/launch-aurora.sh"
chmod +x "$TMP/opt/aurora-browser/launch-aurora.sh"

cp "$DIR/update.sh" "$TMP/opt/aurora-browser/update.sh"
chmod +x "$TMP/opt/aurora-browser/update.sh"

cp "$DIR/update.conf" "$TMP/opt/aurora-browser/update.conf"

cp "$DIR/setup-sandbox.sh" "$TMP/opt/aurora-browser/setup-sandbox.sh"
chmod +x "$TMP/opt/aurora-browser/setup-sandbox.sh"

echo "CHROMIUM_VERSION=0" > "$TMP/opt/aurora-browser/version.txt"

cat > "$TMP/opt/aurora-browser/.gitignore" <<'GI'
chrome-linux/
chrome-linux.old/
profile/
GI

# extension
cp -r "$ROOT/extension/"* "$TMP/opt/aurora-browser/extension/"

# .desktop
cat > "$TMP/usr/share/applications/aurora-browser.desktop" <<'DESK'
[Desktop Entry]
Name=Aurora Browser
Comment=Aurora-based browser with auto-update
Exec=/opt/aurora-browser/launch-aurora.sh %U
Icon=aurora-browser
Terminal=false
Type=Application
Categories=Network;WebBrowser;
MimeType=text/html;x-scheme-handler/http;x-scheme-handler/https;
StartupWMClass=Aurora-Browser
DESK

# icon
if [ -f "$ROOT/aurora.png" ]; then
  cp "$ROOT/aurora.png" "$TMP/usr/share/icons/hicolor/48x48/apps/aurora-browser.png"
fi

# symlink
ln -s /opt/aurora-browser/launch-aurora.sh "$TMP/usr/local/bin/aurora-browser"

dpkg-deb --build "$TMP" "$PKG"
rm -rf "$TMP"
echo "==> Built: $PKG"
