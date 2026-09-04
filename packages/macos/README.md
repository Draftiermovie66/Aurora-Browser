# Aurora Browser for macOS (BETA)

> **Status: BETA** — This build is experimental and may change. Packaging and
> updates are works in progress. Use at your own risk, and back up your data.

## Requirements

- macOS 11.0 (Big Sur) or later
- Apple Silicon (M1/M2/M3) or Intel Mac
- Chromium engine downloaded automatically on first run

## Install

The BETA is distributed as a `.dmg`:

1. Download `Aurora-Browser-{version}-BETA.dmg` from Releases
2. Open the DMG and drag **Aurora Browser** into Applications
3. First launch: right-click the app → **Open** (macOS Gatekeeper will warn
   about the unsigned BETA build)
4. The engine is downloaded automatically via `update.sh`

## Auto-update

The browser checks for updates once per day. To force an update:

```bash
/Applications/Aurora\ Browser.app/Contents/Resources/update.sh
```

## Build from source

Builds must run on macOS (for `.dmg` creation):

```bash
VERSION=2.0.1 bash macos/build.sh
```

Outputs:
- `build/macos/Aurora Browser.app` — the app bundle
- `build/Aurora-Browser-{version}-BETA.dmg` — the installer (requires hdiutil)

## Structure

```
macos/
├── build.sh      # Creates the .app bundle and .dmg
└── update.sh     # Downloads/updates the macOS engine
```

Inside the app bundle:
```
Aurora Browser.app/
  Contents/
    Info.plist
    MacOS/launch-aurora      # launcher
    Resources/
      extension/             # new tab page (React)
      profile/               # user data (cookies, history)
      chrome-mac/            # engine (downloaded)
      update.sh              # updater
      update.conf
      version.txt
```

## Notes

- The engine is Chrome-for-Testing for macOS (arm64/universal2).
- No code signing or notarization yet — expected for a BETA.
- The custom new-tab React page is fully supported.
