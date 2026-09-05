#!/usr/bin/env bash
set -euo pipefail
# Aurora Browser — Package script
# Creates a distributable package from a built Ladybird tree.

BUILD_DIR="${1:?Usage: package.sh <ladybird-build-dir> <output-dir> <version>}"
INSTALL_DIR="${2:?Usage: package.sh <ladybird-build-dir> <output-dir> <version>}"
VERSION="${3:?Usage: package.sh <ladybird-build-dir> <output-dir> <version>}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "  Packaging Aurora Browser v${VERSION}..."

rm -rf "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR"

case "$(uname -s)" in
  Linux)
    # Ladybird builds into Build/ladybird/ or similar
    BUILT_BIN=$(find "$BUILD_DIR" -path "*/ladybird" -type f -executable 2>/dev/null | head -n1)
    if [ -z "$BUILT_BIN" ]; then
      BUILT_BIN=$(find "$BUILD_DIR/Build" -name "ladybird" -type f -executable 2>/dev/null | head -n1)
    fi
    if [ -z "$BUILT_BIN" ]; then
      echo "ERROR: Could not find built ladybird binary."
      echo "Build output contents:"
      find "$BUILD_DIR/Build" -maxdepth 3 -type f 2>/dev/null | head -20
      exit 1
    fi

    BUILT_DIR=$(dirname "$BUILT_BIN")
    # Copy the entire build output (engine + resources)
    cp -R "$BUILT_DIR"/* "$INSTALL_DIR/"

    # Create launcher script
    cat > "$INSTALL_DIR/aurora-browser" <<LAUNCH
#!/bin/bash
DIR="\$(cd "\$(dirname "\$0")" && pwd)"
exec "\$DIR/ladybird" "\$@"
LAUNCH
    chmod +x "$INSTALL_DIR/aurora-browser"
    ;;

  Darwin)
    # Find the built .app bundle
    APP=$(find "$BUILD_DIR" -name "Ladybird.app" -type d 2>/dev/null | head -n1)
    if [ -z "$APP" ]; then
      APP=$(find "$BUILD_DIR/Build" -name "Ladybird.app" -type d 2>/dev/null | head -n1)
    fi
    if [ -z "$APP" ]; then
      echo "ERROR: Could not find Ladybird.app bundle."
      exit 1
    fi

    # Rename to Aurora Browser.app
    cp -R "$APP" "$INSTALL_DIR/Aurora Browser.app"

    # Update Info.plist
    PLIST="$INSTALL_DIR/Aurora Browser.app/Contents/Info.plist"
    if [ -f "$PLIST" ]; then
      sed -i '' 's/CFBundleName<\/key>\n\s*<string>Ladybird/CFBundleName<\/key>\n\t\t<string>Aurora Browser/g' "$PLIST" 2>/dev/null || \
        sed -i '' 's/>Ladybird</>Aurora Browser</g' "$PLIST"
      sed -i '' 's/CFBundleIdentifier.*ladybird/CFBundleIdentifier>com.aurora.browser</g' "$PLIST" 2>/dev/null || true
    fi
    ;;

  MINGW*|MSYS*|CYGWIN*)
    BUILT_BIN=$(find "$BUILD_DIR" -name "ladybird.exe" -type f 2>/dev/null | head -n1)
    if [ -z "$BUILT_BIN" ]; then
      echo "ERROR: Could not find built ladybird.exe."
      exit 1
    fi
    BUILT_DIR=$(dirname "$BUILT_BIN")
    cp -R "$BUILT_DIR"/* "$INSTALL_DIR/"
    cp "$BUILT_BIN" "$INSTALL_DIR/aurora-browser.exe"
    ;;
esac

# Copy resources
cp "$ROOT/assets/icons/aurora.png" "$INSTALL_DIR/aurora.png" 2>/dev/null || true
echo "$VERSION" > "$INSTALL_DIR/version.txt"

echo "  Package created: $INSTALL_DIR"
