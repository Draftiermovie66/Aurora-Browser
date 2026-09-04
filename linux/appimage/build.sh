#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$DIR/../.." && pwd)"
COMMON="$DIR/../common"

VERSION="${VERSION:-2.0.2}"

echo "==> Building Aurora Browser AppImage (version $VERSION) ..."
APPDIR=$(mktemp -d)/AppDir
mkdir -p "$APPDIR/usr/bin" "$APPDIR/usr/lib" "$APPDIR/usr/share/applications" \
         "$APPDIR/usr/share/icons/hicolor/48x48/apps" \
         "$APPDIR/usr/share/icons/hicolor/256x256/apps"

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
rsync -a --exclude 'node_modules' "$ROOT/extension/" "$APPDIR/opt/aurora-browser/extension/"

# Icon
# linuxdeploy requires icons at specific resolutions (not 800x800).
# Generate a valid 256x256 copy for bundling.
ICON_SRC="$ROOT/aurora.png"
ICON_256="$ROOT/build/aurora-browser-256.png"
mkdir -p "$ROOT/build"
resize_icon() {
  if command -v convert >/dev/null 2>&1; then
    convert "$ICON_SRC" -resize 256x256 "$ICON_256"
  elif command -v magick >/dev/null 2>&1; then
    magick "$ICON_SRC" -resize 256x256 "$ICON_256"
  elif command -v python3 >/dev/null 2>&1; then
    python3 - "$ICON_SRC" "$ICON_256" <<'PY'
import sys
try:
    from PIL import Image
except ImportError:
    sys.exit(1)
src, dst = sys.argv[1], sys.argv[2]
im = Image.open(src).convert("RGBA").resize((256, 256), Image.LANCZOS)
im.save(dst, "PNG")
PY
  fi
  [ -f "$ICON_256" ] || cp "$ICON_SRC" "$ICON_256"
}
resize_icon
cp "$ICON_256" "$APPDIR/usr/share/icons/hicolor/256x256/apps/aurora-browser.png"
cp "$ICON_256" "$APPDIR/aurora-browser.png"

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

# Launcher wrapper in AppDir: AppImages mount read-only, so the engine,
# profile, and extension are staged into a user-writable data dir. This
# wrapper doubles as the .desktop Exec=aurora-browser entry.
cat > "$APPDIR/usr/bin/aurora-browser" <<'WRAP'
#!/bin/bash
set -euo pipefail
APPDIR="${APPDIR:-$(cd "$(dirname "$(readlink -f "$0")")/../../" && pwd)}"
export APPDIR

DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/aurora-browser"
mkdir -p "$DATA_DIR"
if [ ! -d "$DATA_DIR/extension" ]; then
  cp -r "$APPDIR/opt/aurora-browser/extension" "$DATA_DIR/extension"
fi

LAST="$DATA_DIR/.last-update-check"
if [ ! -f "$LAST" ] || [ "$(find "$LAST" -mtime +0)" ]; then
  touch "$LAST"
  mkdir -p "$DATA_DIR/profile"
  INSTALL_DIR="$DATA_DIR" \
    "$APPDIR/opt/aurora-browser/update.sh" --quiet >/dev/null 2>&1 &
fi

ENGINE="$DATA_DIR/chrome-linux/chrome"
[ -x "$ENGINE" ] || INSTALL_DIR="$DATA_DIR" "$APPDIR/opt/aurora-browser/update.sh"

ENGINE_VER="$(sed -n 's/^CHROMIUM_VERSION=//p' "$DATA_DIR/version.txt" 2>/dev/null)"
[ -z "$ENGINE_VER" ] && ENGINE_VER="152.0.0.0"
AURORA_UA="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/${ENGINE_VER} Safari/537.36 AuroraBrowser/${ENGINE_VER%%.*}"

# Default to the Aurora new tab page when launching without a URL.
if [ $# -eq 0 ]; then
  set -- chrome://newtab
fi

FLAGS=(
  --user-data-dir="$DATA_DIR/profile"
  --no-first-run
  --disable-features=TranslateUI
  --disable-setuid-sandbox
  --disable-background-networking
  --disable-component-update
  --class=Aurora-Browser
  --user-agent="$AURORA_UA"
  --load-extension="$DATA_DIR/extension"
)
exec "$ENGINE" "${FLAGS[@]}" "$@"
WRAP
chmod +x "$APPDIR/usr/bin/aurora-browser"

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

# appimagetool writes the AppImage into the current working directory,
# so run linuxdeploy from a scratch output dir that we control.
OUTTMP=$(mktemp -d)

echo "==> Bundling AppImage ..."
export APPIMAGE_EXTRACT_AND_RUN=1
export ARCH="${ARCH:-x86_64}"
(
  cd "$OUTTMP"
  "$LINUXDEPLOY" \
    --appdir "$APPDIR" \
    --output appimage \
    --desktop-file "$APPDIR/usr/share/applications/aurora-browser.desktop" \
    --icon-file "$ICON_256"
)

PRODUCED=$(find "$OUTTMP" -maxdepth 1 -name "*.AppImage" | head -n1)
if [ -z "$PRODUCED" ]; then
  echo "ERROR: appimagetool did not produce an AppImage under $OUTTMP"
  exit 1
fi
mv "$PRODUCED" "$OUT"

echo "==> Built: $OUT"
echo "    Run with: chmod +x $OUT && ./$(basename "$OUT")"