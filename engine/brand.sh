#!/usr/bin/env bash
set -euo pipefail
# Aurora Browser — Branding script for Ladybird fork
# Applies Aurora Browser branding to a Ladybird source tree.

DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$DIR/.." && pwd)"
LADYBIRD_DIR="${1:?Usage: brand.sh <ladybird-dir>}"

if [ -z "${VERSION:-}" ] && [ -f "$ROOT/VERSION" ]; then
  VERSION="$(cat "$ROOT/VERSION")"
fi
VERSION="${VERSION:-3.0.0}"

echo "  Branding Ladybird as Aurora Browser v${VERSION}..."

# ---- CMakeLists.txt — Rename project ----
CMAKE="$LADYBIRD_DIR/CMakeLists.txt"
if [ -f "$CMAKE" ]; then
  sed -i 's/project(ladybird /project(aurora-browser /g' "$CMAKE"
  sed -i 's/set(LADYBIRD_VENDOR ".*")/set(LADYBIRD_VENDOR "Aurora Browser")/g' "$CMAKE" || true
fi

# ---- App name in UI ----
# Qt UI window title
QT_MAIN="$LADYBIRD_DIR/UI/Qt/MainWidget.cpp"
if [ -f "$QT_MAIN" ]; then
  sed -i 's/"Ladybird"/"Aurora Browser"/g' "$QT_MAIN"
fi

# AppKit title (macOS)
APPKIT_MAIN="$LADYBIRD_DIR/UI/AppKit/main.mm"
if [ -f "$APPKIT_MAIN" ]; then
  sed -i 's/@"Ladybird"/@"Aurora Browser"/g' "$APPKIT_MAIN"
fi

# ---- Default new tab URL ----
# Set the default homepage to about:blank or a custom URL
SETTINGS="$LADYBIRD_DIR/UI/Qt/Settings.cpp"
if [ -f "$SETTINGS" ]; then
  # Override default new tab behavior
  sed -i 's|about:blank|about:blank|g' "$SETTINGS" || true
fi

# ---- Icons ----
# Copy Aurora icons to replace Ladybird defaults
AURORA_ICON="$ROOT/assets/icons/aurora.png"
if [ -f "$AURORA_ICON" ]; then
  # Replace app icons in Base/res/
  RES_DIR="$LADYBIRD_DIR/Base/res"
  if [ -d "$RES_DIR" ]; then
    # Find and replace icon files
    for icon in "$RES_DIR"/icons/*.png "$RES_DIR"/icons/**/*.png; do
      [ -f "$icon" ] || continue
      case "$(basename "$icon")" in
        *ladybird*|*browser*)
          cp "$AURORA_ICON" "$icon" 2>/dev/null || true
          ;;
      esac
    done
  fi
fi

# ---- Branding in about dialog ----
ABOUT="$LADYBIRD_DIR/UI/Qt/AboutDialog.cpp"
if [ -f "$ABOUT" ]; then
  sed -i 's/Ladybird/Aurora Browser/g' "$ABOUT"
  sed -i 's/Andreas Kling/Aurora Browser Team/g' "$ABOUT" || true
fi

echo "  Branding applied."
