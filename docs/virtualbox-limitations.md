# VirtualBox support and known limitations

Status: **Phase 1.** This document records what EclipseOS does and does not
provide in VirtualBox. It is deliberately explicit: the "pre-installed
VirtualBox guest utilities" part of the original requirement is **not met**,
and the ISO does not pretend otherwise.

## Summary

| Capability | Status in the EclipseOS ISO | Notes |
| --- | --- | --- |
| Boot in VirtualBox UEFI and BIOS | Expected | Automated CI uses QEMU; VirtualBox acceptance is manual and not yet recorded. |
| Graphics controller | VMSVGA | Selected by `scripts/create-vbox-vm.sh`; 128 MiB video RAM. |
| Basic desktop rendering | Expected via the in-kernel `vmwgfx` driver and Mesa | No Oracle Guest Additions required. Performance and maximum resolution depend on the host and VirtualBox version. |
| Automatic guest resolution / window resize | **Not available** | Requires Guest Additions. Set a mode manually with `xrandr` if the virtual monitor exposes one. |
| Seamless mouse integration | **Not available** | The guest uses a relative pointer. Use VirtualBox's host key to release the pointer. |
| Shared clipboard | **Not available** | No Guest Additions. Clipboard settings in the VM do nothing useful. |
| Shared folders | **Not available** | No Guest Additions. |
| 3D acceleration | Unverified | The VM enables VirtualBox's 3D option, but EclipseOS has not been tested with it. If rendering fails, turn 3D off and use the X11 session. |
| USB 3.0 / xHCI | Not enabled by the VM script | The VirtualBox Extension Pack is not distributed with EclipseOS. |
| Secure Boot | **Not tested** | Test with Secure Boot disabled until the signed-boot path is verified in Phase 6. |
| Audio | Expected | Intel HDA emulation. No Guest Additions required. |
| Time synchronisation | systemd-timesyncd over NAT | No Guest Additions time sync. |

## Why the guest utilities are absent

1. Debian 13 (`trixie`) stable does not ship `virtualbox-guest-utils` in its
   stable archive. The package has appeared in Debian `contrib`/unstable, but
   that is not a stable, supportable input for this release.
2. The official Oracle VirtualBox Guest Additions are licensed under the
   VirtualBox Personal Use and Evaluation License (PUEL), not an open-source
   licence. EclipseOS does not redistribute them.
3. There has been no legal review of a backport of Debian's contrib package.
   Until that review exists, shipping it would violate the project's
   open-source-only policy.
4. The VirtualBox Extension Pack is also PUEL and is not distributed.

This is a licensing and support decision, not an oversight.

## What works without Guest Additions

The open-source Linux stack already contains what a VirtualBox guest needs for
a basic desktop:

- the kernel `vmwgfx` driver drives the VMSVGA adapter;
- Mesa provides OpenGL/software rendering;
- the X11 session (Phase 1: LightDM + openbox; Phase 2: Plasma X11 fallback)
  does not depend on Guest Additions;
- NAT networking, DHCP and DNS work through the emulated Ethernet adapter;
- audio works through the emulated HDA controller;
- the VM can boot from the ISO with EFI or BIOS firmware.

The result is usable for testing the operating system, but it is not the
seamless VirtualBox integration a user gets with Guest Additions.

## Manual workarounds

These are host-side or user-side options, not features of the ISO:

- **Resolution:** after login, run `xrandr` to list modes and select one the
  virtual monitor exposes. Do not expect arbitrary host-window resizing.
- **Pointer:** use the VirtualBox host key (usually Right Ctrl) to release the
  pointer from the guest.
- **File transfer:** attach a second virtual disk, use a network service you
  install yourself, or rebuild the ISO with an extra package. EclipseOS does
  not enable SSH or a file-sharing service by default.
- **3D:** disable 3D acceleration in the VM settings if the desktop is black,
  corrupted or extremely slow, then retry the X11 session.
- **Guest Additions:** a user may install Oracle's Guest Additions manually
  inside a running system. They are not part of EclipseOS, are PUEL-licensed,
  and are not covered by EclipseOS testing.

## What the VirtualBox VM script sets

`scripts/create-vbox-vm.sh` creates a VM with:

- 4096 MiB RAM, 2 vCPUs;
- 128 MiB video RAM, VMSVGA;
- EFI firmware by default (`--no-efi` for BIOS);
- a 25 GiB VDI disk;
- the ISO attached to the SATA optical drive;
- NAT networking.

It no longer enables clipboard or drag-and-drop modes, because those settings
would only be meaningful with Guest Additions. If you install Guest Additions
yourself, enable those features in VirtualBox afterwards.

## Acceptance status

No VirtualBox boot has been recorded yet. The Phase 1 acceptance gate requires
a manual UEFI and BIOS boot in VirtualBox; until those runs exist, this page
describes expected behaviour, not a passed test. The QEMU tests exercise the
same ISO but use a different virtual graphics adapter (`-vga std`) and cannot
prove VirtualBox-specific behaviour.

## Future work

The guest-utilities question is revisited only if:

- a future Debian stable release ships a redistributable, reviewed guest
  utilities package; or
- the project decides to document a fully user-installed, non-redistributed
  Guest Additions path after a licence review.

Even then, the decision must be recorded in [`licenses.md`](licenses.md), and
the ISO must keep working without the utilities.
