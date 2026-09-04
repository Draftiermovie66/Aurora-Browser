#!/usr/bin/env bash
# Deprecated shim — canonical: packages/linux/debian/build.sh
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
exec bash "$DIR/../../packages/linux/debian/build.sh" "$@"
