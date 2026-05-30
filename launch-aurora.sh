#!/usr/bin/env bash
DIR="$(cd "$(dirname "$0")" && pwd)"

# Background update check (once per day)
UPDATE_CHECK="$DIR/profile/.last-update-check"
if [ ! -f "$UPDATE_CHECK" ] || [ "$(find "$UPDATE_CHECK" -mtime +0)" ]; then
  touch "$UPDATE_CHECK"
  bash "$DIR/update.sh" --quiet >/dev/null 2>&1 &
fi

FLAGS=(
  --user-data-dir="$DIR/profile"
  --no-first-run
  --disable-features=TranslateUI
  --disable-setuid-sandbox
  --class=Aurora-Browser
)
exec "$DIR/chrome-linux/chrome" "${FLAGS[@]}" "$@"
