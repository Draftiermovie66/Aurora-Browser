#!/usr/bin/env bash
# Deprecated shim — canonical: packages/macos/build.sh
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
exec bash "$DIR/../packages/macos/build.sh" "$@"
