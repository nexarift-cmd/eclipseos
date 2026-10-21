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

> **Phase 1 is accepted at 2048 MiB in VirtualBox.** The user booted the
> original `d10c78c3…` ISO with **Skip Unattended Installation ticked** and
> reached the live desktop. The final Phase 1 rebuild is
> `eclipseos-26.10-amd64.iso`
> (SHA256 `aade6c679e41b82bf62aa1a190ca334fbe7091dfcdcaf1254da2d61c04fac397`).
> GitHub Actions [run
> 39547858160](https://github.com/nexarift-cmd/eclipseos/actions/runs/39547858160)
> passed UEFI, BIOS and the VirtualBox storage-profile QEMU boot, and the
> final ISO reached the desktop in VirtualBox EFI and BIOS. The unticked
> wizard path is fixed: VirtualBox no longer detects the image as a Debian
> installer, so it creates no VISO; the new initramfs also boots through an
> existing VISO. **4096 MiB is recommended but untested on this 5.1 GB host.**
> [Run #4](https://github.com/nexarift-cmd/eclipseos/actions/runs/39362243286)
> built the strict `STRICT_FOSS=1` image with zero non-free firmware packages.
> See [`docs/virtualbox-limitations.md`](docs/virtualbox-limitations.md),
> the [reproduction and fix evidence](docs/evidence/phase1/virtualbox-unattended.md),
> and the [Phase 1 evidence index](docs/evidence/phase1/README.md). Phase 2
> has started; the Plasma/SDDM migration is on a separate branch until it
> boots and passes its gate.

| Phase | Deliverable | Status |
| --- | --- | --- |
| 0 | Decisions, risk register, repository skeleton | Complete |
| 1 | Minimal hybrid live ISO with GRUB/Plymouth branding | **Complete and accepted at 2048 MiB**; final QEMU UEFI/BIOS + VirtualBox storage-profile pass; VirtualBox EFI/BIOS pass; 4096 MiB recommended but untested here |
| 2 | Plasma desktop, taskbar, Start menu, themes | In progress on a separate branch until the first Plasma ISO boots |
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

The Phase 1 live image is intentionally smaller than the target product:
LightDM + openbox + xterm/feh prove the boot and graphical path. Phase 2
replaces that session with Plasma and SDDM. The table above describes the
target product, not the Phase 1 contents.

## Architecture and planning

- [`docs/architecture.md`](docs/architecture.md) — system design, boot flow,
  desktop shell plan, installer flow and risk register.
- [`docs/roadmap.md`](docs/roadmap.md) — phases, acceptance tests and
  dependencies.
- [`docs/build-environment.md`](docs/build-environment.md) — exact host
  requirements and commands.
- [`docs/licenses.md`](docs/licenses.md) — component licensing and the
  non-free firmware / Guest Additions decisions.
- [`docs/virtualbox-limitations.md`](docs/virtualbox-limitations.md) — what
  works without Oracle Guest Additions, and what does not.
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
  live-build debootstrap xorriso squashfs-tools mtools dosfstools cpio \
  xz-utils grub-pc-bin grub-efi-amd64-bin grub-efi-amd64-signed shim-signed \
  isolinux syslinux-common \
  qemu-system-x86 qemu-utils ovmf python3 \
  shellcheck file desktop-file-utils
```

`make doctor` checks that the needed tools are present. Full instructions,
including a VirtualBox-hosted Debian build VM and the CI option, are in
[`docs/build-environment.md`](docs/build-environment.md).

## Build and test

```bash
git clone <repository-url> eclipseos
cd eclipseos

make doctor          # verify OS, tools, disk, CPU and memory
make static-check    # shell lint, Python/JSON syntax, desktop entry
make iso             # build eclipseos-26.10-amd64.iso + .sha256 + .buildinfo
make test            # QEMU UEFI/BIOS + VirtualBox-like EFI/IDE + rewritten-menu tests
make test-vm         # create a 4 GB recommended / 2 vCPU / EFI VirtualBox VM
                     # (use --memory 2048 for the accepted size on this host)
```

A strict open-source build omits all `non-free-firmware` packages:

```bash
make iso STRICT_FOSS=1
make iso-strict      # equivalent
```

Branding assets are generated at build time. To render them alone:

```bash
make assets          # writes branding/assets/*.png and the logo SVG
```

The resulting artefact is expected at the repository root:

```text
eclipseos-26.10-amd64.iso
eclipseos-26.10-amd64.iso.sha256
eclipseos-26.10-amd64.iso.buildinfo
```

The live session user is `eclipse` with no password. Root login is not
enabled. The installer (Phase 3) requires a real password for the installed
account.

### Continuous integration

[`.github/workflows/build.yml`](.github/workflows/build.yml) builds the ISO in
a privileged Debian 13 container on `ubuntu-24.04`, runs the static checks,
boots the image in QEMU with OVMF (UEFI), SeaBIOS, and a VirtualBox-like `pc`
machine with an IDE optical drive and standard VGA at 2048 MiB, then uploads
the ISO, checksum, build info, serial logs and screenshots as artifacts. QEMU
cannot usefully emulate VMSVGA (`vmwgfx` rejects the QEMU hypervisor), so the
VMSVGA path is covered by the local VirtualBox test. A rewritten-menu boot
without `boot=live` remains a manual negative control, not a passing gate. A
manual `workflow_dispatch` run can build both the default and
`STRICT_FOSS=1` flavours.

[Run #3](https://github.com/nexarift-cmd/eclipseos/actions/runs/39359532446)
(commit `c874d77`) succeeded end to end. It built the 890 MiB default ISO,
verified the SHA256 file, reached the desktop marker in both QEMU firmware
modes, and published `eclipseos-26.10-amd64-default` plus
`test-evidence-default`.

[Run #4](https://github.com/nexarift-cmd/eclipseos/actions/runs/39362243286)
was a `workflow_dispatch` run of the same commit. Its default job reproduced
the same SHA256; its strict job built a 464 MiB main-only ISO with
`0300-licences: 0 approved non-free-firmware package(s)`, and both QEMU boots
passed. The exact checksums, logs and screenshots are in
[`docs/evidence/phase1`](docs/evidence/phase1/README.md).

[Run 39547858160](https://github.com/nexarift-cmd/eclipseos/actions/runs/39547858160)
is the final Phase 1 gate: it rebuilt the default ISO after the VirtualBox
fix and the test-harness corrections, passed UEFI, BIOS and the
VirtualBox-storage-profile QEMU boot, and published checksum
`aade6c67…c397`. VirtualBox remains a manual acceptance environment, not a CI
virtualiser; the accepted EFI/BIOS result at 2048 MiB is recorded in the
evidence directory, and 4096 MiB is recommended but untested here. Read
[`docs/virtualbox-limitations.md`](docs/virtualbox-limitations.md) before
expecting clipboard, shared folders or automatic display resizing.

## Security and privacy

- No telemetry, analytics or advertising.
- No installed-system credentials are baked into the ISO. The live account
  `eclipse` is intentionally passwordless and has passwordless `sudo` only
  inside the live session; the Phase 3 installer must create a real installed
  account password and must not copy the live sudoers drop-in.
- No remote shell or default network services on the live image.
- Firewall, unattended security updates and SSD TRIM are planned defaults for
  the installed system (Phases 3–4); they are not present in the Phase 1 live
  image.
- Secure Boot is a Phase 6 release gate. Until signed images are verified,
  the live ISO should be tested with Secure Boot disabled.

## License

EclipseOS code in this repository is licensed under
**GPL-3.0-or-later**. Upstream components retain their own licenses; see
[`docs/licenses.md`](docs/licenses.md) and [`COPYING`](COPYING).

"Windows 11" is a trademark of Microsoft Corporation. EclipseOS is not
affiliated with, endorsed by or sponsored by Microsoft. No Microsoft assets
are used.
