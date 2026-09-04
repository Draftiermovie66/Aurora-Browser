#!/usr/bin/env bash
# Aurora Browser — root shim (delegates to scripts/build/build.sh)
# Kept for backwards compatibility; canonical location is scripts/build/build.sh
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
exec bash "$DIR/scripts/build/build.sh" "$@"
