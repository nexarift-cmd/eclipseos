#!/usr/bin/env bash
#
# One-command EclipseOS ISO build. `make iso` is the supported interface.
#
# live-build needs root for the chroot. This wrapper re-executes itself with
# sudo while preserving the build options, prepares every generated part of the
# live-build tree (brand artwork, firmware list, GRUB font, licence documents),
# runs live-build, and gives generated artefacts back to the invoking user.
#
# Environment:
#   STRICT_FOSS=1     build without the non-free-firmware archive or any
#                     firmware package list (see docs/licenses.md)
#   SOURCE_DATE_EPOCH fixed build timestamp; defaults to the last commit time
#   GIT_COMMIT        override the recorded commit (used by CI)
#   EOS_VERSION       override VERSION (normally not needed)

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
VERSION="$(tr -d '\r\n' < "$ROOT_DIR/VERSION")"
ISO_NAME="eclipseos-${VERSION}-amd64"
BUILD_DIR="$ROOT_DIR/build"
OUT_ISO="$ROOT_DIR/${ISO_NAME}.iso"
ASSET_DIR="$ROOT_DIR/branding/assets"
DOC_STAGE="$BUILD_DIR/config/includes.chroot/usr/share/doc/eclipseos"
FIRMWARE_TEMPLATE="$BUILD_DIR/config/package-lists/eclipse-firmware.list.chroot.in"
FIRMWARE_LIST="$BUILD_DIR/config/package-lists/eclipse-firmware.list.chroot"
GRUB_DIR="$BUILD_DIR/config/bootloaders/grub-pc"

CLEAN=1
STRICT_FOSS="${STRICT_FOSS:-0}"

usage() {
    cat <<EOF
Usage: $(basename "$0") [options]

Options:
  --clean            Remove previous live-build state before building (default)
  --incremental      Reuse the existing chroot and binary tree
  --strict-foss      Same as STRICT_FOSS=1: no non-free firmware at all
  -h, --help         Show this help

Environment:
  STRICT_FOSS=1      Strict FOSS build (forces a clean build)
  SOURCE_DATE_EPOCH  Fixed build timestamp
  GIT_COMMIT         Commit recorded in build metadata
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --incremental) CLEAN=0 ;;
        --clean) CLEAN=1 ;;
        --strict-foss) STRICT_FOSS=1 ;;
        -h|--help) usage; exit 0 ;;
        *)
            printf 'Unknown option: %s\n' "$1" >&2
            usage >&2
            exit 2
            ;;
    esac
    shift
done

case "$STRICT_FOSS" in
    1|true|yes) STRICT_FOSS=1 ;;
    0|false|no|"") STRICT_FOSS=0 ;;
    *)
        printf 'error: invalid STRICT_FOSS value: %s (use 1 or 0)\n' "$STRICT_FOSS" >&2
        exit 2
        ;;
esac
export STRICT_FOSS

# A strict build must not inherit non-free packages from an earlier chroot.
if [[ "$STRICT_FOSS" -eq 1 && "$CLEAN" -eq 0 ]]; then
    printf 'STRICT_FOSS=1 forces a clean build; ignoring --incremental.\n'
    CLEAN=1
fi

ORIGINAL_UID="${SUDO_UID:-$(id -u)}"
ORIGINAL_GID="${SUDO_GID:-$(id -g)}"

compute_git_commit() {
    if [[ -n "${GIT_COMMIT:-}" ]]; then
        printf '%s' "$GIT_COMMIT"
    elif command -v git >/dev/null 2>&1 \
        && git -c safe.directory="$ROOT_DIR" -C "$ROOT_DIR" rev-parse --verify HEAD >/dev/null 2>&1; then
        git -c safe.directory="$ROOT_DIR" -C "$ROOT_DIR" rev-parse HEAD
    else
        printf 'not-a-git-checkout'
    fi
}

GIT_COMMIT="$(compute_git_commit)"
export GIT_COMMIT

if [[ "$(id -u)" -ne 0 ]]; then
    if ! command -v sudo >/dev/null 2>&1; then
        printf 'error: live-build requires root and sudo is not installed.\n' >&2
        printf 'Run as root or install sudo. See docs/build-environment.md.\n' >&2
        exit 1
    fi
    printf 'Elevating with sudo...\n'
    env_args=(
        env
        "STRICT_FOSS=$STRICT_FOSS"
        "GIT_COMMIT=$GIT_COMMIT"
        "EOS_VERSION=$VERSION"
    )
    if [[ -n "${SOURCE_DATE_EPOCH:-}" ]]; then
        env_args+=("SOURCE_DATE_EPOCH=$SOURCE_DATE_EPOCH")
    fi
    exec sudo "${env_args[@]}" bash "$0" "$@"
fi

restore_ownership() {
    [[ "$ORIGINAL_UID" -ne 0 ]] || return 0
    local path
    for path in \
        "$ASSET_DIR" \
        "$FIRMWARE_LIST" \
        "$GRUB_DIR/splash.png" \
        "$GRUB_DIR/unicode.pf2" \
        "$DOC_STAGE" \
        "$OUT_ISO" \
        "${OUT_ISO}.sha256" \
        "${OUT_ISO}.buildinfo" \
        "$BUILD_DIR/build.log" \
        "$BUILD_DIR/config.log"; do
        if [[ -e "$path" ]]; then
            chown -R "$ORIGINAL_UID:$ORIGINAL_GID" "$path" 2>/dev/null || true
        fi
    done
}
trap restore_ownership EXIT

if [[ ! -f "$BUILD_DIR/auto/config" || ! -d "$BUILD_DIR/config/package-lists" ]]; then
    printf 'error: live-build configuration is incomplete.\n' >&2
    printf 'Expected %s/auto/config and %s/config/package-lists.\n' "$BUILD_DIR" "$BUILD_DIR" >&2
    exit 1
fi

printf 'EclipseOS %s build\n' "$VERSION"
printf 'Root: %s\n' "$ROOT_DIR"
printf 'Licence mode: %s\n' "$([[ "$STRICT_FOSS" -eq 1 ]] && printf 'strict FOSS (main only)' || printf 'default (main + redistributable firmware)')"
"$SCRIPT_DIR/check-host.sh"

# A deterministic timestamp matters for generated metadata and reproducibility.
if [[ -z "${SOURCE_DATE_EPOCH:-}" ]]; then
    if [[ "$GIT_COMMIT" != "not-a-git-checkout" ]] \
        && SOURCE_DATE_EPOCH="$(git -c safe.directory="$ROOT_DIR" -C "$ROOT_DIR" \
            show -s --format=%ct "$GIT_COMMIT" 2>/dev/null)"; then
        :
    else
        SOURCE_DATE_EPOCH="$(date -u -d '2026-10-01 00:00:00Z' +%s)"
    fi
fi
if [[ ! "$SOURCE_DATE_EPOCH" =~ ^[0-9]+$ ]]; then
    printf 'error: SOURCE_DATE_EPOCH is not a Unix timestamp: %s\n' "$SOURCE_DATE_EPOCH" >&2
    exit 2
fi
export SOURCE_DATE_EPOCH
export EOS_VERSION="$VERSION"
export TZ=UTC
export LC_ALL=C.UTF-8
umask 022

printf 'SOURCE_DATE_EPOCH=%s (%s)\n' \
    "$SOURCE_DATE_EPOCH" \
    "$(date -u -d "@$SOURCE_DATE_EPOCH" '+%Y-%m-%dT%H:%M:%SZ')"
printf 'Git commit: %s\n' "$GIT_COMMIT"

cd "$BUILD_DIR"

if [[ "$CLEAN" -eq 1 ]]; then
    printf 'Cleaning previous live-build state...\n'
    lb clean --purge || true
fi

# ---------------------------------------------------------------------------
# Generated tree contents
#
# Everything below is gitignored and produced here. The hooks and the final
# verification hook fail the build if any of it is missing or empty.
# ---------------------------------------------------------------------------

printf 'Rendering EclipseOS brand assets...\n'
rm -rf "$ASSET_DIR"
python3 "$ROOT_DIR/branding/render.py" --out "$ASSET_DIR"

install -D -m 0644 \
    "$ASSET_DIR/eclipseos-wallpaper-1920x1080.png" \
    "$BUILD_DIR/config/includes.chroot/usr/share/backgrounds/eclipseos/eclipseos-wallpaper-1920x1080.png"
install -D -m 0644 \
    "$ASSET_DIR/eclipseos-mark-256.png" \
    "$BUILD_DIR/config/includes.chroot/usr/share/pixmaps/eclipseos/eclipseos-mark-256.png"
install -D -m 0644 \
    "$ASSET_DIR/eclipseos-mark.png" \
    "$BUILD_DIR/config/includes.chroot/usr/share/plymouth/themes/eclipseos/logo.png"
install -D -m 0644 \
    "$ASSET_DIR/eclipseos-plymouth-splash-1920x1080.png" \
    "$BUILD_DIR/config/includes.chroot/usr/share/plymouth/themes/eclipseos/splash.png"
install -D -m 0644 \
    "$ASSET_DIR/eclipseos-progress-track.png" \
    "$BUILD_DIR/config/includes.chroot/usr/share/plymouth/themes/eclipseos/eclipseos-progress-track.png"
install -D -m 0644 \
    "$ASSET_DIR/eclipseos-progress-fill.png" \
    "$BUILD_DIR/config/includes.chroot/usr/share/plymouth/themes/eclipseos/eclipseos-progress-fill.png"
install -D -m 0644 \
    "$ASSET_DIR/eclipseos-grub-splash-1024x768.png" \
    "$GRUB_DIR/splash.png"

GRUB_FONT=""
for candidate in /usr/share/grub/unicode.pf2 /usr/share/grub2/unicode.pf2; do
    if [[ -r "$candidate" ]]; then
        GRUB_FONT="$candidate"
        break
    fi
done
if [[ -z "$GRUB_FONT" ]]; then
    printf 'error: unicode.pf2 not found; install grub-common.\n' >&2
    exit 1
fi
install -D -m 0644 "$GRUB_FONT" "$GRUB_DIR/unicode.pf2"
printf 'GRUB font: %s\n' "$GRUB_FONT"

if [[ "$STRICT_FOSS" -eq 1 ]]; then
    rm -f "$FIRMWARE_LIST"
    printf 'Firmware list: disabled (STRICT_FOSS=1)\n'
else
    [[ -s "$FIRMWARE_TEMPLATE" ]] || {
        printf 'error: missing firmware template: %s\n' "$FIRMWARE_TEMPLATE" >&2
        exit 1
    }
    install -m 0644 "$FIRMWARE_TEMPLATE" "$FIRMWARE_LIST"
    printf 'Firmware list: %s\n' "${FIRMWARE_LIST#"$ROOT_DIR"/}"
fi

install -D -m 0644 "$ROOT_DIR/COPYING" "$DOC_STAGE/copyright"
install -D -m 0644 "$ROOT_DIR/docs/licenses.md" "$DOC_STAGE/licenses.md"
{
    printf 'EclipseOS %s\n' "$VERSION"
    printf 'Release: eclipse-%s\n' "$VERSION"
    printf 'Git commit: %s\n' "$GIT_COMMIT"
    printf 'Licence: GPL-3.0-or-later (original EclipseOS work)\n'
    printf 'Firmware mode: %s\n' "$([[ "$STRICT_FOSS" -eq 1 ]] && printf 'strict-foss' || printf 'redistributable-firmware')"
} > "$DOC_STAGE/version"

# live-build reads auto/config through `lb config`; run it explicitly so a
# configuration error stops the build before the package download starts.
printf 'Configuring live-build...\n'
set +e
lb config 2>&1 | tee "$BUILD_DIR/config.log"
LB_CONFIG_STATUS=${PIPESTATUS[0]}
set -e
if [[ "$LB_CONFIG_STATUS" -ne 0 ]]; then
    printf 'error: lb config failed with status %d. Inspect %s/config.log\n' \
        "$LB_CONFIG_STATUS" "$BUILD_DIR" >&2
    exit "$LB_CONFIG_STATUS"
fi

# `lb build` must see the same strictness as auto/config; export is defensive
# because the configuration stagefile is now present.
printf 'Running live-build (log: build/build.log)...\n'
set +e
lb build 2>&1 | tee "$BUILD_DIR/build.log"
LB_STATUS=${PIPESTATUS[0]}
set -e
if [[ "$LB_STATUS" -ne 0 ]]; then
    printf 'error: live-build failed with status %d. Inspect %s/build.log\n' \
        "$LB_STATUS" "$BUILD_DIR" >&2
    exit "$LB_STATUS"
fi

SOURCE_ISO=""
for candidate in \
    "$BUILD_DIR/live-image-amd64.hybrid.iso" \
    "$BUILD_DIR/live-image-amd64.iso"; do
    if [[ -f "$candidate" ]]; then
        SOURCE_ISO="$candidate"
        break
    fi
done
if [[ -z "$SOURCE_ISO" ]]; then
    SOURCE_ISO="$(find "$BUILD_DIR" -maxdepth 1 -type f \
        \( -name '*.hybrid.iso' -o -name 'live-image*.iso' \) -print -quit)"
fi
if [[ -z "$SOURCE_ISO" || ! -f "$SOURCE_ISO" ]]; then
    printf 'error: live-build completed but no ISO was found in %s\n' "$BUILD_DIR" >&2
    exit 1
fi

mv -f "$SOURCE_ISO" "$OUT_ISO"
"$SCRIPT_DIR/checksum.sh" "$OUT_ISO"

{
    printf 'EclipseOS %s\n' "$VERSION"
    printf 'Image: %s\n' "$(basename "$OUT_ISO")"
    printf 'SHA256: %s\n' "$(sha256sum "$OUT_ISO" | awk '{print $1}')"
    printf 'Built (UTC): %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    printf 'SOURCE_DATE_EPOCH: %s\n' "$SOURCE_DATE_EPOCH"
    printf 'Git commit: %s\n' "$GIT_COMMIT"
    printf 'Licence mode: %s\n' "$([[ "$STRICT_FOSS" -eq 1 ]] && printf 'strict-foss' || printf 'redistributable-firmware')"
    printf 'Build host: %s %s\n' "$(uname -srm)" "$(uname -o 2>/dev/null || true)"
    printf 'live-build: %s\n' "$(lb --version 2>/dev/null | head -n 1)"
    printf 'xorriso: %s\n' "$(xorriso --version 2>/dev/null | head -n 1)"
} > "${OUT_ISO}.buildinfo"

printf '\nBuilt: %s\n' "$OUT_ISO"
printf 'SHA256: %s\n' "$(sha256sum "$OUT_ISO" | awk '{print $1}')"
printf 'Build info: %s.buildinfo\n' "$OUT_ISO"
printf 'Test with: make test-all\n'
