# Phase 2 evidence

Phase 2 is **in progress and not accepted**. This directory records what was
actually observed, including failed experiments and the QEMU/VirtualBox split.

## Verification matrix

| Check | QEMU (CI) | Real VirtualBox | Real hardware |
| --- | --- | --- | --- |
| Phase 1 live ISO at 2048 MiB | Storage-profile QEMU pass | **Accepted** (EFI and BIOS) | Not tested |
| Plasma first boot, Wayland | **Passed** at 1280x800 before the VM selector | Not applicable to the current VM selector | Not tested |
| Plasma X11 in a VM | **Passed** in run 39693031395; marker reported `session=x11`, `selection=eclipseos-x11` | **Passed** in one manual 2048 MiB boot | Not applicable |
| Plasma desktop in real VirtualBox at 2048 MiB | n/a | **Passed** (manual report, see [virtualbox-2048-manual.md](virtualbox-2048-manual.md)) | Not tested |
| Plasma at 1920x1080 | Capture path being re-tested with X11; not yet claimed | Not captured | Not captured |
| Light theme | Manual test target only; not yet captured | Not captured | Not captured |
| Branded SDDM greeter | Manual test target added; not yet captured | Not captured | Not captured |
| Pinned taskbar applications | Previous ISO showed one generic icon; array fix is awaiting a new screenshot | Not re-tested | Not tested |
| Phase 2 acceptance | **Not claimed** | **Not claimed** | **Not claimed** |

QEMU proves the ISO boots, SDDM autologins, the Plasma compositor and shell
start, the serial boot marker fires and the framebuffer is not blank. It does
not prove VMSVGA behaviour, VirtualBox Guest Additions integration or
real-hardware Wayland. Those remain manual gates.

## Run 39693031395: VM X11 selection

Build #16, GitHub Actions run
[39693031395](https://github.com/nexarift-cmd/eclipseos/actions/runs/39693031395)
from commit `78474f5`, passed the static checks, built the ISO and passed the
UEFI, BIOS and VirtualBox-storage-profile QEMU gates.

- ISO SHA-256:
  `fdf62a578dd0a1fbf842b6102aaf07bedc2bfd5da4db033bc3499d26162cdacc`
- ISO artifact: `12390332016`
- Test evidence artifact: `12390301964`
- Boot marker:
  `ECLIPSEOS_BOOT_OK stage=desktop session=x11 theme=dark virt=kvm selection=eclipseos-x11 failed_units=0`
- Screenshots: 1280x800, non-black content approximately 51.5%.

This run proved the ShellCheck SC2016 fix, the VM-aware X11 selection, and
that the current Phase 2 ISO can autologin to Plasma X11 under QEMU. It did not
test VirtualBox, 1920x1080, the light theme or the SDDM greeter.

## First Plasma ISO, QEMU Wayland

The first Plasma build passed the UEFI, BIOS and VirtualBox-storage-profile
QEMU tests in [run
39553121980](https://github.com/nexarift-cmd/eclipseos/actions/runs/39553121980)
from commit `152cc90`. It used Plasma Wayland and reported
`session=wayland failed_units=0` at 1280x800.
The ISO SHA-256 was `a60ae34046138653ab0541d8aa6396d18f3bb91e3e94b68e5178c2a0a79fc5f5`.
That run predates the centred-taskbar layout and the VM X11 selector.

The layout commit `80c8b13` passed the same three QEMU gates in [run
39556703403](https://github.com/nexarift-cmd/eclipseos/actions/runs/39556703403).
Its ISO SHA-256 was
`ca5f25f53fc1092b68968917391b7c7fdeab03706c38226e16cd1bea2c27c8cb`.
The captured desktop is [qemu-uefi-wayland-1280x800.png](qemu-uefi-wayland-1280x800.png);
the serial line is
[qemu-uefi-wayland-1280x800-serial.log](qemu-uefi-wayland-1280x800-serial.log)
and the machine-readable result is
[qemu-uefi-wayland-1280x800-result.json](qemu-uefi-wayland-1280x800-result.json).

This screenshot is evidence that Plasma, KWin and the panel start. It is not
final visual acceptance: only one pinned task icon rendered, and the capture
is 1280x800 rather than the required 1920x1080.

## Real VirtualBox boot at 2048 MiB

The project owner booted the run 39693031395 ISO in VirtualBox 7.2.20r175154
with 2048 MiB RAM. Plasma, the taskbar, Start menu, desktop applications, the
EclipseOS theme and networking (`ping debian.org`, 3/3 replies) worked.
`free -m` showed 633 MB available. A slight lag was observed on the
approximately 5 GiB Ryzen 3 2200U host; it is recorded as an observation, not
a failure. See [virtualbox-2048-manual.md](virtualbox-2048-manual.md) for the
limits of this manual evidence.

## Previous 1920x1080 EDID experiment

A test-only QEMU std-VGA EDID override (`xres=1920,yres=1080`) was tried in
[run 39555039318](https://github.com/nexarift-cmd/eclipseos/actions/runs/39555039318)
with Wayland. Plasma and KWin started, but the framebuffer was black except
for the cursor; the test correctly failed. The image is kept as
[qemu-uefi-std-edid-1920x1080-black.png](qemu-uefi-std-edid-1920x1080-black.png),
with the serial line in
[qemu-uefi-std-edid-1920x1080-black-serial.log](qemu-uefi-std-edid-1920x1080-black-serial.log).
The EDID override was rejected for Wayland. It is now an opt-in QEMU test
option only and is being re-tested with the VM X11 session; it is not part of
the release gate or the ISO.

## Automatic X11 in virtual machines

`eclipseos-session.service` runs before SDDM, calls
`systemd-detect-virt --vm`, and writes a late SDDM drop-in selecting
`eclipseos-x11` for VMs and `eclipseos-wayland` otherwise. The static SDDM
configuration keeps X11 as the safe fallback. This is deliberately a
hypervisor selection, not a crash-loop fallback: SDDM starts the X server
before an X11 session runs, so a Wayland process cannot switch to
`startplasma-x11` after a failure.

Run 39693031395 confirmed the QEMU marker reports `session=x11`, `virt=kvm`
and `selection=eclipseos-x11`. VirtualBox Phase 2 is covered only by the
manual 2048 MiB report above; the Phase 1 VirtualBox result does not prove it.

## Outstanding acceptance evidence

- Real VirtualBox UEFI and BIOS boots of a Phase 2 ISO at 2048 MiB, with
  firmware mode and screenshot/serial log recorded for each.
- 1920x1080 dark and light desktop screenshots from a genuine 1920x1080
  framebuffer, not an artificial upscale.
- Start menu open/search/launch/power-off interaction.
- Taskbar pinned applications, running indicators and tray controls.
- Branded SDDM greeter screenshot and a successful login.
- Real-hardware Wayland boot.
