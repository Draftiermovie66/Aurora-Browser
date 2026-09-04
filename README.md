# Aurora Browser

A custom Chromium-based browser with a self-contained profile, auto-update, a
polished new tab page, and packages for all major platforms.

## Project Structure

```
Aurora-Browser/
├── extension/             # Shared browser extension (React new tab page, manifest)
├── linux/                 # Linux packaging, organized by distro family
│   ├── common/            # Shared launch.sh, update.sh, update.conf, setup-sandbox.sh
│   ├── debian/            # Ubuntu / Debian / Mint  (.deb)
│   ├── redhat/            # Fedora / RHEL / CentOS (.rpm)
│   ├── arch/              # Arch / Manjaro           (PKGBUILD)
│   └── appimage/          # Any Linux distro         (.AppImage)
├── macos/                 # macOS BETA (.app bundle + .dmg)
├── windows/               # Windows (launcher, update.ps1, build.ps1)
├── build.sh               # Root build script (delegates per platform)
├── release.sh             # GitHub release automation
├── aurora.png             # Browser icon
└── README.md
```

## Supported Platforms

| Platform  | Package                   | How to install                         |
|-----------|---------------------------|----------------------------------------|
| Ubuntu/Debian/Mint | `.deb`          | `sudo dpkg -i aurora-browser_*.deb`    |
| Fedora/RHEL/CentOS | `.rpm`        | `sudo dnf install aurora-browser_*.rpm`|
| Arch/Manjaro       | PKGBUILD       | `cd linux/arch && makepkg -si`         |
| Any Linux          | `.AppImage`    | `chmod +x *.AppImage && ./Aurora-*.AppImage` |
| Windows            | `.exe`         | download `aurora-browser-*-win.exe`, run `update.ps1`, launch |
| macOS (BETA)       | `.dmg`         | open DMG, drag to Applications         |

See `linux/README.md` and `macos/README.md` for platform-specific details.

## Install (Linux)

```bash
# Debian/Ubuntu/Mint
sudo dpkg -i aurora-browser_2.0.1_amd64.deb

# Fedora/RHEL
sudo dnf install aurora-browser-2.0.1-1.x86_64.rpm

# Any Linux (portable)
chmod +x Aurora-Browser-2.0.1-x86_64.AppImage && ./Aurora-Browser-2.0.1-x86_64.AppImage
```

The browser engine is downloaded automatically during installation / first run.

## Usage

- **App menu**: search "Aurora Browser"
- **Terminal**: `aurora-browser`

All cookies, history, and extensions are stored in a self-contained profile:
`/opt/aurora-browser/profile/` on Linux, the app bundle's `Resources/profile/`
on macOS, and the install folder on Windows.

## Install (Windows)

1. Download the `aurora-browser-*-win.exe` launcher and keep it in a folder
   alongside `update.ps1`, the `extension/` directory, and the `chrome-win/` engine
2. Run `update.ps1` in PowerShell to download the engine
3. Launch with `aurora-browser.exe`

## Install (macOS BETA)

1. Open the `.dmg`, drag **Aurora Browser** into Applications
2. Right-click → **Open** on first launch (unsigned BETA)
3. Engine downloads automatically

## Updating

The browser checks for updates once per day in the background. To force a check:

**Linux:**
```bash
sudo /opt/aurora-browser/update.sh
```

**macOS:**
```bash
/Applications/Aurora\ Browser.app/Contents/Resources/update.sh
```

**Windows:**
```powershell
.\update.ps1
```

Updates are pulled from [GitHub releases](https://github.com/Draftiermovie66/Aurora-Browser/releases) or fall back to the latest engine snapshot.

## Build from Source

```bash
# Debian / Ubuntu
VERSION=2.0.1 bash linux/debian/build.sh

# Fedora / RHEL
VERSION=2.0.1 bash linux/redhat/build.sh

# AppImage (any Linux)
VERSION=2.0.1 bash linux/appimage/build.sh

# Arch
cd linux/arch && makepkg -si

# macOS (must run on macOS for .dmg)
VERSION=2.0.1 bash macos/build.sh

# Windows (must run on Windows)
.\build.ps1 -version 2.0.1
```

Or use the root orchestrator:

```bash
./build.sh deb
./build.sh rpm
./build.sh appimage
./build.sh arch
./build.sh macos
./build.sh windows
```

## License

MIT
