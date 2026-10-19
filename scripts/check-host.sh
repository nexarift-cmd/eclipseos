#!/usr/bin/env bash
#
# Validate an EclipseOS build host before spending time on an ISO.
# Run as the user who will invoke make; build.sh performs privilege elevation.
#
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
WITH_TESTS=0

for arg in "$@"; do
    case "$arg" in
        --with-tests) WITH_TESTS=1 ;;
        -h|--help)
            printf 'Usage: %s [--with-tests]\n' "$(basename "$0")"
            exit 0
            ;;
        *)
            printf 'Unknown option: %s\n' "$arg" >&2
            exit 2
            ;;
    esac
done

if [[ -t 1 ]]; then
    C_OK=$'\033[32m'; C_WARN=$'\033[33m'; C_FAIL=$'\033[31m'; C_RESET=$'\033[0m'
else
    C_OK=''; C_WARN=''; C_FAIL=''; C_RESET=''
fi

FAILURES=0
WARNINGS=0

ok()   { printf '%s[ OK ]%s %s\n'   "$C_OK"   "$C_RESET" "$*"; }
warn() { printf '%s[WARN]%s %s\n'   "$C_WARN" "$C_RESET" "$*"; WARNINGS=$((WARNINGS + 1)); }
fail() { printf '%s[FAIL]%s %s\n'   "$C_FAIL" "$C_RESET" "$*"; FAILURES=$((FAILURES + 1)); }
info() { printf '       %s\n' "$*"; }

printf 'EclipseOS build host check\n'
printf 'Root: %s\n\n' "$ROOT_DIR"

# ---------------------------------------------------------------------------
# Operating system. The live-build configuration is validated on Debian 13.
# ---------------------------------------------------------------------------
if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    info "OS: ${PRETTY_NAME:-unknown}"
    if [[ "${ID:-}" == "debian" && "${VERSION_ID:-}" == "13" ]]; then
        ok 'Debian 13 (trixie) detected'
    elif [[ "${ID:-}" == "debian" ]]; then
        warn "Debian ${VERSION_ID:-unknown} detected; this tree is tested against Debian 13"
    else
        fail "Unsupported host OS '${ID:-unknown}'. Use Debian 13 amd64 (bare metal, VM or privileged container)."
    fi
else
    fail 'Cannot read /etc/os-release; this is not a supported Linux build host.'
fi

ARCH="$(uname -m)"
if [[ "$ARCH" == "x86_64" ]]; then
    ok 'x86_64 architecture'
else
    fail "x86_64 is required; found $ARCH"
fi

if [[ "$(id -u)" -eq 0 ]]; then
    ok 'Running as root'
else
    if command -v sudo >/dev/null 2>&1; then
        ok 'Non-root user with sudo available (build.sh will elevate as needed)'
        if sudo -n true >/dev/null 2>&1; then
            ok 'Passwordless sudo currently available'
        else
            warn 'sudo may prompt for a password; run in an interactive terminal'
        fi
    else
        fail 'sudo is required when not running as root'
    fi
fi

# ---------------------------------------------------------------------------
# CPU, memory and disk. These are deliberately conservative preflight checks.
# ---------------------------------------------------------------------------
CPUS="$(getconf _NPROCESSORS_ONLN 2>/dev/null || printf '0')"
if [[ "$CPUS" -ge 4 ]]; then
    ok "CPU threads: $CPUS"
elif [[ "$CPUS" -ge 2 ]]; then
    warn "CPU threads: $CPUS (4+ recommended; build will be slow)"
else
    fail "CPU threads: $CPUS (at least 2 required, 4 recommended)"
fi

if [[ -r /proc/meminfo ]]; then
    MEM_MB="$(awk '/^MemTotal:/ {printf "%d", $2/1024}' /proc/meminfo)"
    if [[ "$MEM_MB" -ge 7600 ]]; then
        ok "Memory: ${MEM_MB} MiB"
    elif [[ "$MEM_MB" -ge 3800 ]]; then
        warn "Memory: ${MEM_MB} MiB (8 GiB recommended)"
    else
        fail "Memory: ${MEM_MB} MiB (4 GiB is the hard minimum; 8 GiB recommended)"
    fi
fi

FREE_MB="$(df -Pk "$ROOT_DIR" | awk 'NR==2 {print $4}')"
FREE_GB=$((FREE_MB / 1024 / 1024))
if [[ "$FREE_GB" -ge 40 ]]; then
    ok "Free disk: ${FREE_GB} GiB"
elif [[ "$FREE_GB" -ge 25 ]]; then
    warn "Free disk: ${FREE_GB} GiB (40 GiB is the recommended minimum for a full KDE build)"
else
    fail "Free disk: ${FREE_GB} GiB (need at least 25 GiB, 40 GiB recommended)"
fi

# ---------------------------------------------------------------------------
# Required build tools.
# ---------------------------------------------------------------------------
require_commands=(
    git make python3
    lb debootstrap xorriso mksquashfs mmd mcopy mkfs.msdos cpio
    grub-mkrescue grub-mkstandalone
    sha256sum gzip xz apt-get dpkg-query
)
missing=()
for cmd in "${require_commands[@]}"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        missing+=("$cmd")
    fi
done

if [[ ${#missing[@]} -eq 0 ]]; then
    ok 'All required build commands are installed'
else
    fail "Missing build commands: ${missing[*]}"
fi

if [[ "$(id -u)" -ne 0 ]] && ! command -v sudo >/dev/null 2>&1; then
    fail 'sudo is missing; build.sh cannot elevate for live-build'
fi

if command -v lb >/dev/null 2>&1; then
    info "live-build: $(lb --version 2>/dev/null | head -n 1)"
fi
if command -v xorriso >/dev/null 2>&1; then
    info "xorriso: $(xorriso --version 2>/dev/null | head -n 1)"
fi

if [[ -n "${HOME:-}" && -w "${HOME:-/nonexistent}" ]]; then
    ok "HOME is writable: $HOME"
else
    fail 'HOME is missing or not writable'
fi

# Network is not strictly required if a complete local Debian mirror is in
# use, so this is a warning rather than a hard failure.
if command -v getent >/dev/null 2>&1 && getent hosts deb.debian.org >/dev/null 2>&1; then
    ok 'Debian archive DNS resolves (network assumed reachable)'
else
    warn 'Cannot resolve deb.debian.org; use a local mirror if the host is offline'
fi

# ---------------------------------------------------------------------------
# Test tools.
# ---------------------------------------------------------------------------
if [[ "$WITH_TESTS" -eq 1 ]]; then
    printf '\nTest requirements\n'
    test_commands=(qemu-system-x86_64 qemu-img python3)
    test_missing=()
    for cmd in "${test_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            test_missing+=("$cmd")
        fi
    done
    if [[ ${#test_missing[@]} -eq 0 ]]; then
        ok 'QEMU and Python test tools are installed'
    else
        fail "Missing test commands: ${test_missing[*]}"
    fi

    OVMF_CODE=""
    for candidate in \
        /usr/share/OVMF/OVMF_CODE_4M.fd \
        /usr/share/OVMF/OVMF_CODE.fd \
        /usr/share/ovmf/OVMF.fd \
        /usr/share/qemu/OVMF.fd; do
        if [[ -r "$candidate" ]]; then OVMF_CODE="$candidate"; break; fi
    done
    if [[ -n "$OVMF_CODE" ]]; then
        ok "UEFI firmware: $OVMF_CODE"
    else
        fail 'OVMF firmware not found (install the ovmf package)'
    fi

    if [[ -e /dev/kvm && -r /dev/kvm && -w /dev/kvm ]]; then
        ok 'KVM is available; QEMU tests will be accelerated'
    else
        warn 'KVM unavailable; QEMU tests will use slow software emulation'
    fi
fi

printf '\n'
if [[ "$FAILURES" -gt 0 ]]; then
    printf '%s%d requirement(s) failed, %d warning(s).%s\n' "$C_FAIL" "$FAILURES" "$WARNINGS" "$C_RESET"
    printf 'Install the documented dependencies (see docs/build-environment.md) and retry.\n'
    exit 1
fi

printf '%sHost check passed with %d warning(s).%s\n' "$C_OK" "$WARNINGS" "$C_RESET"
