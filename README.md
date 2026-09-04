# Aurora Browser

A custom Aurora-based browser with a self-contained profile, auto-update, and a polished new tab page.

## Project Structure

```
Aurora-Browser/
├── extension/             # Shared browser extension (new tab page, manifest)
├── linux/                 # Linux-specific build, launch, and update scripts
│   ├── build.sh           # Builds the .deb package
│   ├── launch.sh          # Linux launcher script
│   ├── update.sh          # Engine update script
│   ├── update.conf        # Update configuration
│   └── setup-sandbox.sh   # Sandbox permissions
├── windows/               # Windows-specific build, launch, and update scripts
│   ├── build.ps1          # Builds the Windows package
│   ├── launch.c           # C# source for the .exe launcher
│   ├── update.ps1         # Chromium update script
│   └── src/               # Source code for the .exe launcher
├── build.sh               # Root build script (delegates to linux/ or windows/)
├── release.sh             # GitHub release automation
├── aurora.png             # Browser icon
└── README.md
```

## Install (Linux)

```bash
sudo dpkg -i aurora-browser_1.1.1_amd64.deb
```

The browser engine is downloaded automatically during installation.

## Usage

- **App menu**: search "Aurora Browser"
- **Terminal**: `aurora-browser`

All cookies, history, and extensions are stored in `/opt/aurora-browser/profile/`.

## Install (Windows)

1. Extract the release zip
2. Run `update.ps1` in PowerShell to download the Aurora engine
3. Launch with `aurora-browser.exe`

## Updating

The browser checks for updates once per day in the background. To force a check:

**Linux:**
```bash
sudo /opt/aurora-browser/update.sh
```

**Windows:**
```powershell
.\update.ps1
```

Updates are pulled from [GitHub releases](https://github.com/Draftiermovie66/Aurora-Browser/releases) or fall back to the latest engine snapshot.

## Build from Source

**Linux:**
```bash
sudo apt install dpkg-dev fakeroot
./build.sh deb
sudo dpkg -i aurora-browser_*.deb
```

**Windows:**
```powershell
.\build.sh windows
```

## License

MIT
