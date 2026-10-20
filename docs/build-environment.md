# Build environment

EclipseOS is built with Debian `live-build`. That tool chain needs a Linux
kernel, loop devices and privileged chroot operations. It cannot run in this
Windows sandbox, and a Windows-only build is not supported.

## Current sandbox: why Phase 1 cannot run here

The Phase 0 environment check found:

| Resource | Result |
| --- | --- |
| OS | Windows 11 Pro 10.0.26100, x86_64 |
| CPU | AMD Ryzen 3 2200U, 2 cores / 4 threads |
| RAM | 5.0 GB total, < 0.5 GB free at inspection |
| Free disk on C: | 17.8 GB |
| Linux environment | No WSL distribution; WSL feature not installed |
| Containers | No Docker/Podman |
| VirtualBox | Not installed |
| QEMU / xorriso / live-build | Not installed |
| Administrative rights | No |
| Network | Available (Debian/GitHub endpoints reachable) |

Consequences:

- no ISO can be built in this session;
- no VirtualBox or QEMU boot screenshots can be captured;
- Calamares, Plasma and firmware behaviour cannot be tested here;
- attempting a QEMU-in-QEMU Debian builder would exceed the available disk and
  RAM with a full KDE image, and would still need hours of software emulation.

The repository is therefore being prepared so it can be built on a proper
host without redesign. **Do not interpret generated source files as a tested
ISO.**

## Option A (recommended): GitHub Actions

A hosted Ubuntu runner builds inside a privileged Debian 13 container, then
boots the ISO in QEMU and publishes the image, checksum, serial logs and
screenshots as artifacts. No local Linux install is required.

The workflow is [`.github/workflows/build.yml`](../.github/workflows/build.yml).
It:

- frees disk space on the Ubuntu runner before starting;
- runs `scripts/static-check.sh` (shell lint, Python/JSON syntax, desktop
  entry);
- starts `debian:13` with `--privileged` and the workspace bind-mounted;
- installs `live-build`, GRUB, xorriso, squashfs tools, xz-utils, QEMU, OVMF
  and the static-check tools (`shellcheck`, `file`, `desktop-file-utils`)
  inside the container;
- runs `make doctor` (including the QEMU/OVMF checks) before starting the
  build, so a missing host tool fails immediately;
- runs `make iso`;
- runs `make -k test-all` for UEFI (OVMF) and BIOS (SeaBIOS);
- uploads `eclipseos-*.iso`, `*.sha256`, `*.buildinfo`, `build.log`, serial
  logs, `result.json` and screenshots;
- can build both the default and `STRICT_FOSS=1` flavours on a manual
  `workflow_dispatch` run.

Requirements:

- a public repository, or Actions budget for a private repository;
- 30–60 minutes of CI time per build, depending on runner speed and TCG;
- artifact storage for the ISO (several GB);
- no KVM on standard runners, so boot tests use QEMU TCG and are slow;
- a successful workflow run before any Phase 1 acceptance claim.

**Workflow status:** the first run reached the Debian container host check but
failed because `xz-utils` was missing. The workflow, this document and the
README now include it, and CI runs `make doctor` before the build. A successful
workflow run is still required before Phase 1 acceptance. A local build with
the same Makefile remains possible.

## Option B: dedicated Debian 13 build VM or machine

Recommended for repeated release builds and faster iteration.

- Debian 13 (`trixie`) amd64
- 4+ vCPU, 8 GB RAM (16 GB recommended)
- 40 GB free disk minimum (60 GB+ recommended)
- network to `deb.debian.org` or a pinned snapshot mirror
- normal user with `sudo`
- optional: KVM acceleration for QEMU tests
- VirtualBox can be installed on the same host for manual acceptance, but
  automated CI should use QEMU

### Install the build dependencies

Run as a normal user with sudo, on Debian 13:

```bash
sudo apt-get update
sudo apt-get install -y --no-install-recommends \
  ca-certificates curl git make sudo \
  live-build debootstrap xorriso squashfs-tools mtools dosfstools cpio \
  xz-utils grub-pc-bin grub-efi-amd64-bin grub-efi-amd64-signed shim-signed \
  isolinux syslinux-common \
  qemu-system-x86 qemu-utils ovmf python3 \
  shellcheck file desktop-file-utils
```

### Host tool coverage

`make doctor` runs `scripts/check-host.sh --with-tests` and verifies every
command used by the build and the QEMU tests. `make static-check` additionally
uses `shellcheck`, `file` and `desktop-file-validate` when present. The
commands most often missed map to these Debian packages:

| Command or file | Debian package |
| --- | --- |
| `lb` | `live-build` |
| `debootstrap` | `debootstrap` |
| `xorriso` | `xorriso` |
| `mksquashfs` | `squashfs-tools` |
| `mmd`, `mcopy` | `mtools` |
| `mkfs.msdos` | `dosfstools` |
| `cpio` | `cpio` |
| `xz` | `xz-utils` |
| `grub-mkrescue`, `grub-mkstandalone` | `grub-common` |
| BIOS GRUB modules | `grub-pc-bin` |
| UEFI GRUB modules | `grub-efi-amd64-bin` |
| `qemu-system-x86_64` | `qemu-system-x86` |
| `qemu-img` | `qemu-utils` |
| OVMF firmware | `ovmf` |
| `desktop-file-validate` | `desktop-file-utils` (static check) |

`zstd` is not a host build dependency for this configuration: the squashfs
filesystem uses xz and the initramfs uses gzip. The image package list installs
`zstd` inside the live system for kernel/initramfs use. `desktop-file-validate`
is optional for a local build (the static check skips it if absent); CI installs
it so the session desktop entry is always validated.

Check:

```bash
cd /path/to/eclipseos
make doctor
```

### Build and test

```bash
make iso
sha256sum -c eclipseos-26.10-amd64.iso.sha256
make test-all
```

Use `make iso STRICT_FOSS=1` (or `make iso-strict`) to build without
`non-free-firmware`. The strict build forces a clean tree and uses only the
Debian `main` archive. Static checks can be run without building:

```bash
make static-check
```

`live-build` creates a chroot and needs root operations. `scripts/build.sh`
re-executes itself with `sudo` when needed and returns artefact ownership to
the invoking user. Never run arbitrary downloaded scripts as root; inspect
them first.

### VirtualBox acceptance VM

Host prerequisite: VirtualBox 7.x with the Extension Pack only if the user
needs USB 3.0/remote desktop features. The Extension Pack is not redistributed
with EclipseOS.

```bash
sudo apt-get install -y virtualbox
VBoxManage --version
./scripts/create-vbox-vm.sh \
  --iso "$PWD/eclipseos-26.10-amd64.iso" \
  --name EclipseOS-26.10 \
  --start
```

## Option C: WSL2 on Windows

WSL2 can run Debian tooling, but building live images with loop mounts and
custom kernels inside WSL is not the supported path. It also consumes the
same RAM/disk and needs administrator rights to enable virtualisation.

If used anyway:

```powershell
wsl --install -d Debian
```

Then, inside Debian, install the dependencies above. Requirements:

- Windows 11 with virtualisation enabled in firmware;
- 16 GB RAM recommended;
- 50 GB free for the WSL virtual disk and build;
- administrator rights for the one-time WSL installation;
- do not attempt nested VirtualBox inside WSL for acceptance testing; run
  QEMU tests in WSL and VirtualBox on Windows.

This sandbox cannot perform the WSL installation because it has no
administrative rights.

## Option D: Debian 13 container with sufficient privileges

`live-build` can run in a privileged container, but cannot create a
meaningful VirtualBox test from inside. Use a Debian 13 image and mount a
workspace with at least 40 GB:

```bash
docker run --rm -it --privileged \
  -v "$PWD:/work" -w /work debian:13-slim bash
```

Inside:

```bash
apt-get update
apt-get install -y ...   # same list as Option B
make iso
```

Containers are suitable for CI. Bind mounts and chroot operations vary by
host, so treat this as a build path, not a substitute for hardware testing.

## Ports, mirrors and reproducibility

- Keep network access restricted to Debian mirrors, the pinned snapshot
  service, and explicitly approved application sources.
- No API keys, tokens or passwords belong in the repository or ISO.
- Release builds should use a pinned `snapshot.debian.org` timestamp and a
  fixed `SOURCE_DATE_EPOCH`. The build-info file records the exact inputs.
- Build caches may speed iteration but must be purged for release builds.
- Secure Boot signing keys and VirtualBox Guest Additions licensing are
  release gates, not build shortcuts.

## Disk usage expectations

Approximate, to be measured in Phase 1:

- Debian base + chroot: 2–4 GB
- KDE, apps, installer and themes: another 3–5 GB
- squashfs and ISO: 2–4 GB
- QEMU test disk: 25 GB sparse
- caches and logs: 2–5 GB

Plan for **40 GB free minimum**, and 60 GB for comfortable iteration. The
current 17.8 GB sandbox cannot reliably hold a full KDE build plus ISO plus
test disk.
