param(
  [switch]$quiet = $false,
  [switch]$check = $false
)

function Log { if (-not $quiet) { Write-Host @args } }

$DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$CONFIG = Join-Path $DIR "update.conf"
$VERSION_FILE = Join-Path $DIR "version.txt"

$REPO = "Draftiermovie66/Aurora-Browser"

if (Test-Path $CONFIG) {
  Get-Content $CONFIG | ForEach-Object {
    if ($_ -match '^REPO="(.+)"') { $REPO = $Matches[1] }
  }
}

$CURRENT = ""
if (Test-Path $VERSION_FILE) {
  $content = Get-Content $VERSION_FILE
  $match = $content | Where-Object { $_ -match "CHROMIUM_VERSION=(.+)" }
  if ($match) { $CURRENT = $matches[1] }
}

$DOWNLOAD_URL = ""
$LATEST_TAG = ""

Log "Checking github.com/$REPO for updates ..."

try {
  $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$REPO/releases/latest" -ErrorAction Stop
  $LATEST_TAG = $release.tag_name
  Log "  Current version: $(if ($CURRENT) { $CURRENT } else { 'unknown' })"
  Log "  Latest release:  $LATEST_TAG"
  if ($LATEST_TAG -eq $CURRENT) { Log "Already up to date."; exit 0 }
  $asset = $release.assets | Where-Object { $_.name -like "*chrome-win*" }
  if ($asset) { $DOWNLOAD_URL = $asset.browser_download_url }
}
catch {
  Log "GitHub check failed, falling back to Chromium snapshot..."
}

if (-not $DOWNLOAD_URL) {
  try {
    $SNAPSHOT_REV = Invoke-RestMethod -Uri "https://www.googleapis.com/download/storage/v1/b/chromium-browser-snapshots/o/Win_x64%2FLAST_CHANGE?alt=media" -ErrorAction Stop
    if ($SNAPSHOT_REV -eq $CURRENT) { Log "Already up to date."; exit 0 }
    $LATEST_TAG = $SNAPSHOT_REV
    $DOWNLOAD_URL = "https://www.googleapis.com/download/storage/v1/b/chromium-browser-snapshots/o/Win_x64%2F${SNAPSHOT_REV}%2Fchrome-win.zip?alt=media"
  }
  catch {
    Log "Failed to fetch Chromium snapshot revision."
    exit 1
  }
}

if ($check) { Log "Update available: $LATEST_TAG"; exit 0 }

Log "Downloading $LATEST_TAG ..."
$ZIP = Join-Path $env:TEMP "aurora-update.zip"
Invoke-WebRequest -Uri $DOWNLOAD_URL -OutFile $ZIP

Log "Extracting ..."
$EXTRACT_DIR = Join-Path $env:TEMP "aurora-extracted"
if (Test-Path $EXTRACT_DIR) { Remove-Item -Recurse -Force $EXTRACT_DIR }
New-Item -ItemType Directory -Force -Path $EXTRACT_DIR | Out-Null
Expand-Archive -Path $ZIP -DestinationPath $EXTRACT_DIR -Force

$CHROME_DIR = Join-Path $EXTRACT_DIR "chrome-win"
if (-not (Test-Path $CHROME_DIR)) {
  Log "ERROR: chrome-win/ not found in the archive."
  Remove-Item -Force $ZIP
  Remove-Item -Recurse -Force $EXTRACT_DIR
  exit 1
}

Log "Applying update ..."
$OLD_DIR = Join-Path $DIR "chrome-win.old"
if (Test-Path $OLD_DIR) { Remove-Item -Recurse -Force $OLD_DIR }
$CURRENT_DIR = Join-Path $DIR "chrome-win"
if (Test-Path $CURRENT_DIR) { Move-Item -Path $CURRENT_DIR -Destination $OLD_DIR }
Move-Item -Path $CHROME_DIR -Destination $CURRENT_DIR

"CHROMIUM_VERSION=$LATEST_TAG" | Out-File -FilePath $VERSION_FILE -Encoding ascii

try {
  $chromeVer = & "$CURRENT_DIR\chrome.exe" --version 2>&1
  if ($chromeVer -match "(\d+\.\d+\.\d+\.\d+)") {
    "CHROME_VERSION=$($Matches[1])" | Out-File -FilePath $VERSION_FILE -Encoding ascii -Append
  }
}
catch {}

Log "Update complete: $LATEST_TAG"
Remove-Item -Force $ZIP
Remove-Item -Recurse -Force $EXTRACT_DIR
