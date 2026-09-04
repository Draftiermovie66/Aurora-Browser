# Contributing to Aurora Browser

Thank you for considering a contribution to Aurora Browser! This guide will help you get set up, follow our workflow, and get your pull request merged quickly.

> **New to open source?** Look for issues labeled [`good first issue`](https://github.com/Draftiermovie66/Aurora-Browser/labels/good%20first%20issue) and [`help wanted`](https://github.com/Draftiermovie66/Aurora-Browser/labels/help%20wanted).

---

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
- [Development Setup](#development-setup)
- [Project Structure](#project-structure)
- [Branching & Workflow](#branching--workflow)
- [Commit Conventions](#commit-conventions)
- [Pull Request Process](#pull-request-process)
- [Coding Standards](#coding-standards)
- [Testing](#testing)
- [Release Process](#release-process)
- [Getting Help](#getting-help)

---

## Code of Conduct

This project adheres to the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md). By participating, you agree to uphold it. Please report unacceptable behavior to the maintainers via the contact listed in [SECURITY.md](SECURITY.md).

---

## How Can I Contribute?

- **Report bugs** — Use the *Bug report* issue template; include platform, version, repro steps, and logs/screenshots.
- **Request features** — Use the *Feature request* template; describe the use case and alternatives.
- **Fix bugs / implement features** — Comment on an issue to claim it, then open a PR (see below).
- **Improve packaging** — `packages/linux/*`, `packages/macos/`, `packages/windows/` all welcome platform-specific expertise (legacy `linux/`, `macos/`, `windows/` shims delegate to `packages/`).
- **Improve docs** — README, wiki, comments, and examples.
- **Review PRs** — Helpful reviews are a contribution!

---

## Development Setup

### Prerequisites

| Tool | Version | Notes |
|---|---|---|
| Node.js | 20+ | Extension build (`extension/`) |
| npm | 9+ | Installed with Node |
| bash | 4+ | Shell scripts |
| git | 2.30+ | Version control |
| PowerShell | 5+ | Windows build only |
| Xcode CLI Tools | — | macOS `.dmg` only |
| `gh` CLI | — | `release.sh --push` only |

### Clone & Install

```bash
git clone https://github.com/Draftiermovie66/Aurora-Browser.git
cd Aurora-Browser

# Install extension deps and build
npm --prefix extension install
npm --prefix extension run build

# Verify shell scripts (canonical + shims)
bash -n scripts/build/build.sh && bash -n build.sh
bash -n scripts/build/release.sh && bash -n release.sh
for f in packages/linux/common/*.sh packages/linux/debian/*.sh packages/linux/redhat/*.sh packages/linux/appimage/*.sh packages/macos/*.sh; do
  bash -n "$f" && echo "OK $f"
done
```

### Run the Extension in Dev Mode

```bash
cd extension
npm run dev      # Vite dev server at http://localhost:5173
# Edit src/App.jsx, src/components/* — HMR is enabled
npm run build    # Production build to dist/
npm run preview  # Preview dist/ locally
```

### Build a Package Locally

```bash
VERSION=2.0.6 bash packages/linux/debian/build.sh     # .deb
VERSION=2.0.6 bash packages/linux/redhat/build.sh     # .rpm
VERSION=2.0.6 bash packages/linux/appimage/build.sh   # .AppImage
cd packages/linux/arch && makepkg -si                  # Arch (reads VERSION)

# Orchestrator shorthand
./build.sh deb        # shim → scripts/build/build.sh → packages/...
./build.sh rpm
./build.sh appimage
./build.sh arch       # → packages/linux/arch
./build.sh macos      # must run on macOS
./build.sh windows    # must run on Windows / powershell
```

Artifacts land in `build/` (and deb copy at repo root). See [`packages/linux/README.md`](packages/linux/README.md) and platform READMEs for details. Legacy paths (`linux/debian/build.sh`) still work via shims.

---

## Project Structure

```
VERSION                                           # single source of truth
assets/icons/aurora.png                           # canonical icon
extension/        React new-tab (Vite). Manifest V3, newtab override.
packages/linux/common/     Shared launch.sh, update.sh, update.conf, setup-sandbox.sh
packages/linux/debian/     Debian packaging
packages/linux/redhat/     RPM packaging
packages/linux/arch/       PKGBUILD + aurora-browser.install
packages/linux/appimage/   AppImage packaging
packages/macos/            .app bundle + .dmg builder
packages/windows/          C# launcher + PowerShell builders
scripts/build/             build.sh + release.sh (canonical)
scripts/checks/            smoke-update-check.sh, validate-yaml.py
build.sh / release.sh      Shims → scripts/build/*
linux/ macos/ windows/      Legacy shims → packages/* (kept for compat)
```

**Key files to know:**

- `extension/manifest.json` — MV3 new-tab override → `dist/index.html`
- `extension/vite.config.js` — `base: './'`, deterministic asset names
- `linux/common/launch.sh` — Chromium flags + `--user-data-dir` isolation
- `linux/common/update.sh` — daily update check + snapshot fallback

---

## Branching & Workflow

1. **Fork** the repo (or create a branch if you have push access).
2. **Create a feature branch** from `main`:
   ```bash
   git checkout main
   git pull upstream main
   git checkout -b feat/short-description
   # or: fix/issue-123-short-description
   ```
   Branch naming: `feat/…`, `fix/…`, `docs/…`, `chore/…`, `packaging/…`, `extension/…`.

3. **Make focused commits** (see conventions below).
4. **Keep branch up to date**:
   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

5. **Push and open a PR** against `main`.

---

## Commit Conventions

We follow **Conventional Commits**:

```
<type>(<scope>): <short summary>

[optional body]

[optional footer: Closes #123]
```

**Types:** `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`

**Scopes:** `extension`, `linux`, `debian`, `redhat`, `arch`, `appimage`, `macos`, `windows`, `build`, `release`, `docs`

**Examples:**

```
feat(extension): add keyboard shortcut palette
fix(linux): handle missing chrome-linux asset without aborting
docs(readme): add AppImage troubleshooting
chore(deps): bump vite to 6.0.1
```

- Use imperative mood (“add” not “added”).
- One logical change per commit; keep diffs reviewable (<400 lines preferred).
- Reference issues: `Closes #123` or `Fixes #123` in the footer.

---

## Pull Request Process

Before opening a PR:

- [ ] Search existing [issues](https://github.com/Draftiermovie66/Aurora-Browser/issues) and [PRs](https://github.com/Draftiermovie66/Aurora-Browser/pulls) to avoid duplication.
- [ ] Create an issue for large changes and discuss the approach first.
- [ ] Run local checks:
  ```bash
  npm --prefix extension install && npm --prefix extension run build
  for f in build.sh release.sh linux/common/*.sh linux/debian/*.sh linux/redhat/*.sh linux/appimage/*.sh macos/*.sh; do bash -n "$f"; done
  ```
- [ ] Test the package you touched (install the artifact you built if possible).
- [ ] Update docs (`README.md`, `linux/README.md`, etc.) if behavior or install steps changed.

When you open the PR:

1. Fill out the pull request template ( `.github/pull_request_template.md` auto-loads ).
2. Link related issues (`Closes #123`).
3. Add screenshots/recordings for UI changes (`extension/`).
4. Mark as **Draft** if not ready for review.
5. CI must pass (`build-extension` + `lint-shell-scripts`). Fix failures before requesting review.
6. At least one maintainer review is required.

After merge, delete your branch.

### What we look for in reviews

- Correctness, edge cases, and error handling (especially `update.sh` fallback logic)
- No secrets, credentials, or absolute local paths
- Backwards compatibility of launch/update scripts
- Accessibility and performance for `extension/` changes
- Documentation completeness

---

## Coding Standards

Full details: [STYLEGUIDE.md](STYLEGUIDE.md)

**TL;DR:**

- **Shell** — `set -euo pipefail`, `bash -n` clean, quote variables, prefer `common/` reuse
- **JavaScript/React** — Vite + React 18, Framer Motion for animations, keep components small
- **C# (Windows)** — follow existing `windows/src/AuroraBrowser.cs` style
- **Markdown** — wrap lines sensibly, use fenced code blocks with language tags

Run `npx --prefix extension vite build` and `bash -n` before pushing.

---

## Testing

There is no full automated test suite yet — contributions adding tests are especially welcome.

**Manual testing checklist per PR:**

- [ ] Extension builds without warnings (`npm --prefix extension run build`)
- [ ] New Tab renders correctly (if `extension/` changed) — test via `npm run preview` or installed browser
- [ ] Shell scripts pass `bash -n` and `shellcheck` (if available)
- [ ] Built package installs and launches (test at least one Linux target you modified)
- [ ] Update flow still works (`update.sh` / `update.ps1` dry-run)
- [ ] No regressions in profile isolation (`--user-data-dir` still self-contained)

If you add automated checks, document how to run them in the PR description and in `STYLEGUIDE.md`.

---

## Release Process

Releases are cut via `release.sh` and GitHub Releases (maintainers only):

```bash
# Dry-run: builds deb, AppImage, rpm, dmg (and win exe on Windows) and lists assets
./build.sh release 2.0.7
bash release.sh v2.0.7           # same

# Publish (requires gh auth + push rights)
bash release.sh v2.0.7 --push
gh release create v2.0.7 --title "Aurora Browser v2.0.7" --notes "..." <assets>
```

See `.github/workflows/release.yml` and `release-drafter.yml` for automation.

---

## Getting Help

- **Questions / discussion:** Open a [GitHub Discussion](https://github.com/Draftiermovie66/Aurora-Browser/discussions) or comment on a relevant issue.
- **Bugs:** Use the *Bug report* template with platform/version/repro.
- **Security:** See [SECURITY.md](SECURITY.md) — do not open public issues for vulnerabilities.

Thank you for making Aurora better! 🌟
