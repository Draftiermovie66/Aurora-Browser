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

# Portable sed in-place edit (works on both Linux and macOS)
sed_inplace() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "$@"
  else
    sed -i "$@"
  fi
}

# ---- CMakeLists.txt — Rename project ----
CMAKE="$LADYBIRD_DIR/CMakeLists.txt"
if [ -f "$CMAKE" ]; then
  sed_inplace 's/project(ladybird /project(aurora-browser /g' "$CMAKE"
  sed_inplace 's/set(LADYBIRD_VENDOR ".*")/set(LADYBIRD_VENDOR "Aurora Browser")/g' "$CMAKE" || true
fi

# ---- App name in UI ----
QT_MAIN="$LADYBIRD_DIR/UI/Qt/MainWidget.cpp"
if [ -f "$QT_MAIN" ]; then
  sed_inplace 's/"Ladybird"/"Aurora Browser"/g' "$QT_MAIN"
fi

APPKIT_MAIN="$LADYBIRD_DIR/UI/AppKit/main.mm"
if [ -f "$APPKIT_MAIN" ]; then
  sed_inplace 's/@"Ladybird"/@"Aurora Browser"/g' "$APPKIT_MAIN"
fi

# ---- Default new tab URL ----
SETTINGS="$LADYBIRD_DIR/UI/Qt/Settings.cpp"
if [ -f "$SETTINGS" ]; then
  sed_inplace 's|about:blank|about:blank|g' "$SETTINGS" || true
fi

# ---- Icons ----
AURORA_ICON="$ROOT/assets/icons/aurora.png"
if [ -f "$AURORA_ICON" ]; then
  RES_DIR="$LADYBIRD_DIR/Base/res"
  if [ -d "$RES_DIR" ]; then
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
  sed_inplace 's/Ladybird/Aurora Browser/g' "$ABOUT"
  sed_inplace 's/Andreas Kling/Aurora Browser Team/g' "$ABOUT" || true
fi

echo "  Branding applied."
