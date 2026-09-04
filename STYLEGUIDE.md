# Aurora Browser — Style Guide

This guide defines coding, naming, and documentation conventions for Aurora Browser. Follow it for all contributions — CI checks enforce parts of it automatically.

> Summary: small focused changes, conventional commits, `bash -n` clean shell, Vite + React idioms, and docs that stay in sync with code.

---

## Table of Contents

- [General Principles](#general-principles)
- [Git & Commits](#git--commits)
- [Shell (`*.sh`)](#shell-sh)
- [JavaScript / React (`extension/`)](#javascript--react-extension)
- [C# (`windows/src/`)](#c-windows-src)
- [Markdown & Docs](#markdown--docs)
- [Packaging Conventions](#packaging-conventions)
- [Formatting & Linting](#formatting--linting)
- [Code Review Checklist](#code-review-checklist)

---

## General Principles

1. **Reuse `common/`** — Don’t duplicate `launch.sh`, `update.sh`, `update.conf`, or `setup-sandbox.sh`. Package-specific builders copy or symlink them.
2. **Fail safe** — Update scripts must never brick the install. The fix in `38f39f3` (tolerate missing `chrome-linux` asset + fallback snapshot) is the model: log, fallback, don’t `exit 1` on transient release gaps.
3. **Profile isolation** — Never write outside the self-contained profile unless explicitly required (e.g., `setup-sandbox.sh` needs root for chrome-sandbox perms). Document any exception.
4. **Small PRs** — Prefer <400 lines. Split refactor + feat into separate commits/PRs.
5. **Docs accompany code** — If you change install or build steps, update `README.md`, `linux/README.md`, and platform READMEs in the same PR.

---

## Git & Commits

- **Branch names:** `feat/short-desc`, `fix/issue-123`, `docs/readme-links`, `chore/bump-vite`, `packaging/arch-fix`
- **Conventional Commits** (enforced in review):
  ```
  feat(extension): add vimium-style shortcut hints
  fix(linux): fallback when GitHub release lacks chrome-linux
  docs(macos): clarify unsigned BETA first-launch
  chore(deps): bump framer-motion 11 → 13
  ```
  Types: `feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert`  
  Scopes: `extension|linux|debian|redhat|arch|appimage|macos|windows|build|release|docs`
- **History:** Rebase onto `main` before PR (`git fetch upstream && git rebase upstream/main`). No merge commits in PR branches.
- **Messages:** Imperative mood, 72-char subject line, body explains *why* not *what* (the diff shows what).

---

## Shell (`*.sh`)

All bash scripts (`build.sh`, `release.sh`, `linux/*/*.sh`, `macos/*.sh`, `linux/common/*.sh`) must follow:

```bash
#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
VERSION="${VERSION:-2.0.6}"

# Quote every variable, guard every cd
# Prefer functions for non-trivial logic
# Log with echo "==> ..." for user-visible steps
```

**Rules:**

- **Strict mode:** Always `set -euo pipefail` at top.
- **Quoting:** Quote all expansions: `"$DIR"`, `"$VERSION"`, `"$ASSET"` — use `shellcheck` to catch.
- **Validation:** Scripts must pass `bash -n <file>` (CI does this). Run `shellcheck` locally if available.
- **No `cd` without guard:** `cd "$DIR" || exit 1` or use `DIR=...` pattern.
- **Error messages:** Print to stderr: `echo "error: ... " >&2` and exit non-zero on real errors.
- **Idempotency:** `update.sh` and `setup-sandbox.sh` should be safe to run twice.
- **Portability:** Target `bash` 4+. Don’t use `zsh`-only features.
- **Secrets:** Never echo tokens, never commit `.env`.

**Example:**

```bash
# Good
update_engine() {
  local version="$1"
  local asset="chrome-linux-${version}.zip"
  echo "==> Fetching ${asset} ..."
  curl -fsSL -o "/tmp/${asset}" "${BASE_URL}/${asset}" || {
    echo "warn: ${asset} not found, falling back to snapshot" >&2
    curl -fsSL -o "/tmp/${asset}" "${FALLBACK_URL}/latest.zip"
  }
}
```

---

## JavaScript / React (`extension/`)

**Stack:** Vite 6 · React 18 · Framer Motion 13 · `manifest_version: 3`

**Conventions:**

- **Components:** Functional components + hooks only. One component per file. File names `PascalCase.jsx` (e.g., `ShortcutTile.jsx`), utilities `camelCase.js` (`search.js`, `shortcuts.js`, `theme.js`).
- **Imports:** Group order — `react`/`external` → `internal` → `styles`. No default import aliasing.
- **Styling:** `styles.css` + inline Framer props. Prefer CSS variables from `theme.js` over hard-coded colors.
- **State:** Use `localStorage` / `chrome.storage` via helpers; don’t access storage directly in components — wrap in `src/shortcuts.js` / `src/theme.js`.
- **Vite config:** Keep `base: './'` and deterministic `rollupOptions.output` — don’t change without updating packaging docs.
- **Manifest:** `permissions` stays minimal (`storage` only). Adding a permission requires a PR note + `SECURITY.md` update.

**Formatting:**

```jsx
// Good
export default function ShortcutTile({ title, url, onRemove }) {
  return (
    <motion.a
      href={url}
      whileHover={{ scale: 1.04 }}
      className="tile"
    >
      {title}
    </motion.a>
  );
}
```

- 2-space indent, semicolons, single quotes for JS, double quotes for JSX attributes.
- `npm run build` must be warning-free. Fix Vite/Rollup warnings before PR.
- No `console.log` in committed code (use `console.warn` for real warnings, remove debug logs).

**Performance:**

- Memoize expensive lists (`React.memo`, `useMemo`) if needed — New Tab should paint <100ms.
- Lazy-load heavy motion variants.

---

## C# (`windows/src/`)

File: `windows/src/AuroraBrowser.cs`

- Target: .NET Framework / .NET 6+ compatible (check `build.ps1` — don’t bump target without updating the script).
- Follow existing brace style (Allman) and `PascalCase` for classes/methods, `camelCase` for locals.
- Keep launcher logic minimal: resolve paths, ensure `chrome-win/` + `profile/` exist, spawn Chromium with `--user-data-dir`.
- Avoid hard-coded absolute paths — resolve relative to executable.

---

## Markdown & Docs

- **Headings:** ATX (`#`, `##`) with blank line before/after. One `#` per file.
- **Code blocks:** Fenced with language tag: ````bash`, ````js`, ````powershell`
- **Lines:** Wrap at ~100 chars where reasonable; don’t break URLs or code.
- **Links:** Relative for in-repo: `[linux README](linux/README.md)`, absolute for external.
- **Images:** Alt text required: `![Aurora New Tab](aurora.png)`
- **Terminology:** Consistent:
  - Product: **Aurora Browser** (capitalized)
  - Engine: **Chromium engine** / `chrome-linux/` (internal path)
  - Packages: `.deb`, `.rpm`, `PKGBUILD`, `.AppImage`, `.dmg`, `.exe`

---

## Packaging Conventions

- **Versions:** Single source of truth is `VERSION` env var (default `2.0.6` today). `release.sh` strips leading `v` (`${TAG#v}`).
- **Artifacts:** Always output to `build/` (and deb copy at `aurora-browser_${V}_amd64.deb` for compatibility). Never commit artifacts (`*.deb`, `*.rpm`, `*.AppImage`, `*.dmg` are `.gitignore`d).
- **Desktop entry:** `aurora-browser.desktop` must set `Exec=aurora-browser` and `Icon=aurora`.
- **Copy, don’t edit, `common/`:** `debian/build.sh`, `redhat/build.sh`, `appimage/build.sh` copy from `linux/common/` — edit the source there.
- **macOS:** Keep `entitlements.plist` minimal; note BETA unsigned status in `macos/README.md`.

---

## Formatting & Linting

Run before every PR:

```bash
# Shell — must pass
bash -n build.sh && bash -n release.sh
for f in linux/common/*.sh linux/debian/*.sh linux/redhat/*.sh linux/appimage/*.sh macos/*.sh; do
  bash -n "$f" && echo "OK $f"
done

# Optional but recommended
shellcheck linux/common/*.sh  # if installed

# Extension — must build warning-free
npm --prefix extension install
npm --prefix extension run build
```

No auto-formatter is enforced yet — keep diffs minimal and match surrounding style. If we adopt `prettier`/`editorconfig`, this section will be updated.

---

## Code Review Checklist

Use this when reviewing or self-reviewing:

- [ ] Conventional commit messages + tight PR scope
- [ ] `bash -n` clean; `set -euo pipefail` + quoted vars in shell
- [ ] `npm --prefix extension run build` passes; no new `manifest.json` permissions without justification
- [ ] No secrets / tokens / absolute paths
- [ ] `update.sh` / `update.ps1` still safe to re-run; fallback behavior preserved
- [ ] Profile isolation intact (`--user-data-dir` self-contained)
- [ ] Docs updated (`README.md`, `linux/README.md`, platform READMEs, `SECURITY.md` if needed)
- [ ] Screenshots for UI changes
- [ ] Tested at least one package install that was touched

---

Questions? Open a [Discussion](https://github.com/Draftiermovie66/Aurora-Browser/discussions) or ask in your PR.
