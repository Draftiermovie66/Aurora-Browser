# Deprecated shim — canonical: packages/windows/build.ps1
param([string]$version = "")
$ROOT = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$target = Join-Path $ROOT "packages/windows/build.ps1"
if (Test-Path $target) {
  & $target -version $version @args
} else {
  Write-Error "Canonical build script not found at $target"
  exit 1
}
