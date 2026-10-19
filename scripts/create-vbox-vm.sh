#!/usr/bin/env bash
#
# Create a ready-to-boot VirtualBox VM for EclipseOS.
#
# Defaults match the product test target:
#   4096 MiB RAM, 2 vCPUs, 128 MiB video, EFI enabled, 25 GiB disk, ISO attached.
#
# Requires VirtualBox's VBoxManage on PATH. This script only creates a VM and
# attaches the ISO; it does not install EclipseOS or modify the host.
#
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
VERSION="$(tr -d '\r\n' < "$ROOT_DIR/VERSION")"

VM_NAME="EclipseOS-${VERSION}"
ISO="$(find "$ROOT_DIR" -maxdepth 1 -type f -name "eclipseos-${VERSION}-amd64.iso" -print -quit 2>/dev/null || true)"
BASE_DIR="${HOME}/VirtualBox VMs"
MEMORY_MB=4096
CPUS=2
VRAM_MB=128
DISK_MB=25600
EFI=1
START=0
REPLACE=0

usage() {
    cat <<'EOF'
Usage: create-vbox-vm.sh [options]

Options:
  --iso PATH          ISO to attach (default: ./eclipseos-<version>-amd64.iso)
  --name NAME         VM name (default: EclipseOS-<version>)
  --base-dir PATH     Base folder for VM files (default: ~/VirtualBox VMs)
  --memory MB         RAM in MiB (default: 4096)
  --cpus N            vCPU count (default: 2)
  --vram MB           Video RAM in MiB (default: 128)
  --disk MB           Virtual disk size in MiB (default: 25600 = 25 GiB)
  --no-efi            Use legacy BIOS instead of EFI
  --replace           Delete and recreate an existing VM with this name
  --start             Start the VM after creation
  -h, --help          Show this help

The VM uses VMSVGA. Hardware 3D acceleration is enabled; if the guest desktop
fails to render, retry with software rendering or the X11 session. Oracle
Guest Additions are not included: clipboard sharing, shared folders and
automatic resize are unavailable (see docs/virtualbox-limitations.md).
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --iso) ISO="${2:?--iso requires a path}"; shift 2 ;;
        --name) VM_NAME="${2:?--name requires a value}"; shift 2 ;;
        --base-dir) BASE_DIR="${2:?--base-dir requires a path}"; shift 2 ;;
        --memory) MEMORY_MB="${2:?--memory requires a value}"; shift 2 ;;
        --cpus) CPUS="${2:?--cpus requires a value}"; shift 2 ;;
        --vram) VRAM_MB="${2:?--vram requires a value}"; shift 2 ;;
        --disk) DISK_MB="${2:?--disk requires a value}"; shift 2 ;;
        --no-efi) EFI=0; shift ;;
        --replace) REPLACE=1; shift ;;
        --start) START=1; shift ;;
        -h|--help) usage; exit 0 ;;
        *) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
    esac
done

VBOXMANAGE="${VBOXMANAGE:-VBoxManage}"
if ! command -v "$VBOXMANAGE" >/dev/null 2>&1; then
    printf 'error: VBoxManage not found.\n' >&2
    printf 'Install VirtualBox 7.x and ensure VBoxManage is on PATH, or set VBOXMANAGE.\n' >&2
    printf 'On Windows, run this script from Git Bash and add the VirtualBox directory to PATH.\n' >&2
    exit 1
fi

if [[ -z "$ISO" || ! -f "$ISO" ]]; then
    printf 'error: ISO not found: %s\n' "${ISO:-<none>}" >&2
    printf 'Build it with make iso, or pass --iso PATH.\n' >&2
    exit 1
fi

# Make paths absolute for VirtualBox. Git Bash/MSYS path conversion is handled
# by VirtualBox when invoking a native Windows executable; cygpath is used when
# present so paths with spaces and drive letters are unambiguous.
to_native_path() {
    if command -v cygpath >/dev/null 2>&1; then
        cygpath -w "$1"
    else
        printf '%s' "$1"
    fi
}

ISO="$(cd -- "$(dirname -- "$ISO")" && pwd)/$(basename -- "$ISO")"

if [[ -f "${ISO}.sha256" ]]; then
    printf 'Verifying ISO checksum...\n'
    SHA_DIR="$(dirname -- "$ISO")"
    if command -v sha256sum >/dev/null 2>&1; then
        ( cd "$SHA_DIR" && sha256sum -c "$(basename -- "${ISO}.sha256")" )
    else
        printf 'warning: sha256sum unavailable; verify the ISO manually.\n' >&2
    fi
else
    printf 'warning: no .sha256 file beside the ISO; continuing without verification.\n' >&2
fi

ISO="$(to_native_path "$ISO")"
BASE_DIR="$(to_native_path "$BASE_DIR")"

if "$VBOXMANAGE" showvminfo "$VM_NAME" >/dev/null 2>&1; then
    if [[ "$REPLACE" -ne 1 ]]; then
        printf 'error: VM "%s" already exists.\n' "$VM_NAME" >&2
        printf 'Use --replace to delete it and create a fresh VM, or choose another --name.\n' >&2
        exit 1
    fi
    printf 'WARNING: deleting existing VM "%s" and its virtual disk.\n' "$VM_NAME"
    "$VBOXMANAGE" controlvm "$VM_NAME" poweroff >/dev/null 2>&1 || true
    "$VBOXMANAGE" unregistervm "$VM_NAME" --delete >/dev/null
fi

printf 'Creating VM "%s"...\n' "$VM_NAME"
"$VBOXMANAGE" createvm --name "$VM_NAME" --ostype Debian_64 --basefolder "$BASE_DIR" --register >/dev/null

CFG_FILE="$("$VBOXMANAGE" showvminfo "$VM_NAME" --machinereadable | sed -n 's/^CfgFile="\(.*\)"$/\1/p' | head -n 1)"
if [[ -z "$CFG_FILE" ]]; then
    printf 'error: could not determine the VM configuration path from VBoxManage.\n' >&2
    exit 1
fi
# On Git Bash/MSYS, VBoxManage returns a native Windows path. Convert it to a
# POSIX path for dirname, then convert the final disk path back for VBoxManage.
if command -v cygpath >/dev/null 2>&1; then
    CFG_FILE="$(cygpath -u "$CFG_FILE")"
fi
VM_DIR="$(dirname -- "$CFG_FILE")"
DISK_PATH="${VM_DIR}/${VM_NAME}.vdi"
DISK_PATH="$(to_native_path "$DISK_PATH")"

modify_args=(
    --memory "$MEMORY_MB"
    --cpus "$CPUS"
    --vram "$VRAM_MB"
    --graphicscontroller vmsvga
    --accelerate3d on
    --ioapic on
    --rtcuseutc on
    --nic1 nat
    --natdnshostresolver1 on
    --boot1 dvd
    --boot2 disk
    --boot3 none
    --boot4 none
    --audio-controller hda
    --audio-in on
    --audio-out on
)
if [[ "$EFI" -eq 1 ]]; then
    modify_args+=(--firmware efi)
else
    modify_args+=(--firmware bios)
fi

"$VBOXMANAGE" modifyvm "$VM_NAME" "${modify_args[@]}" >/dev/null
"$VBOXMANAGE" createhd --filename "$DISK_PATH" --size "$DISK_MB" --format VDI --variant Standard >/dev/null
"$VBOXMANAGE" storagectl "$VM_NAME" --name "SATA" --add sata --controller IntelAhci --portcount 4 --bootable on >/dev/null
"$VBOXMANAGE" storageattach "$VM_NAME" --storagectl "SATA" --port 0 --device 0 --type hdd --medium "$DISK_PATH" >/dev/null
"$VBOXMANAGE" storageattach "$VM_NAME" --storagectl "SATA" --port 1 --device 0 --type dvddrive --medium "$ISO" >/dev/null

printf '\nVM created:\n'
printf '  Name:    %s\n' "$VM_NAME"
printf '  RAM:     %s MiB\n' "$MEMORY_MB"
printf '  CPUs:    %s\n' "$CPUS"
printf '  Video:   %s MiB, VMSVGA\n' "$VRAM_MB"
printf '  Firmware:%s\n' "$([[ "$EFI" -eq 1 ]] && printf ' EFI' || printf ' BIOS')"
printf '  Disk:    %s MiB (%s)\n' "$DISK_MB" "$DISK_PATH"
printf '  ISO:     %s\n' "$ISO"

if [[ "$START" -eq 1 ]]; then
    printf '\nStarting the VM...\n'
    "$VBOXMANAGE" startvm "$VM_NAME" --type gui
else
    printf '\nStart it with:\n  %s startvm "%s" --type gui\n' "$VBOXMANAGE" "$VM_NAME"
fi

printf '\nIf the VM cannot boot, confirm EFI is enabled and the ISO was attached\n'
printf 'to the SATA optical drive. Remove the ISO after installing.\n'
