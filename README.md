<p align="center">
  <img alt="Aurora Browser" src="https://shieldcn.dev/header/gradient.svg?title=Aurora+Browser&subtitle=A+custom+open-source+web+browser+built+on+the+Ladybird+LibWeb+engine.&mode=dark&image=https%3A%2F%2Fi.ibb.co%2FtjLpHmP%2Fjay-bhadreshwara-zw-Il-z0-QRz-Y-unsplash.jpg&overlay=0.85" />
</p>

<p align="center">
    <a href="https://github.com//Draftiermovie66/Aurora-Browser/actions/workflows/release.yml">
        <img src="https://shieldcn.dev/badge/Build-Passing-success.svg?logo=githubactions" alt="Build">
    </a>
</p>

---

A custom open-source web browser built on the **[Ladybird](https://ladybird.org) LibWeb engine**.

**No Chromium. No Firefox. Custom engine.**

## Architecture

```
Aurora Browser
├── engine/                    # Ladybird fork build system
│   ├── build.sh              # Main build script (clone + brand + build)
│   ├── brand.sh              # Apply Aurora branding to Ladybird source
│   ├── package.sh            # Package built binaries for distribution
│   ├── sign.sh               # Code signing (osslsigncode / signtool)
│   ├── checksums.sh          # SHA256 checksum generation
│   └── newtab/               # Custom new-tab page
│       └── index.html
├── extension/                # Legacy React new-tab (deprecated, kept for reference)
├── packages/                 # Legacy packaging (deprecated)
├── installer/                # Legacy native installer (deprecated)
├── scripts/build/            # Build orchestrator
│   └── build.sh
├── VERSION                   # Single source of truth: 3.0.0
├── LICENSE                   # MIT
└── README.md
```

## Building from Source

### Prerequisites

| Platform | Requirements |
|----------|-------------|
| Linux | Clang 18+, CMake 3.25+, Ninja, Qt6, Rust, nasm, 30GB+ disk |
| macOS | Xcode CLI tools, Homebrew (cmake, ninja, qt, llvm) |
| Windows | WSL2 with Ubuntu 24.04+ (native Windows not yet supported) |

### Build

```bash
git clone --recursive https://github.com/Draftiermovie66/Aurora-Browser
cd Aurora-Browser

# Linux
VERSION=3.0.0 bash engine/build.sh

# macOS
VERSION=3.0.0 bash engine/build.sh

# Windows (inside WSL2)
VERSION=3.0.0 bash engine/build.sh
```

### Build Steps

1. **Clone** — Downloads Ladybird source (`git clone --depth 1`)
2. **Brand** — Applies Aurora Browser name, icons, defaults
3. **Build** — Compiles LibWeb + LibJS + UI (30-120 minutes)
4. **Package** — Creates distributable directory

## Code Signing

Aurora Browser uses [osslsigncode](https://github.com/mtrojnar/osslsigncode) for cross-platform code signing and [SignPath Foundation](https://signpath.org) (free for open-source projects).

```bash
# Set signing credentials
export AURORA_SIGN_CERT=/path/to/certificate.pfx
export AURORA_SIGN_PASS=your-password

# Sign all binaries
VERSION=3.0.0 bash engine/sign.sh build VERSION
```

### SmartScreen Reputation

Windows SmartScreen builds reputation organically after code signing. To expedite:

1. Sign all releases with a consistent certificate (SignPath Foundation is free for OSS)
2. Always timestamp signatures (RFC 3161)
3. Publish `checksums-SHA256.txt` with every release
4. If falsely flagged, submit at https://www.microsoft.com/en-us/wdsi/filesubmission

## Engine: LibWeb (Ladybird)

Aurora Browser is built on [LibWeb](https://github.com/LadybirdBrowser/ladybird), the rendering engine from the Ladybird Browser project.

- **License**: BSD-2-Clause (very permissive)
- **Language**: C++23 + Rust
- **Web Standards**: HTML, CSS (Flexbox/Grid), JavaScript (ES2024+), WebGL, SVG, HTTP/3
- **Process Model**: Multi-process sandboxed (one process per tab)
- **No dependencies** on Chromium, Firefox, or WebKit

### What works
- Most websites (Gmail, GitHub, YouTube, ChatGPT, Wikipedia)
- CSS Flexbox, Grid, modern layouts
- JavaScript (ES2024+, WASM)
- HTTP/2, HTTP/3, TLS 1.3
- Basic WebGL

### What doesn't (yet)
- Browser extensions
- WebRTC
- WebGPU
- Advanced media codecs
- Full DevTools parity

## License

- **Browser**: MIT License
- **Engine (LibWeb)**: BSD-2-Clause License (Ladybird Browser Initiative)

## Credits

- [Ladybird Browser Initiative](https://ladybird.org) — LibWeb engine
- [Andreas Kling](https://github.com/awesomekling) — Ladybird creator
- Aurora Browser is not affiliated with the Ladybird Browser Initiative
