#!/usr/bin/env bash
set -euo pipefail
# Aurora Browser — Build Orchestrator
# Builds the Ladybird-based Aurora Browser for the specified platform.

DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$DIR/../.." && pwd)"

if [ -z "${VERSION:-}" ] && [ -f "$ROOT/VERSION" ]; then
  VERSION="$(cat "$ROOT/VERSION")"
fi
VERSION="${VERSION:-3.0.0}"

ENGINE_DIR="$ROOT/engine"

case "${1:-linux}" in
  linux|deb|rpm|appimage|arch)
    echo "==> Building Aurora Browser for Linux..."
    VERSION="$VERSION" bash "$ENGINE_DIR/build.sh"
    ;;
  macos|mac)
    echo "==> Building Aurora Browser for macOS..."
    VERSION="$VERSION" bash "$ENGINE_DIR/build.sh"
    ;;
  windows|win)
    echo "==> Windows build requires WSL2."
    echo "    Install WSL2, then run: bash engine/build.sh"
    echo "    Or use: ./Meta/ladybird.py run (inside WSL2)"
    ;;
  sign)
    echo "==> Signing release binaries..."
    VERSION="$VERSION" bash "$ENGINE_DIR/sign.sh" "${2:-$ROOT/build}" "$VERSION"
    ;;
  checksums)
    echo "==> Generating checksums..."
    VERSION="$VERSION" bash "$ENGINE_DIR/checksums.sh" "${2:-$ROOT/build}" "$VERSION"
    ;;
  clean)
    echo "==> Cleaning build artifacts..."
    rm -rf "$ROOT/build"
    echo "    Done."
    ;;
  *)
    echo "Usage: $0 {linux|macos|windows|sign|checksums|clean} [version]"
    echo ""
    echo "  linux      - Build for Linux (requires Clang, Qt6, Ninja)"
    echo "  macos      - Build for macOS (requires Xcode, Homebrew deps)"
    echo "  windows    - Build for Windows (requires WSL2)"
    echo "  sign       - Code sign release binaries"
    echo "  checksums  - Generate SHA256 checksums"
    echo "  clean      - Remove build directory"
    exit 1
    ;;
esac
