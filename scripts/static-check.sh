#!/usr/bin/env bash
#
# EclipseOS static checks. These do not replace a build or boot test; they
# catch syntax errors, unsafe shell patterns and malformed JSON before a long
# live-build run starts.

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
PYTHON="${PYTHON:-python3}"

fail() {
    printf 'static-check: %s\n' "$*" >&2
    exit 1
}

printf 'Shell syntax\n'
for script in "$ROOT_DIR"/scripts/*.sh; do
    bash -n "$script" || fail "bash syntax: ${script#"$ROOT_DIR"/}"
done
for hook in "$ROOT_DIR"/build/config/hooks/normal/*.chroot \
            "$ROOT_DIR"/build/config/hooks/normal/*.binary; do
    sh -n "$hook" || fail "sh syntax: ${hook#"$ROOT_DIR"/}"
done
for script in "$ROOT_DIR"/build/config/includes.chroot/usr/local/bin/eclipseos-* \
              "$ROOT_DIR"/build/config/includes.chroot/usr/libexec/eclipseos/*; do
    sh -n "$script" || fail "sh syntax: ${script#"$ROOT_DIR"/}"
done
printf '  ok\n'

if command -v shellcheck >/dev/null 2>&1; then
    printf 'ShellCheck\n'
    shellcheck -s bash "$ROOT_DIR"/scripts/*.sh
    for hook in "$ROOT_DIR"/build/config/hooks/normal/*.chroot \
                "$ROOT_DIR"/build/config/hooks/normal/*.binary; do
        shellcheck -s sh "$hook"
    done
    for script in "$ROOT_DIR"/build/config/includes.chroot/usr/local/bin/eclipseos-* \
                  "$ROOT_DIR"/build/config/includes.chroot/usr/libexec/eclipseos/*; do
        shellcheck -s sh "$script"
    done
    printf '  ok\n'
else
    printf 'ShellCheck not installed; shell lint skipped.\n'
fi

printf 'Python syntax\n'
"$PYTHON" -m py_compile \
    "$ROOT_DIR/branding/render.py" \
    "$ROOT_DIR/tests/qemu_boot_test.py"
printf '  ok\n'

printf 'Brand tokens\n'
"$PYTHON" -c 'import json, sys; json.load(open(sys.argv[1], encoding="utf-8"))' \
    "$ROOT_DIR/branding/tokens.json"
printf '  ok\n'

printf 'Firefox policy JSON\n'
"$PYTHON" -c 'import json, sys; json.load(open(sys.argv[1], encoding="utf-8"))' \
    "$ROOT_DIR/build/config/includes.chroot/usr/share/firefox-esr/distribution/policies.json"
printf '  ok\n'

printf 'Firmware allowlist\n'
"$PYTHON" - "$ROOT_DIR" <<'PY'
import re
import sys
from pathlib import Path

root = Path(sys.argv[1])
hook = (root / "build/config/hooks/normal/0300-licences.chroot").read_text(
    encoding="utf-8"
)
template = (
    root / "build/config/package-lists/eclipse-firmware.list.chroot.in"
).read_text(encoding="utf-8")

match = re.search(r'^ALLOWED_FIRMWARE="(.*?)"$', hook, re.MULTILINE | re.DOTALL)
if not match:
    raise SystemExit("static-check: ALLOWED_FIRMWARE block not found in hook")
hook_packages = [
    line.strip() for line in match.group(1).splitlines() if line.strip()
]
template_packages = [
    line.strip()
    for line in template.splitlines()
    if line.strip() and not line.lstrip().startswith("#")
]

if len(hook_packages) != len(set(hook_packages)):
    raise SystemExit("static-check: duplicate package in ALLOWED_FIRMWARE")
if len(template_packages) != len(set(template_packages)):
    raise SystemExit("static-check: duplicate package in firmware template")
if set(hook_packages) != set(template_packages):
    only_hook = sorted(set(hook_packages) - set(template_packages))
    only_template = sorted(set(template_packages) - set(hook_packages))
    raise SystemExit(
        "static-check: firmware allowlist mismatch; "
        f"only in hook: {only_hook or 'none'}; "
        f"only in template: {only_template or 'none'}"
    )

print(f"  ok ({len(hook_packages)} packages)")
PY

if command -v desktop-file-validate >/dev/null 2>&1; then
    printf 'Desktop entries\n'
    desktop-file-validate \
        "$ROOT_DIR/build/config/includes.chroot/usr/share/wayland-sessions/eclipseos-wayland.desktop" \
        "$ROOT_DIR/build/config/includes.chroot/usr/share/xsessions/eclipseos-x11.desktop" \
        "$ROOT_DIR/build/config/includes.chroot/usr/share/applications/org.eclipseos.theme-toggle.desktop" \
        "$ROOT_DIR/build/config/includes.chroot/etc/xdg/autostart/org.eclipseos.welcome.desktop" \
        "$ROOT_DIR/build/config/includes.chroot/etc/xdg/autostart/org.eclipseos.theme-apply.desktop" \
        "$ROOT_DIR/build/config/includes.chroot/etc/xdg/autostart/org.eclipseos.display-guard.desktop"
    printf '  ok\n'
fi

printf 'Static checks passed.\n'
