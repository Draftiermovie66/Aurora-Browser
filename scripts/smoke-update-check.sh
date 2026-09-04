#!/usr/bin/env bash
# Deprecated shim — canonical: scripts/checks/smoke-update-check.sh
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
exec bash "$DIR/checks/smoke-update-check.sh" "$@"
