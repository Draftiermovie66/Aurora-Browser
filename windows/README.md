# Aurora Browser for Windows

## Quick Start

1. **Download Engine** — Run `update.ps1` in PowerShell to automatically download the latest Aurora engine snapshot.

2. **Launch** — Double-click `aurora-browser.exe` to start Aurora Browser.

3. **Auto-update** — `update.ps1` checks GitHub releases (and falls back to engine snapshots). Run it manually or via a scheduled task.

## Manual Setup

1. Download `chrome-win.zip` from [engine snapshots](https://commondatastorage.googleapis.com/chromium-browser-snapshots/index.html?prefix=Win_x64/)
2. Extract `chrome-win/` into the same directory as `aurora-browser.exe`
3. Run `aurora-browser.exe`

## Directory Structure

```
aurora-browser/
  chrome-win/           # Engine (downloaded via update.ps1)
  chrome-win.old/       # Backup from last update
  aurora-browser.exe    # Launcher (compiled from C# source)
  extension/            # Custom new tab page
  profile/              # User data (cookies, history, etc.)
  update.ps1            # Update script
  version.txt           # Current version tracking
```

## Building the Launcher

The `.exe` launcher is compiled from `src/AuroraBrowser.cs` during the build process. To recompile manually:

```powershell
csc.exe /nologo /out:aurora-browser.exe /target:winexe src\AuroraBrowser.cs
```

## Scheduled Auto-Updates

To check for updates daily, create a scheduled task:

```powershell
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -File `"$env:USERPROFILE\aurora-browser\update.ps1`" --quiet"
$trigger = New-ScheduledTaskTrigger -Daily -At 10am
Register-ScheduledTask -TaskName "Aurora Browser Update" -Action $action -Trigger $trigger
```

## Building from Source

Run `build.ps1` to create a distributable package:

```powershell
.\windows\build.ps1 -version "1.1.1"
```