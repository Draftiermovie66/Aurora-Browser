#!/usr/bin/env bash
set -euo pipefail
# Aurora Browser — Cross-platform code signing
# Signs executables with osslsigncode (Linux/macOS) or signtool (Windows).
# Requires: osslsigncode (cross-platform) or Windows SDK signtool.

DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$DIR/.." && pwd)"

SIGN_CERT="${AURORA_SIGN_CERT:-}"
SIGN_PASS="${AURORA_SIGN_PASS:-}"
SIGN_TIMESTAMP="${AURORA_SIGN_TIMESTAMP:-http://timestamp.digicert.com}"

if [ -z "$SIGN_CERT" ]; then
  echo "WARNING: No signing certificate set. Skipping code signing."
  echo "Set AURORA_SIGN_CERT=path/to/cert.pfx and AURORA_SIGN_PASS=password"
  exit 0
fi

if [ ! -f "$SIGN_CERT" ]; then
  echo "ERROR: Certificate file not found: $SIGN_CERT"
  exit 1
fi

# Find files to sign
find_signables() {
  local dir="$1"
  find "$dir" -type f \( -name "*.exe" -o -name "*.dll" -o -name "*.dylib" -o -name "*.so" \) 2>/dev/null
}

sign_file() {
  local file="$1"
  echo "  Signing: $(basename "$file")"

  if command -v osslsigncode >/dev/null 2>&1; then
    local tmpout="${file}.signed"
    echo "$SIGN_PASS" | osslsigncode sign \
      -pkcs12 "$SIGN_CERT" \
      -readpass /dev/stdin \
      -h sha256 \
      -n "Aurora Browser" \
      -i "https://github.com/Draftiermovie66/Aurora-Browser" \
      -t "$SIGN_TIMESTAMP" \
      -in "$file" \
      -out "$tmpout" 2>/dev/null
    if [ -f "$tmpout" ]; then
      mv "$tmpout" "$file"
      chmod +x "$file"
    fi
  elif command -v signtool >/dev/null 2>&1; then
    signtool sign /f "$SIGN_CERT" /p "$SIGN_PASS" \
      /fd sha256 /tr "$SIGN_TIMESTAMP" /td sha256 \
      "$file" 2>/dev/null
  else
    echo "WARNING: No signing tool found (osslsigncode or signtool)."
    echo "Install osslsigncode: sudo apt install osslsigncode"
    return 1
  fi
}

verify_signature() {
  local file="$1"
  if command -v osslsigncode >/dev/null 2>&1; then
    osslsigncode verify "$file" 2>/dev/null && echo "  Verified: OK" || echo "  Verified: FAILED"
  elif command -v signtool >/dev/null 2>&1; then
    signtool verify /pa "$file" 2>/dev/null && echo "  Verified: OK" || echo "  Verified: FAILED"
  fi
}

# Generate SHA256 checksums
generate_checksums() {
  local dir="$1"
  local outfile="$2"
  echo "# Aurora Browser $3 — SHA256 Checksums" > "$outfile"
  echo "# Generated: $(date -u '+%Y-%m-%d %H:%M:%S UTC')" >> "$outfile"
  echo "" >> "$outfile"
  find "$dir" -type f \( -name "*.exe" -o -name "*.dmg" -o -name "*.deb" -o -name "*.rpm" \
    -o -name "*.AppImage" -o -name "*.tar.*" -o -name "*.zip" \) | sort | while read -r f; do
    local hash
    if command -v sha256sum >/dev/null 2>&1; then
      hash=$(sha256sum "$f" | cut -d' ' -f1)
    elif command -v shasum >/dev/null 2>&1; then
      hash=$(shasum -a 256 "$f" | cut -d' ' -f1)
    else
      hash="UNKNOWN"
    fi
    echo "$hash  $(basename "$f")" >> "$outfile"
  done
  echo "Checksums written to: $outfile"
}

# ---- Main ----
TARGET_DIR="${1:-$ROOT/build}"
VERSION="${2:-$(cat "$ROOT/VERSION" 2>/dev/null || echo 'dev')}"

echo "==> Signing executables in $TARGET_DIR ..."
find_signables "$TARGET_DIR" | while read -r f; do
  sign_file "$f" || true
done

echo ""
echo "==> Verifying signatures..."
find_signables "$TARGET_DIR" | while read -r f; do
  verify_signature "$f" || true
done

echo ""
echo "==> Generating SHA256 checksums..."
CHECKSUM_FILE="$ROOT/build/checksums-SHA256-${VERSION}.txt"
generate_checksums "$TARGET_DIR" "$CHECKSUM_FILE" "$VERSION"

echo ""
echo "==> Code signing complete."
