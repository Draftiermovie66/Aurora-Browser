#!/usr/bin/env bash
DIR="$(cd "$(dirname "$0")" && pwd)"
UPDATE_CHECK="$DIR/profile/.last-update-check"
if [ ! -f "$UPDATE_CHECK" ] || [ "$(find "$UPDATE_CHECK" -mtime +0)" ]; then
  touch "$UPDATE_CHECK"
  bash "$DIR/update.sh" --quiet >/dev/null 2>&1 &
fi

# Branded user agent: keep the Chrome token for site compatibility but
# identify as Aurora Browser.
ENGINE_VER="$(sed -n 's/^CHROMIUM_VERSION=//p' "$DIR/version.txt" 2>/dev/null)"
[ -z "$ENGINE_VER" ] && ENGINE_VER="152.0.0.0"
AURORA_UA="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/${ENGINE_VER} Safari/537.36 AuroraBrowser/${ENGINE_VER%%.*}"

# Default to the Aurora new tab page when launching without a URL.
if [ $# -eq 0 ]; then
  set -- chrome://newtab
fi

FLAGS=(
  --user-data-dir="$DIR/profile"
  --no-first-run
  --disable-features=TranslateUI
  --disable-setuid-sandbox
  --disable-background-networking
  --disable-component-update
  --class=Aurora-Browser
  --user-agent="$AURORA_UA"
  --load-extension="$DIR/extension"
)
exec "$DIR/chrome-linux/chrome" "${FLAGS[@]}" "$@"
