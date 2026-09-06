#!/usr/bin/env bash
set -euo pipefail
# Aurora Browser — Build .rpm package from Ladybird build output

BUILD_DIR="${1:?Usage: build-rpm.sh <ladybird-build-dir> <output-dir> <version>}"
OUTPUT_DIR="${2:?}"
VERSION="${3:?}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "  Building .rpm package..."

STAGE=$(mktemp -d)
mkdir -p "$STAGE/opt/aurora-browser" \
         "$STAGE/usr/bin" \
         "$STAGE/usr/share/applications" \
         "$STAGE/usr/share/icons/hicolor/48x48/apps"

# Find the built ladybird binary
BUILT_BIN=$(find "$BUILD_DIR" -name "ladybird" -type f -executable 2>/dev/null | head -n1)
if [ -z "$BUILT_BIN" ]; then
  echo "ERROR: ladybird binary not found"
  exit 1
fi
BUILT_DIR=$(dirname "$BUILT_BIN")

# Copy engine files
cp -R "$BUILT_DIR"/* "$STAGE/opt/aurora-browser/"

# Copy icon
ICON="$ROOT/assets/icons/aurora.png"
[ -f "$ICON" ] || ICON="$ROOT/aurora.png"
[ -f "$ICON" ] && cp "$ICON" "$STAGE/usr/share/icons/hicolor/48x48/apps/aurora-browser.png"

# Symlink
ln -s /opt/aurora-browser/ladybird "$STAGE/usr/bin/aurora-browser"

# .desktop file
cat > "$STAGE/usr/share/applications/aurora-browser.desktop" <<'DESK'
[Desktop Entry]
Name=Aurora Browser
Comment=Custom open-source browser with LibWeb engine
Exec=/usr/bin/aurora-browser %U
Icon=aurora-browser
Terminal=false
Type=Application
Categories=Network;WebBrowser;
MimeType=text/html;x-scheme-handler/http;x-scheme-handler/https;
DESK

# RPM build
RPMBUILD_DIR=$(mktemp -d)
mkdir -p "$RPMBUILD_DIR/BUILD" "$RPMBUILD_DIR/RPMS/x86_64" \
         "$RPMBUILD_DIR/SOURCES" "$RPMBUILD_DIR/SPECS" "$RPMBUILD_DIR/SRPMS"

tar -czf "$RPMBUILD_DIR/SOURCES/aurora-browser-${VERSION}.tar.gz" -C "$STAGE" .

cat > "$RPMBUILD_DIR/SPECS/aurora-browser.spec" <<SPEC
Name:           aurora-browser
Version:        ${VERSION}
Release:        1%{?dist}
Summary:        Custom open-source browser with LibWeb engine
License:        MIT
URL:            https://github.com/Draftiermovie66/Aurora-Browser
Source0:        aurora-browser-${VERSION}.tar.gz
Requires:       glx-utils mesa-libGLU pulseaudio-libs openssl
BuildArch:      x86_64

%description
Aurora Browser is built on the Ladybird LibWeb engine.
No Chromium. No Firefox. Custom open-source engine.

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

%changelog
* $(date +"%a %b %d %Y") Aurora Browser <draftiermovie66@users.noreply.github.com>
- Version ${VERSION}
SPEC

rpmbuild -bb --define "_topdir $RPMBUILD_DIR" "$RPMBUILD_DIR/SPECS/aurora-browser.spec"

RPM="$OUTPUT_DIR/aurora-browser-${VERSION}-1.x86_64.rpm"
cp "$RPMBUILD_DIR/RPMS/x86_64"/*.rpm "$RPM"
rm -rf "$STAGE" "$RPMBUILD_DIR"
echo "  Built: $RPM"
