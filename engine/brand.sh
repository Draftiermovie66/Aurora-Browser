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

# Portable in-place edit using perl (works on Linux and macOS)
replace() {
  local pattern="$1"
  local file="$2"
  if [ -f "$file" ]; then
    perl -pi -e "$pattern" "$file"
  fi
}

# ---- CMakeLists.txt — Rename project ----
replace 's/project\(ladybird /project(aurora-browser /g' "$LADYBIRD_DIR/CMakeLists.txt"
replace 's/set\(LADYBIRD_VENDOR ".*"\)/set(LADYBIRD_VENDOR "Aurora Browser")/g' "$LADYBIRD_DIR/CMakeLists.txt"

# ---- App name in UI ----
replace 's/"Ladybird"/"Aurora Browser"/g' "$LADYBIRD_DIR/UI/Qt/MainWidget.cpp"

# AppKit title (macOS)
replace 's/@"Ladybird"/@"Aurora Browser"/g' "$LADYBIRD_DIR/UI/AppKit/main.mm"

# ---- Default new tab URL ----
replace 's|about:blank|about:blank|g' "$LADYBIRD_DIR/UI/Qt/Settings.cpp"

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
replace 's/Ladybird/Aurora Browser/g' "$LADYBIRD_DIR/UI/Qt/AboutDialog.cpp"
replace 's/Andreas Kling/Aurora Browser Team/g' "$LADYBIRD_DIR/UI/Qt/AboutDialog.cpp"

echo "  Branding applied."
