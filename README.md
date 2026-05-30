# Aurora Browser

A custom Chromium-based browser with a self-contained profile and auto-update.

## Install

```bash
sudo dpkg -i aurora-browser_1.0.0_amd64.deb
```

The browser engine is downloaded automatically during installation.

## Usage

- **App menu**: search "Aurora Browser"
- **Terminal**: `aurora-browser`

All cookies, history, and extensions are stored in `/opt/aurora-browser/profile/`.

## Updating

The browser checks for updates once per day in the background. To force a check:

```bash
sudo /opt/aurora-browser/update.sh
```

Updates are pulled from [GitHub releases](https://github.com/Draftiermovie66/Aurora-Browser/releases) or fall back to the latest Chromium snapshot.

## Build from source

```bash
sudo apt install dpkg-dev fakeroot
./build-deb.sh
sudo dpkg -i aurora-browser_*.deb
```

## License

MIT
