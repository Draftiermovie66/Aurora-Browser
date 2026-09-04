# Aurora Browser AppImage

A portable, self-contained AppImage that runs on **any Linux distribution**
without installing dependencies.

## Run

```bash
chmod +x Aurora-Browser-2.0.1-x86_64.AppImage
./Aurora-Browser-2.0.1-x86_64.AppImage
```

On some distros you may need to enable FUSE:

```bash
sudo apt install libfuse2   # Debian/Ubuntu
sudo dnf install fuse       # Fedora
```

## Build from source

```bash
VERSION=2.0.1 bash linux/appimage/build.sh
```

The script downloads `linuxdeploy` automatically on first run and produces:

```
build/Aurora-Browser-2.0.1-x86_64.AppImage
```

## Notes

- The engine is downloaded on first run into the profile directory.
- Store the `.AppImage` anywhere; it carries its own launcher and updater.
