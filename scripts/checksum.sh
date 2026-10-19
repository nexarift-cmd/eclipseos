#!/usr/bin/env bash
#
# Create or verify the SHA256 file for an EclipseOS ISO.
# The .sha256 file is written next to the ISO and contains only the basename,
# so it can be verified from the same directory.
#
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"

MODE=create
case "${1:-}" in
    --verify) MODE=verify; shift ;;
    -h|--help)
        printf 'Usage: %s [--verify] [path/to/image.iso]\n' "$(basename "$0")"
        printf 'Without --verify, writes <image>.sha256 next to the image.\n'
        exit 0
        ;;
    --*)
        printf 'Unknown option: %s\n' "$1" >&2
        printf 'Usage: %s [--verify] [path/to/image.iso]\n' "$(basename "$0")" >&2
        exit 2
        ;;
esac

ISO="${1:-$ROOT_DIR/eclipseos-$(tr -d '\r\n' < "$ROOT_DIR/VERSION")-amd64.iso}"
if [[ ! -f "$ISO" ]]; then
    printf 'error: ISO not found: %s\n' "$ISO" >&2
    printf 'usage: %s [--verify] [path/to/image.iso]\n' "$(basename "$0")" >&2
    exit 2
fi

ISO_DIR="$(cd -- "$(dirname -- "$ISO")" && pwd)"
ISO_BASE="$(basename -- "$ISO")"
SHA_FILE="${ISO}.sha256"

if [[ "$MODE" == "verify" ]]; then
    if [[ ! -f "$SHA_FILE" ]]; then
        printf 'error: checksum file not found: %s\n' "$SHA_FILE" >&2
        exit 2
    fi
    (
        cd "$ISO_DIR"
        sha256sum -c "$(basename -- "$SHA_FILE")"
    )
    printf 'Checksum verified: %s\n' "$ISO_BASE"
    exit 0
fi

(
    cd "$ISO_DIR"
    sha256sum "$ISO_BASE" > "$(basename -- "$SHA_FILE")"
)
printf 'Wrote %s\n' "$SHA_FILE"
