#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
NAME="aurora-browser"
VERSION="1.0.0"
ARCH="amd64"
BUILD="$DIR/build/$NAME-$VERSION"
DEB="$DIR/${NAME}_${VERSION}_${ARCH}.deb"

echo "Building $DEB ..."

rm -rf "$DIR/build"

mkdir -p "$BUILD/DEBIAN"
mkdir -p "$BUILD/opt/aurora-browser"
mkdir -p "$BUILD/usr/share/applications"
mkdir -p "$BUILD/usr/share/icons/hicolor/48x48/apps"
mkdir -p "$BUILD/usr/local/bin"

# control file
cat > "$BUILD/DEBIAN/control" <<EOF
Package: aurora-browser
Version: $VERSION
Section: web
Priority: optional
Architecture: $ARCH
Maintainer: Draftiermovie66 <ben.steinvoort@gmail.com>
Description: Aurora Browser - custom Chromium-based browser
 A self-contained Chromium browser profile with auto-update
 from GitHub releases.
Depends: curl, unzip, ca-certificates
EOF

# postinst - download chrome-linux on install
cat > "$BUILD/DEBIAN/postinst" <<'POSTINST'
#!/bin/sh
set -e
DIR=/opt/aurora-browser
if [ ! -d "$DIR/chrome-linux" ]; then
  echo "Aurora Browser: downloading browser engine..."
  bash "$DIR/update.sh" || echo "Run 'sudo bash $DIR/update.sh' later to download the browser."
fi
# ensure launcher is executable
chmod +x "$DIR/launch-aurora.sh" "$DIR/update.sh"
exit 0
POSTINST
chmod +x "$BUILD/DEBIAN/postinst"

# prerm - clean up on remove
cat > "$BUILD/DEBIAN/prerm" <<'PRERM'
#!/bin/sh
set -e
if [ "$1" = "remove" ] || [ "$1" = "purge" ]; then
  rm -f /usr/local/bin/aurora-browser
fi
exit 0
PRERM
chmod +x "$BUILD/DEBIAN/prerm"

# Install files
cp "$DIR/launch-aurora.sh" "$BUILD/opt/aurora-browser/launch-aurora.sh"
cp "$DIR/update.sh" "$BUILD/opt/aurora-browser/update.sh"
cp "$DIR/update.conf" "$BUILD/opt/aurora-browser/update.conf"
cp "$DIR/version.txt" "$BUILD/opt/aurora-browser/version.txt"
cp "$DIR/setup-sandbox.sh" "$BUILD/opt/aurora-browser/setup-sandbox.sh"
cp "$DIR/icon.png" "$BUILD/opt/aurora-browser/icon.png"
[ -f "$DIR/.gitignore" ] && cp "$DIR/.gitignore" "$BUILD/opt/aurora-browser/.gitignore"

# Desktop file
cat > "$BUILD/usr/share/applications/aurora-browser.desktop" <<DESKTOP
[Desktop Entry]
Type=Application
Name=Aurora Browser
Comment=Custom Aurora Browser profile
Exec=/opt/aurora-browser/launch-aurora.sh %U
Icon=aurora-browser
Terminal=false
Categories=Network;WebBrowser;
StartupNotify=true
StartupWMClass=Aurora-Browser
MimeType=text/html;text/xml;application/xhtml+xml;
DESKTOP

# Icon
cp "$DIR/icon.png" "$BUILD/usr/share/icons/hicolor/48x48/apps/aurora-browser.png"

# Symlink in PATH
mkdir -p "$BUILD/usr/local/bin"
ln -sf /opt/aurora-browser/launch-aurora.sh "$BUILD/usr/local/bin/aurora-browser"

# Fix update.conf to use the correct repo (use the config's existing value)
# Already handled by copying the file

# mkdir profile placeholder
mkdir -p "$BUILD/opt/aurora-browser/profile"

# Build the .deb
fakeroot dpkg-deb --build "$BUILD" "$DEB" 2>/dev/null || dpkg-deb --build "$BUILD" "$DEB"

rm -rf "$DIR/build"
echo "Done: $DEB"
echo "Install with: sudo dpkg -i $DEB"
