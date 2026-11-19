#!/usr/bin/env bash
set -euo pipefail

# TwinForge Linux Binary Installer
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/radunicula/twinforge/main/install.sh | bash
#   ./install.sh [--version v0.1.0] [--system] [--from-tarball /path/to/tarball.tar.gz]

REPO="${TWINFORGE_REPO:-radunicula/twinforge}"
VERSION=""
SYSTEM_INSTALL=0
LOCAL_TARBALL=""

while [ $# -gt 0 ]; do
  case "$1" in
    --version)
      VERSION="${2:?Missing value for --version}"
      shift 2
      ;;
    --system)
      SYSTEM_INSTALL=1
      shift
      ;;
    --from-tarball)
      LOCAL_TARBALL="${2:?Missing value for --from-tarball}"
      shift 2
      ;;
    -h|--help)
      cat <<'EOF'
TwinForge Installer

Options:
  --version <tag>          Install a specific release tag (e.g. v0.1.0). Defaults to latest.
  --system                 Install system-wide into /usr/local (requires sudo). Default: ~/.local.
  --from-tarball <file>    Install offline from a local twinforge-*.tar.gz archive.
  -h, --help               Show this help.
EOF
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

ARCH="$(uname -m)"
case "$ARCH" in
  x86_64|aarch64) ;;
  *)
    echo "Unsupported architecture: $ARCH (supported: x86_64, aarch64)" >&2
    exit 1
    ;;
esac

if [ "$SYSTEM_INSTALL" -eq 1 ]; then
  PREFIX="/usr/local"
  SUDO="sudo"
else
  PREFIX="${HOME}/.local"
  SUDO=""
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

TARBALL="$LOCAL_TARBALL"
if [ -z "$TARBALL" ]; then
  command -v curl >/dev/null 2>&1 || { echo "Error: curl is required." >&2; exit 1; }

  if [ -z "$VERSION" ]; then
    echo "==> Fetching latest TwinForge release from github.com/${REPO}..."
    VERSION="$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" \
      | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)"
    if [ -z "$VERSION" ]; then
      echo "Error: Could not determine latest release version for ${REPO}." >&2
      exit 1
    fi
  fi

  CLEAN_VER="${VERSION#v}"
  ASSET="twinforge-${CLEAN_VER}-linux-${ARCH}.tar.gz"
  BASE_URL="https://github.com/${REPO}/releases/download/${VERSION}"
  TARBALL="${TMP_DIR}/${ASSET}"

  echo "==> Downloading ${ASSET} (${VERSION})..."
  curl -fsSL "${BASE_URL}/${ASSET}" -o "$TARBALL"

  if curl -fsSL "${BASE_URL}/SHA256SUMS.txt" -o "${TMP_DIR}/SHA256SUMS.txt" 2>/dev/null; then
    echo "==> Verifying SHA-256 checksum..."
    EXPECTED="$(grep "  ${ASSET}\$" "${TMP_DIR}/SHA256SUMS.txt" | awk '{print $1}' | head -n 1 || true)"
    if [ -n "$EXPECTED" ]; then
      ACTUAL="$(sha256sum "$TARBALL" | awk '{print $1}')"
      if [ "$EXPECTED" != "$ACTUAL" ]; then
        echo "Error: SHA-256 mismatch for ${ASSET}!" >&2
        echo "  Expected: ${EXPECTED}" >&2
        echo "  Actual:   ${ACTUAL}" >&2
        exit 1
      fi
      echo "    Checksum OK (${ACTUAL:0:16}...)"
    fi
  fi
fi

echo "==> Extracting package..."
tar -xzf "$TARBALL" -C "$TMP_DIR"
BIN_FOUND="$(find "$TMP_DIR" -maxdepth 4 -type f -path '*/bin/twinforge' | head -n 1 || true)"
if [ -z "$BIN_FOUND" ] || [ ! -f "$BIN_FOUND" ]; then
  echo "Error: Invalid TwinForge archive layout." >&2
  exit 1
fi
SRC_ROOT="$(dirname "$(dirname "$BIN_FOUND")")"

echo "==> Installing TwinForge into ${PREFIX}..."
$SUDO install -Dm755 "${SRC_ROOT}/bin/twinforge" "${PREFIX}/bin/twinforge"
$SUDO ln -sfn twinforge "${PREFIX}/bin/tf"
$SUDO install -Dm644 "${SRC_ROOT}/share/applications/twinforge.desktop" "${PREFIX}/share/applications/twinforge.desktop"
$SUDO install -Dm644 "${SRC_ROOT}/share/icons/hicolor/256x256/apps/twinforge.png" "${PREFIX}/share/icons/hicolor/256x256/apps/twinforge.png"
$SUDO install -Dm644 "${SRC_ROOT}/share/icons/hicolor/scalable/apps/twinforge.svg" "${PREFIX}/share/icons/hicolor/scalable/apps/twinforge.svg"
if [ -f "${SRC_ROOT}/LICENSE" ]; then
  $SUDO install -Dm644 "${SRC_ROOT}/LICENSE" "${PREFIX}/share/licenses/twinforge/LICENSE"
fi

if command -v update-desktop-database >/dev/null 2>&1; then
  $SUDO update-desktop-database "${PREFIX}/share/applications" 2>/dev/null || true
fi
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  $SUDO gtk-update-icon-cache -f -t "${PREFIX}/share/icons/hicolor" 2>/dev/null || true
fi

if command -v ldd >/dev/null 2>&1; then
  MISSING_LIBS="$(ldd "${PREFIX}/bin/twinforge" 2>&1 | grep -E 'not found|version .* not found' || true)"
  if [ -n "$MISSING_LIBS" ]; then
    echo ""
    echo "Warning: Some required system libraries are missing or older than required:" >&2
    echo "$MISSING_LIBS" >&2
    echo "" >&2
    echo "Note: Current binary releases target Arch Linux / Arch-based rolling distros (Qt 6 + libarchive)." >&2
    echo "On Arch: sudo pacman -S qt6-base qt6-declarative qt6-svg qt6-wayland libarchive" >&2
  fi
fi

echo ""
echo "TwinForge installed successfully!"
echo "  Binary: ${PREFIX}/bin/twinforge (alias: tf)"
if [ "$SYSTEM_INSTALL" -eq 0 ] && [[ ":${PATH}:" != *":${PREFIX}/bin:"* ]]; then
  echo "  Note: Add ${PREFIX}/bin to your PATH to run 'twinforge' or 'tf' from any terminal."
fi
echo ""
echo "Optional: enable shell cd-on-exit ('tfcd') by adding to ~/.bashrc or ~/.zshrc:"
echo "  eval \"\$(tf --shell-init bash)\"   # or zsh / fish"
