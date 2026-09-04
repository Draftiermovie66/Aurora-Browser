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

ENGINE_VER="$(sed -n 's/^CHROMIUM_VERSION=//p' "$RES/version.txt" 2>/dev/null)"
[ -z "$ENGINE_VER" ] && ENGINE_VER="152.0.0.0"
AURORA_UA="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/${ENGINE_VER} Safari/537.36 AuroraBrowser/${ENGINE_VER%%.*}"

# Default to the Aurora new tab page when launching without a URL.
if [ $# -eq 0 ]; then
  set -- "chrome://newtab"
fi

FLAGS=(
  "--user-data-dir=$PROFILE"
  "--load-extension=$EXT"
  "--no-first-run"
  "--disable-features=TranslateUI"
  "--disable-background-networking"
  "--disable-component-update"
  "--user-agent=$AURORA_UA"
)
exec "$ENGINE" "${FLAGS[@]}" "$@"
LAUNCH
chmod +x "$APP/Contents/MacOS/launch-aurora"

# Copy extension (exclude node_modules: dev-only build deps)
rsync -a --exclude 'node_modules' "$ROOT/extension/" "$APP/Contents/Resources/extension/"
cp "$ROOT/aurora.png" "$APP/Contents/Resources/aurora.png"

# version + update config
echo "CHROMIUM_VERSION=0" > "$APP/Contents/Resources/version.txt"
echo 'REPO="Draftiermovie66/Aurora-Browser"' > "$APP/Contents/Resources/update.conf"
cp "$DIR/update.sh" "$APP/Contents/Resources/update.sh"
chmod +x "$APP/Contents/Resources/update.sh"

# Generate a real .icns from aurora.png using iconutil (macOS only).
ICONSET="$TMP/AppIcon.iconset"
mkdir -p "$ICONSET"
for size in 16 32 64 128 256 512; do
  s2=$((size * 2))
  sfile="$ICONSET/icon_${size}x${size}.png"
  s2file="$ICONSET/icon_${size}x${size}@2x.png"
  if command -v sips >/dev/null 2>&1; then
    sips -z "$size" "$size" "$ROOT/aurora.png" --out "$sfile" >/dev/null 2>&1
    [ "$size" -le 256 ] && sips -z "$s2" "$s2" "$ROOT/aurora.png" --out "$s2file" >/dev/null 2>&1
  else
    # Fallback: just drop the source PNG (imperfect, but keeps the build going)
    cp "$ROOT/aurora.png" "$sfile"
  fi
done
if command -v iconutil >/dev/null 2>&1; then
  iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"
else
  cp "$ROOT/aurora.png" "$APP/Contents/Resources/AppIcon.png"
fi

echo "==> App bundle created: $APP"

# ---- Code signing ----
# CODESIGN_IDENTITY: set to a Developer ID certificate name ("Developer ID
# Application: ...") for full signing+notarization. If unset, ad-hoc sign
# ("-") which removes the "damaged" prompt on Apple Silicon / quarantine.
codesign_app() {
  local identity="${CODESIGN_IDENTITY:--}"
  echo "==> Code signing with identity: $identity"
  # Remove quarantine attribute the browser engine may carry after download.
  xattr -dr com.apple.quarantine "$APP" 2>/dev/null || true
  codesign --force --deep --sign "$identity" \
    --options runtime \
    --entitlements "$DIR/entitlements.plist" \
    "$APP" 2>/dev/null \
  || codesign --force --deep --sign "$identity" "$APP"
  codesign --verify --deep --strict "$APP" 2>&1 | sed 's/^/    /'
}

codesign_app

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

  # ---- Notarization (only when credentials are provided) ----
  # Use Xcode notarytool for macOS 12+/Xcode 13+. Requires:
  #   AC_USERNAME   Apple ID
  #   AC_PASSWORD   app-specific password
  #   AC_TEAM_ID    Apple Developer team ID
  # Optionally override with NOTARY_PROFILE (-p profile).
  if [ -n "${AC_USERNAME:-}" ] || [ -n "${NOTARY_PROFILE:-}" ]; then
    echo "==> Submitting DMG for notarization ..."
    NOTARY_ARGS=(notarytool submit "$DMG" --wait --output-format json)
    if [ -n "${NOTARY_PROFILE:-}" ]; then
      NOTARY_ARGS=("${NOTARY_ARGS[@]}" --keychain-profile "$NOTARY_PROFILE")
    else
      NOTARY_ARGS=("${NOTARY_ARGS[@]}" \
        --apple-id "$AC_USERNAME" \
        --password "$AC_PASSWORD" \
        --team-id "${AC_TEAM_ID:-}")
    fi
    if xcrun "${NOTARY_ARGS[@]}"; then
      echo "==> Notarization approved; stapling ticket ..."
      xcrun stapler staple "$DMG"
      xcrun stapler validate "$DMG"
    else
      echo "!! Notarization failed — DMG remains unsigned/unstapled."
    fi
  else
    echo "==> Skipping notarization (set AC_USERNAME/AC_PASSWORD/TEAM_ID or NOTARY_PROFILE)."
  fi
else
  echo "==> hdiutil not available (must run on macOS). Skipping .dmg creation."
  echo "    The .app bundle is ready at: $APP"
fi

echo ""
echo "==> macOS BETA build complete (version $VERSION)"
