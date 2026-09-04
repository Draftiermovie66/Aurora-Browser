#!/usr/bin/env bash
# Deprecated shim — canonical: packages/linux/appimage/build.sh
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
exec bash "$DIR/../../packages/linux/appimage/build.sh" "$@"
