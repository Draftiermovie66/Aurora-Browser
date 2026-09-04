#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$DIR/.." && pwd)"

VERSION="${VERSION:-2.0.1}"

echo "=========================================="
echo " Aurora Browser BETA (macOS) ${VERSION}"
echo "=========================================="
echo ""

# macOS engine note
cat <<'NOTE'

  Aurora Browser for macOS is currently in BETA.
  - The Chromium engine for macOS (chrome-mac) is downloaded via update.sh
  - Packaging produces a .app bundle and a .dmg installer
  - Architecture: arm64 (Apple Silicon) and x86_64 via universal2

NOTE

cleanup() { rm -rf "$TMP"; }
TMP=$(mktemp -d)
trap cleanup EXIT

# Build React extension if node_modules exists
if [ -d "$ROOT/extension/node_modules" ]; then
  echo "==> Building React extension ..."
  (cd "$ROOT/extension" && npm run build)
fi

# Create <dist>/Aurora Browser.app structure
DIST="$ROOT/build/macos"
APP="$DIST/Aurora Browser.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" \
         "$APP/Contents/Resources/extension" \
         "$APP/Contents/Resources/profile"

# Info.plist
cat > "$APP/Contents/Info.plist" <<PLIST
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
  <string>${VERSION} BETA</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleExecutable</key>
  <string>launch-aurora</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>LSMinimumSystemVersion</key>
  <string>11.0</string>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
PLIST

# macOS launcher (shell script that runs the engine)
cat > "$APP/Contents/MacOS/launch-aurora" <<'LAUNCH'
#!/bin/bash
DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$DIR/../"
RES="$ROOT/Resources"
ENGINE="$ROOT/chrome-mac/Google Chrome for Testing.app/Contents/MacOS/Google Chrome for Testing"
if [ ! -f "$ENGINE" ]; then
  ENGINE="$ROOT/chrome-mac/chrome"
fi
PROFILE="$RES/profile"
EXT="$RES/extension"

# Auto-update check (once per day)
UPDATE_CHECK="$PROFILE/.last-update-check"
if [ ! -f "$UPDATE_CHECK" ] || [ "$(find "$UPDATE_CHECK" -mtime +0)" ]; then
  touch "$UPDATE_CHECK"
  "$RES/update.sh" --quiet >/dev/null 2>&1 &
fi

FLAGS=(
  "--user-data-dir=$PROFILE"
  "--load-extension=$EXT"
  "--no-first-run"
  "--disable-features=TranslateUI"
)
exec "$ENGINE" "${FLAGS[@]}" "$@"
LAUNCH
chmod +x "$APP/Contents/MacOS/launch-aurora"

# Copy extension
cp -r "$ROOT/extension/"* "$APP/Contents/Resources/extension/"
cp "$ROOT/aurora.png" "$APP/Contents/Resources/aurora.png"

# version + update config
echo "CHROMIUM_VERSION=0" > "$APP/Contents/Resources/version.txt"
echo 'REPO="Draftiermovie66/Aurora-Browser"' > "$APP/Contents/Resources/update.conf"
cp "$DIR/update.sh" "$APP/Contents/Resources/update.sh"
chmod +x "$APP/Contents/Resources/update.sh"

# Create icon from aurora.png (simple: copy; real .icns requires iconutil on macOS)
cp "$ROOT/aurora.png" "$APP/Contents/Resources/AppIcon.png"

# Create a launch command symlink in /usr/local/bin equivalent
echo "==> App bundle created: $APP"

# Create .dmg (requires hdiutil, only available on macOS)
if command -v hdiutil >/dev/null 2>&1; then
  echo "==> Creating DMG ..."
  DMG="$ROOT/build/Aurora-Browser-${VERSION}-BETA.dmg"
  STAGE="$TMP/dmg"
  mkdir -p "$STAGE"
  cp -R "$APP" "$STAGE/"
  ln -s /Applications "$STAGE/Applications"
  hdiutil create -volname "Aurora Browser" \
    -srcfolder "$STAGE" -ov -format UDZO "$DMG"
  echo "==> DMG: $DMG"
else
  echo "==> hdiutil not available (must run on macOS). Skipping .dmg creation."
  echo "    The .app bundle is ready at: $APP"
fi

echo ""
echo "==> macOS BETA build complete (version $VERSION)"
