# Phase 2 evidence

Phase 2 is a **candidate, not fully accepted**. This directory records what was
actually observed, including failed experiments and the QEMU/VirtualBox split.

## Verification matrix

| Check | QEMU (CI) | Real VirtualBox | Real hardware |
| --- | --- | --- | --- |
| Phase 2 default boot, UEFI + BIOS | **Passed** in run 39903705903 at 1280x800 | **Not run on the final ISO**; a manual BIOS boot of `768a4f9` reached the desktop | Not tested |
| VirtualBox storage profile (UEFI, pc/IDE, 2048 MiB) | **Passed** in run 39903705903 at 1280x800 | BIOS manual pass at 3000 MiB on `768a4f9`; UEFI not run | Not applicable |
| Plasma X11 in a VM | **Passed**: `session=x11`, `virt=kvm`, `selection=eclipseos-x11` | Manual boot reached the desktop; the marker was not captured | Not applicable |
| Plasma desktop at 1920x1080 | **Passed** for both dark and light | Not captured at 1920x1080 | Not captured |
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
start, the serial boot marker fires and the framebuffer is not blank. It does
not prove VMSVGA behaviour in VirtualBox, Guest Additions integration, a real
greeter login, the power-off interaction or real-hardware Wayland. Those
remain manual gates.

## Final QEMU build: run 39903705903

GitHub Actions [run
39903705903](https://github.com/nexarift-cmd/eclipseos/actions/runs/39903705903)
from commit `0dd6f0f` passed the static checks, built the ISO and passed all
six QEMU boots:

| Boot | Result | Size | Evidence |
| --- | --- | --- | --- |
| UEFI q35, default dark | Pass | 1280x800 | [screenshot](qemu-uefi-1280x800.png), [result](qemu-uefi-1280x800-result.json) |
| BIOS q35, default dark | Pass | 1280x800 | artifact JSON in CI run 39903705903 |
| UEFI pc/IDE, VirtualBox storage profile, 2048 MiB | Pass | 1280x800 | artifact JSON in CI run 39903705903 |
| BIOS q35, one-shot light, EDID 1920x1080 | Pass | 1920x1080 | [screenshot](qemu-1920-light.png), [result](qemu-1920-light-result.json), [serial transcript](qemu-1920-light-serial.txt) |
| UEFI q35, dark, EDID 1920x1080 (capture taken after the Firefox launch) | Pass | 1920x1080 | [screenshot](qemu-1920-dark.png), [result](qemu-1920-dark-result.json) |
| UEFI q35, greeter, EDID 1920x1080 | Pass | 1920x1080 | [screenshot](qemu-sddm-greeter.png), [result](qemu-sddm-greeter-result.json) |

- ISO: `eclipseos-26.10-amd64.iso`
- ISO SHA-256:
  `0e8497bda36da7d371a93e35fe37547282a56586d1e5338e94f432569d96aa10`
- ISO size: `1,503,243,197` bytes.
- ISO artifact: `12480521603`.
- Test evidence artifact: `12479889519`.

The three default boots reported:

```text
ECLIPSEOS_BOOT_OK stage=desktop session=x11 theme=dark theme_status=not-checked applied_theme=not-checked scheme=unknown plasma_theme=default lookandfeel=org.eclipseos.desktop virt=kvm selection=eclipseos-x11 vm_tuning=1 failed_units=0
```

The light boot reported:

```text
ECLIPSEOS_BOOT_OK stage=desktop session=x11 theme=light theme_status=applied applied_theme=light scheme=unknown plasma_theme=default lookandfeel=org.eclipseos.light.desktop virt=kvm selection=eclipseos-x11 vm_tuning=1 failed_units=0
```

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
ECLIPSEOS_BOOT_OK stage=greeter session=greeter theme=dark scheme=EclipseOS plasma_theme=default lookandfeel=org.eclipseos.desktop virt=kvm selection=eclipseos-x11 vm_tuning=1 failed_units=0
```

The greeter screenshot shows the EclipseOS live user, the password prompt,
Sleep/Restart/Shut Down actions and the session selector reading
`Desktop Session: EclipseOS (X11)`. It does not prove that a password or empty
password login succeeds.

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
Firefox, light-theme, SDDM and VM-tuning changes.

The **final `0dd6f0f` ISO was not booted in real VirtualBox** because the local
download of the 1.5 GB artifact did not complete. The final ISO is covered by
the QEMU evidence above. This is an explicit limitation of this acceptance
record, not a claim that QEMU is a substitute for VirtualBox VMSVGA.

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
key literally named `General`/`KDE`. Run 39903705903 fixes that gate and is the
accepted QEMU evidence set. The broken intermediate screenshot is not included
in this directory.

## Earlier accepted QEMU evidence

Run [39693031395](https://github.com/nexarift-cmd/eclipseos/actions/runs/39693031395)
from commit `78474f5` proved the VM-aware X11 selection at 1280x800 with
`session=x11`, `virt=kvm` and `selection=eclipseos-x11`. It was the first Phase
2 ISO after the session selector. Its ISO SHA-256 was
`fdf62a578dd0a1fbf842b6102aaf07bedc2bfd5da4db033bc3499d26162cdacc`.

Run [39729967798](https://github.com/nexarift-cmd/eclipseos/actions/runs/39729967798)
added the first Start-menu and Firefox evidence. The final run supersedes it
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
configuration keeps X11 as the safe fallback. The final run reported
`session=x11`, `virt=kvm`, `selection=eclipseos-x11` in every QEMU desktop
marker, and the greeter screenshot shows the same X11 selection.

This is deliberately a hypervisor selection, not a crash-loop fallback: SDDM
starts the X server before an X11 session runs, so a Wayland process cannot
switch to `startplasma-x11` after a failure. Real-hardware Wayland remains
unverified because no physical test was performed.

## Outstanding acceptance evidence

- A real VirtualBox run of the final `0dd6f0f` ISO, at least at 2048 MiB and
  preferably at 3000 MiB.
- A real VirtualBox UEFI boot of a Phase 2 ISO with firmware mode, screenshot
  and serial log recorded.
- Actual Start-menu power-off, not only a visible power menu.
- Tray-control interaction, not only visible tray icons.
- A successful SDDM login, not only a rendered password prompt.
- A 4096 MiB VirtualBox run; this host lacks the memory and virtualisation
  passthrough.
- Real-hardware Wayland.
- Subjective visual acceptance of the light and dark captures by the product
  owner. The files are included so that review is explicit, not inferred from
  a green CI job.
