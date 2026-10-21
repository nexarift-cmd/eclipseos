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
MACHINE="q35"
VGA="std"
OPTICAL="auto"
DIRECT_KERNEL=0
KERNEL=""
INITRD=""
KERNEL_APPEND="console=tty0 console=ttyS0,115200n8 quiet"
OUTDIR=""
BOOT_TMP=""
IDENTITY_TMP=""

cleanup() {
    if [[ -n "$BOOT_TMP" ]]; then
        rm -rf "$BOOT_TMP"
    fi
    if [[ -n "$IDENTITY_TMP" ]]; then
        rm -rf "$IDENTITY_TMP"
    fi
}
trap cleanup EXIT HUP INT TERM

usage() {
    cat <<'EOF'
Usage: test-qemu.sh [options]

Options:
  --firmware uefi|bios  Firmware mode (default: uefi)
  --iso PATH            ISO to test (default: ./eclipseos-<version>-amd64.iso)
  --timeout SECONDS     Boot timeout in seconds (default: 900)
  --memory MB           Guest RAM in MiB (default: 4096)
  --cpus N              Guest vCPUs (default: 2)
  --machine q35|pc      QEMU machine (default: q35; pc for VirtualBox-like IDE)
  --vga std|vmware      VGA adapter (default: std; vmware is VMSVGA-like)
  --optical auto|ide    Optical attachment (default: auto; ide uses pc secondary master)
  --direct-kernel-no-live
                        Boot the ISO kernel/initrd directly, omitting boot=live.
                        Requires xorriso to extract the kernel and initrd.
  --outdir PATH         Output directory (default: tests/out/<timestamp>-<firmware>-...)
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
        --machine) MACHINE="${2:?--machine requires q35 or pc}"; shift 2 ;;
        --vga) VGA="${2:?--vga requires std or vmware}"; shift 2 ;;
        --optical) OPTICAL="${2:?--optical requires auto or ide}"; shift 2 ;;
        --direct-kernel-no-live) DIRECT_KERNEL=1; shift ;;
        --outdir) OUTDIR="${2:?--outdir requires a path}"; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
    esac
done

case "$FIRMWARE" in
    uefi|bios) ;;
    *) printf 'error: --firmware must be uefi or bios\n' >&2; exit 2 ;;
esac
case "$MACHINE" in
    q35|pc) ;;
    *) printf 'error: --machine must be q35 or pc\n' >&2; exit 2 ;;
esac
case "$VGA" in
    std|vmware) ;;
    *) printf 'error: --vga must be std or vmware\n' >&2; exit 2 ;;
esac
case "$OPTICAL" in
    auto|ide) ;;
    *) printf 'error: --optical must be auto or ide\n' >&2; exit 2 ;;
esac
if [[ "$OPTICAL" == "ide" && "$MACHINE" != "pc" ]]; then
    printf 'error: --optical ide requires --machine pc\n' >&2
    exit 2
fi

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

if command -v xorriso >/dev/null 2>&1; then
    IDENTITY_TMP="$(mktemp -d "${TMPDIR:-/tmp}/eclipseos-identity.XXXXXX")"
    xorriso -osirrox on -indev "$ISO" \
        -extract /.disk/info "$IDENTITY_TMP" >/dev/null
    ISO_IDENTITY="$(find "$IDENTITY_TMP" -type f -path '*/.disk/info' -print -quit)"
    if [[ -z "$ISO_IDENTITY" ]]; then
        ISO_IDENTITY="$(find "$IDENTITY_TMP" -type f -name info -print -quit)"
    fi
    if [[ -z "$ISO_IDENTITY" ]]; then
        printf 'error: could not extract /.disk/info from the ISO.\n' >&2
        exit 1
    fi
    if ! grep -q '^EclipseOS ' "$ISO_IDENTITY"; then
        printf 'error: ISO identity is not EclipseOS: ' >&2
        cat "$ISO_IDENTITY" >&2
        exit 1
    fi
    printf 'ISO identity: %s\n' "$(cat "$ISO_IDENTITY")"
else
    printf 'warning: xorriso not found; skipping ISO identity check.\n' >&2
fi

if [[ "$DIRECT_KERNEL" -eq 1 ]]; then
    if ! command -v xorriso >/dev/null 2>&1; then
        printf 'error: xorriso is required for --direct-kernel-no-live.\n' >&2
        exit 1
    fi

    BOOT_TMP="$(mktemp -d "${TMPDIR:-/tmp}/eclipseos-boot.XXXXXX")"
    mkdir -p "$BOOT_TMP/grub" "$BOOT_TMP/extract"
    xorriso -osirrox on -indev "$ISO" \
        -extract /boot/grub/grub.cfg "$BOOT_TMP/grub" >/dev/null
    GRUB_CFG="$(find "$BOOT_TMP/grub" -type f -name grub.cfg -print -quit)"
    if [[ -z "$GRUB_CFG" ]]; then
        printf 'error: could not extract /boot/grub/grub.cfg from the ISO.\n' >&2
        exit 1
    fi
    KERNEL_PATH="$(awk '$1 == "linux" && $2 ~ /^\/live\/vmlinuz/ { print $2; exit }' "$GRUB_CFG")"
    INITRD_PATH="$(awk '$1 == "initrd" && $2 ~ /^\/live\/initrd/ { print $2; exit }' "$GRUB_CFG")"
    if [[ -z "$KERNEL_PATH" || -z "$INITRD_PATH" ]]; then
        printf 'error: could not find /live/vmlinuz and /live/initrd paths in grub.cfg.\n' >&2
        exit 1
    fi
    xorriso -osirrox on -indev "$ISO" \
        -extract "$KERNEL_PATH" "$BOOT_TMP/extract" >/dev/null
    xorriso -osirrox on -indev "$ISO" \
        -extract "$INITRD_PATH" "$BOOT_TMP/extract" >/dev/null
    KERNEL="$(find "$BOOT_TMP/extract" -type f -name "$(basename -- "$KERNEL_PATH")" -print -quit)"
    INITRD="$(find "$BOOT_TMP/extract" -type f -name "$(basename -- "$INITRD_PATH")" -print -quit)"
    if [[ -z "$KERNEL" || -z "$INITRD" ]]; then
        printf 'error: extracted kernel or initrd is missing.\n' >&2
        exit 1
    fi
    printf 'Direct-kernel mode: %s + %s\n' "$(basename -- "$KERNEL")" "$(basename -- "$INITRD")"
    printf 'Kernel command line (no boot=live): %s\n' "$KERNEL_APPEND"
fi

if [[ -z "$OUTDIR" ]]; then
    MODE_SUFFIX=""
    if [[ "$DIRECT_KERNEL" -eq 1 ]]; then
        MODE_SUFFIX="-direct"
    fi
    OUTDIR="$ROOT_DIR/tests/out/$(date -u '+%Y%m%dT%H%M%SZ')-${FIRMWARE}-${MACHINE}-${OPTICAL}-${VGA}${MODE_SUFFIX}"
fi
mkdir -p "$OUTDIR"

python_args=(
    --firmware "$FIRMWARE"
    --iso "$ISO"
    --timeout "$TIMEOUT"
    --memory "$MEMORY"
    --cpus "$CPUS"
    --machine "$MACHINE"
    --vga "$VGA"
    --optical "$OPTICAL"
    --outdir "$OUTDIR"
)
if [[ "$DIRECT_KERNEL" -eq 1 ]]; then
    python_args+=(
        --direct-kernel
        --kernel "$KERNEL"
        --initrd "$INITRD"
        --kernel-append "$KERNEL_APPEND"
    )
fi

python3 "$ROOT_DIR/tests/qemu_boot_test.py" "${python_args[@]}"
