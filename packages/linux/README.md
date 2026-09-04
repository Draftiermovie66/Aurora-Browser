# Aurora Browser for Linux

Aurora Browser is packaged for major Linux distro families. Choose the package type that matches your system.

## Package types

| Directory             | Distro family                                            | Package        |
|-----------------------|----------------------------------------------------------|----------------|
| `appimage/`           | Any Linux distro (universal)                             | `.AppImage`    |
| `debian/`             | Ubuntu, Debian, Linux Mint, Pop!_OS, elementaryOS        | `.deb`         |
| `redhat/`             | Fedora, RHEL, CentOS, Rocky, AlmaLinux                   | `.rpm`         |
| `arch/`               | Arch, Manjaro, EndeavourOS, Garuda                       | `PKGBUILD`     |
| `common/`             | Shared scripts used by all package types                 | —              |

## Which should I use?

- **Ubuntu / Debian / Mint** → `debian/` (`.deb`)
- **Fedora / RHEL / CentOS** → `redhat/` (`.rpm`)
- **Arch / Manjaro** → `arch/` (PKGBUILD)
- **Any other distro or just want portability** → `appimage/` (`.AppImage`)

## Building

All builds produce artifacts into the root `build/` directory. The React new tab
extension is built automatically if `extension/node_modules` exists.

**Debian (.deb):**
```bash
VERSION=2.0.1 bash linux/debian/build.sh
```

**RedHat / Fedora (.rpm):**
```bash
VERSION=2.0.1 bash linux/redhat/build.sh
```

**Arch (PKGBUILD):**
```bash
cd linux/arch && makepkg -si
```

**AppImage (universal):**
```bash
VERSION=2.0.1 bash linux/appimage/build.sh
```

## Shared scripts (`common/`)

The `common/` directory holds the launcher, updater, and sandbox setup that are
identical across every package. Package-specific build scripts copy these into
the correct locations for each format.

- `launch.sh` — loads the engine with self-contained profile
- `update.sh` — downloads/updates the Aurora engine
- `update.conf` — GitHub repo config for updates
- `setup-sandbox.sh` — sets sandbox permissions

## Engine download

Aurora Browser uses a self-contained engine that is downloaded automatically on
first run (or via `update.sh`). On this project the engine directory is still
named `chrome-linux/` internally because it ships an actual Chromium engine; do
not confuse this internal engine path with the Aurora Browser product name.

## Auto-updates

The browser checks for updates once per day. To force a check:

```bash
sudo /opt/aurora-browser/update.sh
```
