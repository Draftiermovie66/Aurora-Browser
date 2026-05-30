#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"

if [ $# -lt 1 ]; then
  echo "Usage: $0 <version> [--push]"
  echo "  <version>  e.g. v1.2.0"
  echo "  --push     Actually create the GitHub release (dry-run otherwise)"
  exit 1
fi

TAG="$1"
PUSH=false
[ "${2:-}" = "--push" ] && PUSH=true

echo "==> Aurora Browser Release $TAG"
echo ""

# ---- Build Linux .deb ----
echo "--- Building Linux .deb ..."
bash "$DIR/build.sh" deb

# ---- Build Windows ZIP (if on Windows) ----
WIN_ZIP="$DIR/aurora-browser-${TAG#v}-win.zip"
if command -v powershell.exe &>/dev/null; then
  echo "--- Building Windows ZIP ..."
  powershell.exe -File "$DIR/windows/build-windows.ps1" -version "${TAG#v}"
  # The build puts it in build/, zip it
  BUILD_DIR="$DIR/build/aurora-browser-${TAG#v}-win"
  if [ -d "$BUILD_DIR" ]; then
    (cd "$DIR/build" && zip -r "$WIN_ZIP" "aurora-browser-${TAG#v}-win")
    echo "  Windows ZIP: $WIN_ZIP"
  fi
else
  echo "  Skipping Windows ZIP (not on Windows)"
fi

# ---- Create GitHub Release ----
LINUX_DEB="$DIR/aurora-browser_${TAG#v}_amd64.deb"

if $PUSH; then
  echo "--- Creating GitHub release $TAG ..."
  gh release create "$TAG" \
    --title "Aurora Browser $TAG" \
    --notes "See extension/newtab.html for what's new in this release." \
    "$LINUX_DEB" \
    ${WIN_ZIP:+"$WIN_ZIP"}
  echo "==> Release $TAG created!"
else
  echo "==> Dry-run mode. Release assets ready:"
  echo "    $LINUX_DEB"
  [ -f "$WIN_ZIP" ] && echo "    $WIN_ZIP"
  echo ""
  echo "Run '$0 $TAG --push' to create the release."
fi
