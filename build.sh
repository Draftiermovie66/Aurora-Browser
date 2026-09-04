#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"

VERSION="${VERSION:-1.1.1}"

case "${1:-deb}" in
  deb)
    bash "$DIR/linux/build.sh" "${@:2}"
    ;;
  windows)
    powershell.exe -File "$DIR/windows/build.ps1" "${@:2}" 2>/dev/null \
      || echo "Run 'powershell.exe .\windows\build.ps1' on Windows."
    ;;
  release)
    bash "$DIR/release.sh" "${2:-${VERSION}}" "${3:---dry}"
    ;;
  *)
    echo "Usage: $0 {deb|windows|release} [version]"
    exit 1
    ;;
esac