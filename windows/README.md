# Aurora Browser for Windows

## Quick Start

1. **Download Chromium** — Run `update.ps1` in PowerShell to automatically download the latest Chromium snapshot.

2. **Launch** — Double-click `launch-aurora.bat` to start Aurora Browser.

3. **Auto-update** — `update.ps1` checks GitHub releases (and falls back to Chromium snapshots). Run it manually or via a scheduled task.

## Manual Setup

1. Download `chrome-win.zip` from [Chromium snapshots](https://commondatastorage.googleapis.com/chromium-browser-snapshots/index.html?prefix=Win_x64/)
2. Extract `chrome-win/` into the same directory as `launch-aurora.bat`
3. Run `launch-aurora.bat`

## Directory Structure

```
aurora-browser/
  chrome-win/           # Chromium engine (downloaded via update.ps1)
  chrome-win.old/       # Backup from last update
  extension/            # Custom new tab page
  profile/              # User data (cookies, history, etc.)
  launch-aurora.bat     # Launcher
  update.ps1            # Update script
  version.txt           # Current version tracking
```

## Scheduled Auto-Updates

To check for updates daily, create a scheduled task:

```powershell
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -File `"$env:USERPROFILE\aurora-browser\update.ps1`" --quiet"
$trigger = New-ScheduledTaskTrigger -Daily -At 10am
Register-ScheduledTask -TaskName "Aurora Browser Update" -Action $action -Trigger $trigger
```

## Building from Source

Run `build-windows.ps1` to create a distributable package:

```powershell
.\windows\build-windows.ps1 -version "1.1.0"
```
