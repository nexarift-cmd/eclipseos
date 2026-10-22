# EclipseOS roadmap and acceptance gates

Every phase must leave a buildable tree and a bootable ISO. A phase is not
complete because code was written; it is complete only when its acceptance
checks have actually run and the evidence is recorded.

Current state: **Phase 0 complete. Phase 1 complete and accepted at
2048 MiB.** The final default ISO is
`aade6c679e41b82bf62aa1a190ca334fbe7091dfcdcaf1254da2d61c04fac397`, built by
GitHub Actions run `39547858160`. QEMU UEFI, BIOS and the VirtualBox
storage-profile boot passed; the final ISO also reached the desktop in
VirtualBox EFI and BIOS. The user accepted the original `d10c78c3…` ISO with
**Skip Unattended Installation ticked** at 2048 MiB. The unticked wizard path
is fixed by branding `/.disk/info` (no VISO detection) plus a `BOOT=live`
initramfs default. 4096 MiB is recommended but remains untested because this
5.1 GB host cannot start the guest. The strict main-only ISO from run #4
contains zero non-free firmware packages; it was not rebuilt after the
Phase 1 fix. Phase 2 has started on a separate branch until its first Plasma
ISO passes a boot gate. Evidence:
[`evidence/phase1`](evidence/phase1/README.md) and
[`evidence/phase1/virtualbox-unattended.md`](evidence/phase1/virtualbox-unattended.md).

## Phase 0 — Plan and repository skeleton

Deliverables:

- technology decisions and rationale;
- risk register, including licensing conflicts;
- repository skeleton;
- build host and test strategy;
- no false claims about a built ISO.

Evidence: this repository, `docs/architecture.md`,
`docs/build-environment.md`, `docs/licenses.md`, the Phase 0 commit and the
Phase 0 report.

Gate: user agrees on a build environment and any licence-policy exceptions.

## Phase 1 — Bootable branded ISO

Scope:

- Debian 13 live-build baseline;
- hybrid UEFI + BIOS ISO, VirtualBox-compatible;
- custom GRUB theme and menu with EclipseOS branding;
- custom Plymouth splash;
- live user `eclipse`, no password;
- minimal graphical environment to prove the graphical stack (openbox or a
  small session) or a console plus framebuffer test;
- checksum and build-info generation;
- QEMU UEFI and BIOS smoke tests with screenshots;
- VirtualBox EFI and BIOS manual confirmation.

Acceptance:

- `make iso` exits 0 on Debian 13 and writes the three expected artefacts;
- SHA256 verifies;
- QEMU UEFI boot reaches the boot marker within the timeout;
- QEMU BIOS boot reaches the boot marker within the timeout;
- screenshots show the GRUB theme and Plymouth/boot result;
- VirtualBox EFI and BIOS both reach the live environment;
- no build-breaking errors or missing firmware on the test hardware.

Evidence: ISO name, SHA256, build log, serial logs, screenshots, test commands.

### Phase 1 implementation status

| Item | State |
| --- | --- |
| live-build configuration, package lists and hooks | Executed by runs #3 and #4; build and final `9900-verify` passed |
| Original GRUB, Plymouth and wallpaper artwork | Visible in the GRUB and Plymouth boot screenshots |
| Branding assets inside the live-build tree | Present in the built image; the boot and desktop screenshots show them |
| `make iso` / SHA256 / build-info | Passed; default 890 MiB and strict 464 MiB ISOs, both SHA256-verified after download |
| QEMU UEFI and BIOS boot tests | Passed for both flavours; zero failed units |
| VirtualBox EFI and BIOS boot | Default ISO passed at the accepted 2048 MiB; 4096 MiB is recommended but blocked by the test host's memory/virtualisation limits |
| Strict `STRICT_FOSS=1` build | Passed; `main` only, zero non-free firmware packages, both QEMU boots pass |
| GitHub Actions build | Run #3 and run #4 both succeeded |

The acceptance line "VirtualBox EFI and BIOS both reach the live environment"
is met at the **accepted 2048 MiB** size, with the host limitation recorded in
[`evidence/phase1/virtualbox-host-limit.txt`](evidence/phase1/virtualbox-host-limit.txt).
4096 MiB is recommended but not an acceptance blocker for this host; it must
be verified on a host with enough RAM and working virtualisation before it is
claimed. The strict build is verified. Static checks alone are not acceptance.

## Phase 2 — Desktop experience

Scope:

- Plasma 6 session, Wayland default and X11 fallback;
- Eclipse look-and-feel package, colours, decorations and fonts;
- original wallpapers, logo/icon set;
- centered taskbar with pinned/running apps and tray;
- Start menu with search and power menu;
- light/dark toggle and wallpaper picker;
- branded SDDM greeter and live autologin;
- Firefox ESR with an EclipseOS start page and bookmarks;
- desktop icons and context menu.

Acceptance:

- live ISO boots directly to the EclipseOS desktop in VirtualBox UEFI and
  BIOS;
- the branded SDDM greeter is visible without autologin and accepts a live
  login;
- screenshots in light and dark mode at 1920x1080;
- Start menu opens, searches, launches an app and powers off;
- taskbar pinned launchers, running indicators and tray controls function;
- Firefox ESR starts and shows the offline EclipseOS start page;
- no Microsoft assets; licence inventory updated;
- QEMU smoke test still passes.

### Status at the current Phase 2 preview

- The current Phase 2 ISO passes the QEMU UEFI, BIOS and
  VirtualBox-storage-profile gates. Run 39693031395 proved the VM-aware X11
  selection with `session=x11`, `virt=kvm` and `selection=eclipseos-x11`.
- A real VirtualBox 7.2 boot at 2048 MiB reached the Plasma desktop; taskbar,
  Start menu, applications, theme and networking worked. A slight lag was
  observed on the low-memory host and is recorded as an observation, not a
  failure. Firmware mode and a screenshot/log were not included in that
  manual report, so it is not a complete UEFI+BIOS acceptance record.
- The Firefox ESR browser is now included with an EclipseOS local start page,
  bookmarks and unprivileged preferences. It remains the unmodified Debian
  Mozilla build.
- Light/dark switching, a light wallpaper, VM compositor tuning and a branded
  SDDM greeter are implemented in the worktree but still need boot evidence.
- A QEMU X11 EDID path at 1920x1080 is being re-tested. The earlier Wayland
  EDID attempt produced a black framebuffer with only the cursor visible and
  was rejected; no 1920x1080 evidence is claimed yet.
- Pinned taskbar launchers were written as one string in the earlier layout;
  this is fixed to a Plasma string list and awaits a new screenshot.
- Real-hardware Wayland boot has **not** been tested; there is no hardware
  result to claim.

The exact evidence and limitations are in
[`evidence/phase2/README.md`](evidence/phase2/README.md).

## Phase 3 — Installer and installed system

Scope:

- branded Calamares with Windows-setup-style flow;
- language, region, keyboard, disk, account, summary, install;
- erase disk, alongside and manual partitioning;
- optional LUKS;
- UEFI and BIOS bootloader installation;
- installed system boots and logs in with the created account;
- first-boot defaults applied.

Acceptance:

- install to a blank disposable virtual disk in UEFI mode;
- install in BIOS mode;
- install alongside a dummy/second OS partition without destroying it;
- LUKS install unlocks and boots;
- installed system boots with ISO detached and SDDM accepts the password;
- screenshots of each installer step and first installed login;
- failed install does not leave a half-configured bootloader silently.

## Phase 4 — Apps, Settings, Store and Updates

Scope:

- Eclipse Settings with all required pages;
- Dolphin preconfigured/rebranded as Eclipse Files (sidebar, tabs, preview);
- Eclipse Store (Discover rebrand) with APT and Flatpak;
- Eclipse Update with APT/PolicyKit UI;
- app suite: terminal, editor, image viewer, media player, calculator,
  screenshots, browser;
- Flatpak configuration, offline error states.

Acceptance:

- each Settings page opens and reports unavailable hardware honestly;
- network, display, sound, theme, update and About actions tested;
- Dolphin tabs/sidebar/preview demonstrated;
- update check and install tested against a disposable package;
- store opens and lists packages; no unsigned repositories added;
- app suite launches and is themed;
- screenshots and functional notes.

## Phase 5 — Shell polish and performance

Scope:

- snap layout picker (halves, quarters, thirds) and window animations;
- virtual desktops / Task View;
- Alt+Tab switch experience;
- widgets panel (weather, clock, calendar);
- global search polish;
- lock screen;
- quick settings and notification centre;
- performance tuning and graceful software-rendering fallbacks.

Acceptance:

- snap layouts work with pointer and keyboard on Wayland and X11 fallback;
- animations do not block input or leave windows off-screen;
- widgets degrade offline without errors;
- lock screen locks/unlocks under both sessions;
- cold boot to desktop within a measured budget on 4 GB / 2 vCPU VM;
- QEMU and VirtualBox screenshots of all major surfaces;
- no regression in prior phase tests.

## Phase 6 — Hardware hardening and release candidate

Scope:

- firmware and driver audit (Wi-Fi, Ethernet, graphics, audio, storage,
  suspend/resume, webcam, printer, Bluetooth);
- Secure Boot validation and MOK flow;
- UEFI/BIOS real-hardware tests;
- dual-boot preservation review;
- performance/memory tuning;
- accessibility and keyboard-only pass;
- final licence inventory;
- `eclipse-26.10-rc1` build and SHA256;
- real-hardware guide and known-issues matrix.

Acceptance:

- at least the documented minimum hardware matrix passes or is explicitly
  listed as unsupported;
- installer runs on UEFI and BIOS real hardware without data loss in the
  tested scenarios;
- Secure Boot documented and tested, or clearly marked disabled for RC;
- no secrets, telemetry or unreviewed proprietary components;
- release notes list every known issue and difference from upstream.

## Stretch — `experimental/kernel`

A separate educational hobby kernel under `experimental/kernel/`:

- x86_64 UEFI application built with C or Rust;
- no dependency on the Debian ISO build;
- obtains a framebuffer via GOP;
- prints `Hello from EclipseOS kernel`;
- boots in QEMU with OVMF;
- clear docs that it is not the EclipseOS product kernel.

It must never replace or block the main OS build.

## Cross-phase quality gates

- `make doctor` passes on the documented build host.
- `make iso` produces a hybrid ISO and checksum.
- QEMU UEFI and BIOS smoke tests pass.
- Checked-in scripts pass shell lint/static checks.
- New upstream components are added to `docs/licenses.md`.
- Every destructive installer path has a warning and test evidence.
- No claim of success precedes actual execution.
- Build output is deterministic where verified; otherwise described honestly.
