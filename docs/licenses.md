# EclipseOS licensing and component inventory

Status: **Phase 1.** This document records the policy, the components selected
for the Phase 1 live image, and every non-free exception. The default ISO has
been built and boot-tested; its build log reports 24 approved
`non-free-firmware` packages. The package manifest is generated inside the
image at build time. The strict `STRICT_FOSS=1` image was also built: it used
the `main` archive only, reported zero non-free firmware packages, and passed
both QEMU boots.

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
3. Redistributable device **firmware** from Debian's `non-free-firmware`
   archive may be included by default for hardware support. Every package is
   listed in this document and in the generated manifest.
4. Proprietary GPU drivers are **not** in the ISO. NVIDIA is planned only as
   an explicit installer opt-in in Phase 3, after the licence text, size and
   Secure Boot MOK flow are shown to the user.
5. Oracle VirtualBox Guest Additions and the Extension Pack are **not
   distributed** because they are PUEL-licensed. Debian 13 stable does not
   ship `virtualbox-guest-utils`; the requirement is unmet and documented in
   [`virtualbox-limitations.md`](virtualbox-limitations.md).
6. Flatpak applications are not part of the ISO. Their licences are shown by
   the store at install time.
7. No review means no inclusion. The build fails if a package from `contrib`,
   `non-free`, or an unapproved `non-free-firmware` package is installed.

## Default build versus `STRICT_FOSS=1`

The default build enables the Debian `main` and `non-free-firmware` archive
areas and installs the firmware list in
`build/config/package-lists/eclipse-firmware.list.chroot.in`.

A strict build uses **`main` only** and does not generate the firmware package
list:

```bash
make iso STRICT_FOSS=1
# or
make iso-strict
```

`scripts/build.sh` removes any previously generated firmware list and forces a
clean build, so files from an earlier non-strict chroot cannot leak in.
`auto/config` then passes only `--archive-areas main`. The generated
`non-free-firmware.tsv` contains only its header, and
`/usr/share/doc/eclipseos/packages.tsv` must contain no
`non-free-firmware` lines. The build-time policy hook enforces this.

**Cost of the strict build:** some Wi-Fi, Ethernet, graphics, audio and
Bluetooth devices will not work without their firmware. The open-source
drivers remain, but the hardware may not become usable. That is the honest
trade-off, not a hidden failure.

## Non-free exceptions in the default ISO

Every package below comes from Debian's `non-free-firmware` archive. They are
redistributable vendor firmware blobs, not drivers and not open source. Each
package carries its own copyright file at `/usr/share/doc/<package>/copyright`
inside the image.

Expected Debian 13 versions at the time of writing: `20250410-2` for the
firmware bundle packages, and `1:1.5-13` for `firmware-zd1211`. The build
manifest records the actual installed versions.

| Package(s) | Licence | Why it is included | How to remove |
| --- | --- | --- | --- |
| `firmware-amd-graphics` | AMD firmware licence (redistributable, non-free) | AMD GPU display and power-management firmware; needed for reliable amdgpu operation on many laptops and desktops | `make iso STRICT_FOSS=1` |
| `firmware-intel-graphics` | Intel firmware licence (redistributable, non-free) | Intel GPU firmware (GuC/HuC/DMC) for modern integrated graphics | `make iso STRICT_FOSS=1` |
| `firmware-intel-misc` | Intel firmware licence (redistributable, non-free) | Miscellaneous Intel device firmware, including some networking and platform blocks | `make iso STRICT_FOSS=1` |
| `firmware-intel-sound` | Intel firmware licence (redistributable, non-free) | Intel audio DSP firmware for laptops that require it | `make iso STRICT_FOSS=1` |
| `firmware-atheros` | Qualcomm Atheros firmware licence (redistributable, non-free) | Atheros Wi-Fi and Bluetooth adapters | `make iso STRICT_FOSS=1` |
| `firmware-brcm80211` | Broadcom firmware licence (redistributable, non-free) | Broadcom Wi-Fi adapters common in laptops | `make iso STRICT_FOSS=1` |
| `firmware-iwlwifi` | Intel firmware licence (redistributable, non-free) | Intel Wi-Fi adapters, including many ThinkPads and business laptops | `make iso STRICT_FOSS=1` |
| `firmware-mediatek` | MediaTek firmware licence (redistributable, non-free) | MediaTek Wi-Fi/Bluetooth adapters | `make iso STRICT_FOSS=1` |
| `firmware-realtek` | Realtek firmware licence (redistributable, non-free) | Realtek wired and wireless adapters, including common USB Ethernet dongles | `make iso STRICT_FOSS=1` |
| `firmware-bnx2`, `firmware-bnx2x` | Broadcom firmware licence (redistributable, non-free) | Broadcom NetXtreme server/desktop Ethernet | `make iso STRICT_FOSS=1` |
| `firmware-cavium` | Cavium/Marvell firmware licence (redistributable, non-free) | Cavium network adapters | `make iso STRICT_FOSS=1` |
| `firmware-myricom` | Myricom firmware licence (redistributable, non-free) | Myricom 10G adapters | `make iso STRICT_FOSS=1` |
| `firmware-netronome` | Netronome firmware licence (redistributable, non-free) | Netronome network adapters | `make iso STRICT_FOSS=1` |
| `firmware-netxen` | QLogic firmware licence (redistributable, non-free) | NetXen/QLogic network adapters | `make iso STRICT_FOSS=1` |
| `firmware-qlogic` | QLogic firmware licence (redistributable, non-free) | QLogic Fibre Channel and network adapters | `make iso STRICT_FOSS=1` |
| `firmware-libertas` | Marvell firmware licence (redistributable, non-free) | Marvell Libertas Wi-Fi adapters | `make iso STRICT_FOSS=1` |
| `firmware-marvell-prestera` | Marvell firmware licence (redistributable, non-free) | Marvell Prestera network switch/accelerator firmware | `make iso STRICT_FOSS=1` |
| `firmware-samsung` | Samsung firmware licence (redistributable, non-free) | Samsung laptop/SSD-related firmware | `make iso STRICT_FOSS=1` |
| `firmware-siano` | Siano firmware licence (redistributable, non-free) | Siano mobile TV receivers | `make iso STRICT_FOSS=1` |
| `firmware-ti-connectivity` | Texas Instruments firmware licence (redistributable, non-free) | TI Wi-Fi/Bluetooth adapters | `make iso STRICT_FOSS=1` |
| `firmware-zd1211` | ZyDAS firmware licence (redistributable, non-free) | ZyDAS USB Wi-Fi adapters | `make iso STRICT_FOSS=1` |
| `firmware-qcom-soc` | Qualcomm firmware licence (redistributable, non-free) | Qualcomm SoC firmware for supported laptops | `make iso STRICT_FOSS=1` |
| `firmware-misc-nonfree` | Mixed vendor firmware licences (redistributable, non-free) | Assorted device firmware not covered by the specialised packages | `make iso STRICT_FOSS=1` |

The authoritative build-time allowlist is the `ALLOWED_FIRMWARE` list in
`build/config/hooks/normal/0300-licences.chroot`. It must stay in sync with
the package-list template and this table.

Phase 2 adds no new non-free exception. Plasma, SDDM, the Breeze-derived
greeter, Firefox ESR and the EclipseOS artwork are all from Debian `main` or
original project work.

### Deliberately excluded non-free packages

| Package | Reason |
| --- | --- |
| `firmware-nvidia-graphics` | NVIDIA GPU firmware; the NVIDIA driver must be an explicit installer opt-in, never preinstalled. |
| `nvidia-driver`, `nvidia-kernel-dkms`, `nvidia-kernel-support` | Proprietary driver stack. Not in the ISO. Phase 3 may offer it as a clearly labelled opt-in with Secure Boot MOK instructions. |
| `firmware-ivtv` | Requires the user to accept a licence at install time; not suitable for a silent live image. |
| `firmware-ipw2x00` | Same licence-acceptance problem. |
| `firmware-sof-signed` | Audio DSP firmware outside the approved hardware scope; can be added after review. |
| `amd64-microcode`, `intel-microcode` | CPU microcode is a Phase 6 hardware-hardening decision, not part of the Phase 1 live image. |
| `virtualbox-guest-utils` | Not available in Debian 13 stable; licensing review incomplete. See [`virtualbox-limitations.md`](virtualbox-limitations.md). |
| `virtualbox-guest-additions-iso` | Oracle PUEL; never bundled. |
| Oracle VirtualBox Extension Pack | Oracle PUEL; never bundled. |

`firmware-linux-free` is in Debian `main` and is DFSG-free; it is not an
exception.

## Component inventory

### Foundation (Phase 1)

| Component | Use | Licence | Source/status |
| --- | --- | --- | --- |
| Debian 13 `trixie` base | Userland, package management, init scripts, security support | Mixed DFSG-free licences; per-package copyright under `/usr/share/doc/*/copyright` | Reused |
| Linux kernel (`linux-image-amd64`) | Hardware support | GPL-2.0-only, with separately licensed firmware | Reused |
| systemd | Init, services, logind, timesync | LGPL-2.1-or-later | Reused |
| live-boot, live-boot-initramfs-tools | Live media boot | GPL-3.0-or-later | Reused |
| live-config | Live-session reconfiguration | GPL-3.0-or-later | **Deliberately not installed**; EclipseOS bakes identity, user and services at build time |
| live-build | Image build tooling | GPL-3.0-or-later | Build host only; not in the ISO |
| GRUB 2 | UEFI and BIOS boot menu | GPL-3.0-or-later | Reused; EclipseOS theme is original |
| Plymouth | Graphical boot splash | GPL-2.0-or-later | Reused; EclipseOS theme is original |
| LightDM / LightDM GTK Greeter | Live login and autologin | GPL-3.0-or-later / GPL-2.0-or-later | Reused; EclipseOS configuration is original; Phase 2 replaces with SDDM/Plasma |
| openbox | Phase 1 window manager | GPL-2.0-or-later | Reused |
| xterm, feh, fastfetch | Phase 1 session tools | MIT / MIT / MIT | Reused |
| NetworkManager, wpasupplicant | Networking | LGPL-2.1-or-later / BSD-3-Clause | Reused |
| X.Org X server and drivers | X11 display stack | MIT and compatible licences | Reused |
| Mesa and kernel graphics drivers | OpenGL and GPU support | MIT / GPL-2.0 / LGPL-2.1 | Reused as dependencies |
| Inter | UI font | SIL Open Font License 1.1 | Reused; reserved name unmodified |
| DejaVu, Liberation fonts | Fallback fonts | Bitstream Vera / GPL-2.0 with font exception | Reused |
| Adwaita and hicolor icon themes | Base icons | LGPL-3.0-or-later / public-domain-ish (verify package copyright) | Reused |
| EclipseOS logo, dark/light wallpapers, GRUB/Plymouth artwork, scripts | Product identity and integration | GPL-3.0-or-later (project) | Original |

### Phase 2 desktop (in the current ISO) and later work

| Component | Use | Licence | Status |
| --- | --- | --- | --- |
| KDE Plasma / KWin 6.3 | Desktop session, compositor | GPL-2.0-or-later / LGPL-2.1-or-later | Included; configured by EclipseOS |
| EclipseOS dark/light Plasma look-and-feel, wallpapers and SDDM branding | EclipseOS visual identity | GPL-3.0-or-later (project); Breeze-derived QML retains upstream LGPL/CC-BY-SA notices | Original configuration and artwork; upstream QML headers retained |
| SDDM | Login manager | GPL-2.0-or-later | Included; EclipseOS configuration |
| Breeze SDDM theme (`sddm-theme-breeze`) | QML greeter base | CC-BY-SA-4.0 metadata; QML files LGPL-2.0-or-later | Included; EclipseOS derivative theme, upstream headers retained |
| KDE Frameworks 6 / Qt 6 | Desktop libraries | LGPL-2.1-or-later / LGPL-3.0 / GPL-3.0 | Included as dependencies |
| Dolphin, Konsole, Kate, Gwenview, KCalc, Spectacle | Desktop applications | GPL-2.0-or-later / LGPL-2.1-or-later | Included |
| Ark | Archive manager | GPL-2.0-or-later | Included |
| Firefox ESR 140 | Browser | MPL-2.0 (and compatible) | Included, unmodified Debian build; EclipseOS local start page and system preferences |
| Haruna | Media player | GPL-3.0-or-later | Planned |
| Discover / PackageKit | Store and package management | GPL-2.0-or-later / LGPL-2.1-or-later | Planned; not installed in the Phase 2 preview |
| Calamares | Installer | GPL-3.0-or-later | Planned; branding/configuration original |
| Flatpak | Application sandbox | LGPL-2.1-or-later | Planned |

## Generated manifest and build-time gate

`build/config/hooks/normal/0300-licences.chroot` writes:

- `/usr/share/doc/eclipseos/packages.tsv` — every installed package with
  version, architecture, archive area and section;
- `/usr/share/doc/eclipseos/non-free-firmware.tsv` — the approved exceptions
  actually present.

It fails the build if:

- any package comes from `contrib` or `non-free`;
- any `non-free-firmware` package is not in the allowlist above.

`build/config/hooks/normal/9900-verify.chroot` then asserts that the files,
branding assets, live account policy and enabled units are present. Both hooks
run inside the chroot before the squashfs is created. The default Phase 1
build ran both hooks successfully: `0300-licences` reported 24 approved
packages and `9900-verify` reported all checks passed. The strict build
reported `0300-licences: 0 approved non-free-firmware package(s)` and also
passed `9900-verify`. The actual manifest is inside each image; strict
evidence is in
[`evidence/phase1/strict`](evidence/phase1/strict/README.md).

The build also stages this document and the project licence into the image:

- `/usr/share/doc/eclipseos/copyright` — GPL-3.0-or-later text;
- `/usr/share/doc/eclipseos/licenses.md` — this inventory;
- `/usr/share/doc/eclipseos/version` — release and build metadata.

## Attribution and trademark notes

- KDE, Plasma, KWin, Dolphin, Konsole, Kate, Gwenview and Discover are names
  of their respective projects; EclipseOS does not claim endorsement.
- Firefox is a trademark of the Mozilla Foundation. EclipseOS ships the
  unmodified Debian Firefox ESR build with a local start page and system
  preferences; it does not rename or repackage Firefox and does not claim
  Mozilla endorsement.
- The EclipseOS SDDM greeter is a branding derivative of the Breeze theme.
  The upstream QML files retain their copyright and SPDX headers in
  `build/config/includes.chroot/usr/share/sddm/themes/eclipseos/`; the
  EclipseOS artwork and theme metadata are original project work.
- Intel, AMD, NVIDIA, Realtek, Broadcom, Qualcomm and other hardware names are
  trademarks of their owners.
- Inter is licensed under the SIL OFL 1.1; the reserved font name is used
  unmodified.
- Open-Meteo (future optional weather widget) is an external service; its
  attribution will appear in the widget if it ships.

## Open decisions

1. **NVIDIA opt-in:** implement in Phase 3 as an installer action that shows
   the licence, download size and Secure Boot MOK steps. Do not add it to the
   default package list.
2. **CPU microcode:** decide in Phase 6 whether to ship redistributable
   microcode updates; if so, add them to the exception table and manifest.
3. **Guest utilities:** revisit only after a Debian stable package and a
   licence review exist. Until then, the requirement is unmet.
4. **Snapshot pinning:** release builds will pin Debian sources to a snapshot;
   the exact package versions and copyright texts will then be archived with
   the ISO.
