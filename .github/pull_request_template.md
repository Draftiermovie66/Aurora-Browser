<!--
Thank you for contributing to Aurora Browser! Please fill out this template.
Delete sections that don't apply.
-->

## Summary

<!-- One-line summary + link to issue (e.g., Closes #123). What does this PR change and why? -->

Closes #

## Type of change

- [ ] `feat` — new feature
- [ ] `fix` — bug fix
- [ ] `docs` — documentation only
- [ ] `style` / `refactor` / `perf` — code improvement, no functional change
- [ ] `build` / `ci` / `chore` — tooling, deps, packaging
- [ ] `security` — fixes a vulnerability (see SECURITY.md — use private advisory if not yet disclosed)

## Scope / Platform

<!-- Check all that apply -->

- [ ] `extension/` — React New Tab (Vite)
- [ ] `linux/common` — shared launch.sh / update.sh / setup-sandbox.sh
- [ ] `linux/debian` — .deb
- [ ] `linux/redhat` — .rpm
- [ ] `linux/arch` — PKGBUILD
- [ ] `linux/appimage` — AppImage
- [ ] `macos` — .dmg / .app
- [ ] `windows` — launcher / build.ps1 / update.ps1
- [ ] `docs` — README / CONTRIBUTING / guides
- [ ] `ci` / `release` — workflows / release.sh

## How to test

<!-- Exact steps a reviewer can run. Be specific. -->

```bash
# Example:
npm --prefix extension install
npm --prefix extension run build
VERSION=2.0.6 bash linux/debian/build.sh
# then install & launch artifact from build/
```

- Steps:
  1.
  2.
  3.

## Screenshots / Recordings

<!-- Required for extension/ UI changes. Drag images here. Delete if not applicable. -->

| Before | After |
|---|---|
|  |  |

## Checklist

- [ ] I have read [CONTRIBUTING.md](../CONTRIBUTING.md) and [STYLEGUIDE.md](../STYLEGUIDE.md)
- [ ] I follow [Conventional Commits](https://www.conventionalcommits.org/) (`feat(scope): ...`)
- [ ] I created a **focused branch** from `main` (`feat/…`, `fix/…`, etc.) and will delete it after merge
- [ ] I linked the related issue (`Closes #…`) and checked for duplicates
- [ ] I updated docs (`README.md`, `linux/README.md`, `macos/README.md`, `windows/README.md`) if install/build behavior changed
- [ ] `npm --prefix extension run build` passes (if `extension/` changed)
- [ ] All `*.sh` changed pass `bash -n` (CI runs `lint-shell-scripts`)
- [ ] I tested the package/target I changed (installed artifact or `npm run preview`)
- [ ] `update.sh` / `update.ps1` still safe to re-run / fallback behavior preserved (if updater changed)
- [ ] No secrets, credentials, or absolute local paths committed
- [ ] No new `manifest.json` permissions without justification in description (+ SECURITY.md if needed)

## Breaking changes

<!-- Does this break existing installs, profiles, or build commands? If yes, describe migration. -->

- [ ] No breaking changes
- [ ] Yes — described below:

## Additional notes

<!-- Anything else reviewers should know. -->
