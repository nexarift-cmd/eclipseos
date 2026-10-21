# Phase 2 evidence

Phase 2 is **in progress and not accepted**. This directory records what was
actually observed, including failed experiments and the QEMU/VirtualBox split.

## Verification matrix

| Check | QEMU (CI) | Real VirtualBox | Real hardware |
| --- | --- | --- | --- |
| Phase 1 live ISO at 2048 MiB | Storage-profile QEMU pass | **Accepted** (EFI and BIOS) | Not tested |
| Plasma first boot, Wayland | **Passed** at 1280x800 before the VM selector | Not tested | Not tested |
| Plasma X11 in a VM | Pending the VM-selector build | **Not tested for Phase 2** | Not applicable |
| Plasma at 1920x1080 | **Not captured** | Not captured | Not captured |
| Light theme | Manual test target only; not captured | Not captured | Not captured |
| Phase 2 acceptance | **Not claimed** | **Not claimed** | **Not claimed** |

QEMU proves the ISO boots, SDDM autologins, the Plasma compositor and shell
start, the serial boot marker fires and the framebuffer is not blank. It does
not prove VMSVGA behaviour, VirtualBox Guest Additions integration or
real-hardware Wayland. Those remain manual gates.

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

## Rejected 1920x1080 EDID experiment

A test-only QEMU std-VGA EDID override (`xres=1920,yres=1080`) was tried in
[run 39555039318](https://github.com/nexarift-cmd/eclipseos/actions/runs/39555039318).
Plasma and KWin started, but the framebuffer was black except for the cursor;
the test correctly failed. The image is kept as
[qemu-uefi-std-edid-1920x1080-black.png](qemu-uefi-std-edid-1920x1080-black.png),
with the serial line in
[qemu-uefi-std-edid-1920x1080-black-serial.log](qemu-uefi-std-edid-1920x1080-black-serial.log).
The EDID override is not part of the build or test gate.

## Automatic X11 in virtual machines

`eclipseos-session.service` runs before SDDM, calls
`systemd-detect-virt --vm`, and writes a late SDDM drop-in selecting
`eclipseos-x11` for VMs and `eclipseos-wayland` otherwise. The static SDDM
configuration keeps X11 as the safe fallback. This is deliberately a
hypervisor selection, not a crash-loop fallback: SDDM starts the X server
before an X11 session runs, so a Wayland process cannot switch to
`startplasma-x11` after a failure.

The next CI run after this change must show a QEMU marker with
`session=x11`, a VM `virt=` value and `selection=eclipseos-x11`; that evidence
is not claimed here until the run completes. VirtualBox Phase 2 must be
recorded separately; the Phase 1 VirtualBox result does not prove it.

## Outstanding acceptance evidence

- Real VirtualBox UEFI and BIOS boots of a Phase 2 ISO at 2048 MiB.
- 1920x1080 dark and light desktop screenshots from real hardware or a
  working accelerated VM, not an artificial upscale.
- Start menu open/search/launch/power-off interaction.
- Taskbar running indicators and tray controls.
- Real-hardware Wayland boot.
