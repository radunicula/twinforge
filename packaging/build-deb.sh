#!/usr/bin/env bash
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
cd "$ROOT"

for cmd in dpkg-deb dpkg-shlibdeps dpkg; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Error: '$cmd' is required (install dpkg-dev / dpkg on Ubuntu/Debian)." >&2
    exit 1
  fi
done

VER="$(sed -n 's/^pkgver=//p' pkgbuild/PKGBUILD | head -n 1)"
REL="$(sed -n 's/^pkgrel=//p' pkgbuild/PKGBUILD | head -n 1)"
VER="${VER:-0.2.0}"
REL="${REL:-1}"
DEB_ARCH="$(dpkg --print-architecture)"

if [ "${1:-}" != "--skip-build" ] || [ ! -x "$ROOT/build/twinforge" ]; then
  echo "==> Building TwinForge binary..."
  "$ROOT/bin/build"
fi

if command -v desktop-file-validate >/dev/null 2>&1; then
  desktop-file-validate "$ROOT/pkgbuild/twinforge.desktop"
fi

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

STAGE_DIR="$WORK_DIR/pkg"
mkdir -p \
  "$STAGE_DIR/DEBIAN" \
  "$STAGE_DIR/usr/bin" \
  "$STAGE_DIR/usr/share/applications" \
  "$STAGE_DIR/usr/share/icons/hicolor/256x256/apps" \
  "$STAGE_DIR/usr/share/icons/hicolor/scalable/apps" \
  "$STAGE_DIR/usr/share/doc/twinforge"

install -Dm755 "$ROOT/build/twinforge" "$STAGE_DIR/usr/bin/twinforge"
ln -sfn twinforge "$STAGE_DIR/usr/bin/tf"
install -Dm644 "$ROOT/pkgbuild/twinforge.desktop" "$STAGE_DIR/usr/share/applications/twinforge.desktop"
install -Dm644 "$ROOT/pkgbuild/twinforge.png" "$STAGE_DIR/usr/share/icons/hicolor/256x256/apps/twinforge.png"
install -Dm644 "$ROOT/pkgbuild/twinforge.svg" "$STAGE_DIR/usr/share/icons/hicolor/scalable/apps/twinforge.svg"
install -Dm644 "$ROOT/LICENSE" "$STAGE_DIR/usr/share/doc/twinforge/copyright"

# Compute shared library dependencies cleanly via dpkg-shlibdeps
mkdir -p "$WORK_DIR/shlib_probe/debian"
cat > "$WORK_DIR/shlib_probe/debian/control" <<'EOF'
Source: twinforge

Package: twinforge
Architecture: any
EOF

SHLIBS="$(cd "$WORK_DIR/shlib_probe" && dpkg-shlibdeps -O "$STAGE_DIR/usr/bin/twinforge" | sed -n 's/^shlibs:Depends=//p')"
QML_DEPS="qt6-qpa-plugins, qml6-module-qtquick, qml6-module-qtquick-controls, qml6-module-qtquick-layouts, qml6-module-qtquick-window, qml6-module-qtquick-templates, qml6-module-qtqml-workerscript, qml6-module-qtqml-models, qml6-module-qtcore, libqt6svg6, hicolor-icon-theme, xdg-utils"

if [ -n "$SHLIBS" ]; then
  ALL_DEPS="${SHLIBS}, ${QML_DEPS}"
else
  ALL_DEPS="${QML_DEPS}"
fi

sed \
  -e "s|@VERSION@|${VER}-${REL}|g" \
  -e "s|@ARCH@|${DEB_ARCH}|g" \
  -e "s|@DEPENDS@|${ALL_DEPS}|g" \
  "$ROOT/packaging/deb/control.in" > "$STAGE_DIR/DEBIAN/control"

mkdir -p "$ROOT/release"
DEB_OUT="$ROOT/release/twinforge_${VER}-${REL}_${DEB_ARCH}.deb"
dpkg-deb --build --root-owner-group "$STAGE_DIR" "$DEB_OUT"

echo "==> Built: $DEB_OUT"
dpkg-deb --info "$DEB_OUT"
dpkg-deb --contents "$DEB_OUT"
