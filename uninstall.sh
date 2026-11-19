#!/usr/bin/env bash
set -euo pipefail

SYSTEM_UNINSTALL=0
if [ "${1:-}" = "--system" ]; then
  SYSTEM_UNINSTALL=1
fi

if [ "$SYSTEM_UNINSTALL" -eq 1 ]; then
  PREFIX="/usr/local"
  SUDO="sudo"
else
  PREFIX="${HOME}/.local"
  SUDO=""
fi

echo "==> Removing TwinForge from ${PREFIX}..."
$SUDO rm -f \
  "${PREFIX}/bin/twinforge" \
  "${PREFIX}/bin/tf" \
  "${PREFIX}/share/applications/twinforge.desktop" \
  "${PREFIX}/share/icons/hicolor/256x256/apps/twinforge.png" \
  "${PREFIX}/share/icons/hicolor/scalable/apps/twinforge.svg" \
  "${PREFIX}/share/licenses/twinforge/LICENSE"
$SUDO rmdir "${PREFIX}/share/licenses/twinforge" 2>/dev/null || true

if command -v update-desktop-database >/dev/null 2>&1; then
  $SUDO update-desktop-database "${PREFIX}/share/applications" 2>/dev/null || true
fi
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  $SUDO gtk-update-icon-cache -f -t "${PREFIX}/share/icons/hicolor" 2>/dev/null || true
fi

echo "TwinForge uninstalled. Your settings in ~/.config/twinforge were preserved."
