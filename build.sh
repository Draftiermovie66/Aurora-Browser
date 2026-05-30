#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"

case "${1:-deb}" in
  deb)
    echo "==> Building .deb package ..."
    PKG="$DIR/aurora-browser_1.1.1_amd64.deb"
    rm -f "$PKG"

    TMP=$(mktemp -d)
    mkdir -p "$TMP/DEBIAN" "$TMP/opt/aurora-browser/extension" \
             "$TMP/opt/aurora-browser/profile" \
             "$TMP/usr/local/bin" \
             "$TMP/usr/share/applications" \
             "$TMP/usr/share/icons/hicolor/48x48/apps"

    # control
    cat > "$TMP/DEBIAN/control" <<'CTRL'
Package: aurora-browser
Version: 1.1.1
Section: web
Priority: optional
Architecture: amd64
Depends: curl, unzip, ca-certificates
Maintainer: Aurora Browser <draftiermovie66@users.noreply.github.com>
Description: Aurora Browser - Chromium-based browser with auto-update
 Automatically downloads and updates the latest Chromium snapshot.
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
    cat > "$TMP/opt/aurora-browser/launch-aurora.sh" <<'LAUNCH'
#!/usr/bin/env bash
DIR="$(cd "$(dirname "$0")" && pwd)"
UPDATE_CHECK="$DIR/profile/.last-update-check"
if [ ! -f "$UPDATE_CHECK" ] || [ "$(find "$UPDATE_CHECK" -mtime +0)" ]; then
  touch "$UPDATE_CHECK"
  bash "$DIR/update.sh" --quiet >/dev/null 2>&1 &
fi
FLAGS=(
  --user-data-dir="$DIR/profile"
  --no-first-run
  --disable-features=TranslateUI
  --disable-setuid-sandbox
  --class=Aurora-Browser
  --load-extension="$DIR/extension"
)
exec "$DIR/chrome-linux/chrome" "${FLAGS[@]}" "$@"
LAUNCH
    chmod +x "$TMP/opt/aurora-browser/launch-aurora.sh"

    cp "$DIR/update.sh" "$TMP/opt/aurora-browser/update.sh"
    chmod +x "$TMP/opt/aurora-browser/update.sh"

    cat > "$TMP/opt/aurora-browser/update.conf" <<'CONF'
# GitHub repository for Aurora Browser updates
REPO="Draftiermovie66/Aurora-Browser"
CONF

    echo "CHROMIUM_VERSION=0" > "$TMP/opt/aurora-browser/version.txt"

    cat > "$TMP/opt/aurora-browser/setup-sandbox.sh" <<'SANDBOX'
#!/bin/sh
if [ -x /opt/aurora-browser/chrome-linux/chrome_sandbox ]; then
  chown root:root /opt/aurora-browser/chrome-linux/chrome_sandbox 2>/dev/null || true
  chmod 4755 /opt/aurora-browser/chrome-linux/chrome_sandbox 2>/dev/null || true
fi
SANDBOX
    chmod +x "$TMP/opt/aurora-browser/setup-sandbox.sh"

    echo "CHROMIUM_VERSION=0" > "$TMP/opt/aurora-browser/version.txt"

    cat > "$TMP/opt/aurora-browser/.gitignore" <<'GI'
chrome-linux/
chrome-linux.old/
profile/
GI

    # extension
    cp -r "$DIR/extension/"* "$TMP/opt/aurora-browser/extension/"

    # .desktop
    cat > "$TMP/usr/share/applications/aurora-browser.desktop" <<'DESK'
[Desktop Entry]
Name=Aurora Browser
Comment=Chromium-based browser with auto-update
Exec=/opt/aurora-browser/launch-aurora.sh %U
Icon=aurora-browser
Terminal=false
Type=Application
Categories=Network;WebBrowser;
MimeType=text/html;x-scheme-handler/http;x-scheme-handler/https;
StartupWMClass=Aurora-Browser
DESK

    # icon
    if [ -f "$DIR/aurora.png" ]; then
      cp "$DIR/aurora.png" "$TMP/usr/share/icons/hicolor/48x48/apps/aurora-browser.png"
    fi

    # symlink
    ln -s /opt/aurora-browser/launch-aurora.sh "$TMP/usr/local/bin/aurora-browser"

    dpkg-deb --build "$TMP" "$PKG"
    rm -rf "$TMP"
    echo "==> Built: $PKG"
    ;;
  windows)
    echo "==> Building Windows package ..."
    powershell.exe -File "$DIR/windows/build-windows.ps1" "${@:2}" 2>/dev/null \
      || echo "Run 'powershell.exe .\windows\build-windows.ps1' on Windows."
    ;;
  *)
    echo "Usage: $0 {deb|windows}"
    exit 1
    ;;
esac
