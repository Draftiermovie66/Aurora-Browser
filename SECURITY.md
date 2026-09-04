# Security Policy

## Supported Versions

Aurora Browser is under active development. Only the latest release line receives security updates.

| Version | Supported |
|---|---|
| `2.0.x` (latest `2.0.6`) | ✅ |
| `< 2.0` | ❌ — please upgrade |

We release patches for critical vulnerabilities as fast as possible (target: 7 days from report to fix or mitigation). Check [Releases](https://github.com/Draftiermovie66/Aurora-Browser/releases) for the latest version.

---

## Reporting a Vulnerability

**Please do NOT open a public GitHub issue for security vulnerabilities.** Public disclosure puts users at risk before a fix is available.

### How to Report

1. **Preferred:** Open a **private Security Advisory** via GitHub:
   - Go to [`Security` → `Report a vulnerability`](https://github.com/Draftiermovie66/Aurora-Browser/security/advisories/new) on this repo
2. **Alternative:** Contact the maintainers directly:
   - GitHub: [`@Draftiermovie66`](https://github.com/Draftiermovie66)
   - Upstream: [`@Draftiermovie66`](https://github.com/Draftiermovie66) (original maintainer)

Include:

- Affected version(s) and platform (`.deb`/`.rpm`/AppImage/`.dmg`/Windows)
- Description of the vulnerability and impact
- Steps to reproduce (PoC if possible)
- Whether the issue is in:
  - the **browser packaging / updater** (`launch.sh`, `update.sh`, `update.ps1`, `setup-sandbox.sh`)
  - the **New Tab extension** (`extension/src/*`, `manifest.json`)
  - the **Chromium engine** itself (we may need to defer to upstream Chromium)
- Your preferred contact for follow-up and disclosure credit

### What to Expect

- **Acknowledgement** within **48 hours**
- **Triage & validation** within **5 business days** — we’ll confirm reproducibility and severity
- **Fix timeline** communicated after triage; critical issues are prioritized for an out-of-band release
- **Coordinated disclosure** — we’ll agree on a disclosure date and credit you if desired

We use CVSS 3.1 to prioritize. Critical/High issues (remote code execution, sandbox escape, arbitrary file write via updater, credential exposure) are treated as emergencies.

---

## Security Considerations for Users & Contributors

### Updater & Engine Downloads

- `linux/common/update.sh` and `windows/update.ps1` fetch engine archives from GitHub Releases (or fallback Chromium snapshots). **Verify** you are running the latest release before reporting an updater issue.
- Do not run `update.sh` with untrusted `update.conf` — it controls the source repo and asset names.
- On Linux, re-run `setup-sandbox.sh` after manual engine updates if you hit sandbox errors — incorrect sandbox perms weaken the Chromium sandbox.

### Profile Isolation

- Aurora uses a **self-contained profile** (`/opt/aurora-browser/profile/`, app bundle `Resources/profile/`, or Windows install folder). This isolates cookies/storage but also means permissions on that directory matter — restrict it to your user (`chmod 700`).

### Extension (New Tab)

- `extension/` runs as a Manifest V3 new-tab override with `storage` permission only. It does **not** request broad host permissions.
- If you add new permissions in `manifest.json`, justify them in your PR and update this policy.

### Supply Chain

- `extension/package-lock.json` is committed — run `npm audit` and keep deps updated (see `.github/dependabot.yml` — weekly npm + Actions updates).
- GitHub Actions workflows are pinned to major versions (`actions/checkout@v4`, `actions/setup-node@v4`). Avoid introducing unpinned or unreviewed actions.

---

## Scope & Out-of-Scope

**In scope:**

- Remote code execution via packaged scripts or extension
- Sandbox escape / privilege escalation via `setup-sandbox.sh` or `launch.sh`
- Arbitrary file write or update hijacking (`update.sh` / `update.ps1`)
- Data exfiltration via the New Tab extension

**Out of scope (unless chainable):**

- Social engineering, physical access
- Vulnerabilities in the upstream Chromium engine itself — report those to the [Chromium security team](https://www.chromium.org/Home/chromium-security/reporting-security-bugs/) and link the Chromium advisory in your Aurora report

---

## Disclosure Policy

We practice **coordinated disclosure**:

1. Reporter submits privately → we confirm & fix
2. Fix is released and users have time to update (typically 14 days after patch release)
3. Public advisory (GitHub Security Advisory) is published with thanks to the reporter (unless they prefer anonymity)

If you have already disclosed publicly, please still report — we’ll prioritize a fix.

---

## Security Updates

- Watch releases: [GitHub Releases](https://github.com/Draftiermovie66/Aurora-Browser/releases) → **Watch → Custom → Releases**
- Update promptly:
  ```bash
  # Linux
  sudo /opt/aurora-browser/update.sh
  # macOS
  /Applications/Aurora\ Browser.app/Contents/Resources/update.sh
  # Windows
  .\update.ps1
  ```

Thank you for helping keep Aurora Browser and its users safe!
