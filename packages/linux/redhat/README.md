# Aurora Browser for Fedora / RHEL / RedHat

Aurora Browser packaged as a Red Hat Package Manager (`.rpm`) for Fedora,
RHEL, CentOS, Rocky, and AlmaLinux.

## Install

```bash
sudo dnf install aurora-browser-2.0.1-1.x86_64.rpm
```

For RHEL/CentOS that use `yum`:

```bash
sudo yum localinstall aurora-browser-2.0.1-1.x86_64.rpm
```

The browser engine is downloaded automatically on first launch.

## Build from source

Requires `rpm-build`:

```bash
sudo dnf install rpm-build
VERSION=2.0.1 bash linux/redhat/build.sh
```

Output: `build/aurora-browser-2.0.1-1.x86_64.rpm`

## Install build dependencies

```bash
sudo dnf install rpm-build curl unzip
```

## Auto-updates

The browser checks for updates once per day. To force:

```bash
sudo /opt/aurora-browser/update.sh
```
