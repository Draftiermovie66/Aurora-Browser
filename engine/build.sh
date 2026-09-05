#!/usr/bin/env bash
set -euo pipefail
# Aurora Browser — Build script for Ladybird engine
# Clones Ladybird, applies Aurora branding, builds for the current platform.

DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$DIR/.." && pwd)"

if [ -z "${VERSION:-}" ] && [ -f "$ROOT/VERSION" ]; then
  VERSION="$(cat "$ROOT/VERSION")"
fi
VERSION="${VERSION:-3.0.0}"

LADYBIRD_REPO="${LADYBIRD_REPO:-https://github.com/LadybirdBrowser/ladybird.git}"
LADYBIRD_BRANCH="${LADYBIRD_BRANCH:-main}"
BUILD_DIR="$ROOT/build/ladybird"
INSTALL_DIR="$ROOT/build/aurora-browser-${VERSION}"

echo "=========================================="
echo " Aurora Browser ${VERSION} — Ladybird Build"
echo "=========================================="
echo ""

# ---- Step 1: Clone or update Ladybird ----
if [ ! -d "$BUILD_DIR/.git" ]; then
  echo "==> Cloning Ladybird engine..."
  git clone --depth 1 --branch "$LADYBIRD_BRANCH" "$LADYBIRD_REPO" "$BUILD_DIR"
else
  echo "==> Ladybird already cloned, pulling latest..."
  (cd "$BUILD_DIR" && git pull --ff-only || true)
fi

# ---- Step 2: Apply Aurora branding patches ----
echo "==> Applying Aurora Browser branding..."
"$DIR/brand.sh" "$BUILD_DIR"

# ---- Step 3: Build Ladybird ----
echo "==> Building Ladybird (this may take 30-120 minutes)..."
cd "$BUILD_DIR"

# Detect platform and set build options
case "$(uname -s)" in
  Linux)
    BUILD_PRESET="${BUILD_PRESET:-Release}"
    BUILD_PRESET="$BUILD_PRESET" ./Meta/ladybird.py build
    ;;
  Darwin)
    BUILD_PRESET="${BUILD_PRESET:-Release}"
    # Use Homebrew clang if available (Apple Clang may be too old for C++23)
    if command -v brew >/dev/null 2>&1 && [ -d "$(brew --prefix llvm 2>/dev/null || true)" ]; then
      export CC="$(brew --prefix llvm)/bin/clang"
      export CXX="$(brew --prefix llvm)/bin/clang++"
    fi
    BUILD_PRESET="$BUILD_PRESET" ./Meta/ladybird.py build
    ;;
  MINGW*|MSYS*|CYGWIN*)
    echo "ERROR: Windows native build is not supported."
    echo "Please build using WSL2. See: https://docs ladybird.org/building"
    exit 1
    ;;
  *)
    echo "ERROR: Unsupported platform: $(uname -s)"
    exit 1
    ;;
esac

# ---- Step 4: Package for distribution ----
echo "==> Packaging Aurora Browser..."
"$DIR/package.sh" "$BUILD_DIR" "$INSTALL_DIR" "$VERSION"

echo ""
echo "==> Build complete!"
echo "    Output: $INSTALL_DIR"
echo "    Run: $INSTALL_DIR/aurora-browser"
