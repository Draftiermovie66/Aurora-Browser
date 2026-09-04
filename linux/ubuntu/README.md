# Aurora Browser for Ubuntu

## Install

```bash
sudo dpkg -i aurora-browser_2.0.0_amd64.deb
sudo apt-get install -f
```

The browser engine is downloaded automatically on first launch.

## Build from source

```bash
sudo apt install dpkg-dev fakeroot nodejs npm
./build.sh deb
sudo dpkg -i aurora-browser_*.deb
```

## Build the extension (React)

```bash
cd extension
npm install
npm run build
```

The built extension output goes to `extension/dist/`.

## Supported versions

- Ubuntu 20.04 LTS+
- Ubuntu 22.04 LTS+
- Ubuntu 24.04 LTS+
- Any Debian-based distro (Debian 11+, Linux Mint, Pop!_OS, etc.)

## Auto-updates

The browser checks for updates once per day. To force:

```bash
sudo /opt/aurora-browser/update.sh
```
