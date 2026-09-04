#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$DIR/../../.." && pwd)"
COMMON="$DIR/../common"

if [ -z "${VERSION:-}" ] && [ -f "$ROOT/VERSION" ]; then
  VERSION="$(cat "$ROOT/VERSION")"
fi
VERSION="${VERSION:-2.0.6}"

ICON_SRC="$ROOT/assets/icons/aurora.png"
[ -f "$ICON_SRC" ] || ICON_SRC="$ROOT/aurora.png"

echo "==> Building RPM package (version $VERSION) ..."

# Build React extension
if [ -d "$ROOT/extension/node_modules" ]; then
  echo "==> Building React extension ..."
  (cd "$ROOT/extension" && npm run build)
fi

# Ensure rpmbuild available
command -v rpmbuild >/dev/null 2>&1 || { echo "rpmbuild not found. Install with: sudo dnf install rpm-build"; exit 1; }

# Prepare layout in a staging directory
STAGE=$(mktemp -d)
mkdir -p "$STAGE/opt/aurora-browser" "$STAGE/usr/bin" \
         "$STAGE/usr/share/applications" "$STAGE/usr/share/icons/hicolor/48x48/apps"

cp "$COMMON/launch.sh" "$STAGE/opt/aurora-browser/launch-aurora.sh"
chmod +x "$STAGE/opt/aurora-browser/launch-aurora.sh"
cp "$COMMON/update.sh" "$STAGE/opt/aurora-browser/update.sh"
chmod +x "$STAGE/opt/aurora-browser/update.sh"
cp "$COMMON/update.conf" "$STAGE/opt/aurora-browser/update.conf"
cp "$COMMON/setup-sandbox.sh" "$STAGE/opt/aurora-browser/setup-sandbox.sh"
chmod +x "$STAGE/opt/aurora-browser/setup-sandbox.sh"
echo "CHROMIUM_VERSION=0" > "$STAGE/opt/aurora-browser/version.txt"
mkdir -p "$STAGE/opt/aurora-browser/profile" "$STAGE/opt/aurora-browser/extension"
rsync -a --exclude 'node_modules' "$ROOT/extension/" "$STAGE/opt/aurora-browser/extension/"
if [ -f "$ICON_SRC" ]; then
  cp "$ICON_SRC" "$STAGE/usr/share/icons/hicolor/48x48/apps/aurora-browser.png"
fi
ln -s /opt/aurora-browser/launch-aurora.sh "$STAGE/usr/bin/aurora-browser"

cat > "$STAGE/usr/share/applications/aurora-browser.desktop" <<'DESK'
[Desktop Entry]
Name=Aurora Browser
Comment=Chromium-based browser with auto-update
Exec=/opt/aurora-browser/launch-aurora.sh %U
Icon=aurora-browser
Terminal=false
Type=Application
Categories=Network;WebBrowser;
MimeType=text/html;x-scheme-handler/http;x-scheme-handler/https;
StartupWMClass=Aurora-Browser
DESK

# Build the RPM
RPMBUILD_DIR="$ROOT/build/rpmbuild"
rm -rf "$RPMBUILD_DIR"
mkdir -p "$RPMBUILD_DIR/BUILD" "$RPMBUILD_DIR/RPMS/x86_64" \
         "$RPMBUILD_DIR/SOURCES" "$RPMBUILD_DIR/SPECS" "$RPMBUILD_DIR/SRPMS"

# Create a source tarball of the staging
tar -czf "$RPMBUILD_DIR/SOURCES/aurora-browser-${VERSION}.tar.gz" -C "$STAGE" .

cat > "$RPMBUILD_DIR/SPECS/aurora-browser.spec" <<SPEC
Name:           aurora-browser
Version:        ${VERSION}
Release:        1%{?dist}
Summary:        Chromium-based browser with self-contained profile and auto-update
License:        MIT
URL:            https://github.com/Draftiermovie66/Aurora-Browser
Source0:        aurora-browser-${VERSION}.tar.gz
Requires:       curl, unzip, ca-certificates
BuildArch:      x86_64

%description
Aurora Browser - Chromium-based browser with self-contained profile,
custom new tab page, and auto-update from GitHub.

%prep
%setup -q -c

%install
mkdir -p %{buildroot}
cp -r ./* %{buildroot}/

%files
/opt/aurora-browser/
/usr/bin/aurora-browser
/usr/share/applications/aurora-browser.desktop
/usr/share/icons/hicolor/48x48/apps/aurora-browser.png

%post
if [ -x /opt/aurora-browser/update.sh ]; then
  /opt/aurora-browser/update.sh --quiet &
fi

%changelog
* $(date +"%a %b %d %Y") Aurora Browser <draftiermovie66@users.noreply.github.com>
- Version ${VERSION}
SPEC

rpmbuild -bb --define "_topdir $RPMBUILD_DIR" "$RPMBUILD_DIR/SPECS/aurora-browser.spec"

OUT="$ROOT/build/aurora-browser-${VERSION}-1.x86_64.rpm"
cp "$RPMBUILD_DIR/RPMS/x86_64"/*.rpm "$OUT"
echo "==> Built: $OUT"
