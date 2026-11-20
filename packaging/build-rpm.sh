#!/usr/bin/env bash
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
cd "$ROOT"

if ! command -v rpmbuild >/dev/null 2>&1; then
  echo "Error: rpmbuild is required (install rpm-build on Fedora)." >&2
  exit 1
fi

VER="$(sed -n 's/^pkgver=//p' pkgbuild/PKGBUILD | head -n 1)"
REL="$(sed -n 's/^pkgrel=//p' pkgbuild/PKGBUILD | head -n 1)"
VER="${VER:-0.1.0}"
REL="${REL:-1}"

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

mkdir -p "$WORK_DIR"/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}

echo "==> Packaging source tarball twinforge-${VER}.tar.gz..."
tar \
  --exclude='./.git' \
  --exclude='./build' \
  --exclude='./release' \
  --exclude='./pkgbuild/pkg' \
  --exclude='./pkgbuild/src' \
  --transform="s,^\.,twinforge-${VER}," \
  -czf "$WORK_DIR/SOURCES/twinforge-${VER}.tar.gz" .

cp "$ROOT/packaging/rpm/twinforge.spec" "$WORK_DIR/SPECS/twinforge.spec"

echo "==> Building RPM for TwinForge v${VER}-${REL}..."
rpmbuild \
  --define "_topdir $WORK_DIR" \
  --define "pkgver $VER" \
  --define "pkgrel $REL" \
  -bb "$WORK_DIR/SPECS/twinforge.spec"

mkdir -p "$ROOT/release"
RPM_FILES="$(find "$WORK_DIR/RPMS" -type f -name '*.rpm')"
if [ -z "$RPM_FILES" ]; then
  echo "Error: rpmbuild produced no .rpm file" >&2
  exit 1
fi

while IFS= read -r rpm_path; do
  cp -f "$rpm_path" "$ROOT/release/"
  out_rpm="$ROOT/release/$(basename "$rpm_path")"
  echo "==> Built: $out_rpm"
  rpm -qlp "$out_rpm"
done <<< "$RPM_FILES"
