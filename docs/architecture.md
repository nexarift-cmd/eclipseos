# EclipseOS architecture

Status: **Phase 1 implementation.** This document describes the target
product and its Phase 1 subset. Phase 1 uses LightDM + openbox + xterm/feh
instead of Plasma + SDDM; Phase 2 replaces the session. No ISO has been built
or booted yet, and this document is not evidence that the system works. See
[build-environment.md](build-environment.md).

## 1. Scope and honest boundaries

EclipseOS is a Linux distribution assembled from Debian, KDE Plasma and
Calamares. The project owns the product layer:

- the EclipseOS visual identity and original artwork;
- the live-build configuration, package selection, hooks and reproducibility
  controls;
- the desktop layout, Start menu, taskbar configuration, snap-layout
  behaviour and system theme;
- the GRUB, Plymouth, SDDM and lock-screen branding;
- Calamares branding and installation policy;
- Eclipse Settings and Eclipse Update;
- integration, defaults, testing and release engineering.

The project does **not** own, and will not falsely claim to own:

- the Linux kernel and Debian userland;
- KDE Plasma, KWin, Dolphin, Konsole, Discover or other upstream applications;
- NetworkManager, PipeWire, BlueZ, CUPS, Calamares or Firefox;
- firmware and drivers supplied by hardware vendors.

This is the same product strategy used by many real distributions: a
distinct, coherent operating-system product delivered on a maintained
upstream base. It is achievable and supportable; writing every kernel driver
and desktop component from scratch is not.

## 2. Technology decisions

| Decision | Choice | Why |
| --- | --- | --- |
| Base distribution | Debian 13 `trixie` (currently 13.7) | Stable, long support, excellent x86_64 hardware coverage, signed UEFI shim, non-free firmware archive, `live-build`, Calamares and KDE packages available. Arch would give newer packages but more breakage and more installer work; an LFS-style base would not be supportable. |
| Image builder | Debian `live-build` | Native hybrid UEFI/BIOS ISO output, hooks, package lists, includes, chroot and squashfs integration. One command wrapper is `make iso`. |
| Desktop | KDE Plasma 6.3 (KWin, Plasma, SDDM) | Gives mature Wayland and X11 sessions, window rules, virtual desktops, tiling, blur, notifications, tray, KRunner, lock screen and accessibility. Building a wlroots/Qt shell would duplicate years of plumbing and reduce hardware coverage. Plasma is the fastest path to a polished, testable result. |
| Desktop customisation | Plasma look-and-feel package, custom QML plasmoids, KWin scripts and configuration | Keeps upstream maintenance and security updates while presenting a distinct EclipseOS experience. |
| Installer | Calamares 3.3 (Debian stable) | Proven distro installer, supports UEFI/BIOS, erase/manual/alongside modes and LUKS. Branding and modules can be replaced without forking the engine. |
| Settings | Custom Qt 6 / QML application | Meets the custom-app requirement and integrates with the same Qt stack as Plasma. C++/Qt avoids an extra Python GUI runtime and produces a small, packageable binary. |
| Update UI | Custom Qt 6 / QML front-end, APT/PolicyKit backend, Discover for app management | Friendly update flow while preserving Debian's signed APT trust chain. |
| File manager / store / apps | Dolphin, Discover, Konsole, Kate, Gwenview, Haruna, KCalc, Spectacle, Firefox ESR | Reused and re-themed where the application does not need a custom implementation. Replacing them would add risk without improving the core OS. |
| Display server default | Wayland, with an X11 fallback session | Wayland is the modern default; X11 remains selectable for troublesome GPUs and VirtualBox configurations. |
| Versioning | `eclipse-YY.MM`; first release `eclipse-26.10` | Unambiguous release cadence and image naming. |
| Project licence | GPL-3.0-or-later for EclipseOS code | Compatible with the KDE ecosystem and keeps the product layer free software. |

### Version inventory of the intended stable base

These are the versions available from Debian 13 at the time of the Phase 0
check. They will be pinned to a Debian snapshot before the release build.

- Debian 13.7 (`trixie`), Linux 6.12.x
- KDE Plasma / Plasma Workspace 6.3.6
- Calamares 3.3.14
- live-build 1:20250505+deb13u1
- SDDM 0.21.0 snapshot
- Firefox ESR 140.x
- PipeWire 1.4.x, NetworkManager 1.52.x, BlueZ 5.82.x, CUPS 2.4.10.x

## 3. System stack

```
┌─────────────────────────────────────────────────────────────────────┐
│ EclipseOS product layer (this repository)                          │
│ Eclipse theme · taskbar · Start · snap layouts · Settings · Update │
├─────────────────────────────────────────────────────────────────────┤
│ Desktop session: KDE Plasma 6.3 / KWin / KRunner / SDDM            │
├─────────────────────────────────────────────────────────────────────┤
│ System services                                                  │
│ systemd · NetworkManager · PipeWire+WirePlumber · BlueZ · CUPS      │
│ power-profiles-daemon · fwupd · nftables/ufw · unattended-upgrades  │
├─────────────────────────────────────────────────────────────────────┤
│ Debian 13 userland, APT/dpkg, glibc, x86_64 packages              │
├─────────────────────────────────────────────────────────────────────┤
│ Linux 6.12 kernel · firmware · GPU / Wi-Fi / storage drivers       │
├─────────────────────────────────────────────────────────────────────┤
│ UEFI (primary) or legacy BIOS · hybrid ISO (El Torito + MBR)       │
└─────────────────────────────────────────────────────────────────────┘
```

### Boot path: live media

1. Firmware boots GRUB from the ISO (UEFI El Torito image or BIOS MBR +
   El Torito).
2. GRUB shows the EclipseOS menu with a default "Live desktop" entry,
   accessibility options and a memory-test entry.
3. The kernel and initramfs boot. `live-boot` locates the squashfs on the
   ISO or USB device.
4. Plymouth displays the original EclipseOS boot splash while the root
   overlay is assembled.
5. systemd reaches the graphical target. Phase 1 starts LightDM, which logs
   the live user in automatically and launches the EclipseOS X11/openbox
   session. Phase 2 replaces this with SDDM and Plasma.
6. The live session runs as `eclipse` (no password) so the desktop is
   immediately usable. No installed-system credential exists yet.
7. Phase 3 adds an "Install EclipseOS" launcher that starts Calamares through
   a PolicyKit wrapper.

### Boot path: installed system

1. UEFI: shim -> signed GRUB -> Debian kernel + initramfs, or direct GRUB if
   Secure Boot is disabled.
2. BIOS: GRUB in the MBR/BIOS boot partition.
3. Optional LUKS unlock.
4. systemd -> SDDM -> Plasma. No autologin on the installed system.
5. First boot performs no phone-home, no account creation and no telemetry.

## 4. Live-build pipeline

`make iso` runs `scripts/build.sh`, which:

1. validates the host and architecture;
2. records `SOURCE_DATE_EPOCH`, commit and licence mode;
3. renders the brand artwork and stages the wallpaper, Plymouth/GRUB
   splashes, GRUB font, firmware list and licence documents into the
   live-build tree;
4. cleans previous live-build state;
5. runs `lb config` explicitly, then `lb build` in `build/`;
6. renames the hybrid image to `eclipseos-26.10-amd64.iso`;
7. writes a SHA256 file and build-info manifest;
8. leaves UEFI and BIOS boot testing to `make test-all` (local or CI).

The live-build tree has these responsibilities:

- `build/auto/config` — live-build options, hybrid boot, archive areas and
  volume metadata;
- `build/config/package-lists/` — curated package sets, separated into base,
  desktop, apps and VM support;
- `build/config/includes.chroot/` — branded files, systemd units, defaults,
  policy files and skeletons;
- `build/config/hooks/` — non-interactive setup, service enablement, cleanup,
  package verification and generated manifests;
- `build/config/bootloaders/` — GRUB theme and configuration;
- `build/config/archives/` — optional pinned snapshot sources;
- `installer/` — mounted/copied into the live image and used by Calamares.

Reproducibility target:

- pin all APT sources to one Debian snapshot for a release;
- set a deterministic `SOURCE_DATE_EPOCH`;
- use a fixed build locale/timezone and `umask`;
- exclude build-host paths and timestamps from generated files;
- compare the SHA256 of two independent release builds in CI.

Live-build and GRUB do not guarantee bit-identical output by default. The
project will only call a build "reproducible" after two builds produce the
same hash; until then the supported promise is "one-command build against a
pinned package snapshot".

## 5. Desktop shell design

### Approach

Use KDE Plasma as the session/compositor and build the visible EclipseOS shell
from focused customisations:

- a Plasma **look-and-feel** package for colours, plasma style, window
  decoration, icon selection, lock screen and splash;
- a bottom, auto-centred **Eclipse Taskbar** built from a Plasma panel plus
  custom QML where the stock applets cannot match the design;
- a custom **Eclipse Start** plasmoid with a pinned grid, recent files,
  search and power actions;
- KWin scripts/effects for snap-layout prompts, animation timing and rounded
  corners where the Breeze decoration is insufficient;
- KRunner for global shell search, themed through the Eclipse look-and-feel;
- an SDDM QML greeter and matching Plasma lock screen;
- a custom **Widgets** panel (clock, calendar, weather) as a QML plasmoid.

### Taskbar and Start

- Panel at the bottom, height ~48 px, translucent with blur, rounded top
  corners and a thin highlight border.
- Pinned launchers: Start, Search, Task View, Eclipse Files, Eclipse Store,
  Firefox, Settings.
- Running applications use the Plasma task manager model, with per-window
  grouping, active-window accent underline and hover previews.
- System tray: NetworkManager, volume, Bluetooth, battery, notifications,
  clock/calendar; click opens the quick-settings panel and notification
  centre.
- Start menu: pinned app grid, recommended/recent documents, search box that
  queries apps, files, settings, calculator and web results opt-in; power
  menu with lock, log out, suspend, restart and shut down.
- All visible strings will be translatable; no Microsoft icons, fonts or
  layouts will be copied.

### Window management

- Halves, quarters and thirds via KWin quick tiling plus an EclipseOS
  snap-layout picker shown while dragging a window to the screen edge.
- Maximise/minimise/restore animations implemented with KWin effect settings
  and, if needed, a small custom effect.
- Virtual desktops with a Task View overlay; Alt+Tab switcher using Plasma's
  window switcher with the EclipseOS theme.
- Window blur via the KWin Blur effect, with performance fallback when
  running in software-rendered VMs.
- Rounded corners: Breeze decoration by default; a measured fallback custom
  KWin effect if Plasma's decoration cannot provide the required 8 px radius
  consistently on X11 and Wayland.

### Search and widgets

- KRunner remains the search engine and exposes apps, files, settings,
  recent documents and calculator (Qalculate). A custom runner may be added
  for EclipseOS-specific settings pages.
- The weather widget uses a direct request to an open, keyless service
  (Open-Meteo) with an explicit city/location setting. It is opt-in and does
  not send telemetry. Offline state is handled gracefully.
- Calendar data comes from the local Plasma calendar stack.

### Lock and login

- SDDM theme: original eclipse corona artwork, blurred wallpaper, user card,
  password field, session picker, accessibility and power actions.
- Plasma lock screen: same wallpaper language, clear unlock affordance and
  media controls; no fake Windows lock screen.
- The installed system never auto-logs in. The live session does, by design.

### Display server policy

The default session is Plasma Wayland. An "EclipseOS on X11" session is
installed and documented for VirtualBox and older GPUs. A boot-time fallback
service may select X11 when the Wayland session fails repeatedly, but it must
not hide persistent crashes from the test suite.

## 6. Installer design

Calamares is configured, not forked. Branding lives in
`installer/branding/eclipseos/`.

Sequence:

1. Welcome — language, region and keyboard.
2. Location — timezone and locale.
3. Keyboard — layout and test field.
4. Partition — erase disk (explicit destructive warning), install alongside,
   manual partitioning, optional LUKS full-disk encryption.
5. Users — full name, login name, hostname, strong password required;
   password-quality checks enforced.
6. Drivers — opt-in NVIDIA proprietary driver and firmware package group;
   no silent proprietary driver install.
7. Summary — disk operations, encryption, bootloader and driver choices
   restated before confirmation.
8. Install — progress, log viewer, no fake progress.
9. Finish — restart or continue live session.

Bootloader:

- UEFI: install GRUB to the existing or newly created EFI System Partition;
  register `EclipseOS` with `efibootmgr`; do not destroy other boot entries.
- BIOS: install GRUB to the target disk's MBR; handle existing Windows
  installations with `os-prober` and a clear warning about boot order.
- LUKS: create `/dev/mapper` mapping, configure crypttab/initramfs and require
  a separate recovery passphrase confirmation.

The installer must be launched with a dedicated wrapper and PolicyKit, not a
root desktop session. Destructive operations require an explicit "Erase
disk" selection, a typed confirmation and a final summary.

The installed system is produced by unpacking the same live root filesystem
and applying target-specific configuration; it is not a separate hand-built
image. This keeps installed and live behaviour aligned.

## 7. Eclipse Settings

Custom Qt 6 / QML app, packaged as `eclipse-settings` (Debian package).

Backends, avoiding reimplementation of privileged system services:

| Page | Backend |
| --- | --- |
| Network | NetworkManager D-Bus (`nmcli` fallback) |
| Display | KScreen / `kscreen-doctor` |
| Sound | PipeWire/WirePlumber via `wpctl` and PulseAudio compatibility |
| Personalization | Plasma `plasma-apply-*` tools + wallpaper/theme DBus |
| Accounts | AccountsService D-Bus + PolicyKit |
| Apps | `.desktop` enumeration + PackageKit for removal |
| Time & Language | `timedated`, `localed` D-Bus |
| Privacy | KDE/Plasma settings files + portal controls |
| Updates | APT helper, see below |
| About | `/etc/os-release`, kernel, KDE/Qt, CPU, memory, disk, firmware |

High-risk privileged actions run through narrowly scoped PolicyKit helpers,
never through a general-purpose root shell. The UI degrades gracefully when a
backend is unavailable (for example no Wi-Fi hardware).

## 8. Eclipse Update and app store

- **Eclipse Update** checks APT for security and regular updates, displays
  severity and download size, and installs through a PolicyKit-authorized
  helper. It will not use a private package source by default.
- **Discover** (rebranded as Eclipse Store) handles graphical application
  discovery/install from Debian and Flatpak. Flatpak is configured at first
  use, not pre-populated with a proprietary store.
- **unattended-upgrades** applies Debian security updates automatically on
  the installed system; boot-time update failures are visible, never silent.
- Update metadata is signed by APT. The UI is not allowed to add arbitrary
  signing keys or repositories.
- EclipseOS-created `.deb` packages are installed from the image initially.
  A separate signed EclipseOS repository/update channel is a post-26.10
  deliverable unless release engineering completes it before RC.

## 9. System services, security and privacy defaults

| Concern | Implementation |
| --- | --- |
| Networking | NetworkManager, IPv6, Wi-Fi regulatory domain from locale; `iwd` not used by default to avoid duplicate supplicants |
| Audio | PipeWire + WirePlumber, ALSA UCM, no PulseAudio daemon |
| Bluetooth | BlueZ, disabled by default when no adapter; discoverability off |
| Printing | CUPS with socket activation, Avahi discovery; firewall-aware |
| Power | power-profiles-daemon; suspend/resume via logind; no TLP conflict |
| Firmware | fwupd; LVFS enabled only after reading fwupd's metadata; no forced updates |
| Firewall | nftables backend via `ufw`/`firewalld` decision gate in Phase 1; default deny inbound, allow established/outbound |
| Security updates | unattended-upgrades for Debian security archive; daily timer |
| SSD TRIM | `fstrim.timer` weekly |
| Telemetry | none |
| Crash reporting | disabled by default; no automatic uploads |
| SSH | server not installed by default |
| Live credentials | `eclipse`, no password, passwordless sudo inside the live session only |
| Installed credentials | real user password required by Calamares; root login disabled |

The live ISO must not expose the live user's passwordless sudo to the
installed system. Calamares creates a fresh sudo group membership and the
live sudoers drop-in is excluded from the target.

## 10. VirtualBox and VM support

The ISO targets VirtualBox as the first manual test platform. Phase 1 sets:

- VMSVGA graphics and 128 MB VRAM in `scripts/create-vbox-vm.sh`;
- EFI by default, BIOS with `--no-efi`;
- 4 GB RAM, 2 vCPU, 25 GiB disk, ISO attached;
- X11 session with software-rendering fallback.

EclipseOS does **not** ship Oracle Guest Additions or the Extension Pack. The
open-source `vmwgfx`/Mesa stack provides basic display support, but automatic
resize, seamless mouse integration, shared clipboard and shared folders are
unavailable. Debian 13 stable does not provide `virtualbox-guest-utils`; the
requirement is unmet. See
[`virtualbox-limitations.md`](virtualbox-limitations.md) for the full matrix
and workarounds.

The VirtualBox acceptance boot has not been recorded. QEMU tests are the CI
gate; they use `-vga std`, so they cannot prove VirtualBox-specific
behaviour.

## 11. Build and test architecture

```
developer / CI
   │
   ├─ make doctor ── host and tool validation
   ├─ make iso ───── live-build ── hybrid ISO + SHA256 + buildinfo
   └─ make test-all
          ├─ QEMU/OVMF   boot, serial marker, framebuffer screenshot
          └─ QEMU/SeaBIOS boot, serial marker, framebuffer screenshot
```

Test tiers:

1. **Static checks** — shell syntax, JSON/QML parse, config schemas,
   desktop-file validation, policy lint, licence inventory.
2. **Boot smoke test** — UEFI and BIOS in QEMU. A systemd oneshot writes a
   marker to the serial console once the graphical session is up. A QMP
   `screendump` captures the screen. The test fails on timeout, failed units,
   missing marker or an all-black screenshot.
3. **Installer test** — boot with a blank virtual disk, install via a
   scripted/guided Calamares run, detach the ISO, boot the installed disk and
   verify login and desktop marker.
4. **Hardware matrix** — real hardware, documented in
   `docs/hardware-test-checklist.md`.

QEMU in CI uses software emulation unless KVM is available; this is slower
but deterministic. VirtualBox is a user acceptance environment, not the
required CI virtualiser.

## 12. Risk register

| ID | Risk | Likelihood | Impact | Mitigation / decision |
| --- | --- | --- | --- | --- |
| R0 | Current sandbox cannot run Linux or virtualisation, so nothing can be built or boot-tested here | Certain | Critical | Build on a Debian 13 host or GitHub Actions. Phase 1 is implemented and statically checked, but acceptance stays open until an ISO boots. No false completion claims. |
| R1 | Oracle Guest Additions are non-free; Debian 13 stable lacks Guest Utilities | High | High | Not bundled. VMSVGA + open-source `vmwgfx`/Mesa is used; clipboard/resize/shared folders are documented as unavailable in [`virtualbox-limitations.md`](virtualbox-limitations.md). Requirement explicitly unmet. |
| R2 | "Open-source only" conflicts with firmware and NVIDIA requirements | Certain | Medium | Default: redistributable non-free firmware in the image for hardware support; NVIDIA driver is opt-in during install; no Oracle PUEL components. Document every exception. |
| R3 | Wayland/Plasma fails under VirtualBox or software rendering | Medium | High | X11 fallback session; VMSVGA; boot marker checks both sessions; CI uses QEMU without GL acceleration. |
| R4 | Calamares alongside/manual partitioning is destructive or fails | Medium | Critical | Back up before test; use disposable virtual disks; typed confirmation; test erase/alongside/LUKS matrices; never auto-select erase. |
| R5 | UEFI + BIOS hybrid boot regressions | Medium | High | Both firmware modes in CI; keep GRUB and syslinux paths independent; test Secure Boot on/off at RC. |
| R6 | Custom QML smoke test cannot prove visual polish | Medium | Medium | Screenshots plus manual visual checklist per phase; QEMU captures at fixed 1920x1080. |
| R7 | ISO size and build disk exhaustion | High on low-resource hosts | High | Curated package lists; no office/games by default; build host >=40 GB free; CI free-disk action; monitor package manifest. |
| R8 | Bit-identical reproducibility is harder than a one-command build | High | Medium | Snapshot pinning, deterministic timestamps, two-build hash comparison; do not claim bit-reproducibility until verified. |
| R9 | Third-party driver/Secure Boot signing | Medium | High | Secure Boot disabled for initial tests; Phase 6 signed shim path and MOK enrollment instructions for NVIDIA. |
| R10 | Broadcom/Realtek Wi-Fi and NVIDIA GPUs need proprietary components | Medium | High | Debian firmware packages on ISO; opt-in NVIDIA; hardware checklist; publish unsupported matrix honestly. |
| R11 | Accessibility and localisation incomplete | Medium | Medium | Use Plasma's accessibility stack; keyboard navigation checks; limit release languages to those actually translated. |
| R12 | Power loss during LUKS install/data loss | Low | Critical | Clear warnings, recovery key guidance, no automatic repartitioning, backup-first documentation. |

## 13. Explicit non-goals for 26.10

- A new kernel, graphics driver stack or filesystem.
- Full Windows application compatibility, NTFS-native OS install, or a
  Windows replacement at the binary ABI level.
- Mobile/ARM images.
- Telemetry, accounts tied to a cloud service, or an official app store
  operated by this project.
- Guaranteed support for every PC. The release is x86_64, UEFI-first, with a
  documented hardware compatibility matrix.

## 14. Phase gates

Phase 0 exit criteria — met:

- Architecture, base distribution, desktop approach and installer chosen.
- Risks and licence conflicts recorded.
- Repository skeleton and build entry points created.

Phase 1 — implemented, not accepted:

- live-build tree, package lists, hooks, branding and QEMU test driver exist;
- local static checks pass;
- **no ISO has been built, no QEMU or VirtualBox boot has run, and no
  screenshot exists.** Acceptance remains open until those results exist.
