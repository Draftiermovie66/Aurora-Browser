#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$DIR/../.." && pwd)"

if [ -z "${VERSION:-}" ] && [ -f "$ROOT/VERSION" ]; then
  VERSION="$(cat "$ROOT/VERSION")"
fi
VERSION="${VERSION:-2.0.6}"

PACKAGES="$ROOT/packages"

case "${1:-deb}" in
  deb|debian)
    bash "$PACKAGES/linux/debian/build.sh" "${@:2}"
    ;;
  rpm|redhat|fedora)
    bash "$PACKAGES/linux/redhat/build.sh" "${@:2}"
    ;;
  appimage)
    bash "$PACKAGES/linux/appimage/build.sh" "${@:2}"
    ;;
  arch)
    echo "==> Arch packages are built with makepkg:"
    echo "    cd $PACKAGES/linux/arch && makepkg -si"
    echo "    (or: cd $ROOT/linux/arch && makepkg -si — legacy path still works)"
    ;;
  macos|mac)
    bash "$PACKAGES/macos/build.sh" "${@:2}"
    ;;
  windows)
    powershell.exe -File "$PACKAGES/windows/build.ps1" "${@:2}" 2>/dev/null \
      || echo "Run 'powershell.exe .\\packages\\windows\\build.ps1' on Windows."
    ;;
  release)
    bash "$DIR/release.sh" "${2:-${VERSION}}" "${3:---dry}"
    ;;
  *)
    echo "Usage: $0 {deb|rpm|appimage|arch|macos|windows|release} [version]"
    echo ""
    echo "  deb      - Debian/Ubuntu (.deb)"
    echo "  rpm      - Fedora/RHEL/RedHat (.rpm)"
    echo "  appimage - Universal Linux (.AppImage)"
    echo "  arch     - Arch Linux (PKGBUILD)"
    echo "  macos    - macOS BETA (.app + .dmg)"
    echo "  windows  - Windows (.exe + zip)"
    exit 1
    ;;
esac
