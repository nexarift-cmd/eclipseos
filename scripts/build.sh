#!/usr/bin/env bash
#
# One-command EclipseOS ISO build. `make iso` is the supported interface.
#
# live-build needs root for the chroot. This wrapper re-executes itself with
# sudo while preserving SOURCE_DATE_EPOCH and normal build options, then gives
# generated artefacts back to the invoking user.

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
VERSION="$(tr -d '\r\n' < "$ROOT_DIR/VERSION")"
ISO_NAME="eclipseos-${VERSION}-amd64"
BUILD_DIR="$ROOT_DIR/build"
OUT_ISO="$ROOT_DIR/${ISO_NAME}.iso"

CLEAN=1
while [[ $# -gt 0 ]]; do
    case "$1" in
        --incremental) CLEAN=0 ;;
        --clean) CLEAN=1 ;;
        -h|--help)
            printf 'Usage: %s [--clean|--incremental]\n' "$(basename "$0")"
            exit 0
            ;;
        *)
            printf 'Unknown option: %s\n' "$1" >&2
            exit 2
            ;;
    esac
    shift
done

ORIGINAL_UID="${SUDO_UID:-$(id -u)}"
ORIGINAL_GID="${SUDO_GID:-$(id -g)}"

if [[ "$(id -u)" -ne 0 ]]; then
    if ! command -v sudo >/dev/null 2>&1; then
        printf 'error: live-build requires root and sudo is not installed.\n' >&2
        printf 'Run as root or install sudo. See docs/build-environment.md.\n' >&2
        exit 1
    fi
    exec sudo -E bash "$0" "$@"
fi

if [[ ! -f "$BUILD_DIR/auto/config" || ! -d "$BUILD_DIR/config/package-lists" ]]; then
    printf 'error: live-build configuration is incomplete (Phase 1 not implemented).\n' >&2
    printf 'Expected %s/auto/config and %s/config/package-lists.\n' "$BUILD_DIR" "$BUILD_DIR" >&2
    exit 1
fi

printf 'EclipseOS %s build\n' "$VERSION"
printf 'Root: %s\n' "$ROOT_DIR"
"$SCRIPT_DIR/check-host.sh"

# Pinned snapshot builds and reproducible timestamps will be enabled once the
# snapshot inputs are finalised. For now use the source commit time, falling
# back to the release month when the tree is not a git checkout.
if [[ -z "${SOURCE_DATE_EPOCH:-}" ]]; then
    if git -C "$ROOT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        SOURCE_DATE_EPOCH="$(git -C "$ROOT_DIR" log -1 --format=%ct)"
    else
        SOURCE_DATE_EPOCH="$(date -u -d '2026-10-01 00:00:00Z' +%s)"
    fi
fi
export SOURCE_DATE_EPOCH
export TZ=UTC
export LC_ALL=C.UTF-8
umask 022

printf 'SOURCE_DATE_EPOCH=%s (%s)\n' "$SOURCE_DATE_EPOCH" "$(date -u -d "@$SOURCE_DATE_EPOCH" '+%Y-%m-%dT%H:%M:%SZ')"

cd "$BUILD_DIR"

if [[ "$CLEAN" -eq 1 ]]; then
    printf 'Cleaning previous live-build state...\n'
    lb clean --purge || true
fi

printf 'Running live-build (log: build/build.log)...\n'
set +e
lb build 2>&1 | tee "$BUILD_DIR/build.log"
LB_STATUS=${PIPESTATUS[0]}
set -e
if [[ "$LB_STATUS" -ne 0 ]]; then
    printf 'error: live-build failed with status %d. Inspect %s/build.log\n' "$LB_STATUS" "$BUILD_DIR" >&2
    exit "$LB_STATUS"
fi

SOURCE_ISO=""
for candidate in \
    "$BUILD_DIR/live-image-amd64.hybrid.iso" \
    "$BUILD_DIR/live-image-amd64.iso"; do
    if [[ -f "$candidate" ]]; then SOURCE_ISO="$candidate"; break; fi
done
if [[ -z "$SOURCE_ISO" ]]; then
    SOURCE_ISO="$(find "$BUILD_DIR" -maxdepth 1 -type f \( -name '*.hybrid.iso' -o -name 'live-image*.iso' \) -print -quit)"
fi
if [[ -z "$SOURCE_ISO" || ! -f "$SOURCE_ISO" ]]; then
    printf 'error: live-build completed but no ISO was found in %s\n' "$BUILD_DIR" >&2
    exit 1
fi

mv -f "$SOURCE_ISO" "$OUT_ISO"
"$SCRIPT_DIR/checksum.sh" "$OUT_ISO"

GIT_COMMIT="$(git -C "$ROOT_DIR" rev-parse HEAD 2>/dev/null || printf 'not-a-git-checkout')"
{
    printf 'EclipseOS %s\n' "$VERSION"
    printf 'Image: %s\n' "$(basename "$OUT_ISO")"
    printf 'SHA256: %s\n' "$(sha256sum "$OUT_ISO" | awk '{print $1}')"
    printf 'Built (UTC): %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    printf 'SOURCE_DATE_EPOCH: %s\n' "$SOURCE_DATE_EPOCH"
    printf 'Git commit: %s\n' "$GIT_COMMIT"
    printf 'Build host: %s %s\n' "$(uname -srm)" "$(uname -o 2>/dev/null || true)"
    printf 'live-build: %s\n' "$(lb --version 2>/dev/null | head -n 1)"
    printf 'xorriso: %s\n' "$(xorriso --version 2>/dev/null | head -n 1)"
} > "${OUT_ISO}.buildinfo"

if [[ "$ORIGINAL_UID" -ne 0 ]]; then
    chown "$ORIGINAL_UID:$ORIGINAL_GID" "$OUT_ISO" "${OUT_ISO}.sha256" "${OUT_ISO}.buildinfo" 2>/dev/null || true
fi

printf '\nBuilt: %s\n' "$OUT_ISO"
printf 'SHA256: %s\n' "$(sha256sum "$OUT_ISO" | awk '{print $1}')"
printf 'Build info: %s.buildinfo\n' "$OUT_ISO"
printf 'Test with: make test-all\n'
