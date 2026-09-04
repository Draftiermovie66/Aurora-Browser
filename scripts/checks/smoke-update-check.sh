#!/usr/bin/env bash
# Smoke test for packages/linux/common/update.sh (with legacy fallback).
#
# Guards against the regression where update.sh silently aborted (via set -e)
# when the GitHub release has no chrome-linux asset, never reaching the
# Chrome-for-Testing fallback. This runs the real asset-resolution logic in
# --check mode (no download) and asserts a fallback URL/version is found.
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$DIR/../.." && pwd)"
# Canonical path, with fallback to legacy linux/ for backwards compat
UPDATE_SH="$ROOT/packages/linux/common/update.sh"
[ -f "$UPDATE_SH" ] || UPDATE_SH="$ROOT/linux/common/update.sh"

if [ ! -f "$UPDATE_SH" ]; then
  echo "FAIL: $UPDATE_SH not found"
  exit 1
fi

bash -n "$UPDATE_SH" || { echo "FAIL: $UPDATE_SH has a syntax error"; exit 1; }

# Run --check in a scratch INSTALL_DIR so we don't touch real data. The output
# is analyzed for evidence that it (a) did not abort on the missing asset and
# (b) resolved a Chrome-for-Testing fallback version.
SCRATCH=$(mktemp -d)
trap 'rm -rf "$SCRATCH"' EXIT

set +e
OUTPUT=$(INSTALL_DIR="$SCRATCH" bash "$UPDATE_SH" --check 2>&1)
STATUS=$?
set -e

echo "$OUTPUT"

if [ "$STATUS" -ne 0 ]; then
  echo "FAIL: update.sh --check exited with status $STATUS"
  echo "This likely means set -e aborted the script (asset-lookup regression)."
  exit 1
fi

# On a first run with no saved version, --check should report an available
# update (it must have fallen through to Chrome-for-Testing or snapshot).
if ! printf '%s' "$OUTPUT" | grep -qEi 'Update available|up to date'; then
  echo "FAIL: update.sh --check did not resolve an engine update."
  exit 1
fi

if printf '%s' "$OUTPUT" | grep -qE 'No chrome-linux asset in release; trying Chrome-for-Testing'; then
  echo "PASS: fell through to Chrome-for-Testing fallback (asset-lookup no longer aborts)."
else
  echo "PASS: engine update resolved (source may vary)."
fi

echo "SMOKE OK"
