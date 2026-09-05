#!/usr/bin/env bash
set -euo pipefail
# Aurora Browser — Generate SHA256 checksums for release assets

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="${1:-$ROOT/build}"
VERSION="${2:-$(cat "$ROOT/VERSION" 2>/dev/null || echo 'dev')}"
OUTPUT="$BUILD_DIR/checksums-SHA256-${VERSION}.txt"

echo "# Aurora Browser v${VERSION} — SHA256 Checksums" > "$OUTPUT"
echo "# Generated: $(date -u '+%Y-%m-%d %H:%M:%S UTC')" >> "$OUTPUT"
echo "#" >> "$OUTPUT"
echo "" >> "$OUTPUT"

find "$BUILD_DIR" -maxdepth 2 -type f \
  \( -name "*.exe" -o -name "*.dmg" -o -name "*.deb" -o -name "*.rpm" \
     -o -name "*.AppImage" -o -name "*.tar.*" -o -name "*.zip" \
     -o -name "*.app" -o -name "aurora-browser" \) | sort | while read -r f; do
  # Skip directories and checksum files
  [ -f "$f" ] || continue
  case "$f" in *checksums*) continue ;; esac

  if command -v sha256sum >/dev/null 2>&1; then
    hash=$(sha256sum "$f" | cut -d' ' -f1)
  elif command -v shasum >/dev/null 2>&1; then
    hash=$(shasum -a 256 "$f" | cut -d' ' -f1)
  else
    hash="NO_TOOL"
  fi
  echo "$hash  $(basename "$f")" >> "$OUTPUT"
done

echo "Checksums: $OUTPUT"
cat "$OUTPUT"
