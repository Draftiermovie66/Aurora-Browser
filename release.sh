#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"

if [ $# -lt 1 ]; then
  echo "Usage: $0 <version> [--push]"
  echo "  <version>  e.g. v2.0.1"
  echo "  --push     Actually create the GitHub release (dry-run otherwise)"
  exit 1
fi

TAG="$1"
V="${TAG#v}"
PUSH=false
[ "${2:-}" = "--push" ] && PUSH=true

echo "==> Aurora Browser Release $TAG"
echo ""

# ---- Build Linux packages ----
echo "--- Building Debian (.deb) ..."
bash "$DIR/linux/debian/build.sh"
DEB="$DIR/aurora-browser_${V}_amd64.deb"

echo "--- Building AppImage ..."
bash "$DIR/linux/appimage/build.sh"
APPIMAGE="$DIR/build/Aurora-Browser-${V}-x86_64.AppImage"

echo "--- Building RedHat (.rpm) ..."
bash "$DIR/linux/redhat/build.sh"
RPM="$DIR/build/aurora-browser-${V}-1.x86_64.rpm"

# ---- Build macOS (BETA) ----
echo "--- Building macOS (BETA) ..."
bash "$DIR/macos/build.sh"
DMG="$DIR/build/Aurora-Browser-${V}-BETA.dmg"

# ---- Build Windows .exe (if on Windows) ----
WIN_EXE="$DIR/build/aurora-browser-${V}-win.exe"
if command -v powershell.exe &>/dev/null; then
  echo "--- Building Windows .exe ..."
  powershell.exe -File "$DIR/windows/build.ps1" -version "$V"
  BUILD_DIR="$DIR/build/aurora-browser-${V}-win"
  if [ -f "$BUILD_DIR/aurora-browser.exe" ]; then
    cp "$BUILD_DIR/aurora-browser.exe" "$WIN_EXE"
  fi
else
  echo "  Skipping Windows .exe (not on Windows)"
fi

# ---- Create GitHub Release ----
ASSETS=("$DEB")
[ -f "$APPIMAGE" ] && ASSETS+=("$APPIMAGE")
[ -f "$RPM" ] && ASSETS+=("$RPM")
[ -f "$DMG" ] && ASSETS+=("$DMG")
[ -f "$WIN_EXE" ] && ASSETS+=("$WIN_EXE")

if $PUSH; then
  echo "--- Creating GitHub release $TAG ..."
  gh release create "$TAG" \
    --title "Aurora Browser $TAG" \
    --notes "Multi-platform release. See extension/react app for what's new." \
    "${ASSETS[@]}"
  echo "==> Release $TAG created!"
else
  echo "==> Dry-run mode. Release assets ready:"
  for a in "${ASSETS[@]}"; do
    [ -f "$a" ] && echo "    $a"
  done
  echo ""
  echo "Run '$0 $TAG --push' to create the release."
fi