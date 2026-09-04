param(
  [string]$version = ""
)

# Resolve repo ROOT (packages/windows → repo root needs 3 levels)
$ROOT = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
if (-not $version -or $version -eq "1.1.1") {
  $verFile = Join-Path $ROOT "VERSION"
  if (Test-Path $verFile) { $version = (Get-Content $verFile -Raw).Trim() }
  if (-not $version) { $version = "2.0.6" }
}

$BUILD = Join-Path $ROOT "build\aurora-browser-$version-win"

Write-Host "Building Aurora Browser $version for Windows..."

if (Test-Path $BUILD) { Remove-Item -Recurse -Force $BUILD }
New-Item -ItemType Directory -Force -Path $BUILD | Out-Null

# Copy extension (exclude node_modules: dev-only build deps, 60MB+)
$EXT_SRC = Join-Path $ROOT "extension"
$EXT_DST = Join-Path $BUILD "extension"
New-Item -ItemType Directory -Force -Path $EXT_DST | Out-Null
robocopy $EXT_SRC $EXT_DST /E /XD node_modules /NFL /NDL /NJH /NJS | Out-Null

# Copy config
@"
# GitHub repository for Aurora Browser updates
REPO="Draftiermovie66/Aurora-Browser"
"@ | Out-File -FilePath (Join-Path $BUILD "update.conf") -Encoding ascii

Copy-Item -Path (Join-Path $PSScriptRoot "update.ps1") -Destination (Join-Path $BUILD "update.ps1")

# Copy logo (new assets/ with fallback)
$LOGO = Join-Path $ROOT "assets\icons\aurora.png"
if (-not (Test-Path $LOGO)) { $LOGO = Join-Path $ROOT "aurora.png" }
if (Test-Path $LOGO) {
  Copy-Item -Path $LOGO -Destination (Join-Path $BUILD "aurora.png")
}

# Create version file
"CHROMIUM_VERSION=0" | Out-File -FilePath (Join-Path $BUILD "version.txt") -Encoding ascii

# Create profile directory placeholder
New-Item -ItemType Directory -Force -Path (Join-Path $BUILD "profile") | Out-Null

# Compile the .exe launcher
Write-Host "Compiling Aurora Browser launcher..."
$CS_SRC = Join-Path $PSScriptRoot "src\AuroraBrowser.cs"
$CS_OUT = Join-Path $BUILD "aurora-browser.exe"

# Try csc.exe first (available with .NET Framework on Windows)
$csc = $null
$framework = Join-Path $env:SystemRoot "Microsoft.NET\Framework64\v4.0.30319\csc.exe"
if (Test-Path $framework) { $csc = $framework }
$framework32 = Join-Path $env:SystemRoot "Microsoft.NET\Framework\v4.0.30319\csc.exe"
if (-not $csc -and (Test-Path $framework32)) { $csc = $framework32 }

if ($csc -and (Test-Path $CS_SRC)) {
  & $csc /nologo /out:"$CS_OUT" /target:winexe "$CS_SRC" 2>&1
  if (Test-Path $CS_OUT) {
    Write-Host "  Compiled: aurora-browser.exe"
  } else {
    Write-Host "  WARNING: csc compilation failed. Falling back to PowerShell launcher."
    $csc = $null
  }
}

# If csc failed, create a PowerShell-based launcher as fallback
if (-not (Test-Path $CS_OUT)) {
  $PS_OUT = Join-Path $BUILD "aurora-browser.exe"
  # Use a .ps1 wrapper with a VBS stub to run it silently
  $launcher = Join-Path $BUILD "launch-aurora.ps1"
  @"
`$dir = Split-Path -Parent `$MyInvocation.MyCommand.Path
`$chromeExe = Join-Path `$dir "chrome-win\chrome.exe"
`$profile = Join-Path `$dir "profile"
`$extension = Join-Path `$dir "extension"

if (-not (Test-Path `$chromeExe)) {
  Write-Host "chrome-win\chrome.exe not found. Run update.ps1 first." -ForegroundColor Red
  Read-Host "Press Enter to exit"
  exit 1
}

`$flags = @(
  "--user-data-dir=`$profile"
  "--no-first-run"
  "--disable-features=TranslateUI"
  "--load-extension=`$extension"
)
& `$chromeExe `$flags
"@ | Out-File -FilePath $launcher -Encoding ascii

  # Create VBScript wrapper to run .ps1 as a windowless exe-like experience
  $vbs = Join-Path $BUILD "Aurora Browser.vbs"
  @"
Set objShell = CreateObject("WScript.Shell")
objShell.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -File """ & CreateObject("Scripting.FileSystemObject").GetParentFolderName(WScript.ScriptFullName) & "\launch-aurora.ps1""", 0, False
"@ | Out-File -FilePath $vbs -Encoding ascii
  Write-Host "  Created launcher: Aurora Browser.vbs (double-click to launch)"
}

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
     aurora-browser.exe (or Aurora Browser.vbs)
     extension/
     update.ps1

3. Double-click aurora-browser.exe to start Aurora Browser.

4. For auto-updates, run update.ps1 periodically or set up a
   scheduled task.
"@ | Out-File -FilePath (Join-Path $BUILD "README.txt") -Encoding ascii

Write-Host ""
Write-Host "Build complete: $BUILD"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Place chrome-win/ in the build directory"
Write-Host "  2. Distribute aurora-browser.exe as the release asset"
