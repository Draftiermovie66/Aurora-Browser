#!/usr/bin/env bash
# Deprecated shim — canonical: packages/linux/redhat/build.sh
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
exec bash "$DIR/../../packages/linux/redhat/build.sh" "$@"
