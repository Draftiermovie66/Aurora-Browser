# Aurora Browser

<p align="center">
  <img src="assets/icons/aurora.png" alt="Aurora Browser" width="128" />
</p>

<p align="center">
  <strong>A fast, polished, Chromium-based browser with a self-contained profile, automatic updates, and a beautiful new-tab experience.</strong>
</p>

<p align="center">
  <a href="https://github.com/Draftiermovie66/Aurora-Browser/releases"><img src="https://img.shields.io/github/v/release/Draftiermovie66/Aurora-Browser?label=latest%20release" alt="Latest Release" /></a>
  <a href="https://github.com/Draftiermovie66/Aurora-Browser/blob/main/LICENSE"><img src="https://img.shields.io/github/license/Draftiermovie66/Aurora-Browser" alt="License: MIT" /></a>
  <a href="https://github.com/Draftiermovie66/Aurora-Browser/actions/workflows/ci.yml"><img src="https://github.com/Draftiermovie66/Aurora-Browser/actions/workflows/ci.yml/badge.svg" alt="CI" /></a>
  <a href="https://github.com/Draftiermovie66/Aurora-Browser/issues"><img src="https://img.shields.io/github/issues/Draftiermovie66/Aurora-Browser" alt="Issues" /></a>
  <img src="https://img.shields.io/badge/platform-Linux%20%7C%20Windows%20%7C%20macOS-informational" alt="Platforms" />
</p>

<p align="center">
  <a href="#-quick-start">Quick Start</a> •
  <a href="#-supported-platforms">Packages</a> •
  <a href="#-building-from-source">Build</a> •
  <a href="#-documentation">Docs</a> •
  <a href="CONTRIBUTING.md">Contributing</a> •
  <a href="SECURITY.md">Security</a>
</p>

---

## ✨ Features

- **Chromium Engine** — Modern, secure browsing with full extension compatibility
- **Self-Contained Profile** — All data (cookies, history, storage) isolated per-install — no pollution of system Chrome/Chromium profiles
- **Polished New Tab Page** — React + Framer Motion new-tab built with Vite, with shortcuts, search, and theming
- **Automatic Updates** — Daily background check via `update.sh` / `update.ps1`; falls back to latest Chromium snapshot if no release asset is found
- **Cross-Platform Packaging** — `.deb`, `.rpm`, `PKGBUILD`, `.AppImage`, `.dmg` (macOS BETA), and Windows launcher (`build.ps1` / `update.ps1`)
- **Sandbox Hardening** — `common/setup-sandbox.sh` configures the Chromium sandbox correctly on Linux
- **CI + Release Automation** — GitHub Actions for extension builds, shell linting, and `release.sh` for multi-platform GitHub Releases

---

## 📸 Preview

> New Tab page is served from `extension/dist/index.html` and overridden via `chrome_url_overrides.newtab` in `extension/manifest.json`.

![Aurora New Tab](assets/icons/aurora.png)

---

## 📦 Supported Platforms

| Platform | Package | Install |
|---|---|---|
| **Ubuntu / Debian / Mint / Pop!_OS** | `.deb` | `sudo dpkg -i aurora-browser_*.deb` |
| **Fedora / RHEL / CentOS / Rocky / Alma** | `.rpm` | `sudo dnf install aurora-browser_*.rpm` |
| **Arch / Manjaro / EndeavourOS** | `PKGBUILD` | `cd packages/linux/arch && makepkg -si` |
| **Any Linux (portable)** | `.AppImage` | `chmod +x Aurora-Browser-*.AppImage && ./Aurora-Browser-*.AppImage` |
| **Windows 10/11** | `aurora-browser-*-win.exe` | Keep launcher beside `update.ps1` + `extension/` + `chrome-win/`, run `.\update.ps1`, then `aurora-browser.exe` |
| **macOS 12+ (BETA)** | `.dmg` | Open DMG → drag to Applications → Right-click → **Open** on first launch (unsigned) |

> Engine is downloaded automatically on first run / install. Internal engine directory is still named `chrome-linux/` or `chrome-win/` because it ships a Chromium build — don’t confuse it with the product name.

Detailed per-platform notes: [`packages/linux/README.md`](packages/linux/README.md) · [`packages/macos/README.md`](packages/macos/README.md) · [`packages/windows/README.md`](packages/windows/README.md)

---

## 🚀 Quick Start

### Linux

```bash
# Debian / Ubuntu / Mint
sudo dpkg -i aurora-browser_2.0.6_amd64.deb

# Fedora / RHEL
sudo dnf install aurora-browser-2.0.6-1.x86_64.rpm

# Arch
cd packages/linux/arch && makepkg -si

# Universal (no install)
chmod +x Aurora-Browser-2.0.6-x86_64.AppImage
./Aurora-Browser-2.0.6-x86_64.AppImage
```

Launch:

```bash
# App menu → search "Aurora Browser"
# or terminal:
aurora-browser
```

Profile location: `/opt/aurora-browser/profile/` (Linux)

### Windows

1. Download `aurora-browser-*-win.exe` and place it in a folder with `update.ps1`, `extension/`, and an empty `chrome-win/` directory
2. In PowerShell:
   ```powershell
   .\update.ps1
   ```
3. Launch:
   ```powershell
   .\aurora-browser.exe
   ```

Profile is stored inside the install folder.

### macOS (BETA)

1. Download `Aurora-Browser-*-BETA.dmg`
2. Open DMG → drag **Aurora Browser** to **Applications**
3. Right-click → **Open** on first launch (bypass unsigned warning)
4. Engine downloads automatically on first run

Profile: `Aurora Browser.app/Contents/Resources/profile/`

---

## 🔄 Updating

Aurora checks once per day in the background. Force an update:

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

Updates are pulled from [GitHub Releases](https://github.com/Draftiermovie66/Aurora-Browser/releases). If a release has no `chrome-linux` asset, the updater falls back to the latest Chromium snapshot (see `packages/linux/common/update.sh`).

---

## 🗂️ Project Structure

```
AuroraBrowser/
├── VERSION                  # Single source of truth for version (e.g. 2.0.6)
├── assets/
│   └── icons/aurora.png     # App icon (canonical; aurora.png at root kept for compat)
├── extension/               # React New Tab (Vite + React 18 + Framer Motion)
│   ├── src/                 # App.jsx, components/, search.js, shortcuts.js, theme.js
│   ├── dist/                # Built new-tab (generated, not committed)
│   ├── manifest.json        # MV3 — chrome_url_overrides.newtab → dist/index.html
│   ├── index.html
│   ├── vite.config.js
│   └── package.json         # version synced with ../VERSION
├── packages/                # Canonical packaging (new)
│   ├── linux/
│   │   ├── common/          # Shared launch.sh, update.sh, update.conf, setup-sandbox.sh
│   │   ├── debian/          # .deb packaging + build.sh
│   │   ├── redhat/          # .rpm packaging + build.sh
│   │   ├── arch/            # PKGBUILD + aurora-browser.install
│   │   └── appimage/        # AppImage build.sh
│   ├── macos/               # .app bundle + .dmg (build.sh, update.sh, entitlements.plist)
│   └── windows/             # Launcher C# (src/AuroraBrowser.cs), build.ps1, update.ps1
├── scripts/
│   ├── build/               # build.sh + release.sh (canonical)
│   └── checks/              # smoke-update-check.sh, validate-yaml.py
├── build.sh                 # Shim → scripts/build/build.sh (kept for compat)
├── release.sh               # Shim → scripts/build/release.sh
├── linux/ macos/ windows/   # Legacy shims → packages/* (kept for compat)
└── README.md
```

---

## 🛠️ Prerequisites

| Tool | Version | Purpose |
|---|---|---|
| **Node.js** | 20+ | Build `extension/` (`npm install && npm run build`) |
| **bash** | 4+ | All `*.sh` builders |
| **dpkg / rpmbuild / makepkg / appimagetool** | — | Only for the Linux target you build |
| **PowerShell 5+** | — | Windows build |
| **Xcode CLI Tools** | — | macOS `.dmg` (must build on macOS) |
| **gh CLI** | — | `release.sh --push` |

---

## 🔨 Building from Source

Artifacts go to `build/` (and deb copy at project root). The React new-tab is built automatically if `extension/node_modules` exists; otherwise run it manually first.

```bash
# 1. Build the New Tab extension
cd extension
npm install
npm run build
cd ..

# 2. Build a platform package (canonical paths)
VERSION=2.0.6 bash packages/linux/debian/build.sh      # .deb
VERSION=2.0.6 bash packages/linux/redhat/build.sh      # .rpm
VERSION=2.0.6 bash packages/linux/appimage/build.sh    # .AppImage
cd packages/linux/arch && makepkg -si                  # Arch (reads ../VERSION)

# macOS — must run on macOS
VERSION=2.0.6 bash packages/macos/build.sh             # → build/Aurora-Browser-*-BETA.dmg

# Windows — must run on Windows
.\packages\windows\build.ps1 -version 2.0.6            # → build/aurora-browser-*-win.exe

# Legacy shims still work (e.g. linux/debian/build.sh → packages/...)
```

**Root orchestrator shorthand:**

```bash
./build.sh deb        # or: debian
./build.sh rpm        # or: redhat, fedora
./build.sh appimage
./build.sh arch
./build.sh macos
./build.sh windows
./build.sh release 2.0.6          # dry-run
./build.sh release 2.0.6 --push   # create GitHub release (needs gh auth)
```

**CI locally:**

```bash
# Extension
npm --prefix extension install
npm --prefix extension run build

# Shell syntax check (same as CI lint-shell-scripts)
bash -n scripts/build/build.sh && bash -n scripts/build/release.sh
for f in packages/linux/common/*.sh packages/linux/debian/*.sh packages/linux/redhat/*.sh packages/linux/appimage/*.sh packages/macos/*.sh; do bash -n "$f" && echo "OK $f"; done
```

---

## 🧩 Extension Development

```bash
cd extension
npm install
npm run dev      # Vite dev server
npm run build    # → dist/
npm run preview  # preview built dist
```

- `manifest.json` is MV3 with `permissions: ["storage"]` and `chrome_url_overrides.newtab`.
- Vite `base: './'` ensures `dist/index.html` works inside the browser package.
- Rollup outputs deterministic `assets/[name].js` for reproducible builds.

---

## ⚙️ Configuration

| File | Purpose |
|---|---|
| `VERSION` | Single source of truth — all builds read this if `$VERSION` not set |
| `assets/icons/aurora.png` | Canonical app icon |
| `packages/linux/common/update.conf` | GitHub repo + update channel config |
| `packages/linux/common/launch.sh` | Chromium flags + self-contained `--user-data-dir` |
| `packages/macos/entitlements.plist` | macOS sandbox entitlements |
| `extension/src/theme.js` | New-tab theme |
| `extension/src/shortcuts.js` | New-tab shortcuts |

---

## 🐛 Troubleshooting

| Symptom | Fix |
|---|---|
| **AppImage won’t start / update.sh aborts** | Ensure network access; updater now tolerates releases without `chrome-linux` asset (fallback snapshot). Run `bash -x /opt/aurora-browser/update.sh` |
| **Sandbox error on Linux** | Re-run `sudo /opt/aurora-browser/setup-sandbox.sh` or reinstall `.deb/.rpm` |
| **Windows engine missing** | Run `.\update.ps1` again in the install folder — `chrome-win/` must be downloaded |
| **macOS “damaged” / unsigned warning** | Right-click → **Open** on first launch; BETA is not yet notarized |
| **New Tab shows blank** | Rebuild extension: `npm --prefix extension run build` then rebuild package |

More help: [Open an issue](https://github.com/Draftiermovie66/Aurora-Browser/issues) using the **Bug report** template.

---

## 🤝 Contributing

We love contributions! See [CONTRIBUTING.md](CONTRIBUTING.md) for setup, branch & commit conventions, and PR process.

- Code style: [STYLEGUIDE.md](STYLEGUIDE.md)
- Conduct: [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)
- Security issues: [SECURITY.md](SECURITY.md) — **do not** open public issues for vulnerabilities.

Quick start for contributors:

```bash
git clone https://github.com/Draftiermovie66/Aurora-Browser.git
cd Aurora-Browser
npm --prefix extension install
npm --prefix extension run build
# make changes on a feature branch, then open a PR
```

---

## 🔒 Security

If you discover a security vulnerability, please follow [SECURITY.md](SECURITY.md) for responsible disclosure. Do not file a public issue.

---

## 📄 License

[MIT](LICENSE) © 2026 Draftiermovie66. See `LICENSE` for full text.

---

## 🙏 Acknowledgments

- [Chromium](https://www.chromium.org/) for the engine
- [React](https://react.dev/), [Vite](https://vitejs.dev/), [Framer Motion](https://www.framer.com/motion/) for the New Tab experience
- Contributors and packagers across Debian, Fedora, Arch, and AppImage ecosystems

---

<p align="center">
  <sub>Built with ❤️ for the open web. If Aurora is useful, please ⭐ the repo!</sub>
</p>
