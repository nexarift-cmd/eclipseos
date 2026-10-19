# EclipseOS

EclipseOS is a Debian-based desktop operating system with an original,
Windows 11-inspired desktop experience. The product version for the first
release is **`eclipse-26.10`**; the installable image is
`eclipseos-26.10-amd64.iso`.

EclipseOS is **not** a from-scratch kernel or a fork of Windows. It is a
curated Debian 13 (`trixie`) foundation with a custom boot experience,
installer configuration, desktop layout and theme, settings application and
update experience. The upstream components are credited in
[`docs/licenses.md`](docs/licenses.md).

## Project status

> **Built and tested:** nothing yet. Phase 0 (planning and scaffolding) is
> complete. No ISO has been produced in the current sandbox because it is a
> Windows host with no Linux build environment, no VirtualBox/QEMU, 5 GB of
> RAM and 17.8 GB of free disk. See
> [`docs/build-environment.md`](docs/build-environment.md). Do not treat any
> phase as "working" until its acceptance tests have run on a suitable build
> host.

| Phase | Deliverable | Status |
| --- | --- | --- |
| 0 | Decisions, risk register, repository skeleton | Complete |
| 1 | Minimal hybrid live ISO with GRUB/Plymouth branding | Blocked on build host |
| 2 | Plasma desktop, taskbar, Start menu, themes | Not started |
| 3 | Calamares installer and bootable installed system | Not started |
| 4 | Eclipse Settings, Files, Store, Updates | Not started |
| 5 | Snap layouts, widgets, search, lock screen polish | Not started |
| 6 | Hardware hardening and `eclipse-26.10-rc1` | Not started |
| Stretch | `experimental/kernel` UEFI framebuffer kernel | Not started |

The detailed gates and definition of done for each phase are in
[`docs/roadmap.md`](docs/roadmap.md).

## What is custom vs. reused

This distinction is intentional. EclipseOS does not pretend that KDE Plasma,
Calamares or Debian are our work.

| Layer | Source | Notes |
| --- | --- | --- |
| Kernel, init, systemd, package management | Debian 13 | Reused upstream |
| Compositor / desktop session | KDE Plasma 6.3 / KWin | Reused, heavily configured |
| Desktop shell (panel layout, Start menu, snap layout, theme) | EclipseOS | Custom QML/KWin/Plasma packages |
| Installer engine | Calamares 3.3 | Reused; EclipseOS branding and configuration |
| Boot menu, splash, greeter, lock screen | EclipseOS | Original GRUB, Plymouth and SDDM themes; Plasma lock screen theme |
| Eclipse Settings | EclipseOS | Custom Qt 6 / QML application |
| Eclipse Update | EclipseOS | Custom Qt 6 / QML front-end over APT + PolicyKit |
| Eclipse Files | Dolphin | Upstream file manager, rebranded and preconfigured |
| Eclipse Store | Discover | Upstream package front-end, rebranded |
| Terminal, editor, viewer, media player, calculator, screenshots | Konsole, Kate, Gwenview, Haruna, KCalc, Spectacle | Upstream applications, themed |
| Browser | Firefox ESR | Upstream, preconfigured |
| Networking, audio, Bluetooth, printing, power | NetworkManager, PipeWire, BlueZ, CUPS, power-profiles-daemon | Reused upstream |
| Branding | EclipseOS | Original SVG logo, wallpapers, icons and themes; no Microsoft assets |

## Architecture and planning

- [`docs/architecture.md`](docs/architecture.md) — system design, boot flow,
  desktop shell plan, installer flow and risk register.
- [`docs/roadmap.md`](docs/roadmap.md) — phases, acceptance tests and
  dependencies.
- [`docs/build-environment.md`](docs/build-environment.md) — exact host
  requirements and commands.
- [`docs/licenses.md`](docs/licenses.md) — component licensing and the
  non-free firmware / Guest Additions decisions.
- [`docs/real-hardware-guide.md`](docs/real-hardware-guide.md) — USB
  preparation, UEFI/BIOS setup, Secure Boot, dual-boot warnings and backup
  checklist.
- [`docs/hardware-test-checklist.md`](docs/hardware-test-checklist.md) —
  hardware compatibility test matrix.

## Planned layout

```text
eclipseos/
├── README.md
├── Makefile
├── VERSION
├── build/                  # live-build config, package lists, hooks, includes
├── installer/              # Calamares configuration and branding
├── shell/                  # Plasma layout, plasmoids, KWin scripts, global theme
├── apps/
│   ├── settings/           # Eclipse Settings (Qt 6 / QML)
│   └── update/             # Eclipse Update (Qt 6 / QML + privileged helper)
├── branding/               # logo, wallpapers, icons, GRUB, Plymouth, SDDM
├── scripts/                # build, checksum, QEMU test, VirtualBox helpers
├── tests/                  # automated boot and smoke tests
├── docs/                   # architecture, licensing, hardware guides
└── experimental/kernel/    # optional from-scratch UEFI kernel (stretch)
```

## Build host requirements

The build must run on **Debian 13 amd64** (bare metal, VM or a Debian 13
container with the required privileges). Windows cannot run `live-build`.
Recommended host resources:

- 4 or more CPU cores
- 8 GB RAM minimum; 16 GB recommended
- 40 GB free disk minimum; 60 GB recommended
- Reliable network access to Debian mirrors (or a local Debian mirror/snapshot)
- `sudo` access (live-build operates on a chroot)

On Debian 13:

```bash
sudo apt-get update
sudo apt-get install -y --no-install-recommends \
  ca-certificates curl git make sudo \
  live-build debootstrap xorriso squashfs-tools mtools dosfstools \
  grub-pc-bin grub-efi-amd64-bin grub-efi-amd64-signed shim-signed \
  isolinux syslinux-common \
  qemu-system-x86 qemu-utils ovmf python3
```

`make doctor` checks that the needed tools are present. Full instructions,
including a VirtualBox-hosted Debian build VM and the CI option, are in
[`docs/build-environment.md`](docs/build-environment.md).

## Build and test

```bash
git clone <repository-url> eclipseos
cd eclipseos

make doctor          # verify OS, tools, disk, CPU and memory
make iso             # build eclipseos-26.10-amd64.iso + .sha256 + .buildinfo
make test            # headless QEMU boot checks (UEFI + BIOS)
make test-vm         # create and start a 4 GB / 2 vCPU / EFI VirtualBox VM
```

The resulting artefact is expected at the repository root:

```text
eclipseos-26.10-amd64.iso
eclipseos-26.10-amd64.iso.sha256
eclipseos-26.10-amd64.iso.buildinfo
```

The live session user will be `eclipse` with no password. Root login is not
enabled. The installer requires a real password for the installed account.

## Security and privacy

- No telemetry, analytics, advertising or hard-coded credentials.
- No remote shell or default network services on the live image.
- The live user has passwordless `sudo` only inside the live session; this
  policy is removed from the installed system.
- Firewall, unattended security updates and SSD TRIM are enabled by default
  on the installed system.
- Secure Boot is a Phase 6 release gate. Until signed images are verified,
  the live ISO should be tested with Secure Boot disabled.

## License

EclipseOS code in this repository is licensed under
**GPL-3.0-or-later**. Upstream components retain their own licenses; see
[`docs/licenses.md`](docs/licenses.md) and [`COPYING`](COPYING).

"Windows 11" is a trademark of Microsoft Corporation. EclipseOS is not
affiliated with, endorsed by or sponsored by Microsoft. No Microsoft assets
are used.
