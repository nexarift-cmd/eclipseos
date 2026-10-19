#!/usr/bin/env bash
#
# Headless QEMU boot test for EclipseOS. Requires the live image's
# eclipseos-bootcheck service to print ECLIPSEOS_BOOT_OK to ttyS0.
#
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
VERSION="$(tr -d '\r\n' < "$ROOT_DIR/VERSION")"

FIRMWARE="uefi"
ISO="$ROOT_DIR/eclipseos-${VERSION}-amd64.iso"
TIMEOUT=900
MEMORY=4096
CPUS=2
OUTDIR=""

usage() {
    cat <<'EOF'
Usage: test-qemu.sh [options]

Options:
  --firmware uefi|bios  Firmware mode (default: uefi)
  --iso PATH            ISO to test (default: ./eclipseos-<version>-amd64.iso)
  --timeout SECONDS     Boot timeout in seconds (default: 900)
  --memory MB           Guest RAM in MiB (default: 4096)
  --cpus N              Guest vCPUs (default: 2)
  --outdir PATH         Output directory (default: tests/out/<timestamp>-<firmware>)
  -h, --help            Show this help
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --firmware) FIRMWARE="${2:?--firmware requires uefi or bios}"; shift 2 ;;
        --iso) ISO="${2:?--iso requires a path}"; shift 2 ;;
        --timeout) TIMEOUT="${2:?--timeout requires seconds}"; shift 2 ;;
        --memory) MEMORY="${2:?--memory requires MiB}"; shift 2 ;;
        --cpus) CPUS="${2:?--cpus requires a number}"; shift 2 ;;
        --outdir) OUTDIR="${2:?--outdir requires a path}"; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
    esac
done

case "$FIRMWARE" in
    uefi|bios) ;;
    *) printf 'error: --firmware must be uefi or bios\n' >&2; exit 2 ;;
esac

if [[ ! -f "$ISO" ]]; then
    printf 'error: ISO not found: %s\n' "$ISO" >&2
    printf 'Build it with make iso first.\n' >&2
    exit 1
fi

if ! command -v qemu-system-x86_64 >/dev/null 2>&1; then
    printf 'error: qemu-system-x86_64 not found. Install qemu-system-x86.\n' >&2
    exit 1
fi
if ! command -v python3 >/dev/null 2>&1; then
    printf 'error: python3 not found.\n' >&2
    exit 1
fi

if [[ -f "${ISO}.sha256" ]]; then
    printf 'Verifying ISO checksum...\n'
    ( cd "$(dirname -- "$ISO")" && sha256sum -c "$(basename -- "${ISO}.sha256")" )
else
    printf 'warning: no SHA256 file beside the ISO; proceeding without verification.\n' >&2
fi

if [[ -z "$OUTDIR" ]]; then
    OUTDIR="$ROOT_DIR/tests/out/$(date -u '+%Y%m%dT%H%M%SZ')-${FIRMWARE}"
fi
mkdir -p "$OUTDIR"

exec python3 "$ROOT_DIR/tests/qemu_boot_test.py" \
    --firmware "$FIRMWARE" \
    --iso "$ISO" \
    --timeout "$TIMEOUT" \
    --memory "$MEMORY" \
    --cpus "$CPUS" \
    --outdir "$OUTDIR"
