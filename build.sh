#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"

VERSION="${VERSION:-2.0.1}"

case "${1:-deb}" in
  deb|debian)
    bash "$DIR/linux/debian/build.sh" "${@:2}"
    ;;
  rpm|redhat|fedora)
    bash "$DIR/linux/redhat/build.sh" "${@:2}"
    ;;
  appimage)
    bash "$DIR/linux/appimage/build.sh" "${@:2}"
    ;;
  arch)
    echo "==> Arch packages are built with makepkg:"
    echo "    cd $DIR/linux/arch && makepkg -si"
    ;;
  macos|mac)
    bash "$DIR/macos/build.sh" "${@:2}"
    ;;
  windows)
    powershell.exe -File "$DIR/windows/build.ps1" "${@:2}" 2>/dev/null \
      || echo "Run 'powershell.exe .\windows\build.ps1' on Windows."
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