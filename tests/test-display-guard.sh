#!/bin/sh
#
# Unit checks for the display guard's fit decision. The real guard cannot be
# boot-tested for a post-start resolution change in QEMU because the test
# harness does not run commands inside the guest. Extract the pure function and
# check the cases that distinguish a VirtualBox fullscreen/window transition
# from a deliberately smaller user-selected mode.
set -eu

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
DISPLAY_SCRIPT="$ROOT_DIR/build/config/includes.chroot/usr/local/bin/eclipseos-display"
TMP_FILE="$(mktemp)"
trap 'rm -f "$TMP_FILE"' EXIT HUP INT TERM

sed -n '/^needs_fit()/,/^}/p' "$DISPLAY_SCRIPT" >"$TMP_FILE"
# shellcheck source=/dev/null
. "$TMP_FILE"

failures=0
check() {
    expected="$1"
    current="$2"
    target="$3"
    if needs_fit "$current" "$target"; then
        actual=fit
    else
        actual=keep
    fi
    if [ "$actual" != "$expected" ]; then
        printf 'display guard: %s against %s: expected %s, got %s\n' \
            "${current:-<empty>}" "${target:-<empty>}" "$expected" "$actual" >&2
        failures=$((failures + 1))
    fi
}

# VirtualBox returns to its taller default when leaving fullscreen.
check fit 1280x800 1280x720
check fit 1366x768 1280x720
check fit 1920x1080 1280x720
check fit 1024x768 1280x720
check fit 1280x721 1280x720
# A mode that is wider but not taller than the target is still clipped by a
# narrow host window, so it must be fitted too.
check fit 1920x600 1280x720
# Already-fits and deliberately smaller modes are preserved.
check keep 1280x720 1280x720
check keep 1024x600 1280x720
check keep 800x600 1280x720
check keep 640x480 1280x720
# `eclipseos.display=keep` reaches the guard as an empty desired target.
check keep 1280x800 ""
# Unparseable geometry is not treated as a reason to force a mode.
check keep unknown 1280x720
check keep 1280x720 invalid

if [ "$failures" -ne 0 ]; then
    exit 1
fi
