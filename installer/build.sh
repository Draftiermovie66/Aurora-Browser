#!/usr/bin/env bash
set -euo pipefail
# Aurora Browser — Installer Builder
# Builds the native Qt installer with embedded Aurora Browser payload.

DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$DIR/.." && pwd)"

if [ -z "${VERSION:-}" ] && [ -f "$ROOT/VERSION" ]; then
  VERSION="$(cat "$ROOT/VERSION")"
fi
VERSION="${VERSION:-3.0.0}"

echo "==> Building Aurora Browser installer (version $VERSION) ..."

# Detect the target platform
PLAT=""
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*) PLAT="windows-x86_64" ;;
  Darwin)                PLAT="macos-$(uname -m)" ;;
  *)                     PLAT="linux-$(uname -m)" ;;
esac

WORK=$(mktemp -d)
PAYLOAD="$WORK/payload"
trap 'rm -rf "$WORK"' EXIT

mkdir -p "$PAYLOAD/linux" \
         "$PAYLOAD/macos" \
         "$PAYLOAD/extension/dist"

ICON_SRC="$ROOT/assets/icons/aurora.png"
[ -f "$ICON_SRC" ] || ICON_SRC="$ROOT/aurora.png"

echo "$VERSION" > "$PAYLOAD/VERSION"
cp "$ICON_SRC" "$PAYLOAD/aurora.png" 2>/dev/null || true

# Copy the new-tab page into the payload
if [ -d "$ROOT/engine/newtab" ]; then
  cp -r "$ROOT/engine/newtab" "$PAYLOAD/newtab"
fi

# Linux launcher script (Ladybird-based)
cat > "$PAYLOAD/linux/aurora-browser" <<'LAUNCH'
#!/bin/bash
DIR="$(cd "$(dirname "$0")" && pwd)"
ENGINE="$DIR/ladybird"
if [ ! -x "$ENGINE" ]; then
  echo "ERROR: ladybird binary not found in $DIR" >&2
  exit 1
fi
exec "$ENGINE" "$@"
LAUNCH
chmod +x "$PAYLOAD/linux/aurora-browser"

# macOS app bundle skeleton
mkdir -p "$PAYLOAD/Aurora Browser.app/Contents/MacOS" \
         "$PAYLOAD/Aurora Browser.app/Contents/Resources"

cat > "$PAYLOAD/Aurora Browser.app/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key>
  <string>Aurora Browser</string>
  <key>CFBundleDisplayName</key>
  <string>Aurora Browser</string>
  <key>CFBundleIdentifier</key>
  <string>com.aurora.browser</string>
  <key>CFBundleVersion</key>
  <string>${VERSION}</string>
  <key>CFBundleShortVersionString</key>
  <string>${VERSION}</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleExecutable</key>
  <string>ladybird</string>
  <key>LSMinimumSystemVersion</key>
  <string>12.0</string>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
PLIST

# Zip the payload
python3 - "$PAYLOAD" "$WORK/payload.zip" <<'PY'
import os, sys, zipfile
src, out = sys.argv[1], sys.argv[2]
def add(z, base, rel):
    p = os.path.join(base, rel)
    if os.path.isdir(p):
        zi = zipfile.ZipInfo.from_file(p, rel + "/")
        zi.compress_type = zipfile.ZIP_DEFLATED
        z.writestr(zi, b"")
        for name in sorted(os.listdir(p)):
            add(z, base, os.path.join(rel, name))
    else:
        st = os.stat(p)
        zi = zipfile.ZipInfo.from_file(p, rel)
        zi.external_attr = (st.st_mode & 0xFFFF) << 16
        zi.compress_type = zipfile.ZIP_DEFLATED
        with open(p, "rb") as f:
            z.writestr(zi, f.read())
with zipfile.ZipFile(out, "w") as z:
    z.comment = b"Aurora Browser installer payload"
    add(z, src, "")
PY

# Build the C++ installer binary
BUILD_DIR="$ROOT/build/installer-cmake"
rm -rf "$BUILD_DIR"
mkdir -p "$ROOT/build"

build_cmake_args=()
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*)
    build_cmake_args=(-G "Visual Studio 17 2022" -A x64)
    ;;
  *)
    build_cmake_args=(-G Ninja)
    ;;
esac

cmake -S "$DIR" -B "$BUILD_DIR" "${build_cmake_args[@]}" -DCMAKE_BUILD_TYPE=Release
cmake --build "$BUILD_DIR" --config Release

# Locate the produced binary
EXT=""
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*) EXT=".exe" ;;
esac
BIN=$(find "$BUILD_DIR" -maxdepth 2 -type f -name "aurora-installer${EXT}" | head -n1)
if [ -z "$BIN" ]; then
  echo "ERROR: cmake did not produce aurora-installer${EXT}"
  echo "Build dir contents:"
  find "$BUILD_DIR" -type f | head -20
  exit 1
fi

echo "==> Embedding payload ..."
OUT="$ROOT/build/aurora-installer-${VERSION}-${PLAT}${EXT}"

python3 - "$BIN" "$WORK/payload.zip" "$VERSION" "$OUT" <<'PY'
import struct, sys, shutil
binpath, zippath, version, out = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
with open(zippath, "rb") as f:
    zipsize = f.seek(0, 2)
ver = version.encode("utf-8")
if len(ver) > 31:
    ver = ver[:31]
ver_bytes = ver.ljust(32, b"\0")
footer = struct.pack("<q", zipsize) + b"AURPAYLD" + ver_bytes + b"DLYAPRUA"
with open(binpath, "rb") as src, open(out, "wb") as dst:
    shutil.copyfileobj(src, dst)
    with open(zippath, "rb") as z:
        shutil.copyfileobj(z, dst)
    dst.write(footer)
PY
chmod +x "$OUT"

echo "==> Verify embedded payload ..."
"$OUT" --version || true

echo "==> Built: $OUT"
echo "    Run with: $OUT --help"
