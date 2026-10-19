# EclipseOS licensing and component inventory

Status: **Phase 0 preliminary inventory.** Package versions will be pinned and
the final ISO will carry a generated, package-level licence manifest. This
document records the licensing policy and every planned component known at
this stage.

## Project licence

Original EclipseOS code and artwork in this repository are released under
**GPL-3.0-or-later**, except where a file carries another SPDX identifier.
See [`../COPYING`](../COPYING).

"Windows 11" is a trademark of Microsoft Corporation. EclipseOS is not
affiliated with Microsoft. No Microsoft logos, icons, wallpapers, fonts or
code are used.

## Policy

1. Every component included in the ISO must be redistributable.
2. Open-source licences are strongly preferred.
3. Non-free **firmware** required for hardware support may be included in the
   `non-free-firmware` archive, but must be identified in the manifest and in
   the release notes. This is a deliberate exception to "open-source only".
4. Proprietary GPU drivers are offered as an **opt-in installer action**, not
   silently preinstalled. The user must see the licence and size.
5. Oracle VirtualBox Guest Additions and the VirtualBox Extension Pack are
   **not distributed** with EclipseOS because they are not open source.
   Whether Debian's `virtualbox-guest-utils` contrib package can be shipped is
   an open licence/backport question for Phase 1.
6. Flatpak applications are not part of the ISO. Their licences are shown by
   the store at install time.
7. No review means no inclusion. The release gate is a generated licence
   manifest plus manual review of any package with no machine-readable
   copyright data.

## Planned components

Exact upstream versions will be pinned in the live-build package list and
recorded in `eclipseos-26.10-amd64.iso.buildinfo`.

### Foundation

| Component | Planned use | Licence | Status |
| --- | --- | --- | --- |
| Debian 13 base (`trixie`) | Userland, package management, init scripts, security support | Mixed DFSG-free licences; per-package copyright under `/usr/share/doc/*/copyright` | Reused |
| Linux kernel | Hardware support | GPL-2.0-only (with separately licensed firmware blobs) | Reused |
| systemd | Init, services, logind, timers | LGPL-2.1-or-later | Reused |
| live-boot / live-config | Live media boot | GPL-3.0-or-later | Reused |
| live-build | Image build tooling | GPL-3.0-or-later | Reused (build host only) |
| GRUB 2 | UEFI and BIOS boot menu | GPL-3.0-or-later | Reused; EclipseOS theme is original |
| shim | Secure Boot chain | BSD-2-Clause / efitools licence mix; verify Debian package | Planned for RC |
| Plymouth | Graphical boot splash | GPL-2.0-or-later | Reused; EclipseOS theme is original |
| Calamares | Installer | GPL-3.0-or-later | Reused; EclipseOS configuration/branding is original |
| NetworkManager | Network management | LGPL-2.1-or-later / GPL-2.0-or-later components | Reused |
| PipeWire / WirePlumber | Audio and media graph | MIT | Reused |
| BlueZ | Bluetooth | LGPL-2.1-or-later | Reused |
| CUPS | Printing | Apache-2.0 | Reused |
| Avahi | mDNS/service discovery | LGPL-2.1-or-later | Reused |
| power-profiles-daemon | Power profiles | GPL-3.0-or-later | Reused |
| fwupd | Firmware updates | LGPL-2.1-or-later | Reused |
| nftables / ufw or firewalld | Firewall | GPL-2.0 / GPL-3.0-or-later (verify selected package) | Phase 1 decision |
| unattended-upgrades | Automatic security updates | GPL-2.0-or-later | Reused |
| Flatpak | Application sandbox/runtime manager | LGPL-2.1-or-later | Reused |

### Desktop

| Component | Planned use | Licence | Status |
| --- | --- | --- | --- |
| KDE Plasma / Plasma Workspace 6.3 | Desktop session, panel, system tray, notifications | GPL-2.0-or-later and LGPL-2.1-or-later (mixed) | Reused |
| KWin | Compositor and window management | GPL-2.0-or-later | Reused |
| SDDM | Login greeter | GPL-2.0-or-later | Reused; EclipseOS QML theme is original |
| KRunner | Global search | LGPL-2.1-or-later / GPL-2.0-or-later components | Reused |
| Qt 6 | Application toolkit | LGPL-3.0-only with Qt exceptions / GPL-3.0 | Reused |
| KDE Frameworks 6 | KDE libraries | LGPL-2.1-or-later and compatible | Reused |
| Inter | UI font | SIL Open Font License 1.1 | Reused, redistributable |
| KDE Breeze icons | Base icon set | LGPL-3.0-or-later (verify package copyright) | Reused |
| Papirus icon theme (optional) | Supplemental icons | GPL-3.0-or-later | Candidate; licence audit |
| EclipseOS logo, wallpapers, theme, GRUB/Plymouth/SDDM artwork | Product identity | GPL-3.0-or-later (project) | Original |

### Applications

| Component | Planned use | Licence | Status |
| --- | --- | --- | --- |
| Firefox ESR | Web browser | MPL-2.0 (some files under compatible licences) | Reused |
| Dolphin | Eclipse Files, rebranded | GPL-2.0-or-later | Reused |
| Konsole | Eclipse Terminal, rebranded | GPL-2.0-or-later | Reused |
| Kate | Text editor | LGPL-2.1-or-later / GPL-2.0-or-later components | Reused |
| Gwenview | Image viewer | GPL-2.0-or-later | Reused |
| Haruna | Media player | GPL-3.0-or-later (verify package) | Reused |
| KCalc | Calculator | GPL-2.0-or-later | Reused |
| Spectacle | Screenshot tool | GPL-2.0-or-later | Reused |
| Discover | Eclipse Store, rebranded | GPL-2.0-or-later (verify package) | Reused |
| PackageKit | Package management backend | GPL-2.0-or-later / LGPL-2.1-or-later | Reused |
| Eclipse Settings | Custom unified settings app | GPL-3.0-or-later | Original |
| Eclipse Update | Custom update UI | GPL-3.0-or-later | Original |
| PolicyKit | Privilege separation | LGPL-2.1-or-later | Reused |
| Open-Meteo API (optional weather widget) | Weather data | Data under CC BY 4.0; service terms apply | External service; opt-in |

### Firmware, drivers and VM support

These are the honest exceptions and open items. None are silently installed
without documentation.

| Component | Planned use | Licence | Status |
| --- | --- | --- | --- |
| `firmware-iwlwifi`, `firmware-realtek`, `firmware-atheros`, `firmware-brcm80211`, etc. | Wi-Fi/Ethernet/Bluetooth hardware enablement | Mixed vendor licences; redistributable, mostly not open source | Candidate for non-free-firmware; must be listed in manifest |
| `amd64-microcode`, `intel-microcode` | CPU stability/security | Vendor licences; redistributable | Candidate; user-visible |
| NVIDIA proprietary driver | Opt-in GPU support | NVIDIA licence | Not in ISO by default; offered by installer; Secure Boot MOK flow required |
| Mesa, amdgpu, i915, nouveau | Open-source graphics | MIT / GPL-2.0 / LGPL-2.1 | Reused |
| VirtualBox Guest Utilities | Clipboard, shared folders, resize | Debian contrib; exact licence must be audited | **Not approved yet**; Debian 13 stable lacks the package |
| Oracle VirtualBox Guest Additions ISO | Official VM integration | Oracle PUEL | **Not distributed** |
| VirtualBox Extension Pack | USB 3.0, VRDP, encryption | Oracle PUEL | **Not distributed** |

### Build and test dependencies (not in ISO)

| Component | Licence | Notes |
| --- | --- | --- |
| QEMU | GPL-2.0-only | Test host |
| OVMF / edk2 | BSD-2-Clause-Patent and compatible | UEFI test firmware |
| xorriso / libisoburn | GPL-3.0-or-later | ISO production |
| squashfs-tools | GPL-2.0-or-later | Live root filesystem |
| Python 3 | PSF-2.0 | Test and helper scripts |
| Git | GPL-2.0-only | Source management |

## Generated manifest requirement

Before any release candidate:

1. Add `build/config/hooks/` logic to emit
   `licenses/packages.tsv` with package name, version, architecture, Debian
   archive area, and copyright file path.
2. Copy the complete Debian copyright texts into the live image at
   `/usr/share/doc/` (normal Debian behaviour).
3. Copy the EclipseOS licence, this inventory, upstream attributions, and
   original asset licences into `/usr/share/licenses/eclipseos/`.
4. Fail the release if a package is in a non-free area and is not listed as
   an approved exception.
5. Archive the manifest alongside the ISO and SHA256.

The default Debian package contents already include their copyright files;
the manifest makes the inventory reviewable without booting the image.

## Attribution and trademark notes

- KDE, Plasma, KWin, Dolphin, Konsole, Kate, Gwenview and Discover are
  trademarks/names of their respective projects; EclipseOS renames only the
  visible product entries where allowed by the licences and does not claim
  endorsement.
- Firefox is a trademark of the Mozilla Foundation. The unmodified Debian
  Firefox ESR build is used, and EclipseOS does not claim Mozilla endorsement.
- Intel, AMD, NVIDIA, Realtek, Broadcom and other hardware names are
  trademarks of their owners.
- Inter is licensed under the SIL OFL 1.1; the reserved font name is used
  unmodified.
- If Papirus icons are included, their GPL terms and attribution will be kept.
- Open-Meteo attribution will appear in the weather widget settings/about
  screen if the widget ships.

## Open licensing decisions for Phase 1

1. **Firmware:** include redistributable `non-free-firmware` for hardware
   support, or produce a strictly open-source ISO with degraded hardware?
   The architecture currently recommends inclusion with a manifest.
2. **VirtualBox Guest Utilities:** seek a legally reviewed backport from
   Debian unstable/contrib; if unavailable, do not bundle and document the
   limitation. Display resize via VMSVGA does not require the proprietary
   Guest Additions.
3. **NVIDIA:** keep the driver installer-optional, and only after Secure Boot
   MOK handling is documented and tested.
