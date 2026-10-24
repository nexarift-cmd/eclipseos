# Phase 2 evidence

Phase 2 is a **candidate, not fully accepted**. This directory records what was
actually observed, including failed experiments and the QEMU/VirtualBox split.

## Verification matrix

| Check | QEMU (CI) | Real VirtualBox | Real hardware |
| --- | --- | --- | --- |
| Phase 2 default boot, UEFI + BIOS | **Passed** in run 40113308256 at 1280x720 | **Not run on the final ISO**; a manual BIOS boot of `768a4f9` reached the desktop | Not tested |
| VirtualBox storage profile (UEFI, pc/IDE, 2048 MiB) | **Passed** in run 40113308256 at 1280x720 | BIOS manual pass at 3000 MiB on `768a4f9`; UEFI not run | Not applicable |
| Plasma X11 in a VM | **Passed**: `session=x11`, `virt=kvm`, `selection=eclipseos-x11` | Manual boot reached the desktop; the marker was not captured | Not applicable |
| VM display fit and bottom panel | **Passed**: 1280x800 and 1366x768 initial modes both fitted to 1280x720; the whole floating panel was detected at the bottom | Not captured on the final ISO | Not applicable |
| Plasma desktop at 1920x1080 | **Passed** for both dark and light with `eclipseos.display=keep` | Not captured at 1920x1080 | Not captured |
| Light theme boot | **Passed**: genuine light wallpaper and light panel, `theme_status=applied`, `applied_theme=light` | Runtime light switch reported working by the owner on `768a4f9` | Not tested |
| Dark theme boot | **Passed**: dark wallpaper and panel at 1920x1080; the capture shows Firefox open | Owner reported the normal dark desktop; no screenshot | Not captured |
| Branded SDDM greeter | **Passed**: visible at 1920x1080, `Desktop Session: EclipseOS (X11)` | Not captured | Not captured |
| Start menu open/search/launch | **Passed**: Kickoff open, `firefox` search, Firefox ESR launch and offline start page | Menu/power entry visible per owner; search and launch not recorded | Not tested |
| Start menu power-off action | **Not exercised** | **Not exercised**; only the menu and power entry were visible | Not tested |
| Taskbar pinned launchers and running indicator | **Passed visually** in the desktop and Firefox captures | Owner reported the taskbar usable | Not tested |
| Taskbar tray-control interaction | **Not exercised**; tray icons are visible | **Not exercised** | Not tested |
| Successful SDDM login | **Not exercised**; greeter only | **Not exercised** | Not tested |
| Firefox ESR + EclipseOS start page | **Passed** in QEMU | **Passed** per owner report on `768a4f9` | Not tested |
| Real-hardware Wayland | Not applicable | Not applicable | **Not tested** |
| 4096 MiB VirtualBox | Not applicable | **Not tested**; host has about 5.1 GiB visible RAM | Not applicable |
| Phase 2 acceptance | **Not claimed** | **Not claimed** | **Not claimed** |

QEMU proves the ISO boots, SDDM autologins, the Plasma compositor and shell
start, the serial boot marker fires, the VM display is fitted to 1280x720 and
the framebuffer is not blank. It does not prove VMSVGA behaviour in VirtualBox,
Guest Additions integration, a real greeter login, the power-off interaction or
real-hardware Wayland. Those remain manual gates.

## Current QEMU candidate: run 40113308256

GitHub Actions [run
40113308256](https://github.com/nexarift-cmd/eclipseos/actions/runs/40113308256)
passed the static checks, built the ISO and passed all seven QEMU boots. The
branch head under test is `41645a9` on `phase2-plasma`; the ISO buildinfo
records `51ea5ce`, GitHub's synthetic PR merge commit for the same content.
This record describes that code. A later documentation-only commit can be
rebuilt and produce a different ISO checksum; it does not change the boot
evidence for the same code.

| Boot | Result | Size | Evidence |
| --- | --- | --- | --- |
| UEFI q35, default dark | Pass | 1280x720 | [screenshot](qemu-uefi-1280x720.png), [result](qemu-uefi-1280x720-result.json), [serial](qemu-uefi-1280x720-serial.txt) |
| BIOS q35, default dark | Pass | 1280x720 | artifact JSON in CI run 40113308256 |
| UEFI q35, 1366x768 EDID, expected 1280x720, panel check | Pass | 1280x720 | [screenshot](qemu-1366-test-1280x720.png), [result](qemu-1366-test-1280x720-result.json), [serial](qemu-1366-test-1280x720-serial.txt) |
| UEFI pc/IDE, VirtualBox storage profile, 2048 MiB | Pass | 1280x720 | artifact JSON in CI run 40113308256 |
| BIOS q35, one-shot light, EDID 1920x1080, display keep | Pass | 1920x1080 | [screenshot](qemu-1920-light.png), [result](qemu-1920-light-result.json), [serial](qemu-1920-light-serial.txt) |
| UEFI q35, dark, EDID 1920x1080, display keep (capture taken after the Firefox launch) | Pass | 1920x1080 | [screenshot](qemu-1920-dark.png), [result](qemu-1920-dark-result.json) |
| UEFI q35, greeter, EDID 1920x1080 | Pass | 1920x1080 | [screenshot](qemu-sddm-greeter.png), [result](qemu-sddm-greeter-result.json) |

- ISO: `eclipseos-26.10-amd64.iso`
- ISO SHA-256:
  `97fd89e2e82d4ecd006ba584aea8a719d3b8ff0a3471d90dd0c0db611d31af20`
- ISO size: `1,503,267,773` bytes.
- ISO artifact: `12566944320`.
- ISO artifact ZIP SHA-256:
  `b7bfb990edd42c1b207cf28cf1fb13ee7ef091e69f535885587471b04be15008`
- Test evidence artifact: `12568175031`.
- Test evidence ZIP SHA-256:
  `0902763c21a78de59ce64d07cf25604d93cd9d9eca3a543f51d3d21b1ccde2b2`

The default UEFI, BIOS and VirtualBox-storage-profile boots reported the same
display result:

```text
ECLIPSEOS_BOOT_OK stage=desktop session=x11 theme=dark theme_status=not-checked applied_theme=not-checked scheme=unknown plasma_theme=default lookandfeel=org.eclipseos.desktop display=1280x720 display_initial=1280x800 display_mode=EclipseOS-1280x720 display_output=Virtual-1 display_target=1280x720 display_source=modeline display_modeline=existing guard=ready guard_panel=1 virt=kvm selection=eclipseos-x11 vm_tuning=1 failed_units=0
```

The 1366x768 regression gate started from a 1366x768 EDID mode and reported:

```text
ECLIPSEOS_BOOT_OK stage=desktop session=x11 theme=dark theme_status=not-checked applied_theme=not-checked scheme=unknown plasma_theme=default lookandfeel=org.eclipseos.desktop display=1280x720 display_initial=1366x768 display_mode=EclipseOS-1280x720 display_output=Virtual-1 display_target=1280x720 display_source=modeline display_modeline=existing guard=ready guard_panel=1 virt=kvm selection=eclipseos-x11 vm_tuning=1 failed_units=0
```

The final marker says `display_modeline=existing` because the pre-Plasma
wrapper and the post-Plasma guard are separate `fit` runs. The first run added
the CVT modeline; the guard saw it already present, re-selected
`EclipseOS-1280x720` and re-anchored the panel. The screenshot is exactly
1280x720. Panel edge detection found the floating panel at rows 663-711 with
an 8 px gap below it, so both top and bottom edges are on-screen. The
`1366x768` gate does not accept 1360x768 or any other mode taller than the
1280x720 target.

The light marker was:

```text
ECLIPSEOS_BOOT_OK stage=desktop session=x11 theme=light theme_status=applied applied_theme=light scheme=unknown plasma_theme=default lookandfeel=org.eclipseos.light.desktop display=1920x1080 display_initial=1920x1080 display_mode=unknown display_output=unknown display_target=keep display_source=keep display_modeline=none guard=ready guard_panel=1 virt=kvm selection=eclipseos-x11 vm_tuning=1 failed_units=0
```

The dark 1920x1080 marker reported the same `display_target=keep` result. Both
visual boots deliberately bypass the fitter, so their screenshots remain
genuine 1920x1080 captures, not upscales. The light panel was detected at rows
1023-1077 and the dark panel at 1023-1071; both are fully visible.

`scheme=unknown` is not a dark-theme fallback. Plasma's look-and-feel manager
can remove the local `ColorScheme` key after applying the colour scheme while
keeping the rendered colours. The light capture is visibly light, the marker
records `lookandfeel=org.eclipseos.light.desktop`, and the apply debug log
records successful `lookandfeel`, `colours`, `desktoptheme` and `wallpaper`
commands. The gate deliberately accepts a missing local `ColorScheme` key but
rejects a non-light look-and-feel, a failed apply, or a non-light saved
`ColorScheme` value.

The greeter boot reported:

```text
ECLIPSEOS_BOOT_OK stage=greeter session=greeter theme=dark scheme=EclipseOS plasma_theme=default lookandfeel=org.eclipseos.desktop display=unknown display_initial=unknown display_mode=unknown display_output=unknown display_target=unknown display_source=unknown display_modeline=unknown virt=kvm selection=eclipseos-x11 vm_tuning=1 failed_units=0
```

The greeter screenshot shows the EclipseOS live user, the password prompt,
Sleep/Restart/Shut Down actions and the session selector reading
`Desktop Session: EclipseOS (X11)`. It does not prove that a password or empty
password login succeeds. No desktop panel exists at the greeter, so the panel
check correctly reports absent.

## Start menu and Firefox

The dark 1920x1080 boot also exercised Kickoff with QMP keyboard input. The
screenshots are:

- [Kickoff open, with the power actions visible](qemu-startmenu-open.png)
- [Firefox search result](qemu-startmenu-search.png)
- [Firefox launched with the EclipseOS start page](qemu-1920-dark.png)

The last image is the same framebuffer as the dark-theme capture: Firefox ESR
is running with its taskbar entry active, and the start page URL is local
(`file:///usr/share/eclipseos/browser/home.html`). There is no separate
duplicate Firefox still. The automation is best-effort visual evidence: it
opens the menu, types `firefox`, presses Enter and captures the result. It
does not click the power action or tray controls.

## Real VirtualBox: 3000 MiB, BIOS, `768a4f9`

The project owner reported a boot of the ISO from run
[39842389588](https://github.com/nexarift-cmd/eclipseos/actions/runs/39842389588)
from commit `768a4f9` with 3000 MiB RAM and **EFI off** (VirtualBox BIOS):

- Desktop reached: yes; exact time not recorded.
- Lag: improved compared with the earlier 2048 MiB report.
- Firefox start page: working.
- Power menu: visible.
- Runtime light-theme switch: reported working.
- Problems: none reported.

`VBoxManage showvminfo UltraSigmaEclipseOS` confirms the machine was left at
3000 MiB, BIOS firmware, VMSVGA with 128 MiB VRAM, an IDE-attached ISO, and a
26:49 VBox session. The report did not include a framebuffer screenshot or a
serial log, and it does **not** cover VirtualBox UEFI. The complete scope and
limits are in
[`virtualbox-3000-bios-manual.md`](virtualbox-3000-bios-manual.md).

The earlier 2048 MiB Phase 2 report for commit `78474f5` remains in
[`virtualbox-2048-manual.md`](virtualbox-2048-manual.md); it predates the
Firefox, light-theme, SDDM, display-fit and VM-tuning changes.

The **final `41645a9` ISO was not booted in real VirtualBox**. The local
download of the 1.5 GB artifact did not complete, so the final ISO is covered
by QEMU evidence only. This is an explicit limitation of this acceptance
record, not a claim that QEMU is a substitute for VirtualBox VMSVGA. The 2048
MiB size is the acceptance size on this host; 4096 MiB is recommended but
cannot be tested on a host with about 5.1 GiB visible RAM and no usable
virtualisation passthrough.

## Display-fit experiments and failed intermediate runs

The 1366x768 panel bug was reproduced by the earlier QEMU gate. Run
[40107374670](https://github.com/nexarift-cmd/eclipseos/actions/runs/40107374670)
ended at 1360x768 instead of 1280x720 and the panel was not visible in the
capture. That run proved that merely choosing a mode no taller than the host is
wrong when the mode is taller than the 1280x720 target.

Run [40110568685](https://github.com/nexarift-cmd/eclipseos/actions/runs/40110568685)
then ended at 800x600 because the CVT modeline path failed silently; the
fallback selected the largest advertised mode inside the target. The follow-up
commits added a built-in 1280x720 CVT modeline when the `cvt` helper is absent,
kept the added/existing state out of a command-substitution subshell, and added
the driver diagnostics now used by the pass. Run 40113308256 is the first run
where the pre-Plasma fit and the post-Plasma guard both selected 1280x720 and
the panel passed the edge check.

## Earlier failed light-theme experiments

Run [39842389588](https://github.com/nexarift-cmd/eclipseos/actions/runs/39842389588)
from `768a4f9` passed the six QEMU boots, but its light screenshot was still
dark. The cause was that `eclipseos-theme apply` inferred the theme from
`kdeglobals` after Plasma had changed the file, so it applied the dark
look-and-feel. The fix reads the authoritative `/run/eclipseos-theme` value
written by the pre-SDDM service and re-asserts the selected keys.

Run [39902097199](https://github.com/nexarift-cmd/eclipseos/actions/runs/39902097199)
from `0cb6c5e` produced a genuinely light 1920x1080 screenshot, but the QEMU
light test was marked failed because the new gate called `read_key` with a
group argument it does not accept. The screenshot was correct; the gate read a
key literally named `General`/`KDE`. Run 39908248658 fixed that gate. Its
captures remain historical evidence; run 40113308256 supersedes them for the
current candidate.

## Earlier accepted QEMU evidence

Run [39908248658](https://github.com/nexarift-cmd/eclipseos/actions/runs/39908248658)
from commit `716378a` passed UEFI, BIOS, the VirtualBox storage profile and the
1920x1080 light, dark and greeter captures at 1280x800. Its ISO SHA-256 was
`875de1db5bf988169b8e0c804b059cbeeaeffe6ae485598049ba47f0fb0124ea`
(artifact `12482665020`, evidence `12481998046`). It was the previous candidate
before the VM display-fit and panel-guard work.

Run [39693031395](https://github.com/nexarift-cmd/eclipseos/actions/runs/39693031395)
from commit `78474f5` proved the VM-aware X11 selection at 1280x800 with
`session=x11`, `virt=kvm` and `selection=eclipseos-x11`. It was the first Phase
2 ISO after the session selector. Its ISO SHA-256 was
`fdf62a578dd0a1fbf842b6102aaf07bedc2bfd5da4db033bc3499d26162cdacc`.

Run [39729967798](https://github.com/nexarift-cmd/eclipseos/actions/runs/39729967798)
added the first Start-menu and Firefox evidence. The current run supersedes it
with fresh 1920x1080 captures and the corrected light-theme path.

The first Plasma ISO used Wayland and passed the same QEMU gates in run
39553121980. The earlier 1920x1080 Wayland EDID experiment in run 39555039318
produced a black framebuffer with only the cursor:
[qemu-uefi-std-edid-1920x1080-black.png](qemu-uefi-std-edid-1920x1080-black.png).
That result is retained as a negative experiment; the successful 1920x1080
captures use the VM X11 session.

## Automatic X11 in virtual machines

`eclipseos-session.service` runs before SDDM, calls
`systemd-detect-virt --vm`, and writes a late SDDM drop-in selecting
`eclipseos-x11` for VMs and `eclipseos-wayland` otherwise. The static SDDM
configuration keeps X11 as the safe fallback. The current run reported
`session=x11`, `virt=kvm`, `selection=eclipseos-x11` in every QEMU desktop
marker, and the greeter screenshot shows the same X11 selection.

This is deliberately a hypervisor selection, not a crash-loop fallback: SDDM
starts the X server before an X11 session runs, so a Wayland process cannot
switch to `startplasma-x11` after a failure. Real-hardware Wayland remains
unverified because no physical test was performed.

## Outstanding acceptance evidence

- A real VirtualBox run of the final `41645a9` ISO, at least at 2048 MiB and
  preferably at 3000 MiB.
- A real VirtualBox UEFI boot of a Phase 2 ISO with firmware mode, screenshot
  and serial log recorded.
- Actual Start-menu power-off, not only a visible power menu.
- Tray-control interaction, not only visible tray icons.
- A successful SDDM login, not only a rendered password prompt.
- A 4096 MiB VirtualBox run; this host lacks the memory and virtualisation
  passthrough.
- Real-hardware Wayland.
- Subjective visual acceptance of the light, dark and fitted 1280x720 captures
  by the product owner. The files are included so that review is explicit, not
  inferred from a green CI job.
