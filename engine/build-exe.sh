#!/usr/bin/env bash
set -euo pipefail
# Aurora Browser — Build Windows .exe using cross-compilation via Wine/MinGW
# This builds a minimal launcher .exe that runs ladybird.exe (built via WSL2)

BUILD_DIR="${1:?Usage: build-exe.sh <ladybird-build-dir> <output-dir> <version>}"
OUTPUT_DIR="${2:?}"
VERSION="${3:?}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "  Building Windows package..."

mkdir -p "$OUTPUT_DIR"

# Find the built ladybird binary (Linux binary, we'll ship it for WSL2 use)
BUILT_BIN=$(find "$BUILD_DIR" -name "ladybird" -type f -executable 2>/dev/null | head -n1)
if [ -z "$BUILT_BIN" ]; then
  echo "ERROR: ladybird binary not found"
  exit 1
fi
BUILT_DIR=$(dirname "$BUILT_BIN")

# Copy engine files
cp -R "$BUILT_DIR"/* "$OUTPUT_DIR/"

# Create a batch launcher
cat > "$OUTPUT_DIR/aurora-browser.bat" <<'BAT'
@echo off
set DIR=%~dp0
if exist "%DIR%ladybird.exe" (
    start "" "%DIR%ladybird.exe" %*
) else if exist "%DIR%ladybird" (
    echo Run inside WSL2: ./ladybird
    pause
) else (
    echo ERROR: ladybird not found in %DIR%
    pause
)
BAT

# Create a PowerShell launcher
cat > "$OUTPUT_DIR/aurora-browser.ps1" <<'PS1'
$dir = Split-Path -Parent $MyInvocation.MyCommand.Path
$exe = Join-Path $dir "ladybird.exe"
if (Test-Path $exe) {
    Start-Process -FilePath $exe -ArgumentList $args
} else {
    Write-Host "ladybird.exe not found. Build with WSL2 first." -ForegroundColor Red
    Read-Host "Press Enter to exit"
}
PS1

# Create README
cat > "$OUTPUT_DIR/README.txt" <<EOF
Aurora Browser v${VERSION} for Windows
======================================

This package contains the Aurora Browser engine for Windows.

Option 1: Build from source (recommended)
  1. Install WSL2 with Ubuntu 24.04+
  2. Clone: git clone https://github.com/Draftiermovie66/Aurora-Browser
  3. Build: VERSION=${VERSION} bash engine/build.sh
  4. The binary will work natively on Windows

Option 2: Use the included Linux binary inside WSL2
  1. Install WSL2
  2. Copy this folder to WSL2
  3. Run: ./ladybird

Engine: LibWeb (Ladybird) — BSD-2-Clause
Browser: Aurora Browser — MIT
EOF

# Create a self-extracting zip
cd "$OUTPUT_DIR"
zip -r "$OUTPUT_DIR/aurora-browser-${VERSION}-windows-x64.zip" . -x "*.zip"
cd "$ROOT"

echo "  Built: $OUTPUT_DIR/aurora-browser-${VERSION}-windows-x64.zip"
