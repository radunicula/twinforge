#!/usr/bin/env bash
set -euo pipefail

BIN="${1:-/usr/bin/twinforge}"
TF_BIN="/usr/bin/tf"

echo "==> Verifying installed binary & CLI alias..."
test -x "$BIN"
test -x "$TF_BIN"

echo "==> Checking dynamic library resolution (ldd)..."
LDD_OUT="$(ldd "$BIN")"
echo "$LDD_OUT" | grep -E "libQt6|libarchive" || true
if echo "$LDD_OUT" | grep -q "not found"; then
  echo "Error: Unresolved shared library dependencies:" >&2
  echo "$LDD_OUT" | grep "not found" >&2
  exit 1
fi

echo "==> Verifying CLI flags (--version, --help, --shell-init)..."
VER_OUT="$("$BIN" --version)"
echo "$VER_OUT"
echo "$VER_OUT" | grep -q "twinforge "
"$TF_BIN" --help | grep -q -- "--smoke-test"
"$TF_BIN" --shell-init bash | grep -q "tfcd()"

echo "==> Verifying desktop entry & icons..."
DESKTOP_FILE="/usr/share/applications/twinforge.desktop"
test -f "$DESKTOP_FILE"
if command -v desktop-file-validate >/dev/null 2>&1; then
  desktop-file-validate "$DESKTOP_FILE"
fi
grep -q "^Exec=twinforge %U$" "$DESKTOP_FILE"
test -f /usr/share/icons/hicolor/256x256/apps/twinforge.png
test -f /usr/share/icons/hicolor/scalable/apps/twinforge.svg

echo "==> Running end-to-end headless archive copy smoke test..."
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$TMP/cfg" "$TMP/cache" "$TMP/out"
PAYLOAD="TwinForge archive smoke test payload"

python3 - "$TMP/sample.zip" "$PAYLOAD" <<'PY'
import sys, zipfile
zip_path, payload = sys.argv[1], sys.argv[2]
with zipfile.ZipFile(zip_path, "w") as zf:
    zf.writestr("hello.txt", payload + "\n")
PY

SMOKE_OUT="$(
  QT_QPA_PLATFORM=offscreen \
  XDG_CONFIG_HOME="$TMP/cfg" \
  XDG_CACHE_HOME="$TMP/cache" \
  "$BIN" --smoke-test "$TMP/sample.zip" "$TMP/out"
)"
echo "$SMOKE_OUT"
echo "$SMOKE_OUT" | grep -q "SMOKE_TEST_OK:"

test -f "$TMP/out/hello.txt"
ACTUAL="$(cat "$TMP/out/hello.txt")"
if [ "$ACTUAL" != "$PAYLOAD" ]; then
  echo "Error: Extracted payload mismatch: expected '$PAYLOAD', got '$ACTUAL'" >&2
  exit 1
fi

echo "==> Package smoke test PASSED!"
