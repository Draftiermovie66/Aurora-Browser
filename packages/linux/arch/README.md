# Aurora Browser for Arch Linux

## Install from AUR (when published)

```bash
yay -S aurora-browser
```

## Build locally

```bash
cd linux/arch
makepkg -si
```

## Build from source

```bash
# First build the .deb
cd ../..
VERSION=2.0.0 bash linux/build.sh

# Then build the Arch package
cd linux/arch
makepkg -si
```

## Manual install from .deb

Arch Linux can install .deb packages directly using `debtap`:

```bash
yay -S debtap
debtap aurora-browser_2.0.0_amd64.deb
sudo pacman -U aurora-browser-2.0.0-1-x86_64.pkg.tar.zst
```
