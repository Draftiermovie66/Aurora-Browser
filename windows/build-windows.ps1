param(
  [string]$version = "1.1.0"
)

$ROOT = Split-Path -Parent $Split-Path -Parent $MyInvocation.MyCommand.Path
$BUILD = Join-Path $ROOT "build\aurora-browser-$version-win"

Write-Host "Building Aurora Browser $version for Windows..."

if (Test-Path $BUILD) { Remove-Item -Recurse -Force $BUILD }
New-Item -ItemType Directory -Force -Path $BUILD | Out-Null

# Copy extension
$EXT_SRC = Join-Path $ROOT "extension"
$EXT_DST = Join-Path $BUILD "extension"
Copy-Item -Recurse -Path $EXT_SRC -Destination $EXT_DST

# Copy config and scripts to root
@"
# GitHub repository for Aurora Browser updates
# Format: OWNER/REPO
REPO="Draftiermovie66/Aurora-Browser"
"@ | Out-File -FilePath (Join-Path $BUILD "update.conf") -Encoding ascii

Copy-Item -Path (Join-Path $ROOT "update.ps1") -Destination (Join-Path $BUILD "update.ps1")
Copy-Item -Path (Join-Path $ROOT "launch-aurora.bat") -Destination (Join-Path $BUILD "launch-aurora.bat")

# Copy logo
$LOGO = Join-Path $ROOT "aurora.png"
if (Test-Path $LOGO) {
  Copy-Item -Path $LOGO -Destination (Join-Path $BUILD "aurora.png")
}

# Create version file
"CHROMIUM_VERSION=0" | Out-File -FilePath (Join-Path $BUILD "version.txt") -Encoding ascii

# Create profile directory placeholder
New-Item -ItemType Directory -Force -Path (Join-Path $BUILD "profile") | Out-Null

# Create README
@"
Aurora Browser $version for Windows
====================================

1. Download a Chromium snapshot (chrome-win.zip) from
   https://www.chromium.org/getting-involved/download-chromium/
   or run update.ps1 to download the latest automatically.

2. Extract chrome-win/ into this directory so you have:
   aurora-browser-$version-win/
     chrome-win/chrome.exe
     extension/
     launch-aurora.bat
     update.ps1

3. Run launch-aurora.bat to start Aurora Browser.

4. For auto-updates, run update.ps1 periodically.
"@ | Out-File -FilePath (Join-Path $BUILD "README.txt") -Encoding ascii

Write-Host "Build complete: $BUILD"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Place chrome-win/ in the build directory"
Write-Host "  2. Zip the folder and distribute"
